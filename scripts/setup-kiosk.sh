#!/bin/bash

# =============================================================================
# Kiosk System Setup Script
# =============================================================================
# Purpose: Configure Raspberry Pi for kiosk system with touchscreen interface
# Target: Post prepare-system.sh execution
# Version: 1.4.3
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
readonly SCRIPT_VERSION="1.4.3"
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
readonly KIOSK_TEMP_DIR="$KIOSK_BASE_DIR/tmp"

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
    "print_server"
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
        wget -q -O "$KIOSK_SCRIPTS_DIR/start.sh" \
             "$DIST_KIOSK_DIR/scripts/start.sh" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar start.sh, usando padrão local"
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$KIOSK_SCRIPTS_DIR/start.sh" \
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
    if [[ ! -f "$KIOSK_SCRIPTS_DIR/start.sh" ]]; then
        log_info "Criando start.sh padrão..."
        # This will be handled later in setup_start_script function
    else
        log_success "✅ Template start.sh disponível"
    fi

    # Download system-info.sh utility
    log_info "Baixando utilitário system-info.sh..."
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$KIOSK_UTILS_DIR/system-info.sh" \
             "$DIST_KIOSK_DIR/utils/system-info.sh" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar system-info.sh"
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$KIOSK_UTILS_DIR/system-info.sh" \
             "$DIST_KIOSK_DIR/utils/system-info.sh" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar system-info.sh"
        }
    else
        log_warn "⚠️  wget ou curl não disponível, system-info.sh não será instalado"
    fi

    # Verify and set permissions for system-info.sh
    if [[ -f "$KIOSK_UTILS_DIR/system-info.sh" ]]; then
        chmod +x "$KIOSK_UTILS_DIR/system-info.sh"
        log_success "✅ Utilitário system-info.sh disponível"
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
    local prepare_version="1.4.3"  # Latest prepare-system version
    
    # Default configuration values
    local KIOSK_VERSION="$prepare_version"
    local KIOSK_APP_MODE="REDE"  # REDE or WEB
    local KIOSK_APP_URL="http://localhost:3000"
    local KIOSK_APP_API="https://app.ticketbay.com.br/api/v1"
    local KIOSK_PRINT_HOST="localhost"
    local KIOSK_PRINT_PORT="50001"

    # Create kiosk configuration file
    log_info "Criando arquivo de configuração do kiosk..."
    cat > "$KIOSK_CONFIG_FILE" << EOF
# Kiosk System Configuration
# Generated on $(date)

# System Information
KIOSK_VERSION="$KIOSK_VERSION"
KIOSK_SETUP_DATE="$(date '+%Y-%m-%d %H:%M:%S')"

# Application Configuration
KIOSK_APP_MODE="$KIOSK_APP_MODE"
KIOSK_APP_URL="$KIOSK_APP_URL"
KIOSK_APP_API="$KIOSK_APP_API"


# Print Server Configuration
KIOSK_PRINT_PORT="$KIOSK_PRINT_PORT"
KIOSK_PRINT_URL="http://$KIOSK_PRINT_HOST:$KIOSK_PRINT_PORT"
KIOSK_PRINT_SERVER="$KIOSK_PRINT_SERVER/print.js"
KIOSK_PRINT_SCRIPT="$KIOSK_PRINT_SCRIPT/print.py"
KIOSK_PRINT_TEMP="$KIOSK_TEMP_DIR"

# Directories
KIOSK_BASE_DIR="$KIOSK_BASE_DIR"
KIOSK_SCRIPTS_DIR="$KIOSK_SCRIPTS_DIR"
KIOSK_SERVER_DIR="$KIOSK_SERVER_DIR"
KIOSK_UTILS_DIR="$KIOSK_UTILS_DIR"
KIOSK_TEMPLATES_DIR="$KIOSK_TEMPLATES_DIR"
KIOSK_TEMP_DIR="$KIOSK_TEMP_DIR"
EOF
    
    if [[ -f "$KIOSK_CONFIG_FILE" ]]; then
        log_success "✅ Arquivo de configuração criado: $KIOSK_CONFIG_FILE"
    else
        log_error "❌ Falha ao criar arquivo de configuração"
        return 1
    fi
    
    # Add global environment variables (always update existing ones)
    log_info "Atualizando variáveis do ambiente global..."
    
    local env_vars=(
        "KIOSK_VERSION=\"$KIOSK_VERSION\""
        "KIOSK_APP_MODE=\"$KIOSK_APP_MODE\""
        "KIOSK_APP_URL=\"$KIOSK_APP_URL\""
        "KIOSK_APP_API=\"$KIOSK_APP_API\""
        "KIOSK_PRINT_PORT=\"$KIOSK_PRINT_PORT\""
        "KIOSK_PRINT_HOST=\"$KIOSK_PRINT_HOST\""
        "KIOSK_PRINT_URL=\"http://$KIOSK_PRINT_HOST:$KIOSK_PRINT_PORT\""
        "KIOSK_PRINT_SERVER=\"$KIOSK_SERVER_DIR/print.js\""
        "KIOSK_PRINT_SCRIPT=\"$KIOSK_UTILS_DIR/print.py\""
        "KIOSK_PRINT_TEMP=\"$KIOSK_TEMP_DIR\""
        "KIOSK_SCRIPTS_DIR=\"$KIOSK_SCRIPTS_DIR\""
        "KIOSK_SERVER_DIR=\"$KIOSK_SERVER_DIR\""
        "KIOSK_UTILS_DIR=\"$KIOSK_UTILS_DIR\""
        "KIOSK_TEMPLATES_DIR=\"$KIOSK_TEMPLATES_DIR\""
    )
    
    # Remove existing variables first to ensure updates
    for var in "${env_vars[@]}"; do
        local var_name=$(echo "$var" | cut -d'=' -f1)
        
        # Remove existing variable if it exists
        if grep -q "^export $var_name=" "$GLOBAL_ENV_FILE" 2>/dev/null; then
            sed -i "/^export $var_name=/d" "$GLOBAL_ENV_FILE" 2>/dev/null || true
            log_info "🔄 Variável existente removida: $var_name"
        fi
        
        # Add the variable (always)
        echo "export $var" >> "$GLOBAL_ENV_FILE"
        log_info "✅ Variável atualizada: $var_name"
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

setup_print_server() {
    local step="print_server"
    local last_step=$(get_last_state)
    
    if should_skip_step "$step" "$last_step"; then
        log_info "⏭️  Pulando configuração do servidor de impressão (já executada)"
        return 0
    fi
    
    print_header "CONFIGURANDO SERVIDOR DE IMPRESSÃO NODE.JS"
    save_state "$step"
    
    log_info "Configurando servidor de impressão Node.js..."
    
    # Create print server directory structure
    mkdir -p "$KIOSK_TEMP_DIR"
    
    # Download print.js from repository
    log_info "Baixando servidor de impressão (print.js)..."
    local print_js_url="$DIST_KIOSK_DIR/server/print.js"
    local print_js_path="$KIOSK_SERVER_DIR/print.js"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$print_js_path" "$print_js_url" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar print.js do repositório, criando versão local"
            create_local_print_server
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$print_js_path" "$print_js_url" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar print.js do repositório, criando versão local"
            create_local_print_server
        }
    else
        log_warn "⚠️  wget ou curl não disponível, criando versão local do print.js"
        create_local_print_server
    fi
    
    # Download printer.py script
    log_info "Baixando script de impressão Python (printer.py)..."
    local printer_py_url="$DIST_KIOSK_DIR/utils/printer.py"
    local printer_py_path="$KIOSK_UTILS_DIR/printer.py"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$printer_py_path" "$printer_py_url" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar printer.py do repositório, criando versão local"
            create_local_printer_script
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$printer_py_path" "$printer_py_url" 2>/dev/null || {
            log_warn "⚠️  Não foi possível baixar printer.py do repositório, criando versão local"
            create_local_printer_script
        }
    else
        log_warn "⚠️  wget ou curl não disponível, criando versão local do printer.py"
        create_local_printer_script
    fi
    
    # Create package.json for the print server
    log_info "Criando package.json para o servidor de impressão..."
    create_print_server_package_json
    
    # Install Node.js dependencies
    log_info "Instalando dependências do servidor de impressão..."
    install_print_server_dependencies
    
    # Create print server service
    log_info "Criando serviço systemd para o servidor de impressão..."
    create_print_server_service
    
    # Set proper permissions
    log_info "Configurando permissões dos arquivos..."
    chmod +x "$printer_py_path" 2>/dev/null || true
    chmod +x "$print_js_path" 2>/dev/null || true
    chown -R pi:pi "$KIOSK_SERVER_DIR" "$KIOSK_UTILS_DIR" "$KIOSK_TEMP_DIR" 2>/dev/null || true
    
    log_success "✅ Servidor de impressão configurado com sucesso"
    
    # Display summary
    echo
    log_info "📋 Servidor de impressão configurado:"
    log_info "   • Arquivo principal: $print_js_path"
    log_info "   • Script Python: $printer_py_path"
    log_info "   • Porta: $KIOSK_PRINT_PORT"
    log_info "   • Serviço: kiosk-print-server.service"
    log_info "   • URL local: http://localhost:$KIOSK_PRINT_PORT"
}

create_local_print_server() {
    log_info "Criando servidor de impressão local..."
    
    cat > "$KIOSK_SERVER_DIR/print.js" << 'EOF'
const express = require("express")
const dotenv = require("dotenv")
const fs = require("fs")
const path = require("path")
const winston = require("winston")
const axios = require("axios")
const { exec } = require("child_process")
const cors = require("cors")

const app = express()

// Load environment variables
const devMode = process.env.NODE_ENV === "development"
const envFile = devMode ? ".env.local" : ".env"
dotenv.config({ path: envFile })

const PORT = process.env.KIOSK_PRINT_PORT || process.env.PORT || 50001
const API_URL = process.env.KIOSK_APP_API || process.env.API_URL

// Configure logging
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: '/var/log/kiosk-print-server.log' }),
        new winston.transports.Console()
    ]
});

// Função para executar o script Python
function printPDF(filePath) {
    return new Promise((resolve, reject) => {
        const pythonScript = path.resolve(__dirname, "../utils/printer.py")
        const command = `python3 ${pythonScript} "${filePath}"`
        
        logger.info(`Executando comando de impressão: ${command}`)
        
        exec(command, (error, stdout, stderr) => {
            if (error) {
                logger.error(`Erro ao imprimir: ${error.message}`)
                return reject(new Error("Erro ao imprimir o arquivo PDF."))
            }
            if (stderr) {
                logger.error(`Stderr da impressão: ${stderr}`)
                return reject(new Error(stderr))
            }
            
            logger.info(`Impressão concluída: ${stdout}`)
            resolve(stdout)
        })
    })
}

// Função para baixar um arquivo PDF
async function downloadPDF(url, outputPath) {
    try {
        logger.info(`Baixando PDF de: ${url}`)
        
        const response = await axios({ 
            method: "GET", 
            url, 
            responseType: "stream",
            timeout: 30000 // 30 seconds timeout
        })
        
        const fileDir = path.dirname(outputPath)
        if (!fs.existsSync(fileDir)) {
            fs.mkdirSync(fileDir, { recursive: true })
        }
        
        const writer = fs.createWriteStream(outputPath)
        response.data.pipe(writer)
        
        return new Promise((resolve, reject) => {
            writer.on("finish", () => {
                logger.info(`PDF baixado com sucesso: ${outputPath}`)
                resolve()
            })
            writer.on("error", (error) => {
                logger.error(`Erro ao salvar PDF: ${error.message}`)
                reject(error)
            })
        })
    } catch (error) {
        logger.error(`Erro ao baixar PDF: ${error.message}`)
        throw new Error("Erro ao baixar o PDF.")
    }
}

// Middleware
app.use(cors({
    origin: "*",
    methods: ["GET", "POST"],
    allowedHeaders: ["Content-Type", "Authorization"]
}))

app.use(express.json())

// Health check endpoint
app.get("/health", (req, res) => {
    res.json({ 
        status: "ok", 
        service: "kiosk-print-server",
        version: "1.0.0",
        timestamp: new Date().toISOString()
    })
})

// Rota para baixar e imprimir um arquivo PDF
app.get("/badge/:id", async (req, res, next) => {
    const ID = parseInt(req.params.id, 10)
    
    logger.info(`Requisição de impressão recebida para ID: ${ID}`)
    
    if (isNaN(ID) || ID <= 0) {
        logger.warn(`ID inválido recebido: ${req.params.id}`)
        return res.status(400).json({ status: "error", message: "ID inválido." })
    }
    
    const filename = `badge_${ID}_${Date.now()}.pdf`
    const filePath = path.join(__dirname, "../tmp", filename)
    const fileApiUrl = `${API_URL}/app/totem/badge/${ID}`
    
    try {
        await downloadPDF(fileApiUrl, filePath)
        await printPDF(filePath)
        
        // Clean up downloaded file after printing
        setTimeout(() => {
            fs.unlink(filePath, (err) => {
                if (err) logger.warn(`Erro ao remover arquivo: ${err.message}`)
                else logger.info(`Arquivo temporário removido: ${filePath}`)
            })
        }, 5000) // Remove after 5 seconds
        
        logger.info(`Impressão concluída com sucesso para ID: ${ID}`)
        res.json({ 
            status: "success", 
            message: "Badge impresso com sucesso.", 
            id: ID,
            file: filename,
            timestamp: new Date().toISOString()
        })
    } catch (error) {
        logger.error(`Erro na impressão para ID ${ID}: ${error.message}`)
        next(error)
    }
})

// Rota para listar arquivos na fila de impressão
app.get("/queue", (req, res) => {
    const filesDir = path.join(__dirname, "../tmp")
    
    if (!fs.existsSync(filesDir)) {
        return res.json({ queue: [], count: 0 })
    }
    
    fs.readdir(filesDir, (err, files) => {
        if (err) {
            logger.error(`Erro ao listar fila: ${err.message}`)
            return res.status(500).json({ status: "error", message: "Erro ao acessar fila de impressão" })
        }
        
        const pdfFiles = files.filter(file => file.endsWith('.pdf'))
        res.json({ queue: pdfFiles, count: pdfFiles.length })
    })
})

// Error handler
app.use((err, req, res, next) => {
    logger.error(`Erro interno: ${err.message}`)
    res.status(500).json({ 
        status: "error", 
        message: "Erro interno no servidor.",
        timestamp: new Date().toISOString()
    })
})

// Start server
app.listen(PORT, "0.0.0.0", () => {
    logger.info(`Servidor de impressão rodando${devMode ? " (DEV MODE)" : ""} em http://0.0.0.0:${PORT}`)
    logger.info(`API URL configurada: ${API_URL}`)
})

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('Servidor de impressão sendo finalizado...')
    process.exit(0)
})

process.on('SIGINT', () => {
    logger.info('Servidor de impressão interrompido pelo usuário')
    process.exit(0)
})
EOF
    
    log_success "✅ Arquivo print.js local criado"
}

create_local_printer_script() {
    log_info "Criando script de impressão Python local..."
    
    cat > "$KIOSK_UTILS_DIR/printer.py" << 'EOF'
#!/usr/bin/env python3
"""
Kiosk Print System - Python Printer Script
Handles PDF printing via CUPS on Raspberry Pi
"""

import sys
import os
import subprocess
import logging
from pathlib import Path
import argparse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/kiosk-printer.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

def get_default_printer():
    """Get the default printer from CUPS"""
    try:
        result = subprocess.run(['lpstat', '-d'], capture_output=True, text=True, check=True)
        output = result.stdout.strip()
        
        if 'no system default destination' in output.lower():
            logger.warning("Nenhuma impressora padrão configurada")
            return None
            
        # Extract printer name from "system default destination: printer_name"
        if ':' in output:
            printer_name = output.split(':')[-1].strip()
            logger.info(f"Impressora padrão encontrada: {printer_name}")
            return printer_name
    except subprocess.CalledProcessError as e:
        logger.error(f"Erro ao obter impressora padrão: {e}")
        return None
    
    return None

def list_available_printers():
    """List all available printers"""
    try:
        result = subprocess.run(['lpstat', '-p'], capture_output=True, text=True, check=True)
        printers = []
        
        for line in result.stdout.split('\n'):
            if line.startswith('printer '):
                printer_name = line.split()[1]
                printers.append(printer_name)
        
        logger.info(f"Impressoras disponíveis: {printers}")
        return printers
    except subprocess.CalledProcessError as e:
        logger.error(f"Erro ao listar impressoras: {e}")
        return []

def print_pdf(file_path, printer_name=None, copies=1):
    """Print PDF file using CUPS lp command"""
    
    # Validate file exists
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Arquivo não encontrado: {file_path}")
    
    # Validate file is PDF
    if not file_path.lower().endswith('.pdf'):
        raise ValueError("Apenas arquivos PDF são suportados")
    
    logger.info(f"Iniciando impressão: {file_path}")
    
    # Get printer to use
    if not printer_name:
        printer_name = get_default_printer()
        
        if not printer_name:
            # Try to get first available printer
            available_printers = list_available_printers()
            if available_printers:
                printer_name = available_printers[0]
                logger.info(f"Usando primeira impressora disponível: {printer_name}")
            else:
                raise RuntimeError("Nenhuma impressora configurada no sistema")
    
    # Build lp command
    cmd = ['lp']
    
    if printer_name:
        cmd.extend(['-d', printer_name])
    
    if copies > 1:
        cmd.extend(['-n', str(copies)])
    
    # Add print options for better PDF handling
    cmd.extend([
        '-o', 'fit-to-page',           # Scale to fit page
        '-o', 'sides=one-sided',       # Single-sided printing
        '-o', 'media=A4',              # Paper size
        '-o', 'orientation-requested=3' # Portrait orientation
    ])
    
    cmd.append(file_path)
    
    try:
        logger.info(f"Executando comando: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        # lp returns job ID on success
        job_info = result.stdout.strip()
        logger.info(f"Impressão enviada com sucesso: {job_info}")
        
        return {
            'status': 'success',
            'job_info': job_info,
            'printer': printer_name,
            'file': file_path,
            'copies': copies
        }
        
    except subprocess.CalledProcessError as e:
        error_msg = f"Erro na impressão: {e.stderr.strip() if e.stderr else str(e)}"
        logger.error(error_msg)
        raise RuntimeError(error_msg)

def check_printer_status(printer_name=None):
    """Check printer status"""
    try:
        if printer_name:
            cmd = ['lpstat', '-p', printer_name]
        else:
            cmd = ['lpstat', '-p']
            
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        status_info = result.stdout.strip()
        logger.info(f"Status da impressora: {status_info}")
        
        return status_info
        
    except subprocess.CalledProcessError as e:
        logger.error(f"Erro ao verificar status: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description='Kiosk Print System - PDF Printer')
    parser.add_argument('file_path', help='Caminho para o arquivo PDF')
    parser.add_argument('-p', '--printer', help='Nome da impressora (opcional)')
    parser.add_argument('-c', '--copies', type=int, default=1, help='Número de cópias')
    parser.add_argument('-s', '--status', action='store_true', help='Verificar status da impressora')
    parser.add_argument('-l', '--list', action='store_true', help='Listar impressoras disponíveis')
    
    args = parser.parse_args()
    
    try:
        if args.list:
            printers = list_available_printers()
            if printers:
                print("Impressoras disponíveis:")
                for printer in printers:
                    print(f"  - {printer}")
            else:
                print("Nenhuma impressora encontrada")
            return 0
        
        if args.status:
            status = check_printer_status(args.printer)
            if status:
                print(status)
            return 0
        
        # Print the PDF
        result = print_pdf(args.file_path, args.printer, args.copies)
        
        print(f"✅ Impressão concluída:")
        print(f"   Arquivo: {result['file']}")
        print(f"   Impressora: {result['printer']}")
        print(f"   Cópias: {result['copies']}")
        print(f"   Job: {result['job_info']}")
        
        return 0
        
    except Exception as e:
        logger.error(f"Erro: {e}")
        print(f"❌ Erro: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
EOF
    
    log_success "✅ Arquivo printer.py local criado"
}

create_print_server_package_json() {
    log_info "Criando package.json..."
    
    cat > "$KIOSK_SERVER_DIR/package.json" << 'EOF'
{
  "name": "kiosk-print-server",
  "version": "1.0.0",
  "description": "Servidor de impressão para sistema kiosk Raspberry Pi",
  "main": "print.js",
  "scripts": {
    "start": "node print.js",
    "dev": "NODE_ENV=development node print.js",
    "test": "echo \"No tests specified\" && exit 0"
  },
  "keywords": [
    "kiosk",
    "print",
    "raspberry-pi",
    "pdf",
    "cups"
  ],
  "author": "Kiosk System",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "axios": "^1.6.0",
    "dotenv": "^16.3.1",
    "winston": "^3.11.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
    
    log_success "✅ package.json criado"
}

install_print_server_dependencies() {
    log_info "Instalando dependências do Node.js..."
    
    cd "$KIOSK_SERVER_DIR"
    
    # Install dependencies using npm
    if npm install --production --silent; then
        log_success "✅ Dependências instaladas com sucesso"
    else
        log_error "❌ Falha ao instalar dependências"
        return 1
    fi
    
    # Create .env file if it doesn't exist
    if [[ ! -f "$KIOSK_SERVER_DIR/.env" ]]; then
        log_info "Criando arquivo .env..."
        cat > "$KIOSK_SERVER_DIR/.env" << EOF
# Kiosk Print Server Configuration
NODE_ENV=production
KIOSK_PRINT_PORT=50001
KIOSK_APP_API=https://app.ticketbay.com.br/api/v1
EOF
        log_success "✅ Arquivo .env criado"
    fi
}

create_print_server_service() {
    log_info "Criando serviço systemd para o servidor de impressão..."
    
    cat > "/etc/systemd/system/kiosk-print-server.service" << EOF
[Unit]
Description=Kiosk Print Server
Documentation=https://github.com/edywmaster/rpi-setup
After=network.target cups.service
Wants=cups.service

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=$KIOSK_SERVER_DIR
ExecStart=/usr/bin/node print.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=kiosk-print-server

# Environment variables
Environment=NODE_ENV=production
Environment=KIOSK_PRINT_PORT=50001
Environment=KIOSK_APP_API=https://app.ticketbay.com.br/api/v1

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$KIOSK_SERVER_DIR $KIOSK_TEMP_DIR /var/log

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    if systemctl daemon-reload; then
        log_success "✅ Systemd recarregado"
    else
        log_error "❌ Falha ao recarregar systemd"
        return 1
    fi
    
    if systemctl enable kiosk-print-server.service; then
        log_success "✅ Serviço kiosk-print-server habilitado"
    else
        log_error "❌ Falha ao habilitar serviço"
        return 1
    fi
    
    # Start the service
    if systemctl start kiosk-print-server.service; then
        log_success "✅ Serviço kiosk-print-server iniciado"
    else
        log_warn "⚠️  Falha ao iniciar serviço (será iniciado no próximo boot)"
    fi
    
    log_success "✅ Serviço systemd configurado"
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
    local prepare_version="1.4.3"  # Latest prepare-system version
    
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
    local prepare_version="1.4.3"  # Latest prepare-system version
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
    log_info "�️ Servidor de Impressão:"
    log_info "   • Serviço: kiosk-print-server.service"
    log_info "   • Porta: $print_port"
    log_info "   • URL: http://localhost:$print_port"
    log_info "   • Status: $(systemctl is-active kiosk-print-server.service 2>/dev/null || echo 'inativo')"
    log_info "   • Health check: http://localhost:$print_port/health"
    log_info "   • Print endpoint: http://localhost:$print_port/badge/{id}"
    log_info "   • Script Python: $KIOSK_UTILS_DIR/printer.py"
    
    echo
    log_info "📄 Arquivos importantes:"
    log_info "   • Configuração: $KIOSK_CONFIG_FILE"
    log_info "   • Log de instalação: $LOG_FILE"
    log_info "   • Variáveis globais: $GLOBAL_ENV_FILE"
    log_info "   • Log do servidor: /var/log/kiosk-print-server.log"
    log_info "   • Log do printer: /var/log/kiosk-printer.log"
    log_info "   • Utilitário de info: $KIOSK_UTILS_DIR/system-info.sh"
    
    echo
    log_info "🔧 Utilitários disponíveis:"
    log_info "   • Informações do sistema: $KIOSK_UTILS_DIR/system-info.sh"
    log_info "   • Para verificar status: sudo $KIOSK_UTILS_DIR/system-info.sh"
    
    echo
    log_info "🔄 Próximos passos:"
    log_info "   1. Instalar aplicação ReactJS no diretório apropriado"
    log_info "   2. Configurar impressoras no CUPS (http://$(hostname -I | awk '{print $1}'):631)"
    log_info "   3. Testar servidor de impressão: curl http://localhost:$print_port/health"
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
    setup_print_server
    setup_splash_screen
    setup_startup_service
    configure_services
    
    # Completion
    display_completion_summary
}

# Execute main function
main "$@"
