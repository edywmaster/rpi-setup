#!/bin/bash

# =============================================================================
# Raspberry Pi Multiple Device Deployment Script
# =============================================================================
# Purpose: Deploy prepare-system.sh to multiple Raspberry Pi devices
# Repository: https://github.com/edywmaster/rpi-setup
# Version: 1.0.0
# =============================================================================

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_URL="https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh"
readonly LOG_FILE="deployment-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Device configuration
# Adicione os IPs dos seus dispositivos Raspberry Pi aqui
DEVICES=(
    # "192.168.1.100"
    # "192.168.1.101"
    # "192.168.1.102"
    # "pi-device-01.local"
    # "pi-device-02.local"
)

# SSH configuration
readonly SSH_USER="pi"
readonly SSH_TIMEOUT=10
readonly SSH_OPTIONS="-o ConnectTimeout=$SSH_TIMEOUT -o BatchMode=yes -o StrictHostKeyChecking=no"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
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

print_separator() {
    echo -e "${YELLOW}----------------------------------------${NC}"
}

# =============================================================================
# DEPLOYMENT FUNCTIONS
# =============================================================================

check_prerequisites() {
    print_header "VERIFICANDO PRÉ-REQUISITOS"
    
    # Check if devices are configured
    if [[ ${#DEVICES[@]} -eq 0 ]]; then
        log_error "Nenhum dispositivo configurado!"
        echo
        echo "Para usar este script:"
        echo "1. Edite o arquivo $SCRIPT_NAME"
        echo "2. Adicione os IPs dos seus Raspberry Pi no array DEVICES"
        echo "3. Execute novamente"
        echo
        echo "Exemplo:"
        echo 'DEVICES=('
        echo '    "192.168.1.100"'
        echo '    "192.168.1.101"'
        echo '    "pi-device-01.local"'
        echo ')'
        exit 1
    fi
    
    # Check if curl is available
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl não está instalado. Instale com: sudo apt-get install curl"
        exit 1
    fi
    
    # Check if ssh is available
    if ! command -v ssh >/dev/null 2>&1; then
        log_error "ssh não está instalado. Instale com: sudo apt-get install openssh-client"
        exit 1
    fi
    
    # Test script URL availability
    log_info "Testando disponibilidade do script..."
    if curl -fsSL --connect-timeout 10 "$SCRIPT_URL" >/dev/null; then
        log_success "Script disponível no GitHub"
    else
        log_error "Falha ao acessar script em: $SCRIPT_URL"
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

test_device_connectivity() {
    local device="$1"
    
    log_info "Testando conectividade: $device"
    
    # Test ping
    if ! ping -c 1 -W 2 "$device" >/dev/null 2>&1; then
        log_warn "Ping falhou para: $device"
        return 1
    fi
    
    # Test SSH
    if ! ssh $SSH_OPTIONS "$SSH_USER@$device" "echo 'SSH OK'" >/dev/null 2>&1; then
        log_warn "SSH falhou para: $device"
        return 1
    fi
    
    log_success "Conectividade OK: $device"
    return 0
}

deploy_to_device() {
    local device="$1"
    local start_time=$(date +%s)
    
    print_separator
    log_info "🔧 Iniciando configuração: $device"
    
    # Test connectivity first
    if ! test_device_connectivity "$device"; then
        log_error "❌ $device - Falha na conectividade"
        return 1
    fi
    
    # Execute the script
    log_info "Executando script de preparação..."
    if ssh $SSH_OPTIONS "$SSH_USER@$device" "curl -fsSL $SCRIPT_URL | sudo bash" 2>&1 | tee -a "$LOG_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "✅ $device - Configuração concluída em ${duration}s"
        return 0
    else
        log_error "❌ $device - Falha na execução do script"
        return 1
    fi
}

display_summary() {
    local successful="$1"
    local failed="$2"
    local total=$((successful + failed))
    
    print_header "RESUMO DA IMPLANTAÇÃO"
    
    echo -e "${GREEN}Dispositivos configurados com sucesso: $successful/$total${NC}"
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Dispositivos com falha: $failed/$total${NC}"
    fi
    
    echo
    log_info "Log detalhado salvo em: $LOG_FILE"
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}"
        cat << 'EOF'
    ████████╗ ██████╗ ██████╗  ██████╗ ███████╗    ██████╗ ██╗  ██╗
    ╚══██╔══╝██╔═══██╗██╔══██╗██╔═══██╗██╔════╝    ██╔═══██╗██║ ██╔╝
       ██║   ██║   ██║██║  ██║██║   ██║███████╗    ██║   ██║█████╔╝ 
       ██║   ██║   ██║██║  ██║██║   ██║╚════██║    ██║   ██║██╔═██╗ 
       ██║   ╚██████╔╝██████╔╝╚██████╔╝███████║    ╚██████╔╝██║  ██╗
       ╚═╝    ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝     ╚═════╝ ╚═╝  ╚═╝
EOF
        echo -e "${NC}"
        log_success "Todos os dispositivos foram configurados com sucesso!"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "RASPBERRY PI MULTIPLE DEPLOYMENT"
    
    log_info "Iniciando implantação em múltiplos dispositivos..."
    log_info "Script: $SCRIPT_NAME"
    log_info "Executado em: $(date)"
    log_info "Dispositivos configurados: ${#DEVICES[@]}"
    
    # Check prerequisites
    check_prerequisites
    
    # Deployment variables
    local successful=0
    local failed=0
    
    # Ask for confirmation
    echo
    echo "Dispositivos que serão configurados:"
    for device in "${DEVICES[@]}"; do
        echo "  - $device"
    done
    echo
    read -p "Continuar com a implantação? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Implantação cancelada pelo usuário"
        exit 0
    fi
    
    # Deploy to each device
    print_header "INICIANDO IMPLANTAÇÃO"
    
    for device in "${DEVICES[@]}"; do
        if deploy_to_device "$device"; then
            ((successful++))
        else
            ((failed++))
        fi
    done
    
    # Display summary
    display_summary "$successful" "$failed"
    
    # Exit with appropriate code
    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}

# Show usage if no devices configured or help requested
if [[ ${#DEVICES[@]} -eq 0 ]] || [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << 'EOF'
Raspberry Pi Multiple Device Deployment Script

Este script executa prepare-system.sh em múltiplos dispositivos Raspberry Pi.

CONFIGURAÇÃO:
1. Edite este script e configure o array DEVICES com os IPs dos seus Raspberry Pi
2. Certifique-se de ter acesso SSH configurado (chaves SSH recomendadas)
3. Execute o script

EXEMPLO DE CONFIGURAÇÃO:
DEVICES=(
    "192.168.1.100"
    "192.168.1.101"
    "pi-device-01.local"
)

PRÉ-REQUISITOS:
- Acesso SSH aos dispositivos (usuário 'pi')
- Dispositivos com Raspberry Pi OS Lite
- Conectividade com internet nos dispositivos

USO:
    ./deploy-multiple.sh

OPÇÕES:
    -h, --help    Mostra esta ajuda
EOF
    exit 0
fi

# Execute main function
main "$@"
