#!/bin/bash

# =============================================================================
# Kiosk Print Server Usage Examples
# =============================================================================
# Este script demonstra como usar o servidor de impressão do kiosk
# após a instalação via setup-kiosk.sh
# =============================================================================

set -e

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Server configuration
readonly PRINT_SERVER_URL="http://localhost:50001"

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_example() {
    echo -e "${BLUE}[EXEMPLO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

check_server() {
    log_info "Verificando se o servidor está rodando..."
    
    if curl -s "$PRINT_SERVER_URL/health" > /dev/null; then
        log_success "✅ Servidor de impressão está ativo"
        return 0
    else
        echo "❌ Servidor não está respondendo. Iniciando serviço..."
        sudo systemctl start kiosk-print-server.service
        sleep 3
        
        if curl -s "$PRINT_SERVER_URL/health" > /dev/null; then
            log_success "✅ Servidor iniciado com sucesso"
            return 0
        else
            echo "❌ Falha ao iniciar servidor. Verifique os logs:"
            echo "sudo journalctl -u kiosk-print-server.service"
            return 1
        fi
    fi
}

echo "🖨️ Exemplos de Uso do Servidor de Impressão Kiosk"
echo

print_header "VERIFICAÇÃO DO SERVIDOR"

check_server || exit 1

echo
print_header "EXEMPLOS DE USO DA API"

# Health Check
log_example "1. Health Check do Servidor"
echo "curl $PRINT_SERVER_URL/health"
echo
curl -s "$PRINT_SERVER_URL/health" | jq . 2>/dev/null || curl -s "$PRINT_SERVER_URL/health"
echo

# List Printers
log_example "2. Listar Impressoras Disponíveis"
echo "curl $PRINT_SERVER_URL/printers"
echo
curl -s "$PRINT_SERVER_URL/printers" | jq . 2>/dev/null || curl -s "$PRINT_SERVER_URL/printers"
echo

# Print Queue
log_example "3. Verificar Fila de Impressão"
echo "curl $PRINT_SERVER_URL/queue"
echo
curl -s "$PRINT_SERVER_URL/queue" | jq . 2>/dev/null || curl -s "$PRINT_SERVER_URL/queue"
echo

# Printer Status
log_example "4. Status da Impressora"
echo "curl $PRINT_SERVER_URL/printer-status"
echo
curl -s "$PRINT_SERVER_URL/printer-status" | jq . 2>/dev/null || curl -s "$PRINT_SERVER_URL/printer-status"
echo

echo
print_header "EXEMPLO DE IMPRESSÃO"

log_example "5. Imprimir Badge (simulação)"
echo "# Para imprimir um badge real, use:"
echo "curl $PRINT_SERVER_URL/badge/123"
echo
echo "# AVISO: Isso irá tentar imprimir um badge real com ID 123"
echo "# Descomente a linha abaixo para testar:"
echo "# curl $PRINT_SERVER_URL/badge/123"
echo

echo
print_header "COMANDOS PYTHON DIRETOS"

log_example "6. Usando o Script Python Diretamente"
echo

log_info "Listar impressoras:"
echo "python3 /opt/kiosk/utils/printer.py --list"
echo
if [[ -f "/opt/kiosk/utils/printer.py" ]]; then
    python3 /opt/kiosk/utils/printer.py --list 2>/dev/null || echo "Requer CUPS configurado"
else
    echo "Script não encontrado. Execute primeiro setup-kiosk.sh"
fi
echo

log_info "Verificar status da impressora:"
echo "python3 /opt/kiosk/utils/printer.py --status"
echo

log_info "Verificar CUPS:"
echo "python3 /opt/kiosk/utils/printer.py --check-cups"
echo
if [[ -f "/opt/kiosk/utils/printer.py" ]]; then
    python3 /opt/kiosk/utils/printer.py --check-cups 2>/dev/null || echo "CUPS não está rodando"
else
    echo "Script não encontrado"
fi
echo

echo
print_header "MONITORAMENTO E LOGS"

log_example "7. Comandos de Monitoramento"
echo

log_info "Ver logs do servidor em tempo real:"
echo "sudo journalctl -u kiosk-print-server.service -f"
echo

log_info "Ver logs do arquivo:"
echo "tail -f /var/log/kiosk-print-server.log"
echo

log_info "Status do serviço:"
echo "sudo systemctl status kiosk-print-server.service"
echo

log_info "Reiniciar servidor:"
echo "sudo systemctl restart kiosk-print-server.service"
echo

echo
print_header "CONFIGURAÇÃO AVANÇADA"

log_example "8. Configuração do Ambiente"
echo

log_info "Arquivo de configuração:"
echo "cat /opt/kiosk/server/.env"
echo
if [[ -f "/opt/kiosk/server/.env" ]]; then
    echo "# Conteúdo atual:"
    cat /opt/kiosk/server/.env | head -10
else
    echo "Arquivo .env não encontrado"
fi
echo

log_info "Variáveis do sistema kiosk:"
echo "cat /opt/kiosk/kiosk.conf"
echo

echo
print_header "INTEGRAÇÃO COM APLICAÇÃO"

log_example "9. Exemplo de Integração JavaScript"
echo
cat << 'EOF'
// Exemplo de uso em aplicação React/JavaScript
const printBadge = async (userId) => {
  try {
    const response = await fetch(`http://localhost:50001/badge/${userId}`);
    const result = await response.json();
    
    if (result.status === 'success') {
      console.log('Badge impresso com sucesso!');
    } else {
      console.error('Erro na impressão:', result.message);
    }
  } catch (error) {
    console.error('Erro de conexão:', error);
  }
};

// Verificar se servidor está funcionando
const checkPrintServer = async () => {
  try {
    const response = await fetch('http://localhost:50001/health');
    const health = await response.json();
    return health.status === 'ok';
  } catch {
    return false;
  }
};
EOF
echo

echo
print_header "TROUBLESHOOTING"

log_example "10. Solução de Problemas Comuns"
echo

log_info "Se o servidor não inicia:"
echo "1. sudo systemctl status kiosk-print-server.service"
echo "2. sudo journalctl -u kiosk-print-server.service"
echo "3. Verificar se Node.js está instalado: node --version"
echo "4. Verificar dependências: cd /opt/kiosk/server && npm list"
echo

log_info "Se não consegue imprimir:"
echo "1. sudo systemctl status cups"
echo "2. lpstat -p (listar impressoras)"
echo "3. lpoptions -d printer_name (definir padrão)"
echo "4. Verificar impressora conectada via USB/rede"
echo

log_info "Para configurar nova impressora:"
echo "1. Acessar http://$(hostname -I | awk '{print $1}'):631"
echo "2. Administration -> Add Printer"
echo "3. Configurar como impressora padrão"
echo

echo
log_success "🎉 Exemplos de uso concluídos!"
log_info "Para mais informações, consulte /opt/kiosk/server/README.md"
