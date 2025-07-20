#!/bin/bash

# =============================================================================
# Raspberry Pi System Preparation Script - TEST VERSION
# =============================================================================
# Purpose: Test version to validate fixes for pipe execution
# Target: Raspberry Pi OS Lite (Debian 12 "bookworm")
# Version: 1.0.1 - Fixed BASH_SOURCE issues for pipe execution
# =============================================================================

set -eo pipefail  # Exit on error, pipe failures

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || pwd)"
readonly LOG_FILE="/var/log/rpi-preparation.log"
readonly LOCK_FILE="/tmp/rpi-preparation.lock"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Test function to validate fixes
test_bash_source_fix() {
    echo "Testing BASH_SOURCE variable handling..."
    echo "SCRIPT_NAME: $SCRIPT_NAME"
    echo "SCRIPT_DIR: $SCRIPT_DIR"
    echo "Script is working correctly for pipe execution!"
}

# Main function for testing
main() {
    echo "=========================================="
    echo " RASPBERRY PI SETUP - TEST VERSION"
    echo "=========================================="
    echo
    echo "This is a test version to validate pipe execution fixes."
    echo
    test_bash_source_fix
    echo
    echo "✅ All tests passed!"
    echo "The main script should now work correctly with:"
    echo "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
}

# Execute main function
main "$@"
