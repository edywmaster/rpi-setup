#!/bin/bash

# Script de teste para o serviço kiosk-fullscreen corrigido
# Version 1.4.3

readonly SCRIPT_NAME="test-kiosk-fullscreen-service"
readonly LOG_FILE="/var/log/kiosk-fullscreen-test.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE"
}

check_service_file() {
    log_info "Verificando arquivo do serviço..."
    
    if [[ ! -f "/etc/systemd/system/kiosk-fullscreen.service" ]]; then
        log_error "Arquivo do serviço não encontrado"
        return 1
    fi
    
    # Verificar se contém as variáveis de ambiente corrigidas
    if grep -q "Environment=TERM=xterm-256color" "/etc/systemd/system/kiosk-fullscreen.service"; then
        log_success "Variável TERM configurada corretamente"
    else
        log_error "Variável TERM não encontrada no serviço"
        return 1
    fi
    
    if grep -q "ExecStartPre=" "/etc/systemd/system/kiosk-fullscreen.service"; then
        log_success "ExecStartPre configurado para aguardar X11"
    else
        log_warning "ExecStartPre não configurado"
    fi
    
    return 0
}

show_service_status() {
    log_info "Status atual do serviço:"
    echo ""
    
    if systemctl is-enabled kiosk-fullscreen.service >/dev/null 2>&1; then
        log_success "Serviço está habilitado"
    else
        log_warning "Serviço não está habilitado"
    fi
    
    local status=$(systemctl is-active kiosk-fullscreen.service 2>/dev/null || echo "inactive")
    case $status in
        "active")
            log_success "Serviço está ativo"
            ;;
        "inactive")
            log_info "Serviço está inativo"
            ;;
        "failed")
            log_error "Serviço falhou"
            ;;
        *)
            log_warning "Status do serviço: $status"
            ;;
    esac
    
    echo ""
}

show_recent_logs() {
    log_info "Logs recentes do serviço:"
    echo ""
    
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -u kiosk-fullscreen.service --lines=10 --no-pager || true
    else
        log_warning "journalctl não disponível"
    fi
    
    echo ""
}

check_environment_variables() {
    log_info "Verificando variáveis de ambiente necessárias..."
    
    # Verificar se /etc/environment contém variáveis KIOSK
    if [[ -f "/etc/environment" ]]; then
        local kiosk_vars=$(grep "^export KIOSK_" /etc/environment 2>/dev/null | wc -l)
        if [[ $kiosk_vars -gt 0 ]]; then
            log_success "$kiosk_vars variáveis KIOSK encontradas em /etc/environment"
        else
            log_warning "Nenhuma variável KIOSK encontrada em /etc/environment"
        fi
    else
        log_error "/etc/environment não encontrado"
    fi
}

check_x11_requirements() {
    log_info "Verificando requisitos do X11..."
    
    # Verificar se X11 está instalado
    if command -v startx >/dev/null 2>&1; then
        log_success "startx está disponível"
    else
        log_warning "startx não encontrado"
    fi
    
    if command -v xset >/dev/null 2>&1; then
        log_success "xset está disponível"
    else
        log_error "xset não encontrado"
    fi
    
    # Verificar se X11 está ativo
    if [[ -e "/tmp/.X11-unix/X0" ]]; then
        log_success "X11 socket encontrado (/tmp/.X11-unix/X0)"
    else
        log_warning "X11 socket não encontrado - X11 pode não estar ativo"
    fi
    
    # Verificar DISPLAY
    if [[ -n "${DISPLAY:-}" ]]; then
        log_success "DISPLAY está definido: $DISPLAY"
        if xset q >/dev/null 2>&1; then
            log_success "X11 está respondendo"
        else
            log_warning "X11 não está respondendo"
        fi
    else
        log_warning "DISPLAY não está definido"
    fi
}

check_chromium() {
    log_info "Verificando Chromium..."
    
    if command -v chromium-browser >/dev/null 2>&1; then
        log_success "chromium-browser está disponível"
        local version=$(chromium-browser --version 2>/dev/null || echo "Versão não disponível")
        log_info "Versão: $version"
    else
        log_error "chromium-browser não encontrado"
    fi
}

create_test_service() {
    log_info "Criando serviço de teste..."
    
    cat > "/tmp/test-kiosk-fullscreen.service" << 'EOF'
[Unit]
Description=Teste Kiosk Fullscreen Start Service
After=graphical.target network.target sound.target
Wants=graphical.target
Requires=graphical.target
RequiresMountsFor=/home

[Service]
Type=simple
ExecStart=/opt/kiosk/scripts/kiosk-start-fullscreen.sh --validate-only
Restart=no
User=pi
Group=pi
WorkingDirectory=/home/pi

# Environment variables necessárias
Environment=DISPLAY=:0
Environment=TERM=xterm-256color
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=HOME=/home/pi
Environment=USER=pi

# Configurações de segurança ajustadas para X11
PrivateTmp=false
ProtectSystem=false
ProtectHome=false
NoNewPrivileges=false

# Aguardar até que X11 esteja disponível
ExecStartPre=/bin/bash -c 'until [ -e /tmp/.X11-unix/X0 ]; do sleep 1; done'

[Install]
WantedBy=graphical.target
EOF

    log_success "Serviço de teste criado em /tmp/test-kiosk-fullscreen.service"
    
    log_info "Para instalar o serviço de teste:"
    echo "  sudo cp /tmp/test-kiosk-fullscreen.service /etc/systemd/system/"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl start test-kiosk-fullscreen.service"
    echo "  sudo journalctl -u test-kiosk-fullscreen.service"
}

show_troubleshooting_guide() {
    log_info "Guia de solução de problemas:"
    echo ""
    
    echo "🔧 Problemas comuns e soluções:"
    echo ""
    
    echo "1. TERM environment variable not set:"
    echo "   - Verificar se o serviço inclui Environment=TERM=xterm-256color"
    echo "   - Recarregar systemd: sudo systemctl daemon-reload"
    echo ""
    
    echo "2. X11 não disponível:"
    echo "   - Verificar se X11 está ativo: sudo systemctl status graphical.target"
    echo "   - Verificar socket X11: ls -la /tmp/.X11-unix/"
    echo "   - Testar DISPLAY: DISPLAY=:0 xset q"
    echo ""
    
    echo "3. Chromium não inicia:"
    echo "   - Verificar instalação: chromium-browser --version"
    echo "   - Testar manualmente: DISPLAY=:0 chromium-browser --kiosk http://google.com"
    echo "   - Verificar logs: journalctl -u kiosk-fullscreen.service -f"
    echo ""
    
    echo "4. Permissões:"
    echo "   - Verificar dono dos arquivos: ls -la /opt/kiosk/scripts/"
    echo "   - Corrigir se necessário: sudo chown pi:pi /opt/kiosk/scripts/*"
    echo ""
    
    echo "5. Serviço systemd:"
    echo "   - Recarregar configuração: sudo systemctl daemon-reload"
    echo "   - Reiniciar serviço: sudo systemctl restart kiosk-fullscreen.service"
    echo "   - Verificar status: sudo systemctl status kiosk-fullscreen.service"
    echo ""
    
    echo "📋 Comandos úteis:"
    echo "   - Logs em tempo real: sudo journalctl -u kiosk-fullscreen.service -f"
    echo "   - Status completo: sudo systemctl status kiosk-fullscreen.service"
    echo "   - Parar serviço: sudo systemctl stop kiosk-fullscreen.service"
    echo "   - Desabilitar: sudo systemctl disable kiosk-fullscreen.service"
    echo ""
}

main() {
    echo "=============================================="
    echo " Teste do Serviço Kiosk Fullscreen"
    echo "=============================================="
    echo "Script: $SCRIPT_NAME"
    echo "Log: $LOG_FILE"
    echo ""
    
    check_service_file
    show_service_status
    check_environment_variables
    check_x11_requirements
    check_chromium
    show_recent_logs
    create_test_service
    show_troubleshooting_guide
    
    echo ""
    log_info "Teste concluído. Verifique os logs acima para diagnosticar problemas."
    echo ""
}

# Verificar se é executado como root para alguns testes
if [[ $EUID -eq 0 ]]; then
    log_warning "Executando como root - alguns testes podem não ser precisos"
fi

main "$@"
