#!/bin/bash

# =============================================================================
# Raspberry Pi System Preparation Script
# =============================================================================
# Purpose: Initial system update and essential package installation
# Target: Raspberry Pi OS Lite (Debian 12 "bookworm")
# Version: 1.0.2
# Compatibility: Raspberry Pi 4B (portable to other models)
# 
# Execution methods:
# - Direct: sudo ./prepare-system.sh
# - Remote: curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash
#
# Improvements in v1.0.2:
# - Enhanced package installation with duplicate detection
# - Automatic locale configuration
# - Improved visual feedback and emojis
# - Better error handling and logging
# - Comprehensive system summary
# =============================================================================

set -eo pipefail  # Exit on error, pipe failures

# Script configuration
readonly SCRIPT_NAME="$(basename "${0:-prepare-system.sh}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
readonly LOG_FILE="/var/log/rpi-preparation.log"
readonly LOCK_FILE="/tmp/rpi-preparation.lock"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Essential packages for kiosk/display systems
readonly ESSENTIAL_PACKAGES=(
    "wget"              # Download tool
    "curl"              # HTTP client
    "jq"                # JSON processor
    "lsof"              # List open files
    "unzip"             # Archive extraction
    "fbi"               # Framebuffer image viewer
    "xserver-xorg"      # X11 server
    "x11-xserver-utils" # X11 utilities
    "dbus-x11"          # D-Bus X11 integration
    "xinit"             # X11 initialization
    "openbox"           # Lightweight window manager
    "python3-pyxdg"     # Python XDG support
    "chromium-browser"  # Web browser
    "unclutter"         # Hide mouse cursor
    "imagemagick"       # Image manipulation
    "libgbm-dev"        # Graphics buffer manager
    "libasound2"        # ALSA sound library
    "build-essential"   # Build tools
)

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

detect_raspberry_pi() {
    local pi_model=""
    local os_version=""
    
    # Detect Pi model
    if [[ -f /proc/device-tree/model ]]; then
        pi_model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
    else
        log_warn "Não foi possível detectar o modelo do Raspberry Pi"
        pi_model="Unknown"
    fi
    
    # Detect OS version
    if command -v lsb_release >/dev/null 2>&1; then
        os_version=$(lsb_release -ds 2>/dev/null)
    else
        os_version="Unknown"
    fi
    
    log_info "Modelo detectado: $pi_model"
    log_info "Sistema operacional: $os_version"
    
    # Validate this is a Raspberry Pi
    if [[ ! "$pi_model" =~ "Raspberry Pi" ]]; then
        log_warn "Este script foi projetado para Raspberry Pi"
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Instalação cancelada pelo usuário"
            exit 0
        fi
    fi
}

check_internet_connectivity() {
    log_info "Verificando conectividade com a internet..."
    
    if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        log_error "Sem conectividade com a internet"
        log_info "Verifique sua conexão de rede e tente novamente"
        exit 1
    fi
    
    log_success "Conectividade com a internet confirmada"
}

create_lock_file() {
    if [[ -f "$LOCK_FILE" ]]; then
        log_error "Outro processo de instalação está em execução"
        log_info "Se você tem certeza de que não há outro processo, remova: $LOCK_FILE"
        exit 1
    fi
    
    echo "$$" > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"' EXIT
}

# =============================================================================
# SYSTEM PREPARATION FUNCTIONS
# =============================================================================

update_package_lists() {
    print_header "ATUALIZANDO LISTAS DE PACOTES"
    
    log_info "Executando apt update..."
    if apt-get update; then
        log_success "Listas de pacotes atualizadas com sucesso"
    else
        log_error "Falha ao atualizar listas de pacotes"
        exit 1
    fi
}

upgrade_system() {
    print_header "ATUALIZANDO SISTEMA"
    
    log_info "Executando upgrade do sistema..."
    if apt-get upgrade -y; then
        log_success "Sistema atualizado com sucesso"
    else
        log_error "Falha ao atualizar o sistema"
        exit 1
    fi
}

install_essential_packages() {
    print_header "INSTALANDO PACOTES ESSENCIAIS"
    
    local failed_packages=()
    local skipped_packages=()
    local installed_count=0
    local total_packages=${#ESSENTIAL_PACKAGES[@]}
    
    log_info "Instalando $total_packages pacotes essenciais..."
    
    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        log_info "Verificando: $package"
        
        # Check if package is already installed
        if dpkg -l | grep -q "^ii  $package "; then
            log_info "⚡ $package já está instalado"
            skipped_packages+=("$package")
            ((installed_count++))
            continue
        fi
        
        log_info "📦 Instalando: $package"
        
        if apt-get install -y "$package" >/dev/null 2>&1; then
            log_success "✅ $package instalado com sucesso"
            ((installed_count++))
        else
            log_error "❌ Falha ao instalar $package"
            failed_packages+=("$package")
        fi
    done
    
    # Summary
    echo
    log_info "📊 Resumo da instalação:"
    log_success "Pacotes instalados/verificados: $installed_count/$total_packages"
    
    if [[ ${#skipped_packages[@]} -gt 0 ]]; then
        log_info "Pacotes já instalados: ${#skipped_packages[@]} (${skipped_packages[*]})"
    fi
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "Pacotes que falharam: ${failed_packages[*]}"
        log_info "Você pode tentar instalar manualmente: apt-get install ${failed_packages[*]}"
    fi
}

cleanup_system() {
    print_header "LIMPEZA DO SISTEMA"
    
    log_info "Executando limpeza de pacotes desnecessários..."
    apt-get autoremove -y >/dev/null 2>&1
    apt-get autoclean >/dev/null 2>&1
    
    log_success "Limpeza concluída"
}

configure_locales() {
    print_header "CONFIGURANDO LOCALES"
    
    log_info "Verificando configuração de locales..."
    
    # Check if locales are properly configured
    if locale -a | grep -q "en_GB.utf8" && locale -a | grep -q "en_US.utf8"; then
        log_success "Locales já configurados corretamente"
        return 0
    fi
    
    log_info "Configurando locales do sistema..."
    
    # Generate missing locales
    if ! locale -a | grep -q "en_GB.utf8"; then
        log_info "Gerando locale en_GB.UTF-8..."
        sed -i 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
    fi
    
    if ! locale -a | grep -q "en_US.utf8"; then
        log_info "Gerando locale en_US.UTF-8..."
        sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    fi
    
    # Generate locales
    locale-gen >/dev/null 2>&1
    
    # Update default locale
    update-locale LANG=en_GB.UTF-8 LC_ALL=en_GB.UTF-8 >/dev/null 2>&1
    
    log_success "Locales configurados com sucesso"
}

display_completion_summary() {
    print_header "PREPARAÇÃO CONCLUÍDA"
    
    echo -e "${GREEN}"
    cat << 'EOF'
    ████████╗ ███████╗ ██████╗ ███╗   ███╗██████╗ ██╗     ███████╗████████╗ ██████╗ 
    ██╔════╝██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║     ██╔════╝╚══██╔══╝██╔═══██╗
    ██║     ██║     ██║   ██║██╔████╔██║██████╔╝██║     █████╗     ██║   ██║   ██║
    ██║     ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝     ██║   ██║   ██║
    ╚██████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ███████╗███████╗   ██║   ╚██████╔╝
     ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝   ╚═╝    ╚═════╝ 
EOF
    echo -e "${NC}"
    
    log_success "🎉 Preparação do sistema Raspberry Pi concluída!"
    echo
    log_info "📋 Informações do sistema:"
    log_info "   • Modelo: $(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')"
    log_info "   • OS: $(lsb_release -ds 2>/dev/null)"
    log_info "   • Kernel: $(uname -r)"
    log_info "   • Arquitetura: $(uname -m)"
    
    echo
    log_info "📁 Arquivos importantes:"
    log_info "   • Logs completos: $LOG_FILE"
    log_info "   • Sistema atualizado: $(date)"
    
    # Check disk usage
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    log_info "   • Uso do disco: $disk_usage"
    
    # Check if reboot is needed
    if [[ -f /var/run/reboot-required ]]; then
        echo
        log_warn "⚠️  Reinicialização necessária para aplicar algumas atualizações"
        log_info "   • Alguns pacotes exigem reinicialização"
        log_info "   • Execute: sudo reboot"
        
        read -p "🔄 Reiniciar agora? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "🔄 Reiniciando sistema..."
            sleep 2
            reboot
        fi
    else
        echo
        log_success "✅ Sistema pronto para uso!"
        log_info "🚀 Próximos passos sugeridos:"
        log_info "   • Configurar SSH keys"
        log_info "   • Instalar software específico"
        log_info "   • Configurar firewall"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "RASPBERRY PI SYSTEM PREPARATION"
    
    log_info "🚀 Iniciando preparação do sistema..."
    log_info "📋 Script: $SCRIPT_NAME"
    log_info "🕒 Executado em: $(date)"
    
    # Validations
    check_root_privileges
    create_lock_file
    detect_raspberry_pi
    check_internet_connectivity
    
    # System preparation
    update_package_lists
    upgrade_system
    configure_locales
    install_essential_packages
    cleanup_system
    
    # Completion
    display_completion_summary
}

# Execute main function
main "$@"
