#!/bin/bash

# =============================================================================
# Demo: Kiosk Start Service Remote Hello World
# =============================================================================
# Purpose: Demonstrate kiosk-start service Hello World output remotely
# Usage: ./demo-kiosk-hello.sh [IP_ADDRESS]
# =============================================================================

set -eo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "${0}")"
readonly DEFAULT_PI_USER="pi"

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

usage() {
    echo "Uso: $SCRIPT_NAME [IP_ADDRESS]"
    echo
    echo "Demonstra a saída 'Hello World!' do serviço kiosk-start remotamente."
    echo
    echo "Parâmetros:"
    echo "  IP_ADDRESS    IP do Raspberry Pi (opcional, padrão: localhost)"
    echo
    echo "Exemplos:"
    echo "  $SCRIPT_NAME                    # Execução local"
    echo "  $SCRIPT_NAME 192.168.1.100     # Execução remota"
    echo
    echo "Requisitos:"
    echo "  - Raspberry Pi deve ter o serviço kiosk-start configurado"
    echo "  - SSH habilitado (para execução remota)"
    echo "  - Usuário 'pi' com acesso sudo"
}

test_local() {
    print_header "TESTE LOCAL - HELLO WORLD"
    
    log_info "Verificando serviço kiosk-start localmente..."
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "kiosk-start.service"; then
        echo "❌ Serviço kiosk-start não encontrado"
        echo "💡 Execute primeiro: sudo ./scripts/setup-kiosk.sh"
        return 1
    fi
    
    # Check service status
    if systemctl is-active kiosk-start.service >/dev/null 2>&1; then
        log_success "Serviço está ativo"
    else
        echo "⚠️  Serviço não está ativo, tentando iniciar..."
        sudo systemctl start kiosk-start.service
        sleep 2
    fi
    
    # Show recent Hello World output
    log_info "Últimas mensagens 'Hello World':"
    echo
    journalctl -u kiosk-start.service --since "2 minutes ago" --no-pager | grep -i "hello\|started\|kiosk" | tail -5 || {
        echo "ℹ️  Nenhuma saída recente encontrada"
        echo "💡 Reiniciando serviço para gerar nova saída..."
        sudo systemctl restart kiosk-start.service
        sleep 3
        journalctl -u kiosk-start.service --since "30 seconds ago" --no-pager | grep -i "hello\|started\|kiosk" | tail -5
    }
    
    echo
    log_info "Status do serviço:"
    systemctl status kiosk-start.service --no-pager -l | head -10
    
    echo
    log_success "Teste local concluído!"
    log_info "💡 Para ver logs em tempo real: sudo journalctl -u kiosk-start.service -f"
}

test_remote() {
    local ip_address="$1"
    
    print_header "TESTE REMOTO - HELLO WORLD"
    log_info "Conectando ao Raspberry Pi: $ip_address"
    
    # Test SSH connectivity
    log_info "Testando conectividade SSH..."
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$DEFAULT_PI_USER@$ip_address" exit 2>/dev/null; then
        echo "❌ Não foi possível conectar via SSH para $ip_address"
        echo "💡 Verifique se:"
        echo "   - O IP está correto"
        echo "   - SSH está habilitado no Pi"
        echo "   - Chaves SSH estão configuradas ou use: ssh-copy-id pi@$ip_address"
        return 1
    fi
    
    log_success "Conectividade SSH OK"
    
    # Remote Hello World test
    log_info "Executando teste remoto..."
    
    ssh "$DEFAULT_PI_USER@$ip_address" << 'EOF'
# Colors for remote output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

echo -e "${BLUE}🔍 Verificando serviço kiosk-start remotamente...${NC}"

# Check if service exists
if ! systemctl list-unit-files | grep -q "kiosk-start.service"; then
    echo -e "${YELLOW}❌ Serviço kiosk-start não encontrado${NC}"
    echo -e "${CYAN}💡 Execute: curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/scripts/setup-kiosk.sh | sudo bash${NC}"
    exit 1
fi

# Check service status
if systemctl is-active kiosk-start.service >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Serviço está ativo${NC}"
else
    echo -e "${YELLOW}⚠️  Serviço não está ativo, tentando iniciar...${NC}"
    sudo systemctl start kiosk-start.service
    sleep 2
fi

echo
echo -e "${BLUE}📋 Informações do sistema:${NC}"
echo "   • Hostname: $(hostname)"
echo "   • Data/Hora: $(date)"
echo "   • IP: $(hostname -I | awk '{print $1}')"

echo
echo -e "${BLUE}🚀 Saída 'Hello World' do kiosk-start:${NC}"
journalctl -u kiosk-start.service --since "2 minutes ago" --no-pager | grep -i "hello\|started\|kiosk" | tail -10 || {
    echo -e "${YELLOW}ℹ️  Nenhuma saída recente, reiniciando serviço...${NC}"
    sudo systemctl restart kiosk-start.service
    sleep 3
    journalctl -u kiosk-start.service --since "30 seconds ago" --no-pager | grep -i "hello\|started\|kiosk" | tail -5
}

echo
echo -e "${BLUE}📊 Status do serviço:${NC}"
systemctl status kiosk-start.service --no-pager -l | head -8

echo
echo -e "${GREEN}🎉 Hello World! - Teste remoto concluído com sucesso!${NC}"
EOF
    
    local ssh_result=$?
    
    if [[ $ssh_result -eq 0 ]]; then
        echo
        log_success "Teste remoto concluído com sucesso!"
    else
        echo
        echo "❌ Teste remoto falhou"
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local ip_address="${1:-}"
    
    print_header "DEMO: KIOSK START HELLO WORLD"
    
    log_info "🧪 Demo do serviço kiosk-start"
    log_info "📋 Script: $SCRIPT_NAME"
    log_info "🕒 Executado em: $(date)"
    echo
    
    # Show usage if help requested
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Determine execution mode
    if [[ -z "$ip_address" ]]; then
        log_info "🏠 Modo: Execução local"
        test_local
    else
        log_info "🌐 Modo: Execução remota para $ip_address"
        test_remote "$ip_address"
    fi
    
    echo
    print_header "COMANDOS ÚTEIS"
    log_info "📋 Comandos para monitoramento:"
    echo "   • Status: systemctl status kiosk-start.service"
    echo "   • Logs: journalctl -u kiosk-start.service -f"
    echo "   • Reiniciar: sudo systemctl restart kiosk-start.service"
    echo "   • Teste: sudo ./tests/test-kiosk-start.sh"
    
    if [[ -n "$ip_address" ]]; then
        echo
        log_info "📋 Para execução remota:"
        echo "   • SSH: ssh $DEFAULT_PI_USER@$ip_address"
        echo "   • Status remoto: ssh $DEFAULT_PI_USER@$ip_address 'systemctl status kiosk-start.service'"
        echo "   • Logs remotos: ssh $DEFAULT_PI_USER@$ip_address 'journalctl -u kiosk-start.service -f'"
    fi
}

# Execute main function
main "$@"
