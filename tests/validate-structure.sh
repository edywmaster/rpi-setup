#!/bin/bash

# =============================================================================
# Project Structure Validation Script
# =============================================================================
# Purpose: Validate the project structure and file organization
# Version: 1.0.0
# =============================================================================

set -eo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Project root
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

check_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
        log_success "$description exists: $file"
        return 0
    else
        log_error "$description missing: $file"
        return 1
    fi
}

check_directory() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$PROJECT_ROOT/$dir" ]]; then
        log_success "$description exists: $dir/"
        return 0
    else
        log_error "$description missing: $dir/"
        return 1
    fi
}

check_executable() {
    local file="$1"
    
    if [[ -x "$PROJECT_ROOT/$file" ]]; then
        log_success "Executable permissions OK: $file"
        return 0
    else
        log_warn "Not executable: $file"
        return 1
    fi
}

main() {
    echo "=========================================="
    echo " PROJECT STRUCTURE VALIDATION"
    echo "=========================================="
    echo "Project root: $PROJECT_ROOT"
    echo

    local errors=0

    # Check main structure
    log_info "Checking main project structure..."
    check_file "README.md" "Main README" || ((errors++))
    check_file "prepare-system.sh" "Main script" || ((errors++))
    
    # Check directories
    log_info "Checking directory structure..."
    check_directory "docs" "Documentation directory" || ((errors++))
    check_directory "docs/production" "Production docs directory" || ((errors++))
    check_directory "docs/development" "Development docs directory" || ((errors++))
    check_directory "scripts" "Scripts directory" || ((errors++))
    check_directory "tests" "Tests directory" || ((errors++))
    check_directory ".github" "GitHub configuration" || ((errors++))

    # Check production documentation
    echo
    log_info "Checking production documentation..."
    check_file "docs/production/DEPLOYMENT.md" "Deployment guide" || ((errors++))
    check_file "docs/production/PREPARE-SYSTEM.md" "System preparation docs" || ((errors++))

    # Check development documentation
    echo
    log_info "Checking development documentation..."
    check_file "docs/development/README-DETAILED.md" "Detailed README" || ((errors++))
    check_file "docs/development/RELEASE-NOTES.md" "Release notes" || ((errors++))
    check_file "docs/README.md" "Documentation index" || ((errors++))

    # Check scripts and tools
    echo
    log_info "Checking scripts and tools..."
    check_file "scripts/deploy-multiple.sh" "Multi-device deployment script" || ((errors++))
    check_file "tests/test-script.sh" "Test script" || ((errors++))
    check_file ".github/copilot-instructions.md" "Copilot instructions" || ((errors++))

    # Check executable permissions
    echo
    log_info "Checking executable permissions..."
    check_executable "prepare-system.sh" || ((errors++))
    check_executable "scripts/deploy-multiple.sh" || ((errors++))
    check_executable "tests/test-script.sh" || ((errors++))

    # Summary
    echo
    echo "=========================================="
    if [[ $errors -eq 0 ]]; then
        log_success "Project structure validation PASSED!"
        echo -e "${GREEN}All files and directories are properly organized.${NC}"
    else
        log_error "Project structure validation FAILED!"
        echo -e "${RED}Found $errors issues that need to be resolved.${NC}"
    fi
    echo "=========================================="

    return $errors
}

# Execute main function
main "$@"
