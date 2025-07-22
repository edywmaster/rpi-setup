#!/bin/bash

# =============================================================================
# Test Script - System Info Utility
# =============================================================================
# Purpose: Test the system-info.sh utility script
# Usage: ./tests/test-system-info.sh
# =============================================================================

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Test configuration
readonly SCRIPT_PATH="./utils/system-info.sh"
readonly TEST_NAME="System Info Utility"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} Testing: $TEST_NAME${NC}"
echo -e "${BLUE}========================================${NC}"

# Test 1: Check if script exists
echo -e "${CYAN}[TEST 1]${NC} Checking if script exists..."
if [[ -f "$SCRIPT_PATH" ]]; then
    echo -e "${GREEN}✅ Script exists: $SCRIPT_PATH${NC}"
else
    echo -e "${RED}❌ Script not found: $SCRIPT_PATH${NC}"
    exit 1
fi

# Test 2: Check if script is executable
echo -e "${CYAN}[TEST 2]${NC} Checking if script is executable..."
if [[ -x "$SCRIPT_PATH" ]]; then
    echo -e "${GREEN}✅ Script is executable${NC}"
else
    echo -e "${YELLOW}⚠️ Script is not executable, making it executable...${NC}"
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}✅ Script made executable${NC}"
fi

# Test 3: Syntax validation
echo -e "${CYAN}[TEST 3]${NC} Validating script syntax..."
if bash -n "$SCRIPT_PATH"; then
    echo -e "${GREEN}✅ Script syntax is valid${NC}"
else
    echo -e "${RED}❌ Script has syntax errors${NC}"
    exit 1
fi

# Test 4: Test script execution (brief mode)
echo -e "${CYAN}[TEST 4]${NC} Testing script execution..."
echo -e "${YELLOW}Running system-info.sh...${NC}"
echo ""

# Run the script and capture basic output
if "$SCRIPT_PATH" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Script executed successfully${NC}"
else
    echo -e "${RED}❌ Script execution failed${NC}"
    exit 1
fi

# Test 5: Check for required functions
echo -e "${CYAN}[TEST 5]${NC} Checking for required functions..."
required_functions=(
    "echo_logo"
    "echo_version"
    "echo_info_system"
    "echo_setup_preparation"
    "echo_setup_kiosk"
    "echo_env_vars"
    "echo_network_info"
    "echo_hardware_status"
    "main"
)

missing_functions=()
for func in "${required_functions[@]}"; do
    if grep -q "^${func}()" "$SCRIPT_PATH"; then
        echo -e "${GREEN}  ✅ Function found: $func${NC}"
    else
        echo -e "${RED}  ❌ Function missing: $func${NC}"
        missing_functions+=("$func")
    fi
done

if [[ ${#missing_functions[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ All required functions found${NC}"
else
    echo -e "${RED}❌ Missing functions: ${missing_functions[*]}${NC}"
    exit 1
fi

# Test 6: Check for cross-platform compatibility measures
echo -e "${CYAN}[TEST 6]${NC} Checking cross-platform compatibility..."
compat_checks=(
    "command -v systemctl"
    "uname.*Darwin"
    "sysctl -n hw.memsize"
    "ifconfig.*flags=.*UP"
)

found_compat=0
for check in "${compat_checks[@]}"; do
    if grep -q "$check" "$SCRIPT_PATH"; then
        ((found_compat++))
    fi
done

if [[ $found_compat -ge 2 ]]; then
    echo -e "${GREEN}✅ Cross-platform compatibility measures found${NC}"
else
    echo -e "${YELLOW}⚠️ Limited cross-platform compatibility detected${NC}"
fi

# Test 7: Verify development environment notes
echo -e "${CYAN}[TEST 7]${NC} Checking for development environment documentation..."
if grep -q "Development Note" "$SCRIPT_PATH" && grep -q "macOS" "$SCRIPT_PATH"; then
    echo -e "${GREEN}✅ Development environment notes found${NC}"
else
    echo -e "${YELLOW}⚠️ Missing development environment documentation${NC}"
fi

# Test 8: Check for proper error handling
echo -e "${CYAN}[TEST 8]${NC} Checking error handling..."
error_handling_patterns=(
    "2>/dev/null"
    "|| echo"
    "command -v.*>/dev/null"
)

found_error_handling=0
for pattern in "${error_handling_patterns[@]}"; do
    if grep -q "$pattern" "$SCRIPT_PATH"; then
        ((found_error_handling++))
    fi
done

if [[ $found_error_handling -ge 2 ]]; then
    echo -e "${GREEN}✅ Error handling patterns found${NC}"
else
    echo -e "${YELLOW}⚠️ Limited error handling detected${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ All tests passed for: $TEST_NAME${NC}"
echo -e "${BLUE}========================================${NC}"

# Environment-specific notes
echo ""
echo -e "${CYAN}📝 Environment Notes:${NC}"
if [[ "$(uname)" == "Darwin" ]]; then
    echo -e "${YELLOW}• Running on macOS - some features will show as 'not available'${NC}"
    echo -e "${YELLOW}• systemctl, vcgencmd, and Pi-specific features not testable${NC}"
    echo -e "${YELLOW}• Full functionality available on Raspberry Pi hardware${NC}"
else
    echo -e "${GREEN}• Running on Linux - full functionality should be available${NC}"
fi

echo ""
echo -e "${CYAN}💡 Usage:${NC}"
echo -e "  Local:  $SCRIPT_PATH"
echo -e "  Remote: curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/utils/system-info.sh | bash"
