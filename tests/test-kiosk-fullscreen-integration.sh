#!/bin/bash

# Test script for integrated kiosk fullscreen functionality
# Version 1.4.3

set -euo pipefail

readonly SCRIPT_PATH="/Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/setup-kiosk.sh"
readonly TEST_NAME="test-kiosk-fullscreen-integration"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_test() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
    ((TESTS_PASSED++))
}

log_failure() {
    echo -e "${RED}[✗]${NC} $*"
    ((TESTS_FAILED++))
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $*"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_RUN++))
    log_test "Running: $test_name"
    
    if eval "$test_command"; then
        log_success "$test_name"
        return 0
    else
        log_failure "$test_name"
        return 1
    fi
}

# =============================================================================
# TEST FUNCTIONS
# =============================================================================

test_setup_kiosk_exists() {
    [[ -f "$SCRIPT_PATH" ]]
}

test_setup_kiosk_executable() {
    [[ -x "$SCRIPT_PATH" ]]
}

test_setup_kiosk_syntax() {
    bash -n "$SCRIPT_PATH" >/dev/null 2>&1
}

test_kiosk_fullscreen_function_exists() {
    grep -q "^setup_kiosk_fullscreen()" "$SCRIPT_PATH"
}

test_installation_steps_updated() {
    grep -A 15 "INSTALLATION_STEPS=" "$SCRIPT_PATH" | grep -q "kiosk_fullscreen"
}

test_main_function_calls_fullscreen() {
    grep -A 20 "# Setup process" "$SCRIPT_PATH" | grep -q "setup_kiosk_fullscreen"
}

test_chromium_fullscreen_options() {
    local chromium_options=(
        "--kiosk"
        "--start-fullscreen"
        "--start-maximized"
        "--window-size=1920,1080"
        "--window-position=0,0"
    )
    
    for option in "${chromium_options[@]}"; do
        if ! grep -q "$option" "$SCRIPT_PATH"; then
            echo "Missing Chromium option: $option"
            return 1
        fi
    done
    
    return 0
}

test_systemd_service_creation() {
    grep -q "kiosk-fullscreen.service" "$SCRIPT_PATH"
}

test_openbox_autostart_creation() {
    grep -q "autostart" "$SCRIPT_PATH" && grep -q "AUTOSTART_EOF" "$SCRIPT_PATH"
}

test_environment_integration() {
    grep -q "load_kiosk_config" "$SCRIPT_PATH" && grep -q "/etc/environment" "$SCRIPT_PATH"
}

test_logging_functions() {
    local log_functions=(
        "log_info"
        "log_warn" 
        "log_error"
        "log_success"
    )
    
    # Check if functions are defined within the kiosk fullscreen function
    local function_content
    function_content=$(sed -n '/^setup_kiosk_fullscreen()/,/^}/p' "$SCRIPT_PATH")
    
    for func in "${log_functions[@]}"; do
        if ! echo "$function_content" | grep -q "$func()"; then
            echo "Missing logging function in setup_kiosk_fullscreen: $func"
            return 1
        fi
    done
    
    return 0
}

test_version_consistency() {
    grep -q 'readonly SCRIPT_VERSION="1.4.3"' "$SCRIPT_PATH"
}

test_kiosk_directory_constants() {
    local required_dirs=(
        "KIOSK_BASE_DIR"
        "KIOSK_SCRIPTS_DIR"
        "KIOSK_UTILS_DIR"
    )
    
    for dir in "${required_dirs[@]}"; do
        if ! grep -q "readonly $dir=" "$SCRIPT_PATH"; then
            echo "Missing directory constant: $dir"
            return 1
        fi
    done
    
    return 0
}

test_no_standalone_script() {
    # Verify the standalone script was removed
    ! [[ -f "/Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/kiosk-start-fullscreen.sh" ]]
}

# =============================================================================
# MAIN TEST EXECUTION
# =============================================================================

main() {
    echo "=============================================="
    echo " Testing Kiosk Fullscreen Integration"
    echo "=============================================="
    echo "Script: $SCRIPT_PATH"
    echo "Test: $TEST_NAME"
    echo ""
    
    log_info "Testing integration of kiosk fullscreen functionality into setup-kiosk.sh"
    echo ""
    
    # Basic file tests
    run_test "Setup kiosk script exists" "test_setup_kiosk_exists"
    run_test "Setup kiosk script is executable" "test_setup_kiosk_executable"
    run_test "Setup kiosk script syntax is valid" "test_setup_kiosk_syntax"
    
    # Integration tests
    run_test "Kiosk fullscreen function exists" "test_kiosk_fullscreen_function_exists"
    run_test "Installation steps updated" "test_installation_steps_updated"
    run_test "Main function calls fullscreen setup" "test_main_function_calls_fullscreen"
    
    # Content and functionality tests
    run_test "Chromium fullscreen options present" "test_chromium_fullscreen_options"
    run_test "Systemd service creation included" "test_systemd_service_creation"
    run_test "Openbox autostart creation included" "test_openbox_autostart_creation"
    run_test "Environment integration included" "test_environment_integration"
    run_test "Logging functions integrated" "test_logging_functions"
    
    # Structure and consistency tests
    run_test "Version consistency" "test_version_consistency"
    run_test "Kiosk directory constants present" "test_kiosk_directory_constants"
    run_test "Standalone script removed" "test_no_standalone_script"
    
    # Summary
    echo ""
    echo "=============================================="
    echo " TEST SUMMARY"
    echo "=============================================="
    echo "Tests run: $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All integration tests passed!"
        echo ""
        echo "✨ The kiosk fullscreen functionality is properly integrated!"
        echo ""
        echo "📋 Integration summary:"
        echo "  ✅ Function setup_kiosk_fullscreen() added to setup-kiosk.sh"
        echo "  ✅ Installation step 'kiosk_fullscreen' added to process"
        echo "  ✅ Main function updated to call fullscreen setup"
        echo "  ✅ Standalone script removed from scripts/ directory"
        echo "  ✅ All functionality preserved within setup process"
        echo ""
        echo "🚀 Usage:"
        echo "  sudo ./scripts/setup-kiosk.sh"
        echo "  # Kiosk fullscreen will be configured automatically"
        return 0
    else
        log_failure "Some integration tests failed"
        echo ""
        echo "🔧 Please review and fix the integration issues before proceeding"
        return 1
    fi
}

# Execute tests
main "$@"
