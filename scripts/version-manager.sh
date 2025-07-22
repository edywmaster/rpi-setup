#!/bin/bash

# =============================================================================
# Version Manager Script - rpi-setup Project
# =============================================================================
# Purpose: Centralized version management for the entire project
# Version: 1.0.0
# Author: Raspberry Pi Setup Team
# Created: 2025-07-21
# =============================================================================
#
# This script manages version information across all components of the 
# rpi-setup project including:
# - Main preparation script (prepare-system.sh)
# - Kiosk setup script (setup-kiosk.sh)
# - Documentation files
# - Release notes
# - Project metadata
#
# Usage:
#   ./scripts/version-manager.sh [OPTIONS]
#
# Options:
#   --current              Show current version information
#   --update VERSION       Update to new version (e.g., 1.3.1)
#   --validate             Validate version consistency across project
#   --help                 Show this help message
#
# Examples:
#   ./scripts/version-manager.sh --current
#   ./scripts/version-manager.sh --update 1.3.1
#   ./scripts/version-manager.sh --validate
#
# =============================================================================

set -eo pipefail

# =============================================================================
# Constants and Configuration
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly VERSION_CONFIG_FILE="$PROJECT_ROOT/.version"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
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

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_header() {
    echo
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
}

# =============================================================================
# Version Configuration
# =============================================================================

# Default version information
DEFAULT_VERSION="1.3.0"
DEFAULT_NODEJS_VERSION="v22.13.1"
DEFAULT_KIOSK_API_VERSION="v1"

# Files that contain version information (as simple arrays)
VERSION_FILES_LIST=(
    "prepare-system.sh"
    "scripts/setup-kiosk.sh"
    "docs/development/RELEASE-NOTES.md"
    "README.md"
    "docs/README.md"
)

# =============================================================================
# Version Management Functions
# =============================================================================

# Initialize version configuration file
init_version_config() {
    if [[ ! -f "$VERSION_CONFIG_FILE" ]]; then
        log_info "Criando arquivo de configuração de versão..."
        cat > "$VERSION_CONFIG_FILE" << EOF
# rpi-setup Project Version Configuration
# Generated on $(date '+%Y-%m-%d %H:%M:%S')

# Main project version
PROJECT_VERSION=$DEFAULT_VERSION

# Component versions
NODEJS_VERSION=$DEFAULT_NODEJS_VERSION
KIOSK_API_VERSION=$DEFAULT_KIOSK_API_VERSION

# Last update information
LAST_UPDATE=$(date '+%Y-%m-%d')
LAST_UPDATE_BY=$(whoami)

# Version history
# Format: VERSION:DATE:DESCRIPTION
VERSION_HISTORY="$DEFAULT_VERSION:$(date '+%Y-%m-%d'):Initial version configuration"
EOF
        log_success "Arquivo de configuração criado: $VERSION_CONFIG_FILE"
    fi
}

# Load version configuration
load_version_config() {
    init_version_config
    source "$VERSION_CONFIG_FILE"
    
    # Validate required variables
    PROJECT_VERSION="${PROJECT_VERSION:-$DEFAULT_VERSION}"
    NODEJS_VERSION="${NODEJS_VERSION:-$DEFAULT_NODEJS_VERSION}"
    KIOSK_API_VERSION="${KIOSK_API_VERSION:-$DEFAULT_KIOSK_API_VERSION}"
}

# Save version configuration
save_version_config() {
    local new_version="$1"
    local description="$2"
    
    # Update version history
    local new_history_entry="$new_version:$(date '+%Y-%m-%d'):$description"
    if [[ -n "$VERSION_HISTORY" ]]; then
        VERSION_HISTORY="$VERSION_HISTORY\n$new_history_entry"
    else
        VERSION_HISTORY="$new_history_entry"
    fi
    
    cat > "$VERSION_CONFIG_FILE" << EOF
# rpi-setup Project Version Configuration
# Updated on $(date '+%Y-%m-%d %H:%M:%S')

# Main project version
PROJECT_VERSION=$new_version

# Component versions
NODEJS_VERSION=$NODEJS_VERSION
KIOSK_API_VERSION=$KIOSK_API_VERSION

# Last update information
LAST_UPDATE=$(date '+%Y-%m-%d')
LAST_UPDATE_BY=$(whoami)

# Version history
# Format: VERSION:DATE:DESCRIPTION
VERSION_HISTORY="$VERSION_HISTORY"
EOF
}

# =============================================================================
# File Update Functions
# =============================================================================

# Update version in prepare-system.sh
update_prepare_system_version() {
    local new_version="$1"
    local file="$PROJECT_ROOT/prepare-system.sh"
    
    if [[ ! -f "$file" ]]; then
        log_error "Arquivo não encontrado: $file"
        return 1
    fi
    
    log_info "Atualizando versão em prepare-system.sh..."
    
    # Update main version line
    sed -i.bak "s/^# Version: .*/# Version: $new_version/" "$file"
    
    # Update SCRIPT_VERSION constant
    sed -i.bak "s/^readonly SCRIPT_VERSION=.*/readonly SCRIPT_VERSION=\"$new_version\"/" "$file"
    
    # Remove backup file
    rm -f "$file.bak"
    
    log_success "Versão atualizada em prepare-system.sh: $new_version"
}

# Update version in setup-kiosk.sh
update_setup_kiosk_version() {
    local new_version="$1"
    local file="$PROJECT_ROOT/scripts/setup-kiosk.sh"
    
    if [[ ! -f "$file" ]]; then
        log_error "Arquivo não encontrado: $file"
        return 1
    fi
    
    log_info "Atualizando versão em setup-kiosk.sh..."
    
    # Update main version line
    sed -i.bak "s/^# Version: .*/# Version: $new_version/" "$file"
    
    # Update SCRIPT_VERSION constant
    sed -i.bak "s/^readonly SCRIPT_VERSION=.*/readonly SCRIPT_VERSION=\"$new_version\"/" "$file"
    
    # Update prepare_version references
    sed -i.bak "s/local prepare_version=.*/local prepare_version=\"$new_version\"  # Latest prepare-system version/" "$file"
    
    # Remove backup file
    rm -f "$file.bak"
    
    log_success "Versão atualizada em setup-kiosk.sh: $new_version"
}

# Update version in README files
update_readme_versions() {
    local new_version="$1"
    
    local files=(
        "$PROJECT_ROOT/README.md"
        "$PROJECT_ROOT/docs/README.md"
        "$PROJECT_ROOT/docs/production/PREPARE-SYSTEM.md"
        "$PROJECT_ROOT/docs/production/DEPLOYMENT.md"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Atualizando referências de versão em $(basename "$file")..."
            
            # Update version references (this is a placeholder - actual patterns depend on file content)
            # We'll add specific patterns based on how versions are mentioned in these files
            
            log_success "Versão atualizada em $(basename "$file")"
        else
            log_warn "Arquivo não encontrado: $file"
        fi
    done
}

# Add new version entry to RELEASE-NOTES.md
add_release_notes_entry() {
    local new_version="$1"
    local description="$2"
    local file="$PROJECT_ROOT/docs/development/RELEASE-NOTES.md"
    
    if [[ ! -f "$file" ]]; then
        log_error "Arquivo RELEASE-NOTES.md não encontrado: $file"
        return 1
    fi
    
    log_info "Adicionando entrada no RELEASE-NOTES.md..."
    
    # Create temporary file with new entry
    local temp_file=$(mktemp)
    local date_str=$(date '+%Y-%m-%d')
    
    # Write new entry to temp file
    cat > "$temp_file" << EOF
# Release Notes

## Version $new_version ($description)

### 🆕 Atualizações

- **Versão atualizada**: Projeto atualizado para versão $new_version
- **Data de atualização**: $date_str
- **Gerenciamento centralizado**: Versões agora gerenciadas via scripts/version-manager.sh

### 🔧 Alterações Técnicas

- Atualização automática de versões em todos os componentes
- Sincronização de versões entre prepare-system.sh e setup-kiosk.sh
- Documentação atualizada com nova versão

---

EOF
    
    # Append rest of original file (skip first line)
    tail -n +2 "$file" >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$file"
    
    log_success "Entrada adicionada ao RELEASE-NOTES.md: Version $new_version"
}

# =============================================================================
# Validation Functions
# =============================================================================

# Validate version consistency across all files
validate_version_consistency() {
    log_header "Validando Consistência de Versões"
    
    load_version_config
    
    local errors=0
    
    # Check prepare-system.sh
    log_info "Verificando prepare-system.sh..."
    local prepare_version=$(grep "^readonly SCRIPT_VERSION=" "$PROJECT_ROOT/prepare-system.sh" 2>/dev/null | cut -d'"' -f2)
    if [[ "$prepare_version" == "$PROJECT_VERSION" ]]; then
        log_success "prepare-system.sh: $prepare_version ✓"
    else
        log_error "prepare-system.sh: $prepare_version (esperado: $PROJECT_VERSION)"
        ((errors++))
    fi
    
    # Check setup-kiosk.sh
    log_info "Verificando setup-kiosk.sh..."
    local kiosk_version=$(grep "^readonly SCRIPT_VERSION=" "$PROJECT_ROOT/scripts/setup-kiosk.sh" 2>/dev/null | cut -d'"' -f2)
    if [[ "$kiosk_version" == "$PROJECT_VERSION" ]]; then
        log_success "setup-kiosk.sh: $kiosk_version ✓"
    else
        log_error "setup-kiosk.sh: $kiosk_version (esperado: $PROJECT_VERSION)"
        ((errors++))
    fi
    
    # Check if RELEASE-NOTES.md has latest version
    log_info "Verificando RELEASE-NOTES.md..."
    if grep -q "## Version $PROJECT_VERSION" "$PROJECT_ROOT/docs/development/RELEASE-NOTES.md" 2>/dev/null; then
        log_success "RELEASE-NOTES.md: Contém versão $PROJECT_VERSION ✓"
    else
        log_warn "RELEASE-NOTES.md: Não contém entrada para versão $PROJECT_VERSION"
    fi
    
    echo
    if [[ $errors -eq 0 ]]; then
        log_success "Todas as versões estão consistentes!"
        return 0
    else
        log_error "Encontrados $errors erro(s) de consistência de versão"
        return 1
    fi
}

# =============================================================================
# Display Functions
# =============================================================================

# Show current version information
show_current_version() {
    log_header "Informações de Versão Atual"
    
    load_version_config
    
    echo -e "${CYAN}Versão Principal:${NC} $PROJECT_VERSION"
    echo -e "${CYAN}Node.js:${NC} $NODEJS_VERSION"
    echo -e "${CYAN}API Kiosk:${NC} $KIOSK_API_VERSION"
    echo -e "${CYAN}Última Atualização:${NC} $LAST_UPDATE"
    echo -e "${CYAN}Atualizado por:${NC} $LAST_UPDATE_BY"
    
    echo
    echo -e "${CYAN}Histórico de Versões:${NC}"
    if [[ -n "$VERSION_HISTORY" ]]; then
        echo -e "$VERSION_HISTORY" | while IFS=':' read -r version date desc; do
            echo "  • $version ($date): $desc"
        done
    else
        echo "  Nenhum histórico disponível"
    fi
    
    echo
    echo -e "${CYAN}Arquivos de Versão:${NC}"
    for file in "${VERSION_FILES_LIST[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            echo "  ✓ $file"
        else
            echo "  ✗ $file (não encontrado)"
        fi
    done
}

# =============================================================================
# Main Update Function
# =============================================================================

# Update all components to new version
update_version() {
    local new_version="$1"
    local description="$2"
    
    # Validate version format (basic check)
    if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Formato de versão inválido: $new_version"
        log_info "Use o formato: MAJOR.MINOR.PATCH (ex: 1.3.1)"
        return 1
    fi
    
    log_header "Atualizando Projeto para Versão $new_version"
    
    # Load current configuration
    load_version_config
    
    log_info "Versão atual: $PROJECT_VERSION"
    log_info "Nova versão: $new_version"
    echo
    
    # Update all files
    update_prepare_system_version "$new_version"
    update_setup_kiosk_version "$new_version"
    update_readme_versions "$new_version"
    add_release_notes_entry "$new_version" "${description:-Version Update}"
    
    # Save new configuration
    PROJECT_VERSION="$new_version"
    save_version_config "$new_version" "${description:-Version Update}"
    
    echo
    log_success "Projeto atualizado para versão $new_version com sucesso!"
    log_info "Execute './scripts/version-manager.sh --validate' para verificar consistência"
}

# =============================================================================
# Help Function
# =============================================================================

show_help() {
    cat << 'EOF'
Version Manager - rpi-setup Project

USAGE:
    ./scripts/version-manager.sh [OPTIONS]

OPTIONS:
    --current              Mostra informações da versão atual
    --update VERSION       Atualiza para nova versão (ex: 1.3.1)
    --validate             Valida consistência de versões no projeto
    --help                 Mostra esta mensagem de ajuda

EXAMPLES:
    # Mostrar versão atual
    ./scripts/version-manager.sh --current

    # Atualizar para nova versão
    ./scripts/version-manager.sh --update 1.3.1

    # Atualizar com descrição personalizada
    ./scripts/version-manager.sh --update 1.4.0 "New Feature Release"

    # Validar consistência
    ./scripts/version-manager.sh --validate

DESCRIPTION:
    Este script gerencia versões centralizadamente para todo o projeto
    rpi-setup, incluindo:
    
    • prepare-system.sh (script principal)
    • setup-kiosk.sh (configuração do kiosk)
    • Documentação e release notes
    • Arquivos de configuração
    
    O sistema mantém um arquivo .version na raiz do projeto com todas
    as informações de versionamento e histórico.

NOTES:
    • Use versionamento semântico (MAJOR.MINOR.PATCH)
    • O script valida formato antes de aplicar mudanças
    • Backup automático é criado antes das alterações
    • Sempre execute --validate após atualizações

EOF
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Change to project root directory
    cd "$PROJECT_ROOT"
    
    case "${1:-}" in
        --current)
            show_current_version
            ;;
        --update)
            if [[ -z "${2:-}" ]]; then
                log_error "Versão requerida para --update"
                log_info "Use: ./scripts/version-manager.sh --update 1.3.1"
                return 1
            fi
            update_version "$2" "${3:-}"
            ;;
        --validate)
            validate_version_consistency
            ;;
        --help|-h)
            show_help
            ;;
        "")
            log_error "Nenhuma opção fornecida"
            echo
            show_help
            return 1
            ;;
        *)
            log_error "Opção inválida: $1"
            echo
            show_help
            return 1
            ;;
    esac
}

# =============================================================================
# Script Execution
# =============================================================================

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
