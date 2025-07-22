#!/bin/bash

# =============================================================================
# Version Manager Test Script
# =============================================================================
# Purpose: Test the version-manager.sh functionality
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

# Project root
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
readonly VERSION_MANAGER="$PROJECT_ROOT/scripts/version-manager.sh"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_header() {
    echo
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
}

# Test version manager script existence and executability
test_script_existence() {
    log_header "Testando Existência do Version Manager"
    
    local errors=0
    
    # Check if script exists
    if [[ -f "$VERSION_MANAGER" ]]; then
        log_success "Script version-manager.sh encontrado"
    else
        log_error "Script version-manager.sh não encontrado em: $VERSION_MANAGER"
        ((errors++))
    fi
    
    # Check if script is executable
    if [[ -x "$VERSION_MANAGER" ]]; then
        log_success "Script version-manager.sh é executável"
    else
        log_error "Script version-manager.sh não é executável"
        ((errors++))
    fi
    
    # Check bash syntax
    if bash -n "$VERSION_MANAGER" 2>/dev/null; then
        log_success "Sintaxe do script version-manager.sh é válida"
    else
        log_error "Erro de sintaxe no script version-manager.sh"
        ((errors++))
    fi
    
    return $errors
}

# Test help functionality
test_help_functionality() {
    log_header "Testando Funcionalidade de Ajuda"
    
    local errors=0
    
    # Test --help option
    log_info "Testando opção --help..."
    if "$VERSION_MANAGER" --help >/dev/null 2>&1; then
        log_success "Opção --help funciona corretamente"
    else
        log_error "Opção --help falhou"
        ((errors++))
    fi
    
    # Test -h option
    log_info "Testando opção -h..."
    if "$VERSION_MANAGER" -h >/dev/null 2>&1; then
        log_success "Opção -h funciona corretamente"
    else
        log_error "Opção -h falhou"
        ((errors++))
    fi
    
    return $errors
}

# Test current version functionality
test_current_version() {
    log_header "Testando Funcionalidade de Versão Atual"
    
    local errors=0
    
    # Test --current option
    log_info "Testando opção --current..."
    if "$VERSION_MANAGER" --current >/dev/null 2>&1; then
        log_success "Opção --current funciona corretamente"
        
        # Check if it shows version information
        local output=$("$VERSION_MANAGER" --current 2>/dev/null)
        if echo "$output" | grep -q "Versão Principal:"; then
            log_success "Output contém informações de versão"
        else
            log_warn "Output não contém informações esperadas de versão"
        fi
    else
        log_error "Opção --current falhou"
        ((errors++))
    fi
    
    return $errors
}

# Test validation functionality
test_validation() {
    log_header "Testando Funcionalidade de Validação"
    
    local errors=0
    
    # Test --validate option
    log_info "Testando opção --validate..."
    if "$VERSION_MANAGER" --validate >/dev/null 2>&1; then
        log_success "Opção --validate executou sem erros"
    else
        log_warn "Opção --validate encontrou inconsistências (isso pode ser normal)"
    fi
    
    # Check if validation output contains expected information
    local output=$("$VERSION_MANAGER" --validate 2>&1)
    if echo "$output" | grep -q "Validando Consistência"; then
        log_success "Output de validação contém cabeçalho esperado"
    else
        log_error "Output de validação não contém cabeçalho esperado"
        ((errors++))
    fi
    
    return $errors
}

# Test version file consistency
test_version_files() {
    log_header "Testando Arquivos de Versão"
    
    local errors=0
    
    # Check prepare-system.sh
    log_info "Verificando prepare-system.sh..."
    if [[ -f "$PROJECT_ROOT/prepare-system.sh" ]]; then
        if grep -q "readonly SCRIPT_VERSION=" "$PROJECT_ROOT/prepare-system.sh"; then
            log_success "prepare-system.sh contém SCRIPT_VERSION"
        else
            log_error "prepare-system.sh não contém SCRIPT_VERSION"
            ((errors++))
        fi
    else
        log_error "prepare-system.sh não encontrado"
        ((errors++))
    fi
    
    # Check setup-kiosk.sh
    log_info "Verificando setup-kiosk.sh..."
    if [[ -f "$PROJECT_ROOT/scripts/setup-kiosk.sh" ]]; then
        if grep -q "readonly SCRIPT_VERSION=" "$PROJECT_ROOT/scripts/setup-kiosk.sh"; then
            log_success "setup-kiosk.sh contém SCRIPT_VERSION"
        else
            log_error "setup-kiosk.sh não contém SCRIPT_VERSION"
            ((errors++))
        fi
    else
        log_error "setup-kiosk.sh não encontrado"
        ((errors++))
    fi
    
    # Check RELEASE-NOTES.md
    log_info "Verificando RELEASE-NOTES.md..."
    if [[ -f "$PROJECT_ROOT/docs/development/RELEASE-NOTES.md" ]]; then
        log_success "RELEASE-NOTES.md encontrado"
    else
        log_error "RELEASE-NOTES.md não encontrado"
        ((errors++))
    fi
    
    return $errors
}

# Test error handling
test_error_handling() {
    log_header "Testando Tratamento de Erros"
    
    local errors=0
    
    # Test invalid option
    log_info "Testando opção inválida..."
    if "$VERSION_MANAGER" --invalid-option >/dev/null 2>&1; then
        log_error "Script não rejeitou opção inválida"
        ((errors++))
    else
        log_success "Script rejeitou opção inválida corretamente"
    fi
    
    # Test --update without version
    log_info "Testando --update sem versão..."
    if "$VERSION_MANAGER" --update >/dev/null 2>&1; then
        log_error "Script não rejeitou --update sem versão"
        ((errors++))
    else
        log_success "Script rejeitou --update sem versão corretamente"
    fi
    
    # Test --update with invalid version format
    log_info "Testando --update com formato inválido..."
    if "$VERSION_MANAGER" --update "invalid-version" >/dev/null 2>&1; then
        log_error "Script não rejeitou formato de versão inválido"
        ((errors++))
    else
        log_success "Script rejeitou formato de versão inválido corretamente"
    fi
    
    return $errors
}

# Test .version file creation
test_version_file_creation() {
    log_header "Testando Criação do Arquivo .version"
    
    local errors=0
    local version_file="$PROJECT_ROOT/.version"
    
    # Backup existing .version file if it exists
    if [[ -f "$version_file" ]]; then
        cp "$version_file" "$version_file.backup"
        log_info "Backup do arquivo .version criado"
    fi
    
    # Remove .version file to test creation
    rm -f "$version_file"
    
    # Run --current to trigger .version creation
    log_info "Executando --current para criar arquivo .version..."
    "$VERSION_MANAGER" --current >/dev/null 2>&1
    
    # Check if .version file was created
    if [[ -f "$version_file" ]]; then
        log_success "Arquivo .version criado com sucesso"
        
        # Check file content
        if grep -q "PROJECT_VERSION=" "$version_file"; then
            log_success "Arquivo .version contém PROJECT_VERSION"
        else
            log_error "Arquivo .version não contém PROJECT_VERSION"
            ((errors++))
        fi
        
        if grep -q "VERSION_HISTORY=" "$version_file"; then
            log_success "Arquivo .version contém VERSION_HISTORY"
        else
            log_error "Arquivo .version não contém VERSION_HISTORY"
            ((errors++))
        fi
    else
        log_error "Arquivo .version não foi criado"
        ((errors++))
    fi
    
    # Restore backup if it existed
    if [[ -f "$version_file.backup" ]]; then
        mv "$version_file.backup" "$version_file"
        log_info "Backup do arquivo .version restaurado"
    fi
    
    return $errors
}

# Test integration with project structure
test_project_integration() {
    log_header "Testando Integração com Estrutura do Projeto"
    
    local errors=0
    
    # Test from project root
    log_info "Testando execução da raiz do projeto..."
    cd "$PROJECT_ROOT"
    if ./scripts/version-manager.sh --current >/dev/null 2>&1; then
        log_success "Execução da raiz do projeto funciona"
    else
        log_error "Execução da raiz do projeto falhou"
        ((errors++))
    fi
    
    # Test from scripts directory
    log_info "Testando execução do diretório scripts..."
    cd "$PROJECT_ROOT/scripts"
    if ./version-manager.sh --current >/dev/null 2>&1; then
        log_success "Execução do diretório scripts funciona"
    else
        log_error "Execução do diretório scripts falhou"
        ((errors++))
    fi
    
    # Test from tests directory
    log_info "Testando execução do diretório tests..."
    cd "$PROJECT_ROOT/tests"
    if ../scripts/version-manager.sh --current >/dev/null 2>&1; then
        log_success "Execução do diretório tests funciona"
    else
        log_error "Execução do diretório tests falhou"
        ((errors++))
    fi
    
    # Return to project root
    cd "$PROJECT_ROOT"
    
    return $errors
}

# Run all tests
run_all_tests() {
    log_header "Executando Todos os Testes do Version Manager"
    
    local total_errors=0
    
    # Run individual tests
    test_script_existence || ((total_errors += $?))
    test_help_functionality || ((total_errors += $?))
    test_current_version || ((total_errors += $?))
    test_validation || ((total_errors += $?))
    test_version_files || ((total_errors += $?))
    test_error_handling || ((total_errors += $?))
    test_version_file_creation || ((total_errors += $?))
    test_project_integration || ((total_errors += $?))
    
    # Show summary
    echo
    log_header "Resumo dos Testes"
    
    if [[ $total_errors -eq 0 ]]; then
        log_success "Todos os testes passaram! Version Manager está funcionando corretamente."
        echo
        log_info "O script version-manager.sh está pronto para uso:"
        echo "  • ./scripts/version-manager.sh --current   (mostrar versão atual)"
        echo "  • ./scripts/version-manager.sh --validate  (validar consistência)"
        echo "  • ./scripts/version-manager.sh --update X.Y.Z  (atualizar versão)"
        echo "  • ./scripts/version-manager.sh --help      (mostrar ajuda)"
    else
        log_error "Encontrados $total_errors erro(s) nos testes."
        log_warn "Verifique os erros acima antes de usar o version-manager.sh"
    fi
    
    return $total_errors
}

# Main function
main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-}" in
        --all|"")
            run_all_tests
            ;;
        --existence)
            test_script_existence
            ;;
        --help-test)
            test_help_functionality
            ;;
        --current-test)
            test_current_version
            ;;
        --validation-test)
            test_validation
            ;;
        --files-test)
            test_version_files
            ;;
        --error-test)
            test_error_handling
            ;;
        --creation-test)
            test_version_file_creation
            ;;
        --integration-test)
            test_project_integration
            ;;
        --help)
            cat << 'EOF'
Version Manager Test Script

USAGE:
    ./tests/test-version-manager.sh [OPTION]

OPTIONS:
    --all                  Executa todos os testes (padrão)
    --existence            Testa existência e executabilidade do script
    --help-test            Testa funcionalidade de ajuda
    --current-test         Testa funcionalidade de versão atual
    --validation-test      Testa funcionalidade de validação
    --files-test           Testa arquivos de versão
    --error-test           Testa tratamento de erros
    --creation-test        Testa criação do arquivo .version
    --integration-test     Testa integração com estrutura do projeto
    --help                 Mostra esta ajuda

EXAMPLES:
    ./tests/test-version-manager.sh
    ./tests/test-version-manager.sh --all
    ./tests/test-version-manager.sh --validation-test

EOF
            ;;
        *)
            log_error "Opção inválida: $1"
            log_info "Use --help para ver opções disponíveis"
            return 1
            ;;
    esac
}

# Execute main function
main "$@"
