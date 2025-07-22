#!/bin/bash

# =============================================================================
# Pre-commit Validation Hook
# =============================================================================
# Purpose: Automatic validation before git commits
# Version: 1.0.0
# Author: Raspberry Pi Setup Team
# Created: 2025-07-21
# =============================================================================
#
# This script runs essential validations before allowing a git commit.
# It ensures code quality and project structure compliance.
#
# To install this hook:
#   cp scripts/pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# To bypass for emergency commits:
#   git commit --no-verify
#
# =============================================================================

set -eo pipefail

# =============================================================================
# Constants and Configuration
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[PRE-COMMIT]${NC} $1"
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

# =============================================================================
# Validation Functions
# =============================================================================

check_staged_files() {
    local staged_files
    staged_files=$(git diff --cached --name-only)
    
    if [[ -z "$staged_files" ]]; then
        log_warn "No staged files found"
        return 1
    fi
    
    log_info "Staged files for commit:"
    echo "$staged_files" | sed 's/^/  /'
    return 0
}

validate_shell_scripts() {
    log_info "Validating shell script syntax..."
    
    local failed=false
    local staged_scripts
    staged_scripts=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$' || true)
    
    if [[ -z "$staged_scripts" ]]; then
        log_info "No shell scripts in staged files"
        return 0
    fi
    
    while IFS= read -r script; do
        if [[ -f "$script" ]]; then
            log_info "Checking syntax: $script"
            if ! bash -n "$script" 2>/dev/null; then
                log_error "Syntax error in: $script"
                failed=true
            fi
        fi
    done <<< "$staged_scripts"
    
    if [[ "$failed" == true ]]; then
        log_error "Shell script validation failed"
        return 1
    else
        log_success "All shell scripts passed syntax validation"
        return 0
    fi
}

validate_project_structure() {
    log_info "Validating project structure..."
    
    if "$PROJECT_ROOT/tests/validate-structure.sh" >/dev/null 2>&1; then
        log_success "Project structure validation passed"
        return 0
    else
        log_error "Project structure validation failed"
        log_info "Run './tests/validate-structure.sh' for details"
        return 1
    fi
}

validate_documentation_structure() {
    log_info "Validating documentation structure..."
    
    if "$PROJECT_ROOT/tests/validate-docs-structure.sh" >/dev/null 2>&1; then
        log_success "Documentation structure validation passed"
        return 0
    else
        log_error "Documentation structure validation failed"
        log_info "Run './tests/validate-docs-structure.sh' for details"
        return 1
    fi
}

validate_version_consistency() {
    log_info "Validating version consistency..."
    
    if "$PROJECT_ROOT/scripts/version-manager.sh" --validate >/dev/null 2>&1; then
        log_success "Version consistency validation passed"
        return 0
    else
        log_error "Version consistency validation failed"
        log_info "Run './scripts/version-manager.sh --validate' for details"
        return 1
    fi
}

# =============================================================================
# Main Validation Logic
# =============================================================================

main() {
    log_info "Starting pre-commit validation..."
    
    cd "$PROJECT_ROOT"
    
    local failed=false
    
    # Check if there are staged files
    if ! check_staged_files; then
        exit 0
    fi
    
    # Run essential validations
    validate_shell_scripts || failed=true
    validate_project_structure || failed=true
    validate_documentation_structure || failed=true
    validate_version_consistency || failed=true
    
    if [[ "$failed" == true ]]; then
        echo
        log_error "Pre-commit validation failed!"
        log_info "Fix the issues above and try again"
        log_info "To bypass validation (not recommended): git commit --no-verify"
        echo
        log_info "For detailed validation, run:"
        log_info "  ./tests/validate-all.sh --pre-change"
        echo
        exit 1
    else
        echo
        log_success "All pre-commit validations passed!"
        log_info "Proceeding with commit..."
        echo
        exit 0
    fi
}

# =============================================================================
# Script Execution
# =============================================================================

# Only run if this script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
