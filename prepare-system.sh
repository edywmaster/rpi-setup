#!/bin/bash

# =============================================================================
# Raspberry Pi System Preparation Script
# =============================================================================
# Purpose: Initial system update and essential package installation
# Target: Raspberry Pi OS Lite (Debian 12 "bookworm")
# Version: 1.0.8
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
#
# Critical fix in v1.0.3:
# - Fixed package installation loop hanging issue
# - Improved package detection method
# - Added timeout protection for package installation
# - Better error isolation (set +e/-e around package installation)
#
# New feature in v1.0.4:
# - Interruption detection and recovery system
# - State tracking for installation steps
# - Resume capability after power loss or accidental shutdown
# - User-friendly recovery options (continue/restart/cancel)
#
# Bug fix in v1.0.5:
# - Fixed timestamp format in state file to prevent source command errors
# - Added proper quoting for state variables to handle spaces
# - Improved state file format for better shell compatibility
#
# UI improvement in v1.0.6:
# - Cleaned up terminal output by removing duplicate log messages with timestamps
# - Terminal now shows only clean colored messages for better readability
# - Complete logs with timestamps still saved to log file
#
# New feature in v1.0.7:
# - Added boot configuration optimization for kiosk/display systems
# - Automatic config.txt and cmdline.txt optimization
# - Removes splash screens, boot logos, and verbose output
# - Creates backup of original cmdline.txt for safety
#
# New feature in v1.0.8:
# - Added automatic user autologin configuration
# - Configures systemd getty service for seamless login
# - Supports state tracking and recovery for autologin setup
# - Validates user existence and service status
# =============================================================================

set -eo pipefail  # Exit on error, pipe failures

# Script configuration
readonly SCRIPT_VERSION="1.0.8"
readonly SCRIPT_NAME="$(basename "${0:-prepare-system.sh}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
readonly LOG_FILE="/var/log/rpi-preparation.log"
readonly LOCK_FILE="/tmp/rpi-preparation.lock"
readonly STATE_FILE="/var/lib/rpi-preparation-state"

# Boot configuration files
readonly FILE_BOOT_CONFIG="/boot/firmware/config.txt"
readonly FILE_BOOT_CMDLINE="/boot/firmware/cmdline.txt"

# Autologin configuration
readonly AUTOLOGIN_USER="pi"
readonly AUTOLOGIN_SERVICE_DIR="/etc/systemd/system/getty@tty1.service.d"
readonly AUTOLOGIN_SERVICE_FILE="$AUTOLOGIN_SERVICE_DIR/override.conf"

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

# Installation steps for state tracking
readonly INSTALLATION_STEPS=(
    "validation"
    "update_lists"
    "system_upgrade"
    "locale_config"
    "package_install"
    "boot_config"
    "autologin_config"
    "cleanup"
    "completion"
)

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
# STATE MANAGEMENT FUNCTIONS
# =============================================================================

save_state() {
    local step="$1"
    local timestamp=$(date '+%Y-%m-%d_%H:%M:%S')
    
    # Create state directory if it doesn't exist
    mkdir -p "$(dirname "$STATE_FILE")"
    
    # Save current state (using quoted format to handle spaces)
    cat > "$STATE_FILE" << EOF
LAST_STEP="$step"
TIMESTAMP="$timestamp"
PID=$$
STATUS="running"
EOF
    
    log_info "Estado salvo: $step"
}

get_last_state() {
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE"
        echo "$LAST_STEP"
    else
        echo ""
    fi
}

get_state_timestamp() {
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE"
        echo "$TIMESTAMP"
    else
        echo ""
    fi
}

mark_completion() {
    if [[ -f "$STATE_FILE" ]]; then
        sed -i 's/STATUS="running"/STATUS="completed"/' "$STATE_FILE" 2>/dev/null || true
    fi
}

check_previous_installation() {
    if [[ ! -f "$STATE_FILE" ]]; then
        return 0  # No previous installation
    fi
    
    source "$STATE_FILE"
    
    # Check if previous installation was completed
    if [[ "$STATUS" == "completed" ]]; then
        log_info "✅ Instalação anterior foi concluída com sucesso"
        return 0
    fi
    
    # Check if previous process is still running
    if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
        log_error "🔒 Outra instalação está em execução (PID: $PID)"
        log_info "Se você tem certeza de que não há outro processo, remova: $STATE_FILE"
        exit 1
    fi
    
    # Previous installation was interrupted
    print_header "INSTALAÇÃO ANTERIOR DETECTADA"
    echo
    log_warn "⚠️  INTERRUPÇÃO DETECTADA!"
    log_info "Uma instalação anterior foi interrompida:"
    log_info "   • Última etapa: $LAST_STEP"
    log_info "   • Data/Hora: $TIMESTAMP"
    log_info "   • Status: Incompleta"
    echo
    
    # Show what was interrupted
    case "$LAST_STEP" in
        "validation")
            log_info "📋 A instalação foi interrompida durante as validações iniciais"
            ;;
        "update_lists")
            log_info "📦 A instalação foi interrompida durante a atualização das listas de pacotes"
            ;;
        "system_upgrade")
            log_info "⬆️  A instalação foi interrompida durante o upgrade do sistema"
            ;;
        "locale_config")
            log_info "🌍 A instalação foi interrompida durante a configuração de locales"
            ;;
        "package_install")
            log_info "📦 A instalação foi interrompida durante a instalação de pacotes"
            log_warn "   ⚠️  Alguns pacotes podem estar parcialmente instalados"
            ;;
        "boot_config")
            log_info "🔧 A instalação foi interrompida durante a configuração de boot"
            log_warn "   ⚠️  Configurações de boot podem estar incompletas"
            ;;
        "autologin_config")
            log_info "👤 A instalação foi interrompida durante a configuração de autologin"
            log_warn "   ⚠️  Configurações de autologin podem estar incompletas"
            ;;
        "cleanup")
            log_info "🧹 A instalação foi interrompida durante a limpeza do sistema"
            ;;
        *)
            log_info "❓ A instalação foi interrompida em uma etapa desconhecida"
            ;;
    esac
    
    echo
    log_info "🔧 Opções disponíveis:"
    log_info "   1️⃣  Continuar instalação (recomendado)"
    log_info "   2️⃣  Reiniciar do zero"
    log_info "   3️⃣  Cancelar"
    echo
    
    while true; do
        read -p "Escolha uma opção (1/2/3): " -n 1 -r choice
        echo
        
        case $choice in
            1|"")
                log_info "🔄 Continuando instalação anterior..."
                return 1  # Continue from interruption
                ;;
            2)
                log_info "🆕 Reiniciando instalação do zero..."
                rm -f "$STATE_FILE"
                return 0  # Start fresh
                ;;
            3)
                log_info "❌ Instalação cancelada pelo usuário"
                exit 0
                ;;
            *)
                log_warn "⚠️  Opção inválida. Digite 1, 2 ou 3."
                ;;
        esac
    done
}

get_step_index() {
    local target_step="$1"
    for i in "${!INSTALLATION_STEPS[@]}"; do
        if [[ "${INSTALLATION_STEPS[$i]}" == "$target_step" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo "0"  # Default to start
}

should_skip_step() {
    local current_step="$1"
    local last_step="$2"
    
    if [[ -z "$last_step" ]]; then
        return 1  # Don't skip, start fresh
    fi
    
    local current_index=$(get_step_index "$current_step")
    local last_index=$(get_step_index "$last_step")
    
    if [[ "$current_index" -le "$last_index" ]]; then
        return 0  # Skip this step
    else
        return 1  # Don't skip
    fi
}

cleanup_state_on_exit() {
    # Mark completion if we reach the end successfully
    if [[ -f "$STATE_FILE" ]]; then
        mark_completion
    fi
    
    # Remove lock file
    rm -f "$LOCK_FILE"
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
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Outro processo de instalação está em execução (PID: $lock_pid)"
            log_info "Se você tem certeza de que não há outro processo, remova: $LOCK_FILE"
            exit 1
        else
            log_warn "Lock file órfão detectado, removendo..."
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo "$$" > "$LOCK_FILE"
    trap 'cleanup_state_on_exit' EXIT
}

# =============================================================================
# SYSTEM PREPARATION FUNCTIONS
# =============================================================================

update_package_lists() {
    local step="update_lists"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando atualização de listas (já executada)"
        return 0
    fi
    
    print_header "ATUALIZANDO LISTAS DE PACOTES"
    save_state "$step"
    
    log_info "Executando apt update..."
    if apt-get update; then
        log_success "Listas de pacotes atualizadas com sucesso"
    else
        log_error "Falha ao atualizar listas de pacotes"
        exit 1
    fi
}

upgrade_system() {
    local step="system_upgrade"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando upgrade do sistema (já executado)"
        return 0
    fi
    
    print_header "ATUALIZANDO SISTEMA"
    save_state "$step"
    
    log_info "Executando upgrade do sistema..."
    if apt-get upgrade -y; then
        log_success "Sistema atualizado com sucesso"
    else
        log_error "Falha ao atualizar o sistema"
        exit 1
    fi
}

install_essential_packages() {
    local step="package_install"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando instalação de pacotes (já executada)"
        return 0
    fi
    
    print_header "INSTALANDO PACOTES ESSENCIAIS"
    save_state "$step"
    
    local failed_packages=()
    local skipped_packages=()
    local installed_count=0
    local total_packages=${#ESSENTIAL_PACKAGES[@]}
    
    log_info "Instalando $total_packages pacotes essenciais..."
    
    # Temporarily disable exit on error for package installation
    set +e
    
    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        log_info "Verificando: $package"
        
        # Check if package is already installed using apt list
        apt list --installed "$package" >/dev/null 2>&1
        if [[ $? -eq 0 ]] && apt list --installed "$package" 2>/dev/null | grep -q "installed"; then
            log_info "⚡ $package já está instalado"
            skipped_packages+=("$package")
            ((installed_count++))
            continue
        fi
        
        log_info "📦 Instalando: $package"
        
        # Install package with timeout and error handling
        if timeout 300 apt-get install -y "$package" >/dev/null 2>&1; then
            log_success "✅ $package instalado com sucesso"
            ((installed_count++))
        else
            log_error "❌ Falha ao instalar $package"
            failed_packages+=("$package")
        fi
    done
    
    # Re-enable exit on error
    set -e
    
    # Summary
    echo
    log_info "📊 Resumo da instalação:"
    log_success "Pacotes instalados/verificados: $installed_count/$total_packages"
    
    if [[ ${#skipped_packages[@]} -gt 0 ]]; then
        log_info "Pacotes já instalados: ${#skipped_packages[@]}"
        log_info "Lista: ${skipped_packages[*]}"
    fi
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "Pacotes que falharam: ${#failed_packages[@]}"
        log_warn "Lista: ${failed_packages[*]}"
        log_info "Você pode tentar instalar manualmente: apt-get install ${failed_packages[*]}"
    fi
    
    # Continue execution even if some packages failed
    log_info "Continuando com a configuração do sistema..."
}

configure_boot_settings() {
    local step="boot_config"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração de boot (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO BOOT DO SISTEMA"
    save_state "$step"
    
    log_info "Configurando arquivos de boot do Raspberry Pi..."
    
    # Check if boot files exist
    if [[ ! -f "$FILE_BOOT_CONFIG" ]]; then
        log_error "Arquivo $FILE_BOOT_CONFIG não encontrado"
        log_warn "Pode não ser um Raspberry Pi ou sistema não suportado"
        return 0
    fi
    
    if [[ ! -f "$FILE_BOOT_CMDLINE" ]]; then
        log_error "Arquivo $FILE_BOOT_CMDLINE não encontrado"
        log_warn "Pode não ser um Raspberry Pi ou sistema não suportado"
        return 0
    fi
    
    # Configure config.txt
    log_info "Configurando $FILE_BOOT_CONFIG..."
    
    if ! grep -q "disable_splash=1" "$FILE_BOOT_CONFIG"; then
        log_info "Adicionando configurações de display ao config.txt..."
        echo "" >> "$FILE_BOOT_CONFIG"
        echo "# Raspberry Pi Display Optimizations - Added by rpi-setup" >> "$FILE_BOOT_CONFIG"
        echo "disable_splash=1" >> "$FILE_BOOT_CONFIG"
        echo "avoid_warnings=1" >> "$FILE_BOOT_CONFIG"
        log_success "✅ Configurações adicionadas ao $FILE_BOOT_CONFIG"
    else
        log_info "⚡ Configurações já presentes no $FILE_BOOT_CONFIG"
    fi
    
    # Configure cmdline.txt  
    log_info "Configurando $FILE_BOOT_CMDLINE..."
    
    if ! grep -q "logo.nologo" "$FILE_BOOT_CMDLINE"; then
        log_info "Adicionando parâmetros de boot otimizados..."
        
        # Create backup of cmdline.txt
        cp "$FILE_BOOT_CMDLINE" "$FILE_BOOT_CMDLINE.backup"
        log_info "Backup criado: $FILE_BOOT_CMDLINE.backup"
        
        # Add boot parameters
        sed -i '1s/$/ logo.nologo vt.global_cursor_default=0 consoleblank=0 loglevel=0 quiet/' "$FILE_BOOT_CMDLINE"
        log_success "✅ Configurações adicionadas ao $FILE_BOOT_CMDLINE"
    else
        log_info "⚡ Configurações já presentes no $FILE_BOOT_CMDLINE"
    fi
    
    # Summary of changes
    echo
    log_info "📋 Configurações de boot aplicadas:"
    log_info "   • disable_splash=1 - Remove tela de splash"
    log_info "   • avoid_warnings=1 - Remove avisos de undervoltage"
    log_info "   • logo.nologo - Remove logo do kernel"
    log_info "   • vt.global_cursor_default=0 - Remove cursor piscando"
    log_info "   • consoleblank=0 - Desabilita blank do console"
    log_info "   • loglevel=0 quiet - Reduz mensagens de boot"
    
    log_success "Configurações de boot concluídas"
}

configure_autologin() {
    local step="autologin_config"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração de autologin (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO AUTOLOGIN"
    save_state "$step"
    
    log_info "Configurando autologin para o usuário '$AUTOLOGIN_USER'..."
    
    # Verificar se o usuário existe
    if ! id "$AUTOLOGIN_USER" >/dev/null 2>&1; then
        log_error "Usuário '$AUTOLOGIN_USER' não encontrado no sistema"
        log_warn "Autologin será configurado, mas pode não funcionar até que o usuário seja criado"
    else
        log_info "✅ Usuário '$AUTOLOGIN_USER' encontrado no sistema"
    fi
    
    # Verificar se já existe configuração
    if [[ -f "$AUTOLOGIN_SERVICE_FILE" ]]; then
        log_info "📋 Verificando configuração existente..."
        
        if grep -q "autologin $AUTOLOGIN_USER" "$AUTOLOGIN_SERVICE_FILE"; then
            log_info "⚡ Autologin já está configurado para o usuário '$AUTOLOGIN_USER'"
            
            # Verificar se o serviço está ativo
            if systemctl is-active --quiet getty@tty1; then
                log_success "✅ Serviço getty@tty1 está ativo"
            else
                log_warn "⚠️  Serviço getty@tty1 não está ativo, reiniciando..."
                systemctl restart getty@tty1
                log_success "✅ Serviço getty@tty1 reiniciado"
            fi
            
            log_success "Configuração de autologin já está aplicada"
            return 0
        else
            log_warn "⚠️  Configuração existente detectada, mas para usuário diferente"
            log_info "Atualizando para o usuário '$AUTOLOGIN_USER'..."
        fi
    fi
    
    # Criar diretório se não existir
    log_info "📁 Criando diretório de configuração..."
    mkdir -p "$AUTOLOGIN_SERVICE_DIR"
    
    # Criar arquivo de configuração
    log_info "📝 Criando arquivo de configuração do autologin..."
    cat > "$AUTOLOGIN_SERVICE_FILE" << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $AUTOLOGIN_USER --noclear %I \$TERM
EOF
    
    if [[ -f "$AUTOLOGIN_SERVICE_FILE" ]]; then
        log_success "✅ Arquivo de configuração criado: $AUTOLOGIN_SERVICE_FILE"
    else
        log_error "❌ Falha ao criar arquivo de configuração"
        return 1
    fi
    
    # Recarregar systemd
    log_info "🔄 Recarregando configurações do systemd..."
    if systemctl daemon-reload; then
        log_success "✅ Systemd recarregado com sucesso"
    else
        log_error "❌ Falha ao recarregar systemd"
        return 1
    fi
    
    # Reiniciar serviço getty@tty1
    log_info "🔄 Reiniciando serviço getty@tty1..."
    if systemctl restart getty@tty1; then
        log_success "✅ Serviço getty@tty1 reiniciado com sucesso"
    else
        log_error "❌ Falha ao reiniciar serviço getty@tty1"
        return 1
    fi
    
    # Verificar status do serviço
    log_info "🔍 Verificando status do serviço..."
    if systemctl is-active --quiet getty@tty1; then
        log_success "✅ Serviço getty@tty1 está ativo e funcionando"
    else
        log_warn "⚠️  Serviço getty@tty1 pode não estar funcionando corretamente"
        log_info "Status do serviço: $(systemctl is-active getty@tty1 2>/dev/null || echo 'unknown')"
    fi
    
    # Resumo da configuração
    echo
    log_info "📋 Configuração de autologin aplicada:"
    log_info "   • Usuário: $AUTOLOGIN_USER"
    log_info "   • Arquivo: $AUTOLOGIN_SERVICE_FILE"
    log_info "   • Serviço: getty@tty1"
    log_info "   • Status: Ativo"
    
    log_success "Configuração de autologin concluída"
}

cleanup_system() {
    local step="cleanup"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando limpeza (já executada)"
        return 0
    fi
    
    print_header "LIMPEZA DO SISTEMA"
    save_state "$step"
    
    log_info "Executando limpeza de pacotes desnecessários..."
    apt-get autoremove -y >/dev/null 2>&1
    apt-get autoclean >/dev/null 2>&1
    
    log_success "Limpeza concluída"
}

configure_locales() {
    local step="locale_config"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração de locales (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO LOCALES"
    save_state "$step"
    
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
    save_state "completion"
    
    print_header "PREPARAÇÃO CONCLUÍDA"
    
    log_success "🎉 Preparação do sistema Raspberry Pi concluída!"
    echo
    log_info "   📋 Informações do sistema:"
    log_info "   • Modelo: $(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')"
    log_info "   • OS: $(lsb_release -ds 2>/dev/null)"
    log_info "   • Kernel: $(uname -r)"
    log_info "   • Arquitetura: $(uname -m)"
    
    echo
    log_info "   📁 Arquivos importantes:"
    log_info "   • Logs completos: $LOG_FILE"
    log_info "   • Sistema atualizado: $(date)"
    
    # Check disk usage
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    log_info "   • Uso do disco: $disk_usage"
    
    # Check if reboot is needed
    if [[ -f /var/run/reboot-required ]]; then
        echo
        log_warn "   ⚠️  Reinicialização necessária para aplicar algumas atualizações"
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
        log_success "✅ Sistema atualizado com sucesso!"
    fi
    
    # Mark installation as completed
    mark_completion
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "RASPBERRY PI SYSTEM PREPARATION v$SCRIPT_VERSION"
    
    log_info "🚀 Iniciando preparação do sistema..."
    log_info "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "🕒 Executado em: $(date)"
    
    # Check for previous interrupted installation
    local continue_from_interruption=false
    if check_previous_installation; then
        # Starting fresh installation
        save_state "validation"
    else
        # Continuing from interruption
        continue_from_interruption=true
        log_info "🔄 Continuando instalação a partir da interrupção..."
    fi
    
    # Validations
    check_root_privileges
    create_lock_file
    
    if [[ "$continue_from_interruption" == false ]]; then
        detect_raspberry_pi
        check_internet_connectivity
    else
        log_info "⏭️  Pulando validações (continuando instalação anterior)"
    fi
    
    # System preparation (with state tracking)
    update_package_lists
    upgrade_system
    configure_locales
    install_essential_packages
    configure_boot_settings
    configure_autologin
    cleanup_system
    
    # Completion
    display_completion_summary
}

# Execute main function
main "$@"
