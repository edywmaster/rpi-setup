#!/bin/bash

# =============================================================================
# Test Script for Interruption Detection and Recovery
# =============================================================================
# Purpose: Simulate interrupted installations and test recovery mechanisms
# Version: 1.0.0
# =============================================================================

set -eo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

readonly STATE_FILE="/var/lib/rpi-preparation-state"
readonly SCRIPT_PATH="../prepare-system.sh"

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

simulate_interruption() {
    local step="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_info "Simulando interrupção na etapa: $step"
    
    # Create state directory if it doesn't exist
    sudo mkdir -p "$(dirname "$STATE_FILE")"
    
    # Create interrupted state
    sudo tee "$STATE_FILE" > /dev/null << EOF
LAST_STEP=$step
TIMESTAMP=$timestamp
PID=99999
STATUS=running
EOF
    
    log_success "Estado de interrupção criado"
}

test_interruption_detection() {
    local step="$1"
    
    print_header "TESTANDO DETECÇÃO DE INTERRUPÇÃO: $step"
    
    # Simulate interruption
    simulate_interruption "$step"
    
    # Show state file content
    log_info "Conteúdo do arquivo de estado:"
    if [[ -f "$STATE_FILE" ]]; then
        sudo cat "$STATE_FILE" | sed 's/^/   /'
    else
        log_error "Arquivo de estado não encontrado"
    fi
    
    echo
    log_info "Agora execute o script principal para ver a detecção de interrupção:"
    log_info "   sudo $SCRIPT_PATH"
    echo
}

cleanup_state() {
    log_info "Limpando estado de teste..."
    sudo rm -f "$STATE_FILE"
    log_success "Estado limpo"
}

show_current_state() {
    print_header "ESTADO ATUAL"
    
    if [[ -f "$STATE_FILE" ]]; then
        log_info "Arquivo de estado encontrado:"
        sudo cat "$STATE_FILE" | sed 's/^/   /'
        echo
        
        # Parse state info
        source <(sudo cat "$STATE_FILE")
        log_info "Detalhes:"
        log_info "   • Última etapa: $LAST_STEP"
        log_info "   • Data/Hora: $TIMESTAMP"
        log_info "   • PID: $PID"
        log_info "   • Status: $STATUS"
    else
        log_info "Nenhum arquivo de estado encontrado"
        log_info "Sistema está limpo para nova instalação"
    fi
}

show_usage() {
    echo "Uso: $0 [OPÇÃO]"
    echo
    echo "Opções:"
    echo "  simulate <step>     Simula interrupção na etapa especificada"
    echo "  status              Mostra estado atual do sistema"
    echo "  cleanup             Remove arquivo de estado"
    echo "  help               Mostra esta ajuda"
    echo
    echo "Etapas disponíveis para simulação:"
    echo "  validation          Validações iniciais"
    echo "  update_lists        Atualização de listas de pacotes"
    echo "  system_upgrade      Upgrade do sistema"
    echo "  locale_config       Configuração de locales"
    echo "  package_install     Instalação de pacotes"
    echo "  cleanup             Limpeza do sistema"
    echo
    echo "Exemplos:"
    echo "  $0 simulate package_install    # Simula interrupção durante instalação"
    echo "  $0 status                      # Verifica estado atual"
    echo "  $0 cleanup                     # Limpa estado para nova instalação"
}

# Main execution
case "${1:-help}" in
    "simulate")
        if [[ -n "$2" ]]; then
            test_interruption_detection "$2"
        else
            log_error "Especifique a etapa para simular interrupção"
            show_usage
            exit 1
        fi
        ;;
    "status")
        show_current_state
        ;;
    "cleanup")
        cleanup_state
        ;;
    "help"|*)
        show_usage
        ;;
esac
