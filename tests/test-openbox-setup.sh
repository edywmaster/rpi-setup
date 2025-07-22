#!/bin/bash

# =============================================================================
# Test Openbox Environment Setup
# =============================================================================
# Purpose: Test the new Openbox configuration functionality
# Target: Validates setup-kiosk.sh Openbox integration
# Version: 1.4.3
# =============================================================================

set -eo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly SETUP_SCRIPT="$PROJECT_ROOT/scripts/setup-kiosk.sh"

# Test directories (simulated)
readonly TEST_BASE="/tmp/kiosk-test-$$"
readonly TEST_HOME="$TEST_BASE/home/pi"
readonly TEST_CONFIG="$TEST_HOME/.config"
readonly TEST_OPENBOX="$TEST_CONFIG/openbox"
readonly TEST_CHROMIUM="$TEST_CONFIG/chromium/Default"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo
    echo "=========================================="
    echo " $1"
    echo "=========================================="
}

# Setup test environment
setup_test_env() {
    log_info "Configurando ambiente de teste..."
    mkdir -p "$TEST_OPENBOX"
    mkdir -p "$TEST_CHROMIUM"
    mkdir -p "$TEST_BASE/opt/kiosk/scripts"
}

# Cleanup test environment
cleanup_test_env() {
    log_info "Limpando ambiente de teste..."
    rm -rf "$TEST_BASE" 2>/dev/null || true
}

# Test 1: Verify script syntax and new function existence
test_script_syntax() {
    print_header "TESTE 1: SINTAXE E ESTRUTURA DO SCRIPT"
    
    log_info "Verificando sintaxe do script..."
    if bash -n "$SETUP_SCRIPT"; then
        log_success "Sintaxe do script está correta"
    else
        log_error "Erro de sintaxe no script"
        return 1
    fi
    
    log_info "Verificando se a função setup_openbox_environment existe..."
    if grep -q "setup_openbox_environment()" "$SETUP_SCRIPT"; then
        log_success "Função setup_openbox_environment encontrada"
    else
        log_error "Função setup_openbox_environment não encontrada"
        return 1
    fi
    
    log_info "Verificando se a função create_kiosk_start_script existe..."
    if grep -q "create_kiosk_start_script()" "$SETUP_SCRIPT"; then
        log_success "Função create_kiosk_start_script encontrada"
    else
        log_error "Função create_kiosk_start_script não encontrada"
        return 1
    fi
}

# Test 2: Verify Openbox setup step is included
test_openbox_integration() {
    print_header "TESTE 2: INTEGRAÇÃO DO OPENBOX NO FLUXO"
    
    log_info "Verificando se openbox_setup está na lista de passos..."
    if grep -A 15 "INSTALLATION_STEPS=" "$SETUP_SCRIPT" | grep -q "openbox_setup"; then
        log_success "Passo openbox_setup encontrado na lista de instalação"
    else
        log_error "Passo openbox_setup não encontrado na lista de instalação"
        return 1
    fi
    
    log_info "Verificando se setup_openbox_environment é chamada no main()..."
    if grep -A 20 "# Setup process" "$SETUP_SCRIPT" | grep -q "setup_openbox_environment"; then
        log_success "Chamada para setup_openbox_environment encontrada no main()"
    else
        log_error "Chamada para setup_openbox_environment não encontrada no main()"
        return 1
    fi
}

# Test 3: Verify autostart script content
test_autostart_content() {
    print_header "TESTE 3: CONTEÚDO DO AUTOSTART"
    
    log_info "Verificando se o autostart contém comandos essenciais..."
    
    # Extract autostart content from the script
    local autostart_content
    autostart_content=$(sed -n '/cat > \/home\/pi\/\.config\/openbox\/autostart << '\''EOF'\''/,/^EOF$/p' "$SETUP_SCRIPT")
    
    # Check for essential commands
    local tests=(
        "xdpyinfo:Verificação do display"
        "unclutter:Ocultação do cursor"
        "xset s off:Desabilitar screensaver"
        "xset -dpms:Desabilitar gerenciamento de energia"
        "chromium --kiosk:Navegador em modo kiosk"
        "KIOSK_APP_URL:Variável de URL da aplicação"
    )
    
    local all_tests_passed=true
    for test_item in "${tests[@]}"; do
        local command="${test_item%%:*}"
        local description="${test_item##*:}"
        
        if echo "$autostart_content" | grep -q "$command"; then
            log_success "$description encontrado"
        else
            log_error "$description não encontrado"
            all_tests_passed=false
        fi
    done
    
    if [ "$all_tests_passed" = true ]; then
        log_success "Todos os comandos essenciais encontrados no autostart"
    else
        log_error "Alguns comandos essenciais estão faltando no autostart"
        return 1
    fi
}

# Test 4: Verify start.sh script content
test_start_script_content() {
    print_header "TESTE 4: CONTEÚDO DO START.SH"
    
    log_info "Verificando se o start.sh contém funções essenciais..."
    
    # Extract start.sh content from the script
    local start_content
    start_content=$(sed -n '/cat > "$KIOSK_SCRIPTS_DIR\/start.sh" << '\''EOF'\''/,/^EOF$/p' "$SETUP_SCRIPT")
    
    # Check for essential functions and commands
    local tests=(
        "load_kiosk_config:Função de carregamento de configuração"
        "show_kiosk_vars:Função de exibição de variáveis"
        "kiosk_start:Função de inicialização do kiosk"
        "ssh_start:Função para conexões SSH"
        "SSH_CONNECTION:Verificação de conexão SSH"
        "startx:Comando para iniciar X"
        "\.config\/openbox\/autostart:Chamada do autostart"
    )
    
    local all_tests_passed=true
    for test_item in "${tests[@]}"; do
        local command="${test_item%%:*}"
        local description="${test_item##*:}"
        
        if echo "$start_content" | grep -q "$command"; then
            log_success "$description encontrado"
        else
            log_error "$description não encontrado"
            all_tests_passed=false
        fi
    done
    
    if [ "$all_tests_passed" = true ]; then
        log_success "Todas as funções essenciais encontradas no start.sh"
    else
        log_error "Algumas funções essenciais estão faltando no start.sh"
        return 1
    fi
}

# Test 5: Verify dependencies installation
test_dependencies() {
    print_header "TESTE 5: INSTALAÇÃO DE DEPENDÊNCIAS"
    
    log_info "Verificando se as dependências do Openbox são instaladas..."
    
    # Check if the script installs required packages
    local packages=(
        "openbox:Window manager principal"
        "unclutter:Para ocultar cursor"
        "xorg:Sistema X Window"
        "xserver-xorg-legacy:Servidor X legacy"
        "x11-xserver-utils:Utilitários do X11"
    )
    
    local all_packages_found=true
    for package_item in "${packages[@]}"; do
        local package="${package_item%%:*}"
        local description="${package_item##*:}"
        
        if grep -A 5 "apt-get install" "$SETUP_SCRIPT" | grep -q "$package"; then
            log_success "$description ($package) será instalado"
        else
            log_error "$description ($package) não será instalado"
            all_packages_found=false
        fi
    done
    
    if [ "$all_packages_found" = true ]; then
        log_success "Todas as dependências necessárias serão instaladas"
    else
        log_error "Algumas dependências estão faltando"
        return 1
    fi
}

# Test 6: Verify completion summary includes Openbox info
test_completion_summary() {
    print_header "TESTE 6: RESUMO DE CONCLUSÃO"
    
    log_info "Verificando se o resumo inclui informações do Openbox..."
    
    # Check if completion summary includes Openbox information
    local summary_items=(
        "Ambiente Gráfico.*Openbox:Seção do ambiente gráfico"
        "Window Manager.*Openbox:Informação do window manager"
        "Autostart.*openbox\/autostart:Caminho do autostart"
        "\.xinitrc:Arquivo xinitrc"
        "Unclutter:Informação sobre cursor"
        "Chromium.*kiosk:Informação sobre navegador"
    )
    
    local all_items_found=true
    for item in "${summary_items[@]}"; do
        local pattern="${item%%:*}"
        local description="${item##*:}"
        
        if grep -A 50 "display_completion_summary" "$SETUP_SCRIPT" | grep -q "$pattern"; then
            log_success "$description encontrada no resumo"
        else
            log_error "$description não encontrada no resumo"
            all_items_found=false
        fi
    done
    
    if [ "$all_items_found" = true ]; then
        log_success "Todas as informações do Openbox estão no resumo"
    else
        log_error "Algumas informações do Openbox estão faltando no resumo"
        return 1
    fi
}

# Main test execution
main() {
    print_header "TESTE DE CONFIGURAÇÃO DO OPENBOX"
    
    log_info "Iniciando testes de validação da configuração do Openbox..."
    log_info "Script alvo: $SETUP_SCRIPT"
    
    # Setup test environment
    setup_test_env
    
    # Run tests
    local tests_passed=0
    local total_tests=6
    
    test_script_syntax && ((tests_passed++))
    test_openbox_integration && ((tests_passed++))
    test_autostart_content && ((tests_passed++))
    test_start_script_content && ((tests_passed++))
    test_dependencies && ((tests_passed++))
    test_completion_summary && ((tests_passed++))
    
    # Cleanup
    cleanup_test_env
    
    # Summary
    echo
    print_header "RESULTADO DOS TESTES"
    
    if [ $tests_passed -eq $total_tests ]; then
        log_success "🎉 Todos os testes passaram ($tests_passed/$total_tests)"
        log_success "✅ A configuração do Openbox está implementada corretamente"
        echo
        log_info "📋 Funcionalidades validadas:"
        log_info "   • Função setup_openbox_environment implementada"
        log_info "   • Integração no fluxo principal do script"
        log_info "   • Script autostart do Openbox configurado"
        log_info "   • Script start.sh com funções de carregamento"
        log_info "   • Dependências necessárias serão instaladas"
        log_info "   • Resumo de conclusão atualizado"
        return 0
    else
        log_error "❌ Alguns testes falharam ($tests_passed/$total_tests)"
        log_error "🔧 Verifique as implementações que falharam"
        return 1
    fi
}

# Execute main function
main "$@"
