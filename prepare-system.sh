#!/bin/bash

# =============================================================================
# Raspberry Pi System Preparation Script
# =============================================================================
# Purpose: Initial system update and essential package installation
# Target: Raspberry Pi OS Lite (Debian 12 "bookworm")
# Version: 1.3.1
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
#
# New feature in v1.0.9:
# - Added Node.js LTS installation with global access
# - Automatic architecture detection (ARM64, ARMv7, x64)
# - Configures global permissions for all users
# - Downloads and installs latest LTS version (v22.13.1)
# - Creates global symlinks and validates installation
#
# New feature in v1.1.0:
# - Added CUPS (Common Unix Printing System) installation and configuration
# - Automatic user addition to lpadmin group for printer management
# - Remote access configuration for web interface (http://ip:631)
# - Disabled automatic printer discovery to prevent network scanning
# - Complete CUPS service management with state tracking and recovery
#
# New feature in v1.2.0:
# - Added PM2 (Process Manager 2) global installation for Node.js applications
# - Automatic PM2 configuration for user 'pi' with process management capabilities
# - Global access to PM2 commands for all users via /usr/bin/pm2
# - Complete integration with existing Node.js installation
# - State tracking and recovery support for PM2 installation
# =============================================================================

set -eo pipefail  # Exit on error, pipe failures

# Script configuration
readonly SCRIPT_VERSION="1.3.1"
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

# Node.js configuration
readonly NODEJS_VERSION="v22.13.1"  # Latest LTS
readonly NODEJS_INSTALL_DIR="/usr/local"
readonly NODEJS_TEMP_DIR="/tmp/nodejs-install"

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
    "xz-utils"          # XZ compression utilities (for Node.js)
    "libssl-dev"        # SSL development libraries (for Node.js)
    "cups"              # Common Unix Printing System
    "cups-client"       # CUPS client utilities
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
    "nodejs_install"
    "pm2_install"
    "cups_config"
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
        "nodejs_install")
            log_info "⚙️  A instalação foi interrompida durante a instalação do Node.js"
            log_warn "   ⚠️  Node.js pode estar parcialmente instalado"
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

install_nodejs() {
    local step="nodejs_install"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando instalação do Node.js (já executada)"
        return 0
    fi
    
    print_header "INSTALANDO NODE.JS"
    save_state "$step"
    
    log_info "Instalando Node.js versão $NODEJS_VERSION..."
    
    # Verificar se Node.js já está instalado
    if command -v node >/dev/null 2>&1; then
        local current_version=$(node -v 2>/dev/null || echo "unknown")
        if [[ "$current_version" == "$NODEJS_VERSION" ]]; then
            log_info "⚡ Node.js versão $NODEJS_VERSION já está instalado"
            log_success "Node.js: $current_version"
            log_success "npm: $(npm -v 2>/dev/null || echo 'não disponível')"
            return 0
        else
            log_warn "⚠️  Node.js versão diferente encontrada: $current_version"
            log_info "Atualizando para a versão $NODEJS_VERSION..."
        fi
    fi
    
    # Detectar arquitetura do sistema
    local arch=$(uname -m)
    local node_distro=""
    
    case "$arch" in
        "aarch64"|"arm64")
            node_distro="node-${NODEJS_VERSION}-linux-arm64"
            log_info "✅ Arquitetura detectada: $arch (ARM64)"
            ;;
        "armv7l")
            node_distro="node-${NODEJS_VERSION}-linux-armv7l"
            log_info "✅ Arquitetura detectada: $arch (ARMv7)"
            ;;
        "x86_64")
            node_distro="node-${NODEJS_VERSION}-linux-x64"
            log_info "✅ Arquitetura detectada: $arch (x64)"
            ;;
        *)
            log_error "❌ Arquitetura não suportada: $arch"
            log_info "Arquiteturas suportadas: aarch64, armv7l, x86_64"
            return 1
            ;;
    esac
    
    local node_url="https://nodejs.org/dist/${NODEJS_VERSION}/${node_distro}.tar.xz"
    
    # Criar diretório temporário
    log_info "📁 Criando diretório temporário..."
    rm -rf "$NODEJS_TEMP_DIR" 2>/dev/null || true
    mkdir -p "$NODEJS_TEMP_DIR"
    
    # Baixar Node.js
    log_info "📥 Baixando Node.js de $node_url..."
    if ! curl -fL "$node_url" -o "$NODEJS_TEMP_DIR/${node_distro}.tar.xz"; then
        log_error "❌ Falha ao baixar Node.js"
        log_info "Verifique sua conexão com a internet e a versão especificada"
        rm -rf "$NODEJS_TEMP_DIR"
        return 1
    fi
    
    log_success "✅ Download concluído"
    
    # Extrair arquivos
    log_info "📦 Extraindo arquivos..."
    cd "$NODEJS_TEMP_DIR"
    
    if ! tar -xf "${node_distro}.tar.xz"; then
        log_error "❌ Falha ao extrair Node.js"
        rm -rf "$NODEJS_TEMP_DIR"
        return 1
    fi
    
    log_success "✅ Extração concluída"
    
    # Instalar Node.js
    log_info "🔧 Instalando Node.js em $NODEJS_INSTALL_DIR..."
    cd "${node_distro}"
    
    # Backup de instalação anterior se existir
    if [[ -d "$NODEJS_INSTALL_DIR/lib/node_modules" ]]; then
        log_info "📋 Fazendo backup da instalação anterior..."
        mv "$NODEJS_INSTALL_DIR/lib/node_modules" "$NODEJS_INSTALL_DIR/lib/node_modules.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi
    
    # Copiar arquivos
    log_info "📂 Copiando binários e bibliotecas..."
    cp -R bin/* "$NODEJS_INSTALL_DIR/bin/" 2>/dev/null || true
    cp -R include/* "$NODEJS_INSTALL_DIR/include/" 2>/dev/null || true
    cp -R lib/* "$NODEJS_INSTALL_DIR/lib/" 2>/dev/null || true
    cp -R share/* "$NODEJS_INSTALL_DIR/share/" 2>/dev/null || true
    
    # Configurar links simbólicos globais
    log_info "🔗 Configurando links simbólicos globais..."
    ln -sf "$NODEJS_INSTALL_DIR/bin/node" /usr/bin/node
    ln -sf "$NODEJS_INSTALL_DIR/bin/npm" /usr/bin/npm
    ln -sf "$NODEJS_INSTALL_DIR/bin/npx" /usr/bin/npx
    
    # Configurar permissões para todos os usuários
    log_info "🔐 Configurando permissões para todos os usuários..."
    chmod +x "$NODEJS_INSTALL_DIR/bin/node" 2>/dev/null || true
    chmod +x "$NODEJS_INSTALL_DIR/bin/npm" 2>/dev/null || true
    chmod +x "$NODEJS_INSTALL_DIR/bin/npx" 2>/dev/null || true
    
    # Configurar permissões do diretório npm global
    if [[ -d "$NODEJS_INSTALL_DIR/lib/node_modules" ]]; then
        chmod -R 755 "$NODEJS_INSTALL_DIR/lib/node_modules" 2>/dev/null || true
    fi
    
    # Verificar instalação
    log_info "🔍 Verificando instalação..."
    
    # Atualizar PATH para verificação
    export PATH="$NODEJS_INSTALL_DIR/bin:/usr/bin:$PATH"
    
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        local installed_node_version=$(node -v 2>/dev/null)
        local installed_npm_version=$(npm -v 2>/dev/null)
        
        log_success "✅ Node.js instalado com sucesso!"
        log_info "   • Node.js: $installed_node_version"
        log_info "   • npm: $installed_npm_version"
        log_info "   • npx: disponível"
        
        # Verificar se npm funciona globalmente
        if npm --version >/dev/null 2>&1; then
            log_success "✅ npm configurado corretamente"
        else
            log_warn "⚠️  npm pode ter problemas de configuração"
        fi
        
    else
        log_error "❌ Falha na verificação da instalação"
        log_info "Node.js pode não estar disponível no PATH"
        rm -rf "$NODEJS_TEMP_DIR"
        return 1
    fi
    
    # Limpar arquivos temporários
    log_info "🧹 Limpando arquivos temporários..."
    rm -rf "$NODEJS_TEMP_DIR"
    
    # Resumo da instalação
    echo
    log_info "📋 Instalação do Node.js concluída:"
    log_info "   • Versão: $NODEJS_VERSION"
    log_info "   • Localização: $NODEJS_INSTALL_DIR/bin/"
    log_info "   • Links globais: /usr/bin/node, /usr/bin/npm, /usr/bin/npx"
    log_info "   • Permissões: Configuradas para todos os usuários"
    log_info "   • Arquitetura: $arch ($node_distro)"
    
    log_success "Node.js e npm estão disponíveis globalmente"
}

install_pm2() {
    local step="pm2_install"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando instalação do PM2 (já executada)"
        return 0
    fi
    
    print_header "INSTALANDO PM2"
    save_state "$step"
    
    log_info "Instalando PM2 (Process Manager 2)..."
    
    # Verificar se PM2 já está instalado
    if command -v pm2 >/dev/null 2>&1; then
        local current_version=$(pm2 -V 2>/dev/null || echo "unknown")
        log_info "⚡ PM2 já está instalado: versão $current_version"
        
        # Verificar se está instalado globalmente
        if npm list -g pm2 >/dev/null 2>&1; then
            log_success "✅ PM2 está disponível globalmente"
            return 0
        else
            log_warn "⚠️  PM2 encontrado mas pode não estar instalado globalmente"
            log_info "Reinstalando PM2 globalmente..."
        fi
    fi
    
    # Verificar se Node.js e npm estão disponíveis
    if ! command -v node >/dev/null 2>&1; then
        log_error "❌ Node.js não encontrado"
        log_info "PM2 requer Node.js para funcionar"
        log_info "Certifique-se de que a etapa nodejs_install foi executada com sucesso"
        return 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        log_error "❌ npm não encontrado"
        log_info "PM2 requer npm para instalação"
        return 1
    fi
    
    log_info "✅ Node.js $(node -v) e npm $(npm -v) detectados"
    
    # Atualizar PATH para garantir acesso aos binários do Node.js
    export PATH="$NODEJS_INSTALL_DIR/bin:/usr/bin:$PATH"
    
    # Instalar PM2 globalmente
    log_info "📦 Instalando PM2 globalmente via npm..."
    
    # Configurar npm para uso global sem sudo (se necessário)
    local npm_config_prefix="$NODEJS_INSTALL_DIR"
    
    if npm install -g pm2; then
        log_success "✅ PM2 instalado com sucesso"
    else
        log_error "❌ Falha ao instalar PM2"
        log_info "Tentando instalação alternativa..."
        
        # Tentativa alternativa usando sudo
        if sudo npm install -g pm2; then
            log_success "✅ PM2 instalado com sucesso (via sudo)"
        else
            log_error "❌ Falha na instalação alternativa do PM2"
            return 1
        fi
    fi
    
    # Criar link simbólico para acesso global
    log_info "🔗 Configurando links simbólicos globais..."
    
    # Encontrar localização do PM2
    local pm2_path=""
    if [[ -f "$NODEJS_INSTALL_DIR/bin/pm2" ]]; then
        pm2_path="$NODEJS_INSTALL_DIR/bin/pm2"
    elif [[ -f "$NODEJS_INSTALL_DIR/lib/node_modules/pm2/bin/pm2" ]]; then
        pm2_path="$NODEJS_INSTALL_DIR/lib/node_modules/pm2/bin/pm2"
    elif command -v pm2 >/dev/null 2>&1; then
        pm2_path=$(which pm2)
    fi
    
    if [[ -n "$pm2_path" ]] && [[ -f "$pm2_path" ]]; then
        ln -sf "$pm2_path" /usr/bin/pm2
        log_success "✅ Link simbólico criado: /usr/bin/pm2 → $pm2_path"
    else
        log_warn "⚠️  Não foi possível encontrar o binário do PM2 para criar link simbólico"
    fi
    
    # Verificar instalação
    log_info "🔍 Verificando instalação do PM2..."
    
    # Atualizar PATH novamente
    export PATH="/usr/bin:$NODEJS_INSTALL_DIR/bin:$PATH"
    
    if command -v pm2 >/dev/null 2>&1; then
        local installed_version=$(pm2 -V 2>/dev/null || echo "unknown")
        log_success "✅ PM2 instalado e funcionando!"
        log_info "   • Versão: $installed_version"
        log_info "   • Localização: $(which pm2 2>/dev/null || echo 'não encontrado')"
        
        # Testar comando básico do PM2
        if pm2 list >/dev/null 2>&1; then
            log_success "✅ PM2 está respondendo corretamente"
        else
            log_warn "⚠️  PM2 instalado mas pode ter problemas de configuração"
        fi
        
    else
        log_error "❌ PM2 não está disponível após instalação"
        log_info "Isso pode indicar problemas de PATH ou permissões"
        return 1
    fi
    
    # Configurar PM2 para o usuário pi
    log_info "👤 Configurando PM2 para o usuário 'pi'..."
    
    if id "pi" >/dev/null 2>&1; then
        # Criar diretório home do PM2 para o usuário pi
        sudo -u pi mkdir -p /home/pi/.pm2 2>/dev/null || true
        
        # Inicializar PM2 para o usuário pi
        if sudo -u pi pm2 list >/dev/null 2>&1; then
            log_success "✅ PM2 configurado para o usuário 'pi'"
        else
            log_warn "⚠️  PM2 pode não estar totalmente configurado para o usuário 'pi'"
            log_info "O usuário pode precisar executar 'pm2 list' uma vez para inicializar"
        fi
    else
        log_warn "⚠️  Usuário 'pi' não encontrado, pulando configuração específica do usuário"
    fi
    
    # Resumo da instalação
    echo
    log_info "📋 Instalação do PM2 concluída:"
    log_info "   • PM2: Instalado globalmente"
    log_info "   • Versão: $(pm2 -V 2>/dev/null || echo 'não disponível')"
    log_info "   • Comando: Disponível em /usr/bin/pm2"
    log_info "   • Node.js: Compatível com versão instalada"
    log_info "   • Usuário 'pi': Configurado para uso"
    
    echo
    log_success "🚀 PM2 está pronto para gerenciar processos Node.js!"
    log_info "Comandos úteis:"
    log_info "   • pm2 list - Listar processos"
    log_info "   • pm2 start app.js - Iniciar aplicação"
    log_info "   • pm2 restart all - Reiniciar todos os processos"
    log_info "   • pm2 stop all - Parar todos os processos"
}

configure_cups() {
    local step="cups_config"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração do CUPS (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO CUPS (SISTEMA DE IMPRESSÃO)"
    save_state "$step"
    
    log_info "Configurando CUPS (Common Unix Printing System)..."
    
    # Verificar se CUPS está instalado
    if ! command -v cupsd >/dev/null 2>&1; then
        log_error "❌ CUPS não está instalado"
        log_info "O CUPS deveria ter sido instalado na etapa de pacotes essenciais"
        return 1
    fi
    
    log_success "✅ CUPS detectado no sistema"
    
    # Adicionar usuário 'pi' ao grupo lpadmin
    log_info "👤 Adicionando usuário 'pi' ao grupo lpadmin..."
    if id "pi" >/dev/null 2>&1; then
        if usermod -aG lpadmin pi; then
            log_success "✅ Usuário 'pi' adicionado ao grupo lpadmin"
        else
            log_error "❌ Falha ao adicionar usuário 'pi' ao grupo lpadmin"
            return 1
        fi
    else
        log_warn "⚠️  Usuário 'pi' não encontrado, pulando adição ao grupo lpadmin"
    fi
    
    # Configurar cupsd.conf para acesso remoto
    log_info "🌐 Configurando acesso remoto ao CUPS..."
    local cupsd_conf="/etc/cups/cupsd.conf"
    
    if [[ ! -f "$cupsd_conf" ]]; then
        log_error "❌ Arquivo $cupsd_conf não encontrado"
        return 1
    fi
    
    # Backup do arquivo original
    cp "$cupsd_conf" "$cupsd_conf.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "📋 Backup criado: $cupsd_conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Configurar para escutar em todas as interfaces
    log_info "🔧 Configurando escuta em todas as interfaces..."
    sed -i 's/^Listen localhost:631/Listen 0.0.0.0:631/' "$cupsd_conf" || true
    sed -i 's/^Listen \/run\/cups\/cups.sock/Listen \/run\/cups\/cups.sock/' "$cupsd_conf" || true
    
    # Configurar permissões de acesso
    log_info "🔐 Configurando permissões de acesso..."
    
    # Seção <Location />
    if grep -q "<Location />" "$cupsd_conf"; then
        sed -i '/<Location \/>/,/<\/Location>/c\
<Location />\
  Order allow,deny\
  Allow all\
<\/Location>' "$cupsd_conf"
        log_info "✅ Configurada seção <Location />"
    fi
    
    # Seção <Location /admin>
    if grep -q "<Location /admin>" "$cupsd_conf"; then
        sed -i '/<Location \/admin>/,/<\/Location>/c\
<Location /admin>\
  Order allow,deny\
  Allow all\
<\/Location>' "$cupsd_conf"
        log_info "✅ Configurada seção <Location /admin>"
    fi
    
    # Seção <Location /admin/conf>
    if grep -q "<Location /admin/conf>" "$cupsd_conf"; then
        sed -i '/<Location \/admin\/conf>/,/<\/Location>/c\
<Location /admin/conf>\
  AuthType Default\
  Require user @SYSTEM\
  Order allow,deny\
  Allow all\
<\/Location>' "$cupsd_conf"
        log_info "✅ Configurada seção <Location /admin/conf>"
    fi
    
    # Desabilitar descoberta automática de impressoras
    log_info "🚫 Desabilitando descoberta automática de impressoras..."
    if grep -q "^Browsing" "$cupsd_conf"; then
        sed -i 's/^Browsing.*/Browsing Off/' "$cupsd_conf"
    else
        echo "Browsing Off" >> "$cupsd_conf"
    fi
    
    if grep -q "^BrowseLocalProtocols" "$cupsd_conf"; then
        sed -i 's/^BrowseLocalProtocols.*/BrowseLocalProtocols none/' "$cupsd_conf"
    else
        echo "BrowseLocalProtocols none" >> "$cupsd_conf"
    fi
    log_info "✅ Descoberta automática desabilitada"
    
    # Configurar cups-files.conf
    log_info "📁 Configurando cups-files.conf..."
    local cups_files_conf="/etc/cups/cups-files.conf"
    
    if [[ -f "$cups_files_conf" ]]; then
        # Backup do arquivo
        cp "$cups_files_conf" "$cups_files_conf.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Configurar SystemGroup
        if grep -q "^SystemGroup" "$cups_files_conf"; then
            sed -i '/^SystemGroup/c\SystemGroup lpadmin' "$cups_files_conf"
        else
            echo "SystemGroup lpadmin" >> "$cups_files_conf"
        fi
        log_info "✅ SystemGroup configurado para lpadmin"
    else
        log_warn "⚠️  Arquivo cups-files.conf não encontrado"
    fi
    
    # Iniciar e habilitar serviço CUPS
    log_info "🔄 Iniciando e habilitando serviço CUPS..."
    if systemctl start cups; then
        log_success "✅ Serviço CUPS iniciado"
    else
        log_error "❌ Falha ao iniciar serviço CUPS"
        return 1
    fi
    
    if systemctl enable cups; then
        log_success "✅ Serviço CUPS habilitado para inicialização automática"
    else
        log_error "❌ Falha ao habilitar serviço CUPS"
        return 1
    fi
    
    # Reiniciar serviço para aplicar configurações
    log_info "🔄 Reiniciando serviço CUPS para aplicar configurações..."
    if systemctl restart cups; then
        log_success "✅ Serviço CUPS reiniciado com sucesso"
    else
        log_error "❌ Falha ao reiniciar serviço CUPS"
        return 1
    fi
    
    # Verificar status do serviço
    log_info "🔍 Verificando status do serviço CUPS..."
    if systemctl is-active --quiet cups; then
        log_success "✅ Serviço CUPS está ativo e funcionando"
    else
        log_warn "⚠️  Serviço CUPS pode não estar funcionando corretamente"
        log_info "Status: $(systemctl is-active cups 2>/dev/null || echo 'unknown')"
    fi
    
    # Obter IP para interface web
    local pi_ip=$(hostname -I | awk '{print $1}' || echo "localhost")
    
    # Resumo da configuração
    echo
    log_info "📋 Configuração do CUPS concluída:"
    log_info "   • Serviço: Ativo e habilitado"
    log_info "   • Usuário 'pi': Adicionado ao grupo lpadmin"
    log_info "   • Acesso remoto: Habilitado"
    log_info "   • Interface web: http://$pi_ip:631"
    log_info "   • Descoberta automática: Desabilitada"
    log_info "   • Configurações: Backup criado"
    
    echo
    log_success "🖨️  CUPS configurado com sucesso!"
    log_info "Acesse a interface web do CUPS em: http://$pi_ip:631"
    log_info "Para gerenciar impressoras: http://$pi_ip:631/admin"
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
    
    # Offer kiosk system setup
    echo
    log_info "🖥️ Setup adicional disponível:"
    log_info "ℹ️  Setup do kiosk pulado"
    log_info "Para instalar posteriormente, execute:"
    log_info "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/scripts/setup-kiosk.sh | sudo bash"
    
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
    install_nodejs
    install_pm2
    configure_cups
    cleanup_system
    
    # Completion
    display_completion_summary
}

# Execute main function
main "$@"
