#!/bin/bash

# =============================================================================
# Package Detection Test Script
# =============================================================================
# Purpose: Test package detection logic
# Version: 1.0.0
# =============================================================================

set -eo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE} TESTING PACKAGE DETECTION LOGIC${NC}"
echo -e "${BLUE}============================================${NC}"

# Test packages - mix of likely installed and not installed
TEST_PACKAGES=("wget" "curl" "nonexistent-package-test-123")

echo -e "${YELLOW}Testing different package detection methods:${NC}"
echo

for package in "${TEST_PACKAGES[@]}"; do
    echo -e "${BLUE}Testing package: $package${NC}"
    
    # Method 1: dpkg -l
    echo -n "  dpkg -l method: "
    if dpkg -l | grep -q "^ii  $package "; then
        echo -e "${GREEN}INSTALLED${NC}"
    else
        echo -e "${RED}NOT FOUND${NC}"
    fi
    
    # Method 2: dpkg-query
    echo -n "  dpkg-query method: "
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
        echo -e "${GREEN}INSTALLED${NC}"
    else
        echo -e "${RED}NOT FOUND${NC}"
    fi
    
    # Method 3: apt list (recommended)
    echo -n "  apt list method: "
    if apt list --installed "$package" 2>/dev/null | grep -q "installed"; then
        echo -e "${GREEN}INSTALLED${NC}"
    else
        echo -e "${RED}NOT FOUND${NC}"
    fi
    
    echo
done

echo -e "${YELLOW}Testing script logic with current method:${NC}"

# Simulate the script logic
test_packages=("wget" "curl" "jq")
failed_packages=()
skipped_packages=()
installed_count=0

for package in "${test_packages[@]}"; do
    echo "Verificando: $package"
    
    if apt list --installed "$package" 2>/dev/null | grep -q "installed"; then
        echo "⚡ $package já está instalado"
        skipped_packages+=("$package")
        ((installed_count++))
        continue
    fi
    
    echo "📦 Seria instalado: $package"
    ((installed_count++))
done

echo
echo -e "${GREEN}Logic test completed:${NC}"
echo "  • Packages processed: ${#test_packages[@]}"
echo "  • Would be skipped: ${#skipped_packages[@]} (${skipped_packages[*]})"
echo "  • Total count: $installed_count"

echo
echo -e "${BLUE}Script should continue processing all packages correctly.${NC}"
