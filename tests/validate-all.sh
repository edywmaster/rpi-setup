#!/bin/bash

# =============================================================================
# Complete Project Validation Script
# =============================================================================
# Purpose: Execute all validation checks and version management in sequence
# Version: 1.0.0
# Author: Raspberry Pi Setup Team
# Created: 2025-07-21
# =============================================================================
#
# This script runs all required validation checks as specified in the
# Copilot instructions. It should be executed before and after any
# significant changes to the project.
#
# Usage:
#   ./tests/validate-all.sh [OPTIONS]
#
# Options:
#   --pre-change           Run pre-change validations only
#   --post-change          Run post-change validations only
#   --with-version         Include version validation and increment
#   --version-update VER   Update version to VER after successful validation
#   --help                 Show this help message
#
# Examples:
#   ./tests/validate-all.sh --pre-change
#   ./tests/validate-all.sh --post-change --with-version
#   ./tests/validate-all.sh --version-update 1.3.2
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
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Logging Functions
# =============================================================================

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

log_section() {
    echo -e "\n${PURPLE}=== $1 ===${NC}\n"
}

log_step() {
    echo -e "${CYAN}➤${NC} $1"
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_structure() {
    log_step "Running project structure validation..."
    if "$PROJECT_ROOT/tests/validate-structure.sh"; then
        log_success "Project structure validation passed"
        return 0
    else
        log_error "Project structure validation failed"
        return 1
    fi
}

validate_docs_structure() {
    log_step "Running documentation structure validation..."
    if "$PROJECT_ROOT/tests/validate-docs-structure.sh"; then
        log_success "Documentation structure validation passed"
        return 0
    else
        log_error "Documentation structure validation failed"
        return 1
    fi
}

validate_copilot_integration() {
    log_step "Running Copilot integration validation..."
    if "$PROJECT_ROOT/tests/validate-copilot-integration.sh"; then
        log_success "Copilot integration validation passed"
        return 0
    else
        log_error "Copilot integration validation failed"
        return 1
    fi
}

validate_version_consistency() {
    log_step "Running version consistency validation..."
    if "$PROJECT_ROOT/scripts/version-manager.sh" --validate; then
        log_success "Version consistency validation passed"
        return 0
    else
        log_error "Version consistency validation failed"
        return 1
    fi
}

validate_script_syntax() {
    log_step "Running syntax validation for all scripts..."
    local failed=0
    
    # Find all .sh files in the project
    while IFS= read -r -d '' script; do
        log_step "Checking syntax: $(basename "$script")"
        if ! bash -n "$script" 2>/dev/null; then
            log_error "Syntax error in: $script"
            failed=1
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -print0)
    
    if [[ $failed -eq 0 ]]; then
        log_success "All scripts passed syntax validation"
        return 0
    else
        log_error "Some scripts failed syntax validation"
        return 1
    fi
}

update_version() {
    local new_version="$1"
    log_step "Updating project version to: $new_version"
    
    if "$PROJECT_ROOT/scripts/version-manager.sh" --update "$new_version"; then
        log_success "Version updated successfully to: $new_version"
        return 0
    else
        log_error "Version update failed"
        return 1
    fi
}

show_current_version() {
    log_step "Current version information:"
    "$PROJECT_ROOT/scripts/version-manager.sh" --current
}

# =============================================================================
# Main Validation Workflows
# =============================================================================

run_pre_change_validation() {
    log_section "PRE-CHANGE VALIDATION"
    
    local failed=0
    
    show_current_version || failed=1
    validate_structure || failed=1
    validate_docs_structure || failed=1
    validate_copilot_integration || failed=1
    validate_version_consistency || failed=1
    validate_script_syntax || failed=1
    
    if [[ $failed -eq 0 ]]; then
        log_success "All pre-change validations passed"
        return 0
    else
        log_error "Pre-change validation failed"
        return 1
    fi
}

run_post_change_validation() {
    log_section "POST-CHANGE VALIDATION"
    
    local failed=0
    
    validate_structure || failed=1
    validate_docs_structure || failed=1
    validate_copilot_integration || failed=1
    validate_script_syntax || failed=1
    
    if [[ $failed -eq 0 ]]; then
        log_success "All post-change validations passed"
        return 0
    else
        log_error "Post-change validation failed"
        return 1
    fi
}

run_complete_validation() {
    log_section "COMPLETE PROJECT VALIDATION"
    
    local failed=0
    
    show_current_version || failed=1
    validate_structure || failed=1
    validate_docs_structure || failed=1
    validate_copilot_integration || failed=1
    validate_version_consistency || failed=1
    validate_script_syntax || failed=1
    
    if [[ $failed -eq 0 ]]; then
        log_success "All validations passed"
        return 0
    else
        log_error "Validation failed"
        return 1
    fi
}

# =============================================================================
# Help and Usage
# =============================================================================

show_help() {
    cat << EOF
Complete Project Validation Script

This script executes all validation checks required by the Copilot instructions.

Usage:
    $0 [OPTIONS]

Options:
    --pre-change           Run pre-change validations only
    --post-change          Run post-change validations only
    --with-version         Include version validation and increment
    --version-update VER   Update version to VER after successful validation
    --help                 Show this help message

Examples:
    $0                                    # Run complete validation
    $0 --pre-change                       # Before making changes
    $0 --post-change --with-version       # After changes with version check
    $0 --version-update 1.3.2            # Update version after validation

Environment Notes:
    - Development on macOS targeting Linux deployment
    - Some validations may show warnings for Linux-specific features
    - Final validation must be performed on Raspberry Pi hardware

EOF
}

# =============================================================================
# Main Script Logic
# =============================================================================

main() {
    local pre_change=false
    local post_change=false
    local with_version=false
    local version_update=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pre-change)
                pre_change=true
                shift
                ;;
            --post-change)
                post_change=true
                shift
                ;;
            --with-version)
                with_version=true
                shift
                ;;
            --version-update)
                version_update="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    log_info "Starting validation process..."
    log_info "Project root: $PROJECT_ROOT"
    log_warn "Note: Running on macOS, targeting Linux deployment"
    
    # Execute appropriate validation workflow
    if [[ "$pre_change" == true ]]; then
        run_pre_change_validation
    elif [[ "$post_change" == true ]]; then
        run_post_change_validation
        if [[ "$with_version" == true ]]; then
            validate_version_consistency
        fi
    else
        run_complete_validation
    fi
    
    # Handle version update if requested
    if [[ -n "$version_update" ]]; then
        log_section "VERSION UPDATE"
        update_version "$version_update"
        validate_version_consistency
    fi
    
    log_section "VALIDATION COMPLETE"
    log_success "All validation processes completed"
    
    if [[ "$pre_change" == true ]]; then
        log_info "Ready to make changes. Run '$0 --post-change' after modifications."
    elif [[ "$post_change" == true ]]; then
        log_info "Changes validated. Consider version update if significant changes were made."
    fi
}

# =============================================================================
# Script Execution
# =============================================================================

# Ensure script is executable
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
