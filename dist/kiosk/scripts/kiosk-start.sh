#!/bin/bash

# =============================================================================
# Kiosk Start Script Template
# =============================================================================
# Purpose: Initialize kiosk system and display status
# This script runs when the kiosk-start service starts
# =============================================================================

# Configuration
readonly LOG_FILE="/var/log/kiosk-start.log"
readonly KIOSK_CONFIG="/opt/kiosk/kiosk.conf"

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo -e "${CYAN}[KIOSK-START]${NC} $message"
}

main() {
    log_message "🚀 Kiosk System Starting..."
    
    # Load configuration if available
    if [[ -f "$KIOSK_CONFIG" ]]; then
        source "$KIOSK_CONFIG"
        log_message "✅ Configuração carregada: $KIOSK_CONFIG"
    else
        log_message "⚠️  Arquivo de configuração não encontrado"
    fi
    
    # Display system information
    log_message "📋 Informações do sistema:"
    log_message "   • Hostname: $(hostname)"
    log_message "   • Data/Hora: $(date)"
    log_message "   • Uptime: $(uptime -p 2>/dev/null || echo 'N/A')"
    
    # Display kiosk information
    if [[ -n "${KIOSK_VERSION_CONFIG:-}" ]]; then
        log_message "   • Versão Kiosk: ${KIOSK_VERSION_CONFIG}"
    fi
    
    if [[ -n "${APP_MODE_CONFIG:-}" ]]; then
        log_message "   • Modo da aplicação: ${APP_MODE_CONFIG}"
    fi
    
    if [[ -n "${PRINT_PORT_CONFIG:-}" ]]; then
        log_message "   • Porta de impressão: ${PRINT_PORT_CONFIG}"
    fi
    
    # Hello World messages for local and remote display
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN} HELLO WORLD - KIOSK SYSTEM STARTED!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo -e "${BLUE}Sistema Kiosk iniciado com sucesso!${NC}"
    echo -e "${BLUE}Data/Hora: $(date)${NC}"
    echo -e "${BLUE}Hostname: $(hostname)${NC}"
    echo
    
    # Log Hello World message
    log_message "🌍 Hello World! Kiosk system is running successfully!"
    log_message "✅ Serviço Kiosk Start inicializado com sucesso"
    
    # Keep service running (for demonstration)
    log_message "🔄 Serviço mantendo execução contínua..."
    
    # Simple loop to keep service alive and display periodic status
    local counter=0
    while true; do
        sleep 30
        counter=$((counter + 1))
        
        if [[ $((counter % 10)) -eq 0 ]]; then  # Every 5 minutes (10 * 30 seconds)
            log_message "💓 Kiosk system heartbeat - $(date)"
            echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} Kiosk system running - Hello World!"
        fi
    done
}

# Execute main function
main "$@"
