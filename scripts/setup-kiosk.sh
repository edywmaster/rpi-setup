#!/bin/bash

# =============================================================================
# Kiosk System Setup Script
# =============================================================================
# Purpose: Configure Raspberry Pi for kiosk system with touchscreen interface
# Target: Post prepare-system.sh execution
# Version: 1.0.0
# Dependencies: Node.js, PM2, CUPS, fbi, imagemagick
# 
# Usage: 
# - Local: sudo ./setup-kiosk.sh
# - Remote: curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/scripts/setup-kiosk.sh | sudo bash
#
# System Overview:
# - ReactJS application for user interface (touchscreen)
# - Local Node.js print server (port 50001)
# - PDF download and printing via Python scripts
# - Integration with external API for user data and badge printing
# =============================================================================

set -eo pipefail  # Exit on error, pipe failures

# Script configuration
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "${0:-setup-kiosk.sh}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
readonly LOG_FILE="/var/log/kiosk-setup.log"
readonly LOCK_FILE="/tmp/kiosk-setup.lock"
readonly STATE_FILE="/var/lib/kiosk-setup-state"

# Kiosk system structure
readonly KIOSK_BASE_DIR="/opt/kiosk"
readonly KIOSK_SCRIPTS_DIR="$KIOSK_BASE_DIR/scripts"
readonly KIOSK_SERVER_DIR="$KIOSK_BASE_DIR/server"
readonly KIOSK_UTILS_DIR="$KIOSK_BASE_DIR/utils"
readonly KIOSK_TEMPLATES_DIR="$KIOSK_BASE_DIR/templates"

# Source structure for copying files
readonly DIST_KIOSK_DIR="https://raw.githubusercontent.com/edywmaster/rpi-setup/main/dist/kiosk"

# Configuration files
readonly KIOSK_CONFIG_FILE="$KIOSK_BASE_DIR/kiosk.conf"
readonly GLOBAL_ENV_FILE="/etc/environment"

# Splash screen configuration
readonly SPLASH_SERVICE_PATH="/etc/systemd/system/kiosk-splash.service"
readonly SPLASH_IMAGE="$KIOSK_TEMPLATES_DIR/splash.jpg"
readonly SPLASH_VERSION="$KIOSK_TEMPLATES_DIR/splash_version.jpg"

# Kiosk Start service configuration
readonly STARTED_SERVICE_PATH="/etc/systemd/system/kiosk-start.service"
readonly KIOSK_START_SCRIPT="$KIOSK_SCRIPTS_DIR/kiosk.sh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Installation steps for state tracking
readonly INSTALLATION_STEPS=(
    "validation"
    "directory_setup"
    "configuration"
    "splash_setup"
    "startup_service"
    "services_config"
    "kiosk_service"
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
    
    mkdir -p "$(dirname "$STATE_FILE")"
    
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

mark_completion() {
    if [[ -f "$STATE_FILE" ]]; then
        sed -i 's/STATUS="running"/STATUS="completed"/' "$STATE_FILE" 2>/dev/null || true
    fi
}

should_skip_step() {
    local current_step="$1"
    local last_step="$2"
    
    if [[ -z "$last_step" ]]; then
        return 1  # Don't skip, start fresh
    fi
    
    local current_index=0
    local last_index=0
    
    for i in "${!INSTALLATION_STEPS[@]}"; do
        if [[ "${INSTALLATION_STEPS[$i]}" == "$current_step" ]]; then
            current_index=$i
        fi
        if [[ "${INSTALLATION_STEPS[$i]}" == "$last_step" ]]; then
            last_index=$i
        fi
    done
    
    if [[ "$current_index" -le "$last_index" ]]; then
        return 0  # Skip this step
    else
        return 1  # Don't skip
    fi
}

cleanup_on_exit() {
    if [[ -f "$STATE_FILE" ]]; then
        mark_completion
    fi
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

check_dependencies() {
    log_info "Verificando dependências necessárias..."
    
    local missing_deps=()
    
    # Check for essential commands
    local required_commands=("node" "npm" "pm2" "fbi" "convert" "systemctl")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Dependências em falta: ${missing_deps[*]}"
        log_info "Execute primeiro o prepare-system.sh para instalar as dependências"
        exit 1
    fi
    
    log_success "Todas as dependências estão disponíveis"
}

create_lock_file() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Outro processo está em execução (PID: $lock_pid)"
            exit 1
        else
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo "$$" > "$LOCK_FILE"
    trap 'cleanup_on_exit' EXIT
}

# =============================================================================
# CONFIGURATION FUNCTIONS
# =============================================================================

setup_kiosk_directories() {
    local step="directory_setup"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando criação de diretórios (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO ESTRUTURA DE DIRETÓRIOS"
    save_state "$step"
    
    log_info "Criando estrutura de diretórios do sistema kiosk..."
    
    # Create base directory first
    if [[ ! -d "$KIOSK_BASE_DIR" ]]; then
        if mkdir -p "$KIOSK_BASE_DIR"; then
            log_success "✅ Diretório base criado: $KIOSK_BASE_DIR"
        else
            log_error "❌ Falha ao criar diretório base: $KIOSK_BASE_DIR"
            return 1
        fi
    else
        log_info "⚡ Diretório base já existe: $KIOSK_BASE_DIR"
    fi
    
    # Copy structure from dist/kiosk using wget or curl
    log_info "Copiando estrutura e arquivos do repositório..."
    
    # Create directories and copy templates
    local directories=(
        "scripts"
        "server" 
        "utils"
        "templates"
    )
    
    for dir in "${directories[@]}"; do
        local target_dir="$KIOSK_BASE_DIR/$dir"
        
        if [[ ! -d "$target_dir" ]]; then
            if mkdir -p "$target_dir"; then
                log_success "✅ Diretório criado: $target_dir"
            else
                log_error "❌ Falha ao criar diretório: $target_dir"
                return 1
            fi
        else
            log_info "⚡ Diretório já existe: $target_dir"
        fi
    done
    
    # Copy splash.jpg template if it exists in the repo
    log_info "Baixando template splash.jpg..."
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$KIOSK_TEMPLATES_DIR/splash.jpg" \
             "$DIST_KIOSK_DIR/templates/splash.jpg" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar splash.jpg, usando padrão local"
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$KIOSK_TEMPLATES_DIR/splash.jpg" \
             "$DIST_KIOSK_DIR/templates/splash.jpg" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar splash.jpg, usando padrão local"
        }
    else
        log_warn "⚠️  wget ou curl não disponível, splash.jpg será criado localmente"
    fi
    
    # Verify splash.jpg exists or create a default one
    if [[ ! -f "$KIOSK_TEMPLATES_DIR/splash.jpg" ]]; then
        log_info "Criando splash.jpg padrão..."
        # This will be handled later in setup_splash_screen function
    else
        log_success "✅ Template splash.jpg disponível"
    fi

    # Copy splash.jpg template if it exists in the repo
    log_info "Baixando start.sh..."
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$KIOSK_START_SCRIPT/start.sh" \
             "$DIST_KIOSK_DIR/scripts/start.sh" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar start.sh, usando padrão local"
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$KIOSK_START_SCRIPT/start.sh" \
             "$DIST_KIOSK_DIR/scripts/start.sh" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar start.sh, usando padrão local"
        }
    else
        log_warn "⚠️  wget ou curl não disponível, start.sh será criado localmente"
    fi

    # Verify splash.jpg exists or create a default one
    if [[ ! -f "$KIOSK_TEMPLATES_DIR/splash.jpg" ]]; then
        log_info "Criando splash.jpg padrão..."
        # This will be handled later in setup_splash_screen function
    else
        log_success "✅ Template splash.jpg disponível"
    fi

    # Verify start.sh exists or create a default one
    if [[ ! -f "$KIOSK_START_SCRIPT/start.sh" ]]; then
        log_info "Criando start.sh padrão..."
        # This will be handled later in setup_start_script function
    else
        log_success "✅ Template start.sh disponível"
    fi

    # Set proper permissions
    log_info "Configurando permissões dos diretórios..."
    chown -R pi:pi "$KIOSK_BASE_DIR" 2>/dev/null || true
    chmod -R 755 "$KIOSK_BASE_DIR" 2>/dev/null || true
    
    log_success "Estrutura de diretórios configurada com sucesso"
}

configure_kiosk_variables() {
    local step="configuration"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração de variáveis (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO VARIÁVEIS DO SISTEMA"
    save_state "$step"
    
    log_info "Configurando variáveis globais do sistema kiosk..."
    
    # Get prepare-system version for reference
    local prepare_version="1.2.0"  # Latest prepare-system version
    
    # Default configuration values
    local KIOSK_VERSION="$prepare_version"
    local APP_MODE="REDE"  # REDE or WEB
    local APP_URL="http://localhost:3000"
    local APP_API_URL="https://app.ticketbay.com.br/api/v1"
    local PRINT_PORT="50001"
    
    # Create kiosk configuration file
    log_info "Criando arquivo de configuração do kiosk..."
    cat > "$KIOSK_CONFIG_FILE" << EOF
# Kiosk System Configuration
# Generated on $(date)

# System Information
KIOSK_VERSION_CONFIG="$KIOSK_VERSION"
KIOSK_SETUP_DATE="$(date '+%Y-%m-%d %H:%M:%S')"

# Application Configuration
APP_MODE_CONFIG="$APP_MODE"
APP_URL_CONFIG="$APP_URL"
APP_API_URL_CONFIG="$APP_API_URL"
PRINT_PORT_CONFIG="$PRINT_PORT"

# Print Server Configuration
PRINT_SERVER_HOST="localhost"
PRINT_SERVER_PORT="$PRINT_PORT"
PRINT_SERVER_URL="http://localhost:$PRINT_PORT"

# PDF Processing
PDF_DOWNLOAD_DIR="/tmp/kiosk-badges"
PDF_PRINT_SCRIPT="$KIOSK_SCRIPTS_DIR/print-badge.py"

# Hardware Configuration
DISPLAY_DEVICE="/dev/fb0"
TOUCHSCREEN_DEVICE="/dev/input/touchscreen"
EOF
    
    if [[ -f "$KIOSK_CONFIG_FILE" ]]; then
        log_success "✅ Arquivo de configuração criado: $KIOSK_CONFIG_FILE"
    else
        log_error "❌ Falha ao criar arquivo de configuração"
        return 1
    fi
    
    # Add global environment variables
    log_info "Adicionando variáveis ao ambiente global..."
    
    local env_vars=(
        "KIOSK_VERSION=\"$KIOSK_VERSION\""
        "APP_MODE=\"$APP_MODE\""
        "APP_URL=\"$APP_URL\""
        "APP_API_URL=\"$APP_API_URL\""
        "PRINT_PORT=\"$PRINT_PORT\""
        "KIOSK_BASE_DIR=\"$KIOSK_BASE_DIR\""
    )
    
    for var in "${env_vars[@]}"; do
        local var_name=$(echo "$var" | cut -d'=' -f1)
        
        if ! grep -q "^export $var_name=" "$GLOBAL_ENV_FILE" 2>/dev/null; then
            echo "export $var" >> "$GLOBAL_ENV_FILE"
            log_info "✅ Variável adicionada: $var_name"
        else
            log_info "⚡ Variável já existe: $var_name"
        fi
    done
    
    # Set file permissions
    chmod 644 "$KIOSK_CONFIG_FILE"
    chown pi:pi "$KIOSK_CONFIG_FILE"
    
    log_success "Configuração de variáveis concluída"
    
    # Display configuration summary
    echo
    log_info "📋 Configuração do sistema kiosk:"
    log_info "   • Versão: $KIOSK_VERSION"
    log_info "   • Modo: $APP_MODE"
    log_info "   • URL da aplicação: $APP_URL"
    log_info "   • API URL: $APP_API_URL"
    log_info "   • Porta de impressão: $PRINT_PORT"
    log_info "   • Diretório base: $KIOSK_BASE_DIR"
}

setup_splash_screen() {
    local step="splash_setup"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração de splash (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO SPLASH SCREEN"
    save_state "$step"
    
    log_info "Configurando splash screen customizado..."
    
    # Use variables already defined in script (no need to source config file)
    local prepare_version="1.2.0"  # Use same version as configure_kiosk_variables
    
    # Check if base splash image exists (create a simple one if not)
    if [[ ! -f "$SPLASH_IMAGE" ]]; then
        log_info "Criando imagem de splash padrão..."
        
        # Create a simple splash image using convert
        convert -size 1920x1080 xc:black \
                -fill white -gravity center \
                -pointsize 72 -annotate +0-100 "KIOSK SYSTEM" \
                -pointsize 48 -annotate +0+50 "Inicializando..." \
                "$SPLASH_IMAGE" 2>/dev/null || {
            
            # Fallback: create with different resolution if 1920x1080 fails
            convert -size 1024x768 xc:black \
                    -fill white -gravity center \
                    -pointsize 48 -annotate +0-50 "KIOSK SYSTEM" \
                    -pointsize 32 -annotate +0+50 "Inicializando..." \
                    "$SPLASH_IMAGE" 2>/dev/null || {
                
                log_error "❌ Falha ao criar imagem de splash"
                return 1
            }
        }
        
        log_success "✅ Imagem de splash padrão criada"
    fi
    
    # Create versioned splash screen
    log_info "Criando splash screen com versão..."
    if convert "$SPLASH_IMAGE" \
             -gravity south \
             -pointsize 36 \
             -fill white \
             -annotate +0+250 "v$prepare_version" \
             "$SPLASH_VERSION" 2>/dev/null; then
        log_success "✅ Splash screen com versão criado"
    else
        log_warn "⚠️  Falha ao criar splash com versão, usando imagem padrão"
        cp "$SPLASH_IMAGE" "$SPLASH_VERSION" 2>/dev/null || true
    fi
    
    # Determine which splash to use
    local splash_to_use
    if [[ -f "$SPLASH_VERSION" ]]; then
        splash_to_use="$SPLASH_VERSION"
        log_info "✅ Usando splash com versão"
    else
        splash_to_use="$SPLASH_IMAGE"
        log_info "⚡ Usando splash padrão"
    fi
    
    # Create splash service
    log_info "Criando serviço de splash screen..."
    
    if [[ -f "$SPLASH_SERVICE_PATH" ]]; then
        log_info "⚡ Serviço de splash já existe, atualizando..."
        systemctl stop kiosk-splash.service 2>/dev/null || true
        systemctl disable kiosk-splash.service 2>/dev/null || true
    fi
    
    cat > "$SPLASH_SERVICE_PATH" << EOF
[Unit]
Description=Kiosk Splash Screen
DefaultDependencies=no
After=local-fs.target
Before=getty@tty1.service

[Service]
Type=simple
ExecStart=/bin/bash -c '/usr/bin/fbi -T 1 -d /dev/fb0 --noverbose -a $splash_to_use & sleep 8; killall fbi'
ExecStop=/usr/bin/killall fbi
StandardInput=tty
StandardOutput=tty
RemainAfterExit=no

[Install]
WantedBy=sysinit.target
EOF
    
    if [[ -f "$SPLASH_SERVICE_PATH" ]]; then
        log_success "✅ Serviço de splash criado: $SPLASH_SERVICE_PATH"
    else
        log_error "❌ Falha ao criar serviço de splash"
        return 1
    fi
    
    # Enable and start the service
    log_info "Habilitando serviço de splash..."
    
    if systemctl daemon-reload; then
        log_success "✅ Systemd recarregado"
    else
        log_error "❌ Falha ao recarregar systemd"
        return 1
    fi
    
    if systemctl enable kiosk-splash.service; then
        log_success "✅ Serviço de splash habilitado"
    else
        log_error "❌ Falha ao habilitar serviço de splash"
        return 1
    fi
    
    # Test the service (optional, as it affects display)
    log_info "ℹ️  Serviço de splash configurado (será ativo no próximo boot)"
    
    # Set proper permissions
    chmod 644 "$SPLASH_SERVICE_PATH"
    chown pi:pi "$SPLASH_IMAGE" "$SPLASH_VERSION" 2>/dev/null || true
    
    log_success "Configuração do splash screen concluída"
    
    # Display summary
    echo
    log_info "📋 Splash screen configurado:"
    log_info "   • Imagem: $splash_to_use"
    log_info "   • Serviço: kiosk-splash.service"
    log_info "   • Versão exibida: v$prepare_version"
    log_info "   • Dispositivo: /dev/fb0"
}

setup_startup_service() {
    local step="startup_service"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração de serviço de inicialização (já executada)"
        return 0
    fi

    print_header "CONFIGURANDO SERVIÇO DE INICIALIZAÇÃO"
    save_state "$step"

    log_info "Configurando serviço de inicialização..."

    # Create startup service
    log_info "Criando serviço de inicialização..."

    if [[ -f "$STARTED_SERVICE_PATH" ]]; then
        log_info "⚡ Serviço de inicialização já existe, atualizando..."
        systemctl stop kiosk-start.service 2>/dev/null || true
        systemctl disable kiosk-start.service 2>/dev/null || true
    fi

    cat > "$STARTED_SERVICE_PATH" << EOF
[Unit]
Description=Kiosk Start Service
After=systemd-user-sessions.service plymouth-quit-wait.service kiosk-splash.service getty.target
Conflicts=getty@tty1.service

[Service]
ExecStart=/bin/bash /opt/kiosk/scripts/start.sh
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=tty
#StandardError=tty
#Restart=always
#RestartSec=1
User=pi
WorkingDirectory=/opt/kiosk

[Install]
WantedBy=multi-user.target
EOF

    if [[ -f "$STARTED_SERVICE_PATH" ]]; then
        log_success "✅ Serviço de inicialização criado: $STARTED_SERVICE_PATH"
    else
        log_error "❌ Falha ao criar serviço de inicialização"
        return 1
    fi
    
    # Enable and start the service
    log_info "Habilitando serviço de inicialização..."
    
    if systemctl daemon-reload; then
        log_success "✅ Systemd recarregado"
    else
        log_error "❌ Falha ao recarregar systemd"
        return 1
    fi
    
    if systemctl enable kiosk-start.service; then
        log_success "✅ Serviço de inicialização habilitado"
    else
        log_error "❌ Falha ao habilitar serviço de inicialização"
        return 1
    fi
    
    # Test the service (optional, as it affects display)
    log_info "ℹ️  Serviço de inicialização configurado (será ativo no próximo boot)"
    
    # Set proper permissions
    chmod 644 "$STARTED_SERVICE_PATH"
    chown pi:pi "$KIOSK_START_SCRIPT" 2>/dev/null || true

    log_success "Configuração do serviço de inicialização concluída"

    # Display summary
    echo
    log_info "📋 Serviço de inicialização configurado:"
    log_info "   • Serviço: kiosk-start.service"
}

configure_services() {
    local step="services_config"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração de serviços (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO SERVIÇOS DO SISTEMA"
    save_state "$step"
    
    log_info "Configurações básicas de serviços concluídas..."
    
    # Here we would add additional service configurations
    # For now, we just ensure the splash service is properly configured
    
    # Verify splash service status
    if systemctl is-enabled kiosk-splash.service >/dev/null 2>&1; then
        log_success "✅ Serviço de splash está habilitado"
    else
        log_warn "⚠️  Serviço de splash pode não estar habilitado corretamente"
    fi
    
    log_success "Configuração de serviços concluída"
}


display_completion_summary() {
    save_state "completion"
    
    print_header "SETUP DO KIOSK CONCLUÍDO"
    
    log_success "🎉 Setup do sistema kiosk concluído com sucesso!"
    echo
    
    # Use variables already defined in script
    local prepare_version="1.2.0"
    local app_mode="REDE"
    local app_url="http://localhost:3000"
    local app_api_url="https://app.ticketbay.com.br/api/v1"
    local print_port="50001"
    
    log_info "📋 Resumo da instalação:"
    log_info "   • Sistema: Kiosk v$prepare_version"
    log_info "   • Modo: $app_mode"
    log_info "   • URL da aplicação: $app_url"
    log_info "   • API URL: $app_api_url"
    log_info "   • Porta de impressão: $print_port"
    
    echo
    log_info "📁 Estrutura criada:"
    log_info "   • Base: $KIOSK_BASE_DIR"
    log_info "   • Scripts: $KIOSK_SCRIPTS_DIR"
    log_info "   • Servidor: $KIOSK_SERVER_DIR"
    log_info "   • Utilitários: $KIOSK_UTILS_DIR"
    log_info "   • Templates: $KIOSK_TEMPLATES_DIR"
    
    echo
    log_info "🖼️ Splash screen:"
    log_info "   • Serviço: kiosk-splash.service (habilitado)"
    log_info "   • Imagem: $SPLASH_VERSION"
    log_info "   • Versão exibida: v$prepare_version"
    
    echo
    log_info "🚀 Serviço Kiosk Start:"
    log_info "   • Serviço: kiosk-start.service"
    log_info "   • Script: $KIOSK_START_SCRIPT"
    log_info "   • Log: /var/log/kiosk-start.log"
    log_info "   • Status: $(systemctl is-active kiosk-start.service 2>/dev/null || echo 'inativo')"
    
    echo
    log_info "📄 Arquivos importantes:"
    log_info "   • Configuração: $KIOSK_CONFIG_FILE"
    log_info "   • Log de instalação: $LOG_FILE"
    log_info "   • Variáveis globais: $GLOBAL_ENV_FILE"
    
    echo
    log_info "🔄 Próximos passos:"
    log_info "   1. Instalar aplicação ReactJS no diretório apropriado"
    log_info "   2. Configurar servidor de impressão Node.js"
    log_info "   3. Configurar scripts Python para impressão"
    log_info "   4. Testar integração com touchscreen"
    log_info "   5. Configurar aplicação para iniciar automaticamente"
    
    # Check if reboot is recommended
    echo
    log_info "💡 Recomendação:"
    log_info "   • Reinicie o sistema para ativar o splash screen"
    log_info "   • Execute: sudo reboot"
    
    mark_completion
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "KIOSK SYSTEM SETUP v$SCRIPT_VERSION"
    
    log_info "🚀 Iniciando setup do sistema kiosk..."
    log_info "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "🕒 Executado em: $(date)"
    
    # Validations
    check_root_privileges
    check_dependencies
    create_lock_file
    
    # Setup process
    setup_kiosk_directories
    configure_kiosk_variables
    setup_splash_screen
    setup_startup_service
    configure_services
    
    # Completion
    display_completion_summary
}

# Execute main function
main "$@"
