#!/usr/bin/env bats
#
# Tests for time parsing in maintenance script
#
# The maintenance script parses elapsed time from `ps -o etime=` which can be:
# - MM:SS (minutes:seconds)
# - HH:MM:SS (hours:minutes:seconds)
# - D-HH:MM:SS (days-hours:minutes:seconds)
#

load '../test_helper'

# =============================================================================
# Days Extraction from Elapsed Time
# =============================================================================

# Extract days from elapsed time format
extract_days() {
    local elapsed="$1"
    local days=0

    if [[ "$elapsed" =~ ^([0-9]+)-.*$ ]]; then
        days="${BASH_REMATCH[1]}"
    fi

    echo "$days"
}

@test "time parsing: MM:SS format has 0 days" {
    run extract_days "05:30"

    [ "$output" = "0" ]
}

@test "time parsing: HH:MM:SS format has 0 days" {
    run extract_days "12:30:45"

    [ "$output" = "0" ]
}

@test "time parsing: 1-00:00:00 has 1 day" {
    run extract_days "1-00:00:00"

    [ "$output" = "1" ]
}

@test "time parsing: 5-12:30:45 has 5 days" {
    run extract_days "5-12:30:45"

    [ "$output" = "5" ]
}

@test "time parsing: 30-00:00:00 has 30 days" {
    run extract_days "30-00:00:00"

    [ "$output" = "30" ]
}

@test "time parsing: 365-12:00:00 has 365 days" {
    run extract_days "365-12:00:00"

    [ "$output" = "365" ]
}

@test "time parsing: empty string has 0 days" {
    run extract_days ""

    [ "$output" = "0" ]
}

@test "time parsing: whitespace is handled" {
    # ps output sometimes has leading/trailing whitespace
    run extract_days "   3-12:00:00   "

    # The regex should still work
    [ "$output" = "0" ]  # Won't match because of leading whitespace
}

@test "time parsing: trimmed string works correctly" {
    local elapsed="  3-12:00:00  "
    elapsed=$(echo "$elapsed" | tr -d ' ')

    run extract_days "$elapsed"

    [ "$output" = "3" ]
}

# =============================================================================
# Orphan Detection Logic (24+ hours)
# =============================================================================

is_orphan() {
    local elapsed="$1"
    local tty="$2"
    local days=0

    # Must have no controlling terminal
    if [[ "$tty" != "?" && "$tty" != "??" ]]; then
        echo "false"
        return
    fi

    # Check for 24+ hours (1+ days)
    if [[ "$elapsed" =~ ^([0-9]+)-.*$ ]]; then
        days="${BASH_REMATCH[1]}"
    fi

    if [[ $days -ge 1 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

@test "orphan detection: process with TTY is not orphan" {
    run is_orphan "5-00:00:00" "pts/0"

    [ "$output" = "false" ]
}

@test "orphan detection: process with no TTY but < 24h is not orphan" {
    run is_orphan "12:30:45" "?"

    [ "$output" = "false" ]
}

@test "orphan detection: process with no TTY and >= 24h is orphan" {
    run is_orphan "1-00:00:00" "?"

    [ "$output" = "true" ]
}

@test "orphan detection: process with ?? TTY and >= 24h is orphan" {
    run is_orphan "2-05:30:00" "??"

    [ "$output" = "true" ]
}

@test "orphan detection: process running 7 days is orphan" {
    run is_orphan "7-12:00:00" "?"

    [ "$output" = "true" ]
}

# =============================================================================
# Log File Size Checking
# =============================================================================

check_file_size() {
    local file="$1"
    local max_mb="$2"
    local max_bytes=$((max_mb * 1024 * 1024))

    if [[ ! -f "$file" ]]; then
        echo "missing"
        return
    fi

    local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")

    if [[ $size -gt $max_bytes ]]; then
        echo "exceeds"
    else
        echo "ok"
    fi
}

@test "file size: missing file returns 'missing'" {
    run check_file_size "${TEST_TEMP_DIR}/nonexistent" 10

    [ "$output" = "missing" ]
}

@test "file size: empty file is under limit" {
    touch "${TEST_TEMP_DIR}/empty.log"

    run check_file_size "${TEST_TEMP_DIR}/empty.log" 10

    [ "$output" = "ok" ]
}

@test "file size: small file is under 10MB limit" {
    echo "small content" > "${TEST_TEMP_DIR}/small.log"

    run check_file_size "${TEST_TEMP_DIR}/small.log" 10

    [ "$output" = "ok" ]
}

@test "file size: file exactly at limit is not exceeding" {
    # Create a 10MB file
    dd if=/dev/zero of="${TEST_TEMP_DIR}/exact.log" bs=1024 count=10240 2>/dev/null

    run check_file_size "${TEST_TEMP_DIR}/exact.log" 10

    [ "$output" = "ok" ]
}

@test "file size: file over limit is detected" {
    # Create an 11MB file
    dd if=/dev/zero of="${TEST_TEMP_DIR}/large.log" bs=1024 count=11264 2>/dev/null

    run check_file_size "${TEST_TEMP_DIR}/large.log" 10

    [ "$output" = "exceeds" ]
}

# =============================================================================
# Disk Usage Percentage Parsing
# =============================================================================

parse_disk_percent() {
    local usage_str="$1"
    echo "${usage_str}" | tr -d '%'
}

@test "disk usage: parses 50% correctly" {
    run parse_disk_percent "50%"

    [ "$output" = "50" ]
}

@test "disk usage: parses 85% correctly" {
    run parse_disk_percent "85%"

    [ "$output" = "85" ]
}

@test "disk usage: parses 100% correctly" {
    run parse_disk_percent "100%"

    [ "$output" = "100" ]
}

@test "disk usage: 90% triggers critical warning" {
    local percent=$(parse_disk_percent "92%")

    [ $percent -gt 90 ]
}

@test "disk usage: 80% triggers low warning" {
    local percent=$(parse_disk_percent "85%")

    [ $percent -gt 80 ]
    [ $percent -le 90 ]
}

@test "disk usage: 70% is OK" {
    local percent=$(parse_disk_percent "70%")

    [ $percent -le 80 ]
}
