#!/bin/bash

# =============================================================================
# Test Script for State File Format Validation
# =============================================================================
# Purpose: Validate that state file format is compatible with shell source
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

readonly TEST_STATE_FILE="/tmp/test-rpi-preparation-state"

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

test_state_file_format() {
    print_header "TESTANDO FORMATO DO ARQUIVO DE ESTADO"
    
    # Create test state file with new format
    local timestamp=$(date '+%Y-%m-%d_%H:%M:%S')
    
    log_info "Criando arquivo de estado de teste..."
    cat > "$TEST_STATE_FILE" << EOF
LAST_STEP="package_install"
TIMESTAMP="$timestamp"
PID=12345
STATUS="running"
EOF
    
    # Show content
    log_info "Conteúdo do arquivo de estado:"
    cat "$TEST_STATE_FILE" | sed 's/^/   /'
    echo
    
    # Test if it can be sourced without errors
    log_info "Testando carregamento com 'source'..."
    
    if source "$TEST_STATE_FILE" 2>/dev/null; then
        log_success "✅ Arquivo carregado com sucesso!"
        echo
        log_info "Variáveis carregadas:"
        log_info "   • LAST_STEP: $LAST_STEP"
        log_info "   • TIMESTAMP: $TIMESTAMP"
        log_info "   • PID: $PID"
        log_info "   • STATUS: $STATUS"
    else
        log_error "❌ Erro ao carregar arquivo de estado"
        return 1
    fi
    
    # Test timestamp format
    echo
    log_info "Testando formato do timestamp..."
    if [[ "$TIMESTAMP" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
        log_success "✅ Formato do timestamp válido: $TIMESTAMP"
    else
        log_error "❌ Formato do timestamp inválido: $TIMESTAMP"
        return 1
    fi
}

test_old_format() {
    print_header "TESTANDO FORMATO ANTIGO (PROBLEMÁTICO)"
    
    # Create test state file with old format (problematic)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_info "Criando arquivo com formato antigo..."
    cat > "$TEST_STATE_FILE.old" << EOF
LAST_STEP=package_install
TIMESTAMP=$timestamp
PID=12345
STATUS=running
EOF
    
    # Show content
    log_info "Conteúdo do arquivo (formato antigo):"
    cat "$TEST_STATE_FILE.old" | sed 's/^/   /'
    echo
    
    # Test if it causes errors
    log_info "Testando carregamento (esperando erro)..."
    
    if source "$TEST_STATE_FILE.old" 2>/dev/null; then
        log_error "❌ Formato antigo não deveria funcionar sem problemas"
        return 1
    else
        log_success "✅ Formato antigo realmente causa erro (como esperado)"
    fi
}

cleanup_test_files() {
    log_info "Limpando arquivos de teste..."
    rm -f "$TEST_STATE_FILE" "$TEST_STATE_FILE.old"
    log_success "Limpeza concluída"
}

validate_script_function() {
    print_header "VALIDANDO FUNÇÃO save_state() NO SCRIPT"
    
    local script_path="../prepare-system.sh"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Script não encontrado: $script_path"
        return 1
    fi
    
    # Check if the function uses the correct format
    if grep -q 'TIMESTAMP="$timestamp"' "$script_path"; then
        log_success "✅ Função save_state() usa formato correto com aspas"
    else
        log_error "❌ Função save_state() não usa formato correto"
        return 1
    fi
    
    if grep -q '+%Y-%m-%d_%H:%M:%S' "$script_path"; then
        log_success "✅ Formato de timestamp correto encontrado"
    else
        log_error "❌ Formato de timestamp correto não encontrado"
        return 1
    fi
}

# Main execution
main() {
    print_header "VALIDAÇÃO DO FORMATO DO ARQUIVO DE ESTADO"
    echo
    
    # Run tests
    test_state_file_format || exit 1
    echo
    test_old_format || exit 1
    echo
    validate_script_function || exit 1
    echo
    
    print_header "TODOS OS TESTES PASSARAM!"
    log_success "🎉 Formato do arquivo de estado está correto"
    log_info "📋 Resumo:"
    log_info "   • Novo formato funciona corretamente"
    log_info "   • Formato antigo realmente causava erro"
    log_info "   • Script usa formato correto"
    log_info "   • Sistema pronto para produção"
    
    cleanup_test_files
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
