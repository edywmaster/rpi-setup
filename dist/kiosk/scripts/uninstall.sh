#!/bin/bash

# =============================================================================
# Kiosk System Uninstall Script
# =============================================================================
# Purpose: Remove kiosk system setup, directories, services and configuration
# Target: Cleanup after setup-kiosk.sh execution
# Version: 1.0.0
# Dependencies: systemctl, rm
# 
# Usage: 
# - Local: sudo ./uninstall.sh
# - Local (força): sudo ./uninstall.sh --force
# - Remote: curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/dist/kiosk/scripts/uninstall.sh | sudo bash -s -- --force
#
# System Cleanup:
# - Remove kiosk directories and files
# - Disable and remove systemd services
# - Clean environment variables
# - Remove state and configuration files
# =============================================================================

set -eo pipefail  # Exit on error, pipe failures

# Script configuration
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "${0:-uninstall.sh}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
readonly LOG_FILE="/var/log/kiosk-uninstall.log"
readonly LOCK_FILE="/tmp/kiosk-uninstall.lock"

# Kiosk system structure (must match setup-kiosk.sh)
readonly KIOSK_BASE_DIR="/opt/kiosk"
readonly KIOSK_SCRIPTS_DIR="$KIOSK_BASE_DIR/scripts"
readonly KIOSK_SERVER_DIR="$KIOSK_BASE_DIR/server"
readonly KIOSK_UTILS_DIR="$KIOSK_BASE_DIR/utils"
readonly KIOSK_TEMPLATES_DIR="$KIOSK_BASE_DIR/templates"

# Configuration and state files
readonly KIOSK_CONFIG_FILE="$KIOSK_BASE_DIR/kiosk.conf"
readonly GLOBAL_ENV_FILE="/etc/environment"
readonly STATE_FILE="/var/lib/kiosk-setup-state"
readonly SETUP_LOG_FILE="/var/log/kiosk-setup.log"

# Service files
readonly SPLASH_SERVICE_PATH="/etc/systemd/system/kiosk-splash.service"
readonly SPLASH_IMAGE="$KIOSK_TEMPLATES_DIR/splash.jpg"
readonly SPLASH_VERSION="$KIOSK_TEMPLATES_DIR/splash_version.jpg"

# Temporary directories
readonly PDF_DOWNLOAD_DIR="/tmp/kiosk-badges"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
    log_message "INFO" "$1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log_message "WARN" "$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR" "$1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_message "SUCCESS" "$1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado com privilégios de root"
        log_info "Execute: sudo $0"
        exit 1
    fi
}

create_lock_file() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Outro processo de uninstall está em execução (PID: $lock_pid)"
            exit 1
        else
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo "$$" > "$LOCK_FILE"
    trap 'cleanup_on_exit' EXIT
}

cleanup_on_exit() {
    rm -f "$LOCK_FILE"
}

# Check if running with force flag or non-interactive
should_skip_confirmation() {
    # Check for --force or --yes flags
    for arg in "$@"; do
        case "$arg" in
            --force|--yes|-y|-f)
                return 0  # Skip confirmation
                ;;
        esac
    done
    
    # Check if running non-interactively (like via curl | bash)
    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        log_info "⚡ Executando em modo não-interativo, pulando confirmação"
        return 0  # Skip confirmation
    fi
    
    return 1  # Show confirmation
}

# =============================================================================
# UNINSTALL FUNCTIONS
# =============================================================================

remove_kiosk_services() {
    print_header "REMOVENDO SERVIÇOS DO SISTEMA"
    
    log_info "Parando e removendo serviços do kiosk..."
    
    # Stop and disable splash service
    if systemctl is-active --quiet kiosk-splash.service 2>/dev/null; then
        log_info "Parando serviço kiosk-splash..."
        if systemctl stop kiosk-splash.service; then
            log_success "✅ Serviço kiosk-splash parado"
        else
            log_warn "⚠️  Falha ao parar serviço kiosk-splash"
        fi
    else
        log_info "⚡ Serviço kiosk-splash já está parado"
    fi
    
    if systemctl is-enabled --quiet kiosk-splash.service 2>/dev/null; then
        log_info "Desabilitando serviço kiosk-splash..."
        if systemctl disable kiosk-splash.service; then
            log_success "✅ Serviço kiosk-splash desabilitado"
        else
            log_warn "⚠️  Falha ao desabilitar serviço kiosk-splash"
        fi
    else
        log_info "⚡ Serviço kiosk-splash já está desabilitado"
    fi
    
    # Remove service files
    if [[ -f "$SPLASH_SERVICE_PATH" ]]; then
        log_info "Removendo arquivo do serviço splash..."
        if rm -f "$SPLASH_SERVICE_PATH"; then
            log_success "✅ Arquivo do serviço removido: $SPLASH_SERVICE_PATH"
        else
            log_error "❌ Falha ao remover arquivo do serviço: $SPLASH_SERVICE_PATH"
        fi
    else
        log_info "⚡ Arquivo do serviço splash não encontrado"
    fi


    # Stop and disable splash service
    if systemctl is-active --quiet kiosk-start.service 2>/dev/null; then
        log_info "Parando serviço kiosk-start..."
        if systemctl stop kiosk-start.service; then
            log_success "✅ Serviço kiosk-start parado"
        else
            log_warn "⚠️  Falha ao parar serviço kiosk-start"
        fi
    else
        log_info "⚡ Serviço kiosk-start já está parado"
    fi

    if systemctl is-enabled --quiet kiosk-start.service 2>/dev/null; then
        log_info "Desabilitando serviço kiosk-start..."
        if systemctl disable kiosk-start.service; then
            log_success "✅ Serviço kiosk-start desabilitado"
        else
            log_warn "⚠️  Falha ao desabilitar serviço kiosk-start"
        fi
    else
        log_info "⚡ Serviço kiosk-start já está desabilitado"
    fi
    
    # Remove service files
    if [[ -f "$KIOSK_START_SERVICE_PATH" ]]; then
        log_info "Removendo arquivo do serviço kiosk-start..."
        if rm -f "$KIOSK_START_SERVICE_PATH"; then
            log_success "✅ Arquivo do serviço removido: $KIOSK_START_SERVICE_PATH"
        else
            log_error "❌ Falha ao remover arquivo do serviço: $KIOSK_START_SERVICE_PATH"
        fi
    else
        log_info "⚡ Arquivo do serviço kiosk-start não encontrado"
    fi
    
    # Reload systemd to update changes
    log_info "Recarregando configurações do systemd..."
    if systemctl daemon-reload; then
        log_success "✅ Systemd recarregado"
    else
        log_warn "⚠️  Falha ao recarregar systemd"
    fi
    
    log_success "Remoção de serviços concluída"
}

remove_kiosk_directories() {
    print_header "REMOVENDO DIRETÓRIOS DO KIOSK"
    
    log_info "Removendo estrutura de diretórios do kiosk..."
    
    # List directories to be removed
    local directories_to_remove=(
        "$KIOSK_SCRIPTS_DIR"
        "$KIOSK_SERVER_DIR"
        "$KIOSK_UTILS_DIR"
        "$KIOSK_TEMPLATES_DIR"
        "$KIOSK_BASE_DIR"
        "$PDF_DOWNLOAD_DIR"
    )
    
    # Remove each directory
    for dir in "${directories_to_remove[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "Removendo diretório: $dir"
            if rm -rf "$dir"; then
                log_success "✅ Diretório removido: $dir"
            else
                log_error "❌ Falha ao remover diretório: $dir"
            fi
        else
            log_info "⚡ Diretório não encontrado: $dir"
        fi
    done
    
    # Verify base directory removal
    if [[ ! -d "$KIOSK_BASE_DIR" ]]; then
        log_success "✅ Estrutura de diretórios completamente removida"
    else
        log_warn "⚠️  Alguns diretórios podem não ter sido removidos completamente"
        log_info "Conteúdo restante em $KIOSK_BASE_DIR:"
        ls -la "$KIOSK_BASE_DIR" 2>/dev/null || true
    fi
    
    log_success "Remoção de diretórios concluída"
}

remove_setup_status() {
    print_header "REMOVENDO STATUS E CONFIGURAÇÕES"
    
    log_info "Removendo arquivos de estado e configuração..."
    
    # Remove state file
    if [[ -f "$STATE_FILE" ]]; then
        log_info "Removendo arquivo de estado..."
        if rm -f "$STATE_FILE"; then
            log_success "✅ Arquivo de estado removido: $STATE_FILE"
        else
            log_error "❌ Falha ao remover arquivo de estado: $STATE_FILE"
        fi
    else
        log_info "⚡ Arquivo de estado não encontrado"
    fi
    
    # Remove configuration file (already removed with directories, but double-check)
    if [[ -f "$KIOSK_CONFIG_FILE" ]]; then
        log_info "Removendo arquivo de configuração..."
        if rm -f "$KIOSK_CONFIG_FILE"; then
            log_success "✅ Arquivo de configuração removido: $KIOSK_CONFIG_FILE"
        else
            log_error "❌ Falha ao remover arquivo de configuração: $KIOSK_CONFIG_FILE"
        fi
    else
        log_info "⚡ Arquivo de configuração não encontrado"
    fi
    
    # Remove setup log file
    if [[ -f "$SETUP_LOG_FILE" ]]; then
        log_info "Removendo log de instalação..."
        if rm -f "$SETUP_LOG_FILE"; then
            log_success "✅ Log de instalação removido: $SETUP_LOG_FILE"
        else
            log_error "❌ Falha ao remover log de instalação: $SETUP_LOG_FILE"
        fi
    else
        log_info "⚡ Log de instalação não encontrado"
    fi
    
    log_success "Remoção de status concluída"
}

remove_environment_variables() {
    print_header "REMOVENDO VARIÁVEIS DE AMBIENTE"
    
    log_info "Removendo variáveis de ambiente globais..."
    
    # List of environment variables to remove
    local env_vars_to_remove=(
        "KIOSK_VERSION"
        "APP_MODE"
        "APP_URL"
        "APP_API_URL"
        "PRINT_PORT"
        "KIOSK_BASE_DIR"
    )
    
    # Create backup of environment file
    if [[ -f "$GLOBAL_ENV_FILE" ]]; then
        local backup_file="${GLOBAL_ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Criando backup do arquivo de ambiente..."
        if cp "$GLOBAL_ENV_FILE" "$backup_file"; then
            log_success "✅ Backup criado: $backup_file"
        else
            log_warn "⚠️  Falha ao criar backup do arquivo de ambiente"
        fi
        
        # Remove kiosk-related environment variables
        local temp_file=$(mktemp)
        local removed_count=0
        
        while IFS= read -r line; do
            local should_keep=true
            for var in "${env_vars_to_remove[@]}"; do
                if [[ "$line" =~ ^export[[:space:]]+${var}= ]]; then
                    should_keep=false
                    ((removed_count++))
                    log_info "⚡ Removendo variável: $var"
                    break
                fi
            done
            
            if [[ "$should_keep" == true ]]; then
                echo "$line" >> "$temp_file"
            fi
        done < "$GLOBAL_ENV_FILE"
        
        # Replace original file with cleaned version
        if mv "$temp_file" "$GLOBAL_ENV_FILE"; then
            log_success "✅ Arquivo de ambiente atualizado ($removed_count variáveis removidas)"
        else
            log_error "❌ Falha ao atualizar arquivo de ambiente"
            rm -f "$temp_file"
        fi
    else
        log_info "⚡ Arquivo de ambiente não encontrado"
    fi
    
    log_success "Remoção de variáveis de ambiente concluída"
}

display_uninstall_summary() {
    print_header "DESINSTALAÇÃO CONCLUÍDA"
    
    log_success "🎉 Desinstalação do sistema kiosk concluída com sucesso!"
    echo
    
    log_info "📋 Resumo da desinstalação:"
    log_info "   • Serviços removidos: kiosk-splash.service"
    log_info "   • Diretórios removidos: $KIOSK_BASE_DIR"
    log_info "   • Arquivos de estado removidos: $STATE_FILE"
    log_info "   • Configurações removidas: $KIOSK_CONFIG_FILE"
    log_info "   • Variáveis de ambiente limpas: $GLOBAL_ENV_FILE"
    
    echo
    log_info "📄 Arquivos de log:"
    log_info "   • Log de desinstalação: $LOG_FILE"
    if [[ -f "${GLOBAL_ENV_FILE}.backup."* ]]; then
        log_info "   • Backup do ambiente: ${GLOBAL_ENV_FILE}.backup.*"
    fi
    
    echo
    log_info "⚠️  Componentes NÃO removidos:"
    log_info "   • Node.js (instalado pelo prepare-system.sh)"
    log_info "   • PM2 (instalado pelo prepare-system.sh)"
    log_info "   • CUPS (instalado pelo prepare-system.sh)"
    log_info "   • ImageMagick e outras dependências do sistema"
    
    echo
    log_info "💡 Próximos passos:"
    log_info "   • Para remover todas as dependências, execute prepare-system.sh --uninstall"
    log_info "   • Reinicie o sistema se necessário: sudo reboot"
    log_info "   • Para reinstalar: execute setup-kiosk.sh novamente"
    
    echo
    log_info "ℹ️  Opções de uso do uninstall:"
    log_info "   • Local: sudo ./uninstall.sh"
    log_info "   • Local (forçado): sudo ./uninstall.sh --force"
    log_info "   • Remoto: curl -fsSL [URL] | sudo bash -s -- --force"
    
    echo
    log_success "🔧 Sistema limpo e pronto para nova instalação!"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "KIOSK SYSTEM UNINSTALL v$SCRIPT_VERSION"
    
    log_info "🗑️  Iniciando desinstalação do sistema kiosk..."
    log_info "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "🕒 Executado em: $(date)"
    
    # Validations
    check_root_privileges
    create_lock_file
    
    # Confirm uninstall (unless forced or non-interactive)
    if should_skip_confirmation "$@"; then
        log_info "🚀 Modo automático ativado, iniciando desinstalação..."
    else
        echo
        log_warn "⚠️  ATENÇÃO: Esta operação irá remover COMPLETAMENTE o sistema kiosk!"
        log_info "📋 Será removido:"
        log_info "   • Todos os diretórios em $KIOSK_BASE_DIR"
        log_info "   • Serviços do systemd (kiosk-splash)"
        log_info "   • Arquivos de configuração e estado"
        log_info "   • Variáveis de ambiente relacionadas"
        echo
        
        read -p "Tem certeza que deseja continuar? (Digite 'yes' para confirmar): " -r
        if [[ ! "$REPLY" == "yes" ]]; then
            log_info "Operação cancelada pelo usuário"
            exit 0
        fi
        
        echo
        log_info "🚀 Iniciando processo de desinstalação..."
    fi
    
    # Uninstall process
    remove_kiosk_services
    remove_kiosk_directories
    remove_setup_status
    remove_environment_variables
    
    # Completion
    display_uninstall_summary
}

# Execute main function
main "$@"
