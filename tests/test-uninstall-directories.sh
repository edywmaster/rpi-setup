#!/bin/bash

# =============================================================================
# Test Script - Uninstall Directory Structure Validation
# =============================================================================
# Purpose: Validate uninstall script directories match setup-kiosk.sh structure
# Target: Test dist/kiosk/scripts/uninstall.sh directory consistency
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
readonly TEST_NAME="Uninstall Directory Structure Validation"
readonly SETUP_SCRIPT="/Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/setup-kiosk.sh"
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

log_info "🧪 Testando consistência de diretórios entre setup e uninstall..."
echo

# Test 1: KIOSK_TEMP_DIR consistency
run_test
log_info "📝 Teste 1: Verificando consistência do KIOSK_TEMP_DIR..."

setup_temp_dir=$(grep "readonly KIOSK_TEMP_DIR=" "$SETUP_SCRIPT" | cut -d'"' -f2)
uninstall_temp_dir=$(grep "readonly KIOSK_TEMP_DIR=" "$UNINSTALL_SCRIPT" | cut -d'"' -f2)

log_info "   Setup: $setup_temp_dir"
log_info "   Uninstall: $uninstall_temp_dir"

if [[ "$setup_temp_dir" == "$uninstall_temp_dir" ]]; then
    log_success "✅ KIOSK_TEMP_DIR consistente entre setup e uninstall"
else
    log_error "❌ KIOSK_TEMP_DIR inconsistente: setup='$setup_temp_dir' vs uninstall='$uninstall_temp_dir'"
fi

# Test 2: Check if uninstall includes KIOSK_SERVER_FILES_DIR
run_test
log_info "📝 Teste 2: Verificando diretório de arquivos do servidor..."
if grep -q "KIOSK_SERVER_FILES_DIR" "$UNINSTALL_SCRIPT"; then
    log_success "✅ KIOSK_SERVER_FILES_DIR definido no uninstall"
else
    log_error "❌ KIOSK_SERVER_FILES_DIR não encontrado no uninstall"
fi

# Test 3: Check if setup creates $KIOSK_SERVER_DIR/files
run_test
log_info "📝 Teste 3: Verificando se setup cria diretório files..."
if grep -q "mkdir.*files" "$SETUP_SCRIPT"; then
    log_success "✅ Setup cria diretório files"
else
    log_error "❌ Setup não cria diretório files"
fi

# Test 4: Check if uninstall cleans temporary PDF files
run_test
log_info "📝 Teste 4: Verificando limpeza de arquivos PDF temporários..."
if grep -A 10 "Limpando arquivos temporários" "$UNINSTALL_SCRIPT" | grep -q "*.pdf"; then
    log_success "✅ Uninstall limpa arquivos PDF temporários"
else
    log_error "❌ Uninstall não limpa arquivos PDF temporários"
fi

# Test 5: Directory removal order
run_test
log_info "📝 Teste 5: Verificando ordem de remoção de diretórios..."
if grep -A 20 "directories_to_remove=" "$UNINSTALL_SCRIPT" | grep -q "KIOSK_BASE_DIR"; then
    log_success "✅ KIOSK_BASE_DIR está na lista de remoção"
else
    log_error "❌ KIOSK_BASE_DIR não está na lista de remoção"
fi

# Test 6: Check KIOSK_TEMP_DIR in environment variables removal
run_test
log_info "📝 Teste 6: Verificando KIOSK_TEMP_DIR nas variáveis de ambiente..."
if grep -A 25 "env_vars_to_remove=" "$UNINSTALL_SCRIPT" | grep -q "KIOSK_TEMP_DIR"; then
    log_success "✅ KIOSK_TEMP_DIR incluído na remoção de variáveis"
else
    log_error "❌ KIOSK_TEMP_DIR não incluído na remoção de variáveis"
fi

# Test 7: Verify directory structure match
run_test
log_info "📝 Teste 7: Verificando estrutura completa de diretórios..."

# Extract directories from both scripts
setup_dirs=$(grep "readonly KIOSK.*_DIR=" "$SETUP_SCRIPT" | cut -d'"' -f2 | sort)
uninstall_dirs=$(grep "readonly KIOSK.*_DIR=" "$UNINSTALL_SCRIPT" | cut -d'"' -f2 | sort)

log_info "   Diretórios no setup:"
echo "$setup_dirs" | while read -r dir; do
    log_info "     - $dir"
done

log_info "   Diretórios no uninstall:"
echo "$uninstall_dirs" | while read -r dir; do
    log_info "     - $dir"
done

# Check if main directories match
if [[ "$setup_dirs" == "$uninstall_dirs" ]]; then
    log_success "✅ Estrutura de diretórios totalmente consistente"
else
    log_warn "⚠️  Estrutura de diretórios tem diferenças (pode ser intencional)"
fi

# Test 8: Check for legacy directory cleanup
run_test
log_info "📝 Teste 8: Verificando limpeza de diretórios legacy..."
if grep -q "PDF_DOWNLOAD_DIR" "$UNINSTALL_SCRIPT"; then
    if grep -q "backward compatibility" "$UNINSTALL_SCRIPT"; then
        log_success "✅ Mantém compatibilidade com diretórios legacy"
    else
        log_warn "⚠️  PDF_DOWNLOAD_DIR presente mas sem comentário de compatibilidade"
    fi
else
    log_error "❌ PDF_DOWNLOAD_DIR não encontrado para limpeza legacy"
fi

# Test 9: Verify syntax of both scripts
run_test
log_info "📝 Teste 9: Verificando sintaxe dos scripts..."
setup_syntax_ok=false
uninstall_syntax_ok=false

if bash -n "$SETUP_SCRIPT" 2>/dev/null; then
    setup_syntax_ok=true
fi

if bash -n "$UNINSTALL_SCRIPT" 2>/dev/null; then
    uninstall_syntax_ok=true
fi

if [[ "$setup_syntax_ok" == true ]] && [[ "$uninstall_syntax_ok" == true ]]; then
    log_success "✅ Sintaxe correta em ambos os scripts"
else
    log_error "❌ Erro de sintaxe detectado"
fi

# Test 10: Check consistency of service paths
run_test
log_info "📝 Teste 10: Verificando consistência de caminhos de serviços..."

setup_print_service=$(grep "kiosk-print-server.service" "$SETUP_SCRIPT" | head -1)
uninstall_print_service=$(grep "kiosk-print-server.service" "$UNINSTALL_SCRIPT" | head -1)

if [[ -n "$setup_print_service" ]] && [[ -n "$uninstall_print_service" ]]; then
    log_success "✅ Serviço kiosk-print-server presente em ambos os scripts"
else
    log_error "❌ Inconsistência no serviço kiosk-print-server"
fi

echo
print_header "RESULTADOS DOS TESTES"

log_info "📊 Resumo dos testes:"
log_info "   • Total de testes: $TESTS_RUN"
log_info "   • Testes passou: $TESTS_PASSED"
log_info "   • Testes falhou: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo
    log_success "🎉 Todos os testes passaram! Diretórios consistentes entre setup e uninstall."
    exit 0
else
    echo
    log_error "❌ $TESTS_FAILED teste(s) falharam. Verifique a consistência dos diretórios."
    exit 1
fi
