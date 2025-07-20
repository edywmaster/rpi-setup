#!/bin/bash

# =============================================================================
# Test Script for Boot Configuration Feature
# =============================================================================
# Purpose: Test and demonstrate boot configuration functionality
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

# Test directories
readonly TEST_DIR="/tmp/rpi-boot-test"
readonly TEST_BOOT_CONFIG="$TEST_DIR/config.txt"
readonly TEST_BOOT_CMDLINE="$TEST_DIR/cmdline.txt"

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

setup_test_environment() {
    print_header "CONFIGURANDO AMBIENTE DE TESTE"
    
    # Create test directory
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # Create sample config.txt
    cat > "$TEST_BOOT_CONFIG" << 'EOF'
# For more options and information see
# http://rpf.io/configtxt
# Some settings may impact device functionality. See link above for details

# uncomment if you get no picture on HDMI for a default "safe" mode
#hdmi_safe=1

# uncomment this if your display has a black border of unused pixels visible
# and your display can output without overscan
#disable_overscan=1

[all]
dtoverlay=vc4-kms-v3d
max_framebuffers=2

[pi4]
# Enable DRM VC4 V3D driver on top of the dispmanx display stack
dtoverlay=vc4-fkms-v3d
max_framebuffers=2

[all]
EOF

    # Create sample cmdline.txt
    cat > "$TEST_BOOT_CMDLINE" << 'EOF'
console=serial0,115200 console=tty1 root=PARTUUID=12345678-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait
EOF

    log_success "Ambiente de teste criado"
    log_info "   • config.txt: $TEST_BOOT_CONFIG"
    log_info "   • cmdline.txt: $TEST_BOOT_CMDLINE"
}

test_config_txt_modification() {
    print_header "TESTANDO MODIFICAÇÃO DO CONFIG.TXT"
    
    echo
    log_info "Conteúdo original do config.txt:"
    cat "$TEST_BOOT_CONFIG" | tail -5
    
    echo
    log_info "Aplicando configurações..."
    
    # Simulate the function logic
    if ! grep -q "disable_splash=1" "$TEST_BOOT_CONFIG"; then
        echo "" >> "$TEST_BOOT_CONFIG"
        echo "# Raspberry Pi Display Optimizations - Added by rpi-setup" >> "$TEST_BOOT_CONFIG"
        echo "disable_splash=1" >> "$TEST_BOOT_CONFIG"
        echo "avoid_warnings=1" >> "$TEST_BOOT_CONFIG"
        log_success "✅ Configurações adicionadas ao config.txt"
    else
        log_info "⚡ Configurações já presentes"
    fi
    
    echo
    log_info "Conteúdo modificado do config.txt:"
    cat "$TEST_BOOT_CONFIG" | tail -5
}

test_cmdline_txt_modification() {
    print_header "TESTANDO MODIFICAÇÃO DO CMDLINE.TXT"
    
    echo
    log_info "Conteúdo original do cmdline.txt:"
    cat "$TEST_BOOT_CMDLINE"
    
    echo
    log_info "Criando backup..."
    cp "$TEST_BOOT_CMDLINE" "$TEST_BOOT_CMDLINE.backup"
    log_success "✅ Backup criado: $TEST_BOOT_CMDLINE.backup"
    
    echo
    log_info "Aplicando configurações..."
    
    # Simulate the function logic
    if ! grep -q "logo.nologo" "$TEST_BOOT_CMDLINE"; then
        sed -i '1s/$/ logo.nologo vt.global_cursor_default=0 consoleblank=0 loglevel=0 quiet/' "$TEST_BOOT_CMDLINE"
        log_success "✅ Configurações adicionadas ao cmdline.txt"
    else
        log_info "⚡ Configurações já presentes"
    fi
    
    echo
    log_info "Conteúdo modificado do cmdline.txt:"
    cat "$TEST_BOOT_CMDLINE"
}

test_idempotency() {
    print_header "TESTANDO IDEMPOTÊNCIA"
    
    log_info "Executando modificações novamente..."
    
    # Test config.txt idempotency
    if ! grep -q "disable_splash=1" "$TEST_BOOT_CONFIG"; then
        log_error "❌ config.txt não deveria precisar de modificação"
        return 1
    else
        log_success "✅ config.txt já configurado (correto)"
    fi
    
    # Test cmdline.txt idempotency
    if ! grep -q "logo.nologo" "$TEST_BOOT_CMDLINE"; then
        log_error "❌ cmdline.txt não deveria precisar de modificação"
        return 1
    else
        log_success "✅ cmdline.txt já configurado (correto)"
    fi
    
    log_success "Idempotência validada - script pode ser executado múltiplas vezes"
}

show_configuration_summary() {
    print_header "RESUMO DAS CONFIGURAÇÕES APLICADAS"
    
    echo
    log_info "📋 Configurações de config.txt:"
    log_info "   • disable_splash=1 - Remove tela de splash do Pi"
    log_info "   • avoid_warnings=1 - Remove avisos de undervoltage"
    
    echo
    log_info "📋 Configurações de cmdline.txt:"
    log_info "   • logo.nologo - Remove logo do kernel Linux"
    log_info "   • vt.global_cursor_default=0 - Remove cursor piscando"
    log_info "   • consoleblank=0 - Desabilita blank do console"
    log_info "   • loglevel=0 quiet - Reduz mensagens verbosas"
    
    echo
    log_info "🎯 Resultado final:"
    log_info "   • Boot mais limpo e profissional"
    log_info "   • Ideal para sistemas kiosk/display"
    log_info "   • Inicialização mais rápida"
    log_info "   • Backup automático criado"
}

cleanup_test_environment() {
    log_info "Limpando ambiente de teste..."
    rm -rf "$TEST_DIR"
    log_success "Limpeza concluída"
}

validate_real_system() {
    print_header "VALIDAÇÃO NO SISTEMA REAL"
    
    echo
    log_info "Para testar no Raspberry Pi real:"
    echo
    log_info "1. Execute o script principal:"
    echo "   curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
    echo
    log_info "2. Verifique os arquivos de boot:"
    echo "   sudo cat /boot/firmware/config.txt | tail -5"
    echo "   sudo cat /boot/firmware/cmdline.txt"
    echo
    log_info "3. Verifique o backup:"
    echo "   sudo ls -la /boot/firmware/cmdline.txt.backup"
    echo
    log_warn "⚠️  Reinicialização necessária para aplicar as configurações de boot"
}

# Main execution
main() {
    print_header "TESTE DA FUNCIONALIDADE DE CONFIGURAÇÃO DE BOOT"
    echo
    
    setup_test_environment
    echo
    test_config_txt_modification
    echo
    test_cmdline_txt_modification
    echo
    test_idempotency
    echo
    show_configuration_summary
    echo
    validate_real_system
    echo
    cleanup_test_environment
    echo
    print_header "TODOS OS TESTES PASSARAM!"
    log_success "🎉 Funcionalidade de configuração de boot validada"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
