#!/usr/bin/env bats
#
# Smoke tests for script syntax validation
#
# These tests verify that all bash scripts:
# - Parse without syntax errors
# - Have correct shebang
# - Have executable patterns
#

load '../test_helper'

# =============================================================================
# Script Syntax Validation
# =============================================================================

@test "syntax: install.sh parses without errors" {
    run bash -n "${PROJECT_ROOT}/install.sh"

    [ "$status" -eq 0 ]
}

@test "syntax: uninstall.sh parses without errors" {
    run bash -n "${PROJECT_ROOT}/uninstall.sh"

    [ "$status" -eq 0 ]
}

@test "syntax: claude-session parses without errors" {
    run bash -n "${SCRIPTS_DIR}/claude-session"

    [ "$status" -eq 0 ]
}

@test "syntax: web-terminal parses without errors" {
    run bash -n "${SCRIPTS_DIR}/web-terminal"

    [ "$status" -eq 0 ]
}

@test "syntax: ttyd-wrapper parses without errors" {
    run bash -n "${SCRIPTS_DIR}/ttyd-wrapper"

    [ "$status" -eq 0 ]
}

@test "syntax: status parses without errors" {
    run bash -n "${SCRIPTS_DIR}/status"

    [ "$status" -eq 0 ]
}

@test "syntax: maintenance parses without errors" {
    run bash -n "${SCRIPTS_DIR}/maintenance"

    [ "$status" -eq 0 ]
}

# =============================================================================
# Shebang Validation
# =============================================================================

check_shebang() {
    local file="$1"
    local first_line=$(head -n1 "$file")

    [[ "$first_line" =~ ^#!.*bash ]] || [[ "$first_line" =~ ^#!/bin/sh ]]
}

@test "shebang: install.sh has bash shebang" {
    run check_shebang "${PROJECT_ROOT}/install.sh"

    [ "$status" -eq 0 ]
}

@test "shebang: uninstall.sh has bash shebang" {
    run check_shebang "${PROJECT_ROOT}/uninstall.sh"

    [ "$status" -eq 0 ]
}

@test "shebang: claude-session has bash shebang" {
    run check_shebang "${SCRIPTS_DIR}/claude-session"

    [ "$status" -eq 0 ]
}

@test "shebang: web-terminal has bash shebang" {
    run check_shebang "${SCRIPTS_DIR}/web-terminal"

    [ "$status" -eq 0 ]
}

@test "shebang: ttyd-wrapper has bash shebang" {
    run check_shebang "${SCRIPTS_DIR}/ttyd-wrapper"

    [ "$status" -eq 0 ]
}

@test "shebang: status has bash shebang" {
    run check_shebang "${SCRIPTS_DIR}/status"

    [ "$status" -eq 0 ]
}

@test "shebang: maintenance has bash shebang" {
    run check_shebang "${SCRIPTS_DIR}/maintenance"

    [ "$status" -eq 0 ]
}

# =============================================================================
# File Existence
# =============================================================================

@test "file exists: install.sh" {
    [ -f "${PROJECT_ROOT}/install.sh" ]
}

@test "file exists: uninstall.sh" {
    [ -f "${PROJECT_ROOT}/uninstall.sh" ]
}

@test "file exists: scripts/claude-session" {
    [ -f "${SCRIPTS_DIR}/claude-session" ]
}

@test "file exists: scripts/web-terminal" {
    [ -f "${SCRIPTS_DIR}/web-terminal" ]
}

@test "file exists: scripts/ttyd-wrapper" {
    [ -f "${SCRIPTS_DIR}/ttyd-wrapper" ]
}

@test "file exists: scripts/status" {
    [ -f "${SCRIPTS_DIR}/status" ]
}

@test "file exists: scripts/maintenance" {
    [ -f "${SCRIPTS_DIR}/maintenance" ]
}

@test "file exists: config/tmux.conf" {
    [ -f "${PROJECT_ROOT}/config/tmux.conf" ]
}

# =============================================================================
# Configuration File Validation
# =============================================================================

@test "config: tmux.conf is not empty" {
    [ -s "${PROJECT_ROOT}/config/tmux.conf" ]
}

@test "config: systemd service file exists" {
    [ -f "${PROJECT_ROOT}/systemd/claude-web.service" ]
}

@test "config: systemd maintenance service exists" {
    [ -f "${PROJECT_ROOT}/systemd/claude-maintenance.service" ]
}

@test "config: systemd maintenance timer exists" {
    [ -f "${PROJECT_ROOT}/systemd/claude-maintenance.timer" ]
}

@test "config: launchd web plist exists" {
    [ -f "${PROJECT_ROOT}/launchd/com.claude.web.plist" ]
}

@test "config: launchd maintenance plist exists" {
    [ -f "${PROJECT_ROOT}/launchd/com.claude.maintenance.plist" ]
}

# =============================================================================
# set -e Validation (scripts should use strict mode)
# =============================================================================

check_set_e() {
    local file="$1"
    grep -q "^set -e" "$file"
}

@test "strict mode: install.sh uses set -e" {
    run check_set_e "${PROJECT_ROOT}/install.sh"

    [ "$status" -eq 0 ]
}

@test "strict mode: claude-session uses set -e" {
    run check_set_e "${SCRIPTS_DIR}/claude-session"

    [ "$status" -eq 0 ]
}

@test "strict mode: ttyd-wrapper uses set -e" {
    run check_set_e "${SCRIPTS_DIR}/ttyd-wrapper"

    [ "$status" -eq 0 ]
}

@test "strict mode: maintenance uses set -e" {
    run check_set_e "${SCRIPTS_DIR}/maintenance"

    [ "$status" -eq 0 ]
}
