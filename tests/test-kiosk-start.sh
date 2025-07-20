#!/bin/bash

# =============================================================================
# Test Script for Kiosk Start Service
# =============================================================================
# Purpose: Test the kiosk-start service functionality
# Usage: ./test-kiosk-start.sh
# =============================================================================

set -eo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "${0}")"
readonly TEST_LOG="/tmp/test-kiosk-start.log"

# Service configuration
readonly KIOSK_START_SERVICE="kiosk-start.service"
readonly KIOSK_START_SCRIPT="/opt/kiosk/scripts/kiosk-start.sh"
readonly KIOSK_START_LOG="/var/log/kiosk-start.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Test results
declare -i tests_total=0
declare -i tests_passed=0
declare -i tests_failed=0

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TEST] $1" >> "$TEST_LOG"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PASS] $1" >> "$TEST_LOG"
    ((tests_passed++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FAIL] $1" >> "$TEST_LOG"
    ((tests_failed++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$TEST_LOG"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# =============================================================================
# TEST FUNCTIONS
# =============================================================================

test_service_exists() {
    ((tests_total++))
    log_test "Verificando se o serviço kiosk-start existe..."
    
    if systemctl list-unit-files | grep -q "kiosk-start.service"; then
        log_pass "Serviço kiosk-start.service existe"
        return 0
    else
        log_fail "Serviço kiosk-start.service não encontrado"
        return 1
    fi
}

test_service_enabled() {
    ((tests_total++))
    log_test "Verificando se o serviço está habilitado..."
    
    if systemctl is-enabled "$KIOSK_START_SERVICE" >/dev/null 2>&1; then
        log_pass "Serviço está habilitado para inicialização automática"
        return 0
    else
        log_fail "Serviço não está habilitado"
        return 1
    fi
}

test_service_active() {
    ((tests_total++))
    log_test "Verificando se o serviço está ativo..."
    
    if systemctl is-active "$KIOSK_START_SERVICE" >/dev/null 2>&1; then
        log_pass "Serviço está ativo e executando"
        return 0
    else
        log_fail "Serviço não está ativo"
        return 1
    fi
}

test_script_exists() {
    ((tests_total++))
    log_test "Verificando se o script de inicialização existe..."
    
    if [[ -f "$KIOSK_START_SCRIPT" ]]; then
        log_pass "Script de inicialização encontrado: $KIOSK_START_SCRIPT"
        return 0
    else
        log_fail "Script de inicialização não encontrado: $KIOSK_START_SCRIPT"
        return 1
    fi
}

test_script_executable() {
    ((tests_total++))
    log_test "Verificando se o script é executável..."
    
    if [[ -x "$KIOSK_START_SCRIPT" ]]; then
        log_pass "Script tem permissões de execução"
        return 0
    else
        log_fail "Script não tem permissões de execução"
        return 1
    fi
}

test_log_file_exists() {
    ((tests_total++))
    log_test "Verificando se o arquivo de log do serviço existe..."
    
    if [[ -f "$KIOSK_START_LOG" ]]; then
        log_pass "Arquivo de log encontrado: $KIOSK_START_LOG"
        return 0
    else
        log_fail "Arquivo de log não encontrado: $KIOSK_START_LOG"
        return 1
    fi
}

test_hello_world_in_logs() {
    ((tests_total++))
    log_test "Verificando se 'Hello World' aparece nos logs..."
    
    if [[ -f "$KIOSK_START_LOG" ]] && grep -q "Hello World" "$KIOSK_START_LOG"; then
        log_pass "Mensagem 'Hello World' encontrada nos logs"
        return 0
    else
        log_fail "Mensagem 'Hello World' não encontrada nos logs"
        return 1
    fi
}

test_service_journal_output() {
    ((tests_total++))
    log_test "Verificando saída do journal do serviço..."
    
    local journal_output
    journal_output=$(journalctl -u "$KIOSK_START_SERVICE" --no-pager -n 10 --output=cat 2>/dev/null || echo "")
    
    if [[ -n "$journal_output" ]]; then
        log_pass "Journal do serviço contém saída"
        log_info "Últimas 5 linhas do journal:"
        echo "$journal_output" | tail -5 | while IFS= read -r line; do
            echo "   $line"
        done
        return 0
    else
        log_fail "Journal do serviço está vazio"
        return 1
    fi
}

test_service_restart() {
    ((tests_total++))
    log_test "Testando reinicialização do serviço..."
    
    log_info "Parando serviço..."
    if systemctl stop "$KIOSK_START_SERVICE" 2>/dev/null; then
        sleep 2
        
        log_info "Iniciando serviço..."
        if systemctl start "$KIOSK_START_SERVICE" 2>/dev/null; then
            sleep 3
            
            if systemctl is-active "$KIOSK_START_SERVICE" >/dev/null 2>&1; then
                log_pass "Serviço reiniciado com sucesso"
                return 0
            else
                log_fail "Serviço não está ativo após reinicialização"
                return 1
            fi
        else
            log_fail "Falha ao iniciar serviço"
            return 1
        fi
    else
        log_fail "Falha ao parar serviço"
        return 1
    fi
}

display_service_info() {
    print_header "INFORMAÇÕES DO SERVIÇO"
    
    log_info "Status do serviço kiosk-start:"
    systemctl status "$KIOSK_START_SERVICE" --no-pager -l 2>/dev/null || log_fail "Não foi possível obter status do serviço"
    
    echo
    log_info "Configuração do serviço:"
    if [[ -f "/etc/systemd/system/$KIOSK_START_SERVICE" ]]; then
        echo "   Arquivo: /etc/systemd/system/$KIOSK_START_SERVICE"
        echo "   Script: $KIOSK_START_SCRIPT"
        echo "   Log: $KIOSK_START_LOG"
    else
        log_fail "Arquivo de configuração do serviço não encontrado"
    fi
    
    echo
    log_info "Últimas 10 linhas do log do serviço:"
    if [[ -f "$KIOSK_START_LOG" ]]; then
        tail -10 "$KIOSK_START_LOG" 2>/dev/null || log_fail "Não foi possível ler o log"
    else
        log_fail "Arquivo de log não encontrado"
    fi
}

test_hello_world_output() {
    ((tests_total++))
    log_test "Testando saída 'Hello World' em tempo real..."
    
    log_info "Reiniciando serviço para capturar saída..."
    systemctl restart "$KIOSK_START_SERVICE" 2>/dev/null || {
        log_fail "Falha ao reiniciar serviço"
        return 1
    }
    
    # Wait for service to start and produce output
    sleep 5
    
    # Check for Hello World in recent journal output
    local recent_output
    recent_output=$(journalctl -u "$KIOSK_START_SERVICE" --since "30 seconds ago" --no-pager --output=cat 2>/dev/null || echo "")
    
    if echo "$recent_output" | grep -q -i "hello world"; then
        log_pass "Saída 'Hello World' detectada no journal"
        log_info "Saída recente:"
        echo "$recent_output" | grep -i "hello\|kiosk\|started" | head -5 | while IFS= read -r line; do
            echo "   $line"
        done
        return 0
    else
        log_fail "Saída 'Hello World' não detectada no journal"
        log_info "Saída recente disponível:"
        echo "$recent_output" | head -5 | while IFS= read -r line; do
            echo "   $line"
        done
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "TESTE DO SERVIÇO KIOSK START"
    
    log_info "🧪 Iniciando testes do serviço kiosk-start..."
    log_info "📋 Script: $SCRIPT_NAME"
    log_info "🕒 Executado em: $(date)"
    echo
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_fail "Este script deve ser executado com privilégios de root"
        log_info "Execute: sudo $0"
        exit 1
    fi
    
    # Initialize test log
    echo "=== Teste do Serviço Kiosk Start - $(date) ===" > "$TEST_LOG"
    
    # Run tests
    test_service_exists
    test_script_exists
    test_script_executable
    test_service_enabled
    test_service_active
    test_log_file_exists
    test_hello_world_in_logs
    test_service_journal_output
    test_hello_world_output
    test_service_restart
    
    echo
    display_service_info
    
    # Display results
    echo
    print_header "RESULTADOS DOS TESTES"
    
    log_info "📊 Resumo dos testes:"
    log_info "   • Total de testes: $tests_total"
    log_info "   • Testes aprovados: $tests_passed"
    log_info "   • Testes falharam: $tests_failed"
    
    if [[ $tests_failed -eq 0 ]]; then
        log_pass "🎉 Todos os testes passaram! Serviço Kiosk Start está funcionando corretamente."
        exit 0
    else
        log_fail "❌ $tests_failed teste(s) falharam. Verifique os logs para mais detalhes."
        log_info "📄 Log de teste salvo em: $TEST_LOG"
        exit 1
    fi
}

# Execute main function
main "$@"
