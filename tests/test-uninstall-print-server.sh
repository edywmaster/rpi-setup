#!/bin/bash

# =============================================================================
# Test Script - Kiosk Uninstall Print Server Validation
# =============================================================================
# Purpose: Validate that the uninstall script properly removes print server components
# Target: Test dist/kiosk/scripts/uninstall.sh print server cleanup
# Version: 1.0.0
# Dependencies: bash
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
readonly TEST_NAME="Uninstall Print Server Validation"
readonly UNINSTALL_SCRIPT="/Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/dist/kiosk/scripts/uninstall.sh"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((TESTS_FAILED++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

run_test() {
    ((TESTS_RUN++))
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_header "$TEST_NAME"

log_info "🧪 Testando script de desinstalação com suporte ao servidor de impressão..."
echo

# Test 1: Check if uninstall script exists
run_test
log_info "📝 Teste 1: Verificando se o script de desinstalação existe..."
if [[ -f "$UNINSTALL_SCRIPT" ]]; then
    log_success "✅ Script de desinstalação encontrado: $UNINSTALL_SCRIPT"
else
    log_error "❌ Script de desinstalação não encontrado: $UNINSTALL_SCRIPT"
fi

# Test 2: Check for print server service constant
run_test
log_info "📝 Teste 2: Verificando constante do serviço de impressão..."
if grep -q "PRINT_SERVER_SERVICE_PATH" "$UNINSTALL_SCRIPT"; then
    log_success "✅ Constante PRINT_SERVER_SERVICE_PATH encontrada"
else
    log_error "❌ Constante PRINT_SERVER_SERVICE_PATH não encontrada"
fi

# Test 3: Check for print server log constants
run_test
log_info "📝 Teste 3: Verificando constantes de logs do servidor de impressão..."
if grep -q "PRINT_SERVER_LOG" "$UNINSTALL_SCRIPT" && grep -q "PRINTER_SCRIPT_LOG" "$UNINSTALL_SCRIPT"; then
    log_success "✅ Constantes de logs do servidor de impressão encontradas"
else
    log_error "❌ Constantes de logs do servidor de impressão não encontradas"
fi

# Test 4: Check for print server service removal in remove_kiosk_services
run_test
log_info "📝 Teste 4: Verificando remoção do serviço kiosk-print-server..."
if grep -A 20 "remove_kiosk_services()" "$UNINSTALL_SCRIPT" | grep -q "kiosk-print-server"; then
    log_success "✅ Remoção do serviço kiosk-print-server implementada"
else
    log_error "❌ Remoção do serviço kiosk-print-server não encontrada"
fi

# Test 5: Check for KIOSK_TEMP_DIR in directories removal
run_test
log_info "📝 Teste 5: Verificando remoção do diretório temporário do kiosk..."
if grep -A 10 "directories_to_remove=" "$UNINSTALL_SCRIPT" | grep -q "KIOSK_TEMP_DIR"; then
    log_success "✅ Diretório temporário do kiosk incluído na remoção"
else
    log_error "❌ Diretório temporário do kiosk não incluído na remoção"
fi

# Test 6: Check for print server log removal
run_test
log_info "📝 Teste 6: Verificando remoção dos logs do servidor de impressão..."
if grep -q "PRINT_SERVER_LOG" "$UNINSTALL_SCRIPT" && grep -q "PRINTER_SCRIPT_LOG" "$UNINSTALL_SCRIPT"; then
    if grep -A 30 "remove_setup_status()" "$UNINSTALL_SCRIPT" | grep -q "Log do servidor"; then
        log_success "✅ Remoção dos logs do servidor de impressão implementada"
    else
        log_error "❌ Remoção dos logs do servidor de impressão não implementada"
    fi
else
    log_error "❌ Constantes de logs não encontradas"
fi

# Test 7: Check for print server environment variables removal
run_test
log_info "📝 Teste 7: Verificando remoção das variáveis de ambiente do servidor de impressão..."
if grep -A 20 "env_vars_to_remove=" "$UNINSTALL_SCRIPT" | grep -q "KIOSK_PRINT"; then
    log_success "✅ Variáveis de ambiente do servidor de impressão incluídas na remoção"
else
    log_error "❌ Variáveis de ambiente do servidor de impressão não incluídas na remoção"
fi

# Test 8: Check for print server processes removal function
run_test
log_info "📝 Teste 8: Verificando função de remoção de processos do servidor de impressão..."
if grep -q "remove_print_server_processes()" "$UNINSTALL_SCRIPT"; then
    log_success "✅ Função remove_print_server_processes() encontrada"
else
    log_error "❌ Função remove_print_server_processes() não encontrada"
fi

# Test 9: Check for PM2 process cleanup
run_test
log_info "📝 Teste 9: Verificando limpeza de processos PM2..."
if grep -A 30 "remove_print_server_processes()" "$UNINSTALL_SCRIPT" | grep -q "pm2"; then
    log_success "✅ Limpeza de processos PM2 implementada"
else
    log_error "❌ Limpeza de processos PM2 não implementada"
fi

# Test 10: Check for port cleanup
run_test
log_info "📝 Teste 10: Verificando limpeza de processos na porta do servidor..."
if grep -A 30 "remove_print_server_processes()" "$UNINSTALL_SCRIPT" | grep -q "lsof.*port"; then
    log_success "✅ Limpeza de processos na porta implementada"
else
    log_error "❌ Limpeza de processos na porta não implementada"
fi

# Test 11: Check if remove_print_server_processes is called in main
run_test
log_info "📝 Teste 11: Verificando se remove_print_server_processes é chamada na função main..."
if grep -A 10 "# Uninstall process" "$UNINSTALL_SCRIPT" | grep -q "remove_print_server_processes"; then
    log_success "✅ Função remove_print_server_processes chamada na main"
else
    log_error "❌ Função remove_print_server_processes não chamada na main"
fi

# Test 12: Check updated summary information
run_test
log_info "📝 Teste 12: Verificando resumo atualizado da desinstalação..."
if grep -A 10 "Resumo da desinstalação" "$UNINSTALL_SCRIPT" | grep -q "kiosk-print-server"; then
    log_success "✅ Resumo da desinstalação inclui servidor de impressão"
else
    log_error "❌ Resumo da desinstalação não inclui servidor de impressão"
fi

# Test 13: Check warning message includes print server
run_test
log_info "📝 Teste 13: Verificando se a mensagem de aviso inclui o servidor de impressão..."
if grep -A 10 "Será removido:" "$UNINSTALL_SCRIPT" | grep -q "servidor de impressão"; then
    log_success "✅ Mensagem de aviso inclui servidor de impressão"
else
    log_error "❌ Mensagem de aviso não inclui servidor de impressão"
fi

# Test 14: Check script syntax
run_test
log_info "📝 Teste 14: Verificando sintaxe do script..."
if bash -n "$UNINSTALL_SCRIPT" 2>/dev/null; then
    log_success "✅ Sintaxe do script está correta"
else
    log_error "❌ Erro de sintaxe no script"
fi

# Test 15: Check script has executable permissions
run_test
log_info "📝 Teste 15: Verificando permissões de execução..."
if [[ -x "$UNINSTALL_SCRIPT" ]]; then
    log_success "✅ Script tem permissões de execução"
else
    log_error "❌ Script não tem permissões de execução"
fi

echo
print_header "RESULTADOS DOS TESTES"

log_info "📊 Resumo dos testes:"
log_info "   • Total de testes: $TESTS_RUN"
log_info "   • Testes passou: $TESTS_PASSED"
log_info "   • Testes falhou: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo
    log_success "🎉 Todos os testes passaram! Script de desinstalação com suporte ao servidor de impressão está correto."
    exit 0
else
    echo
    log_error "❌ $TESTS_FAILED teste(s) falharam. Verifique a implementação."
    exit 1
fi
