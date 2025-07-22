#!/bin/bash

# =============================================================================
# Test Quick Fix for Environment Variables Removal
# =============================================================================
# Purpose: Test the environment variables removal logic quickly
# =============================================================================

set -eo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_info() {
    echo -e "${CYAN}[TEST-INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[TEST-SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[TEST-ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# Test on actual /etc/environment file
test_actual_environment_file() {
    print_header "TESTANDO ARQUIVO /etc/environment REAL"
    
    local GLOBAL_ENV_FILE="/etc/environment"
    
    if [[ ! -f "$GLOBAL_ENV_FILE" ]]; then
        log_error "Arquivo /etc/environment não encontrado!"
        return 1
    fi
    
    log_info "📄 Conteúdo atual do arquivo:"
    cat "$GLOBAL_ENV_FILE"
    echo
    
    # Count current KIOSK variables
    local current_kiosk=$(grep -c "^export KIOSK_" "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
    local current_legacy=$(grep -cE "^export (APP_MODE|APP_URL|APP_API_URL|PRINT_PORT)=" "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
    
    log_info "📊 Estatísticas atuais:"
    log_info "   • Variáveis KIOSK: $current_kiosk"
    log_info "   • Variáveis legadas: $current_legacy"
    
    if [[ $current_kiosk -eq 0 ]] && [[ $current_legacy -eq 0 ]]; then
        log_success "✅ Arquivo já está limpo!"
        return 0
    fi
    
    log_info "🔧 Variáveis que precisam ser removidas encontradas"
    return 1
}

# Apply the corrected removal logic directly
apply_corrected_removal() {
    print_header "APLICANDO CORREÇÃO DIRETAMENTE"
    
    local GLOBAL_ENV_FILE="/etc/environment"
    
    # List of environment variables to remove
    local env_vars_to_remove=(
        "KIOSK_VERSION"
        "KIOSK_APP_MODE"
        "KIOSK_APP_URL"
        "KIOSK_APP_API"
        "KIOSK_PRINT_PORT"
        "KIOSK_PRINT_HOST"
        "KIOSK_PRINT_URL"
        "KIOSK_PRINT_SERVER"
        "KIOSK_PRINT_SCRIPT"
        "KIOSK_PRINT_TEMP"
        "KIOSK_SCRIPTS_DIR"
        "KIOSK_SERVER_DIR"
        "KIOSK_UTILS_DIR"
        "KIOSK_TEMPLATES_DIR"
        "KIOSK_BASE_DIR"
        "KIOSK_TEMP_DIR"
        "APP_MODE"
        "APP_URL"
        "APP_API_URL"
        "PRINT_PORT"
    )
    
    # Create backup
    local backup_file="${GLOBAL_ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Criando backup: $backup_file"
    if ! cp "$GLOBAL_ENV_FILE" "$backup_file"; then
        log_error "Falha ao criar backup"
        return 1
    fi
    
    # Apply corrected removal logic
    local temp_file=$(mktemp)
    local removed_count=0
    
    log_info "Aplicando lógica corrigida de remoção..."
    
    while IFS= read -r line; do
        local should_keep=true
        for var in "${env_vars_to_remove[@]}"; do
            # Using the corrected detection logic
            if [[ "$line" =~ ^export[[:space:]]+${var}= ]] || [[ "$line" == "export ${var}="* ]]; then
                should_keep=false
                ((removed_count++))
                log_info "⚡ Removendo: $var"
                break
            fi
        done
        
        if [[ "$should_keep" == true ]]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$GLOBAL_ENV_FILE"
    
    # Replace original file
    if mv "$temp_file" "$GLOBAL_ENV_FILE"; then
        log_success "✅ Arquivo atualizado ($removed_count variáveis removidas)"
        
        # Show final result
        echo
        log_info "📄 Conteúdo final do arquivo:"
        cat "$GLOBAL_ENV_FILE"
        
        # Verify cleanup
        local final_kiosk=$(grep -c "^export KIOSK_" "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
        local final_legacy=$(grep -cE "^export (APP_MODE|APP_URL|APP_API_URL|PRINT_PORT)=" "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
        
        echo
        log_info "📊 Resultado final:"
        log_info "   • Variáveis KIOSK restantes: $final_kiosk"
        log_info "   • Variáveis legadas restantes: $final_legacy"
        
        if [[ $final_kiosk -eq 0 ]] && [[ $final_legacy -eq 0 ]]; then
            log_success "🎉 SUCESSO: Todas as variáveis KIOSK foram removidas!"
        else
            log_error "❌ FALHA: Ainda há variáveis KIOSK no arquivo"
        fi
        
        return 0
    else
        log_error "Falha ao atualizar arquivo"
        rm -f "$temp_file"
        return 1
    fi
}

main() {
    print_header "TESTE RÁPIDO - CORREÇÃO DE VARIÁVEIS DE AMBIENTE"
    
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado com sudo"
        exit 1
    fi
    
    # Test current state
    if test_actual_environment_file; then
        exit 0
    fi
    
    echo
    read -p "Aplicar correção agora? (Digite 'yes' para confirmar): " -r
    if [[ "$REPLY" == "yes" ]]; then
        apply_corrected_removal
    else
        log_info "Operação cancelada"
    fi
}

main "$@"
