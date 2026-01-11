#!/usr/bin/env bash
#
# test_helper.bash - Common fixtures and utilities for Bats tests
#

# Get the project root directory
export PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)"
export SCRIPTS_DIR="${PROJECT_ROOT}/scripts"

# Create a temporary directory for each test
setup() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export HOME="${TEST_TEMP_DIR}/home"
    mkdir -p "$HOME"
    mkdir -p "${HOME}/.config/claude-remote"
    mkdir -p "${HOME}/.local/bin"
    mkdir -p "${HOME}/.local/share/claude-remote"
}

# Cleanup after each test
teardown() {
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper to source a script function without running main
source_functions() {
    local script="$1"
    # Extract and source only function definitions
    # This is a simplified approach - we'll source the whole script in a subshell
    # and export the function
    true
}

# Create a mock credential file
create_mock_credentials() {
    local password="${1:-testpassword123}"
    echo "$password" > "${HOME}/.config/claude-remote/web-credentials"
    chmod 600 "${HOME}/.config/claude-remote/web-credentials"
}

# Create a mock ttyd binary
create_mock_ttyd() {
    cat > "${HOME}/.local/bin/ttyd" << 'EOF'
#!/bin/bash
echo "mock ttyd called with: $@"
exit 0
EOF
    chmod +x "${HOME}/.local/bin/ttyd"
}

# Create a mock tmux that logs commands
create_mock_tmux() {
    cat > "${HOME}/.local/bin/tmux" << 'EOF'
#!/bin/bash
echo "$@" >> "${HOME}/.tmux_commands.log"
case "$1" in
    has-session)
        # Return success if session name contains "existing"
        [[ "$3" == *"existing"* ]] && exit 0 || exit 1
        ;;
    list-sessions)
        echo "main: 1 windows (created Mon Jan 10 10:00:00 2026)"
        echo "work: 2 windows (created Mon Jan 10 11:00:00 2026)"
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
EOF
    chmod +x "${HOME}/.local/bin/tmux"
    export PATH="${HOME}/.local/bin:$PATH"
}

# Helper to check if a command was called with specific args
assert_tmux_called_with() {
    local expected="$1"
    grep -q "$expected" "${HOME}/.tmux_commands.log"
}

# Extract a function from a bash script and make it available
load_function() {
    local script="$1"
    local func_name="$2"

    # Source the script in a way that we can access its functions
    # We use 'declare -f' to extract function definitions
    (
        # Prevent the script from executing by overriding main behaviors
        set +e
        TMUX="" # Unset TMUX to avoid nested checks

        # Create stubs for commands that might run
        command() { :; }
        tmux() { :; }

        # Source the script
        source "$script" 2>/dev/null || true

        # Print the function definition
        declare -f "$func_name"
    )
}
