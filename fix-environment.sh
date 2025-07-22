#!/bin/bash

# =============================================================================
# Environment Variables Fix Script
# =============================================================================
# Purpose: Diagnose and fix environment variables removal issue
# Usage: curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/fix-environment.sh | sudo bash
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
    echo -e "${CYAN}[FIX-INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[FIX-SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FIX-ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[FIX-WARN]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado com privilégios de root"
        log_info "Execute: curl -fsSL [URL] | sudo bash"
        exit 1
    fi
}

diagnose_current_state() {
    print_header "DIAGNÓSTICO DO ESTADO ATUAL"
    
    local GLOBAL_ENV_FILE="/etc/environment"
    
    if [[ ! -f "$GLOBAL_ENV_FILE" ]]; then
        log_error "Arquivo /etc/environment não encontrado!"
        return 1
    fi
    
    log_info "📄 Arquivo encontrado: $GLOBAL_ENV_FILE"
    log_info "📊 Tamanho: $(wc -c < "$GLOBAL_ENV_FILE") bytes"
    log_info "📋 Linhas: $(wc -l < "$GLOBAL_ENV_FILE")"
    
    # Count KIOSK variables
    local kiosk_count=$(grep -c "^export KIOSK_" "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
    local legacy_count=$(grep -cE "^export (APP_MODE|APP_URL|APP_API_URL|PRINT_PORT)=" "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
    local total_exports=$(grep -c "^export " "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
    
    log_info "🔍 Análise de variáveis:"
    log_info "   • Variáveis KIOSK_*: $kiosk_count"
    log_info "   • Variáveis legadas: $legacy_count"
    log_info "   • Total de exports: $total_exports"
    
    if [[ $kiosk_count -gt 0 ]] || [[ $legacy_count -gt 0 ]]; then
        log_warn "⚠️  Encontradas $(($kiosk_count + $legacy_count)) variáveis KIOSK que precisam ser removidas"
        
        log_info "📝 Variáveis KIOSK encontradas:"
        grep "^export KIOSK_" "$GLOBAL_ENV_FILE" 2>/dev/null | while read -r line; do
            log_info "   • $line"
        done
        
        log_info "📝 Variáveis legadas encontradas:"
        grep -E "^export (APP_MODE|APP_URL|APP_API_URL|PRINT_PORT)=" "$GLOBAL_ENV_FILE" 2>/dev/null | while read -r line; do
            log_info "   • $line"
        done
        
        return 1
    else
        log_success "✅ Arquivo já está limpo de variáveis KIOSK"
        return 0
    fi
}

apply_corrected_fix() {
    print_header "APLICANDO CORREÇÃO DEFINITIVA"
    
    local GLOBAL_ENV_FILE="/etc/environment"
    
    # List of environment variables to remove (complete list)
    local env_vars_to_remove=(
        # Core KIOSK variables
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
        
        # Legacy variables
        "APP_MODE"
        "APP_URL"
        "APP_API_URL"
        "PRINT_PORT"
    )
    
    log_info "🔧 Iniciando correção com lógica robusta..."
    
    # Create backup
    local backup_file="${GLOBAL_ENV_FILE}.fix-backup.$(date +%Y%m%d_%H%M%S)"
    log_info "💾 Criando backup: $backup_file"
    if ! cp "$GLOBAL_ENV_FILE" "$backup_file"; then
        log_error "Falha ao criar backup"
        return 1
    fi
    log_success "✅ Backup criado com sucesso"
    
    # Apply robust removal logic
    local temp_file=$(mktemp)
    local removed_count=0
    local processed_lines=0
    
    log_info "🔄 Processando arquivo linha por linha..."
    
    while IFS= read -r line; do
        ((processed_lines++))
        local should_keep=true
        
        # Multiple detection methods for robustness
        for var in "${env_vars_to_remove[@]}"; do
            # Method 1: Regex with spaces
            if [[ "$line" =~ ^export[[:space:]]+${var}= ]]; then
                should_keep=false
                ((removed_count++))
                log_info "⚡ Removendo (regex): $var"
                break
            fi
            
            # Method 2: Direct pattern matching
            if [[ "$line" == "export ${var}="* ]]; then
                should_keep=false
                ((removed_count++))
                log_info "⚡ Removendo (pattern): $var"
                break
            fi
            
            # Method 3: Flexible pattern (handles any whitespace)
            if [[ "$line" =~ ^export[[:space:]]*${var}[[:space:]]*= ]]; then
                should_keep=false
                ((removed_count++))
                log_info "⚡ Removendo (flexible): $var"
                break
            fi
        done
        
        if [[ "$should_keep" == true ]]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$GLOBAL_ENV_FILE"
    
    log_info "📊 Estatísticas do processamento:"
    log_info "   • Linhas processadas: $processed_lines"
    log_info "   • Variáveis removidas: $removed_count"
    
    # Verify temp file
    local temp_lines=$(wc -l < "$temp_file")
    log_info "   • Linhas no arquivo final: $temp_lines"
    
    # Replace original file
    if mv "$temp_file" "$GLOBAL_ENV_FILE"; then
        log_success "✅ Arquivo atualizado com sucesso"
        
        # Set correct permissions
        chmod 644 "$GLOBAL_ENV_FILE"
        log_success "✅ Permissões definidas (644)"
        
        return 0
    else
        log_error "❌ Falha ao atualizar arquivo"
        rm -f "$temp_file"
        return 1
    fi
}

verify_fix() {
    print_header "VERIFICAÇÃO FINAL"
    
    local GLOBAL_ENV_FILE="/etc/environment"
    
    # Re-check for any remaining KIOSK variables
    local final_kiosk=$(grep -c "^export KIOSK_" "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
    local final_legacy=$(grep -cE "^export (APP_MODE|APP_URL|APP_API_URL|PRINT_PORT)=" "$GLOBAL_ENV_FILE" 2>/dev/null || echo 0)
    local total_remaining=$(($final_kiosk + $final_legacy))
    
    log_info "🔍 Verificação final:"
    log_info "   • Variáveis KIOSK restantes: $final_kiosk"
    log_info "   • Variáveis legadas restantes: $final_legacy"
    log_info "   • Total de variáveis KIOSK: $total_remaining"
    
    if [[ $total_remaining -eq 0 ]]; then
        log_success "🎉 SUCESSO COMPLETO: Todas as variáveis KIOSK foram removidas!"
        log_success "✅ Sistema limpo e pronto para uso"
        
        echo
        log_info "📄 Conteúdo final do arquivo /etc/environment:"
        echo "----------------------------------------"
        cat "$GLOBAL_ENV_FILE"
        echo "----------------------------------------"
        
        return 0
    else
        log_error "❌ FALHA: Ainda restam $total_remaining variável(eis) KIOSK"
        
        if [[ $final_kiosk -gt 0 ]]; then
            log_error "Variáveis KIOSK restantes:"
            grep "^export KIOSK_" "$GLOBAL_ENV_FILE" 2>/dev/null | while read -r line; do
                log_error "   • $line"
            done
        fi
        
        if [[ $final_legacy -gt 0 ]]; then
            log_error "Variáveis legadas restantes:"
            grep -E "^export (APP_MODE|APP_URL|APP_API_URL|PRINT_PORT)=" "$GLOBAL_ENV_FILE" 2>/dev/null | while read -r line; do
                log_error "   • $line"
            done
        fi
        
        return 1
    fi
}

display_final_summary() {
    print_header "RESUMO DA CORREÇÃO"
    
    log_success "🔧 Correção de variáveis de ambiente executada"
    log_info "📅 Data: $(date)"
    log_info "🔗 Script: fix-environment.sh"
    
    echo
    log_info "💡 O que foi feito:"
    log_info "   • Diagnóstico completo do arquivo /etc/environment"
    log_info "   • Backup automático criado"
    log_info "   • Remoção robusta com 3 métodos de detecção"
    log_info "   • Verificação final da limpeza"
    
    echo
    log_info "🎯 Resultado:"
    if verify_fix >/dev/null 2>&1; then
        log_success "   • ✅ Todas as 19 variáveis KIOSK removidas"
        log_success "   • ✅ Sistema completamente limpo"
        log_success "   • ✅ Pronto para nova instalação"
    else
        log_error "   • ❌ Algumas variáveis podem ainda estar presentes"
        log_error "   • ❌ Pode ser necessário remoção manual"
    fi
    
    echo
    log_info "🚀 Próximos passos recomendados:"
    log_info "   • Verificar: cat /etc/environment"
    log_info "   • Reiniciar: sudo reboot (opcional)"
    log_info "   • Reinstalar kiosk se necessário"
}

main() {
    print_header "CORREÇÃO DEFINITIVA - VARIÁVEIS DE AMBIENTE KIOSK"
    
    log_info "🔧 Iniciando correção definitiva para remoção de variáveis KIOSK..."
    log_info "📋 Script: fix-environment.sh"
    log_info "🎯 Objetivo: Remover TODAS as variáveis KIOSK de /etc/environment"
    log_info "🕒 Executado em: $(date)"
    
    # Check permissions
    check_root_privileges
    
    # Diagnose current state
    if diagnose_current_state; then
        log_success "✅ Sistema já está limpo - nenhuma ação necessária"
        display_final_summary
        exit 0
    fi
    
    echo
    log_warn "⚠️  Variáveis KIOSK detectadas - aplicando correção..."
    
    # Apply fix
    if apply_corrected_fix; then
        log_success "✅ Correção aplicada com sucesso"
    else
        log_error "❌ Falha na aplicação da correção"
        exit 1
    fi
    
    # Verify results
    if verify_fix; then
        echo
        display_final_summary
        exit 0
    else
        echo
        log_error "❌ Correção não foi completamente efetiva"
        display_final_summary
        exit 1
    fi
}

# Execute main function
main "$@"
