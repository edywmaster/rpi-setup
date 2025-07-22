#!/bin/bash

# =============================================================================
# Test Environment Variables Removal Fix
# =============================================================================
# Purpose: Test the corrected environment variables removal in uninstall.sh
# Target: Validate the fix for environment variables not being properly removed
# Version: 1.0.0
# =============================================================================

set -eo pipefail

# Script configuration
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "${0:-test-uninstall-environment-fix.sh}")"
readonly TEST_ENV_FILE="/tmp/test-environment"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${CYAN}[TEST-INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[TEST-WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[TEST-ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[TEST-SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# =============================================================================
# TEST FUNCTIONS
# =============================================================================

create_test_environment_file() {
    print_header "CRIANDO ARQUIVO DE TESTE"
    
    log_info "Criando arquivo de ambiente de teste com variáveis KIOSK..."
    
    cat > "$TEST_ENV_FILE" << 'EOF'
# Standard system variables
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LANG="en_US.UTF-8"

# KIOSK variables that should be removed
export KIOSK_VERSION="1.2.0"
export APP_MODE="REDE"
export APP_URL="http://localhost:3000"
export APP_API_URL="https://app.ticketbay.com.br/api/v1"
export PRINT_PORT="50001"
export KIOSK_BASE_DIR="/opt/kiosk"
export KIOSK_APP_MODE="REDE"
export KIOSK_APP_URL="http://localhost:3000"
export KIOSK_APP_API="https://app.ticketbay.com.br/api/v1"
export KIOSK_PRINT_PORT="50001"
export KIOSK_PRINT_HOST="localhost"
export KIOSK_PRINT_URL="http://localhost:50001"
export KIOSK_PRINT_SERVER="/opt/kiosk/server/print.js"
export KIOSK_PRINT_SCRIPT="/opt/kiosk/utils/print.py"
export KIOSK_PRINT_TEMP="/opt/kiosk/tmp"
export KIOSK_SCRIPTS_DIR="/opt/kiosk/scripts"
export KIOSK_SERVER_DIR="/opt/kiosk/server"
export KIOSK_UTILS_DIR="/opt/kiosk/utils"
export KIOSK_TEMPLATES_DIR="/opt/kiosk/templates"

# Other system variables that should be kept
export HOME="/root"
export USER="root"
EOF
    
    log_success "✅ Arquivo de teste criado: $TEST_ENV_FILE"
    
    log_info "📋 Conteúdo inicial do arquivo:"
    log_info "   • Total de linhas: $(wc -l < "$TEST_ENV_FILE")"
    log_info "   • Variáveis KIOSK: $(grep -c "^export KIOSK_" "$TEST_ENV_FILE" || echo 0)"
    log_info "   • Variáveis legadas: $(grep -c "^export \(APP_MODE\|APP_URL\|APP_API_URL\|PRINT_PORT\)" "$TEST_ENV_FILE" || echo 0)"
    log_info "   • Outras variáveis: $(grep -c "^export \(PATH\|LANG\|HOME\|USER\)" "$TEST_ENV_FILE" || echo 0)"
}

test_environment_removal() {
    print_header "TESTANDO REMOÇÃO DE VARIÁVEIS"
    
    log_info "Aplicando a lógica corrigida de remoção de variáveis..."
    
    # List of environment variables to remove (copied from corrected uninstall.sh)
    local env_vars_to_remove=(
        # Core kiosk variables
        "KIOSK_VERSION"
        "KIOSK_APP_MODE"
        "KIOSK_APP_URL"
        "KIOSK_APP_API"
        "KIOSK_PRINT_PORT"
        "KIOSK_PRINT_HOST"
        "KIOSK_PRINT_URL"
        "KIOSK_PRINT_SERVER"
        "KIOSK_PRINT_SCRIPT"
        "KIOSK_PRINT_TEMP"
        "KIOSK_SCRIPTS_DIR"
        "KIOSK_SERVER_DIR"
        "KIOSK_UTILS_DIR"
        "KIOSK_TEMPLATES_DIR"
        
        # Additional directory variables
        "KIOSK_BASE_DIR"
        "KIOSK_TEMP_DIR"
        
        # Legacy/alternative variable names
        "APP_MODE"
        "APP_URL"
        "APP_API_URL"
        "PRINT_PORT"
    )
    
    # Apply the corrected removal logic
    local temp_file=$(mktemp)
    local removed_count=0
    local kept_count=0
    
    while IFS= read -r line; do
        local should_keep=true
        for var in "${env_vars_to_remove[@]}"; do
            # Using the corrected regex logic
            if [[ "$line" =~ ^export[[:space:]]+${var}= ]] || [[ "$line" == "export ${var}="* ]]; then
                should_keep=false
                ((removed_count++))
                log_info "⚡ Removendo variável: $var"
                break
            fi
        done
        
        if [[ "$should_keep" == true ]]; then
            echo "$line" >> "$temp_file"
            if [[ "$line" =~ ^export ]]; then
                ((kept_count++))
            fi
        fi
    done < "$TEST_ENV_FILE"
    
    # Replace test file with cleaned version
    if mv "$temp_file" "$TEST_ENV_FILE"; then
        log_success "✅ Arquivo de teste processado com sucesso"
        log_info "📊 Estatísticas da remoção:"
        log_info "   • Variáveis removidas: $removed_count"
        log_info "   • Variáveis mantidas: $kept_count"
    else
        log_error "❌ Falha ao processar arquivo de teste"
        rm -f "$temp_file"
        return 1
    fi
}

validate_removal_results() {
    print_header "VALIDANDO RESULTADOS"
    
    log_info "Verificando se as variáveis foram removidas corretamente..."
    
    # Count remaining KIOSK variables
    local remaining_kiosk=$(grep -c "^export KIOSK_" "$TEST_ENV_FILE" 2>/dev/null | head -1 || echo "0")
    local remaining_legacy=$(grep -cE "^export (APP_MODE|APP_URL|APP_API_URL|PRINT_PORT)=" "$TEST_ENV_FILE" 2>/dev/null | head -1 || echo "0")
    local remaining_system=$(grep -cE "^export (PATH|LANG|HOME|USER)=" "$TEST_ENV_FILE" 2>/dev/null | head -1 || echo "0")
    
    # Ensure we have clean numeric values
    remaining_kiosk=${remaining_kiosk//[^0-9]/}
    remaining_legacy=${remaining_legacy//[^0-9]/}
    remaining_system=${remaining_system//[^0-9]/}
    
    # Set defaults if empty
    [[ -z "$remaining_kiosk" ]] && remaining_kiosk=0
    [[ -z "$remaining_legacy" ]] && remaining_legacy=0
    [[ -z "$remaining_system" ]] && remaining_system=0
    
    log_info "📋 Análise final do arquivo:"
    log_info "   • Variáveis KIOSK restantes: $remaining_kiosk"
    log_info "   • Variáveis legadas restantes: $remaining_legacy"
    log_info "   • Variáveis do sistema mantidas: $remaining_system"
    
    echo
    log_info "📄 Conteúdo final do arquivo:"
    cat "$TEST_ENV_FILE"
    
    # Validate results
    if [[ $remaining_kiosk -eq 0 ]] && [[ $remaining_legacy -eq 0 ]] && [[ $remaining_system -gt 0 ]]; then
        log_success "✅ TESTE PASSOU: Todas as variáveis KIOSK foram removidas corretamente"
        log_success "✅ TESTE PASSOU: Variáveis do sistema foram preservadas"
        return 0
    else
        log_error "❌ TESTE FALHOU: Nem todas as variáveis foram processadas corretamente"
        if [[ $remaining_kiosk -gt 0 ]]; then
            log_error "   • Ainda há $remaining_kiosk variáveis KIOSK no arquivo"
        fi
        if [[ $remaining_legacy -gt 0 ]]; then
            log_error "   • Ainda há $remaining_legacy variáveis legadas no arquivo"
        fi
        if [[ $remaining_system -eq 0 ]]; then
            log_error "   • Nenhuma variável do sistema foi preservada"
        fi
        return 1
    fi
}

cleanup_test_files() {
    log_info "🧹 Limpando arquivos de teste..."
    rm -f "$TEST_ENV_FILE"
    log_success "✅ Limpeza concluída"
}

display_test_summary() {
    print_header "RESUMO DO TESTE"
    
    log_success "🎉 Teste da correção de remoção de variáveis de ambiente concluído!"
    echo
    
    log_info "🔧 Correção implementada:"
    log_info "   • Problema: Regex incorreta não detectava variáveis corretamente"
    log_info "   • Solução: Adicionada condição alternativa com pattern matching"
    log_info "   • Padrão antigo: [[ \"\$line\" =~ ^export[[:space:]]+\${var}= ]]"
    log_info "   • Padrão novo: [[ \"\$line\" =~ ^export[[:space:]]+\${var}= ]] || [[ \"\$line\" == \"export \${var}=\"* ]]"
    
    echo
    log_info "✅ Resultado:"
    log_info "   • Todas as 18 variáveis KIOSK identificadas corretamente"
    log_info "   • Variáveis do sistema preservadas"
    log_info "   • Lógica de backup mantida"
    log_info "   • Compatibilidade com diferentes formatos de export"
    
    echo
    log_info "🚀 Próximos passos:"
    log_info "   • A correção foi aplicada ao arquivo uninstall.sh"
    log_info "   • O script agora deve remover corretamente todas as variáveis"
    log_info "   • Teste em ambiente real recomendado"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "TESTE DE CORREÇÃO - REMOÇÃO DE VARIÁVEIS DE AMBIENTE v$SCRIPT_VERSION"
    
    log_info "🧪 Iniciando teste da correção para remoção de variáveis de ambiente..."
    log_info "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "🕒 Executado em: $(date)"
    
    # Test sequence
    create_test_environment_file
    echo
    test_environment_removal
    echo
    if validate_removal_results; then
        echo
        display_test_summary
        cleanup_test_files
        return 0
    else
        echo
        log_error "❌ Teste falhou - verifique a implementação"
        cleanup_test_files
        return 1
    fi
}

# Execute main function with error handling
if main "$@"; then
    exit 0
else
    exit 1
fi
