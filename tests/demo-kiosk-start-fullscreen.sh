#!/bin/bash

# Script de demonstração para kiosk-start-fullscreen.sh
# Version 1.4.3
# Demonstra o uso prático do novo script de inicialização

set -euo pipefail

readonly DEMO_NAME="Kiosk Start Fullscreen Demo"
readonly SCRIPT_VERSION="1.4.3"

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# =============================================================================
# FUNÇÕES DE UTILIDADE
# =============================================================================

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN} $*${NC}"
    echo -e "${CYAN}========================================${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

# =============================================================================
# FUNÇÕES DE DEMONSTRAÇÃO
# =============================================================================

show_demo_intro() {
    clear
    log_header "$DEMO_NAME"
    echo ""
    echo "Este script demonstra como usar o kiosk-start-fullscreen.sh"
    echo "para criar um kiosk com Chromium em tela cheia."
    echo ""
    echo "Versão: $SCRIPT_VERSION"
    echo "Compatível com: Raspberry Pi Setup Automation Suite"
    echo ""
    echo "🎯 Funcionalidades demonstradas:"
    echo "  • Configuração automática do Openbox"
    echo "  • Chromium em modo kiosk com tela cheia"
    echo "  • Carregamento de configurações de ambiente"
    echo "  • Validação de sistema"
    echo "  • Modos de operação (SSH vs local)"
    echo ""
    read -p "Pressione ENTER para continuar..."
    echo ""
}

demo_script_info() {
    log_header "Informações do Script"
    
    local script_path="../scripts/kiosk-start-fullscreen.sh"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Script não encontrado: $script_path"
        return 1
    fi
    
    log_info "Exibindo informações do script..."
    echo ""
    
    # Mostrar versão
    log_info "Versão do script:"
    bash "$script_path" --version
    echo ""
    
    # Mostrar ajuda
    log_info "Opções disponíveis:"
    bash "$script_path" --help
    echo ""
    
    log_success "Informações do script exibidas com sucesso"
}

demo_environment_setup() {
    log_header "Configuração de Ambiente"
    
    log_info "Exemplo de configuração /etc/environment para kiosk:"
    echo ""
    
    cat << 'EOF'
# =============================================================================
# CONFIGURAÇÕES DO KIOSK SYSTEM
# =============================================================================

# URL da aplicação kiosk (OBRIGATÓRIO)
export KIOSK_APP_URL="https://exemplo-app-kiosk.com"

# Configurações de display
export KIOSK_DISPLAY=":0"
export KIOSK_RESOLUTION="1920x1080"

# Configurações opcionais
export KIOSK_USER="pi"
export KIOSK_HOME="/home/pi"
export KIOSK_LOG_LEVEL="INFO"

# Configurações de comportamento do Chromium
export KIOSK_CHROMIUM_FLAGS="--disable-web-security --allow-running-insecure-content"

# Timeout para aguardar X11 (segundos)
export KIOSK_STARTUP_TIMEOUT="30"

# =============================================================================
EOF
    
    echo ""
    log_success "Exemplo de configuração exibido"
    echo ""
    
    log_info "Para aplicar essas configurações:"
    echo "  1. sudo nano /etc/environment"
    echo "  2. Adicionar as variáveis acima"
    echo "  3. Reiniciar o sistema ou executar: source /etc/environment"
    echo ""
}

demo_openbox_config() {
    log_header "Configuração do Openbox"
    
    log_info "O script cria automaticamente um arquivo autostart para o Openbox:"
    echo ""
    
    log_info "Localização: ~/.config/openbox/autostart"
    echo ""
    
    log_info "Exemplo de conteúdo gerado:"
    echo ""
    
    cat << 'EOF'
#!/bin/sh

# Esperar até que o DISPLAY=:0 esteja disponível
for i in $(seq 1 10); do
    if [ -n "$(xdpyinfo -display :0 2>/dev/null)" ]; then
        break
    fi
    echo "Aguardando o ambiente gráfico (DISPLAY=:0)..."
    sleep 1
done

# Desabilitar o cursor do mouse
unclutter -idle 0.5 -root &

# Ajustar energia e tela
xset s off &
xset -dpms &
xset s noblank &

# Limpar crash flags do Chromium
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/Default/Preferences 2>/dev/null || true
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences 2>/dev/null || true

# Iniciar Chromium em modo kiosk com tela cheia
chromium-browser \
    --kiosk \
    --start-fullscreen \
    --start-maximized \
    --window-size=1920,1080 \
    --window-position=0,0 \
    --incognito \
    --noerrdialogs \
    --disable-infobars \
    --disable-translate \
    --disable-features=Translate \
    --disable-background-timer-throttling \
    --disable-backgrounding-occluded-windows \
    --disable-renderer-backgrounding \
    --disable-field-trial-config \
    --disable-background-networking \
    --force-device-scale-factor=1 \
    --disable-dev-shm-usage \
    --no-sandbox \
    --disable-gpu-sandbox \
    "$KIOSK_APP_URL" &
EOF
    
    echo ""
    log_success "Configuração do Openbox demonstrada"
    echo ""
}

demo_systemd_service() {
    log_header "Serviço Systemd"
    
    log_info "Para inicialização automática, crie um serviço systemd:"
    echo ""
    
    log_info "Arquivo: /etc/systemd/system/kiosk-fullscreen.service"
    echo ""
    
    cat << 'EOF'
[Unit]
Description=Kiosk Fullscreen Start Service
After=graphical-session.target network.target
Wants=graphical-session.target
RequiresMountsFor=/home

[Service]
Type=simple
ExecStart=/opt/kiosk/scripts/kiosk-start-fullscreen.sh
Restart=always
RestartSec=10
User=pi
Group=pi
Environment=DISPLAY=:0
WorkingDirectory=/home/pi

# Configurações de segurança
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/var/log /tmp

[Install]
WantedBy=graphical-session.target
EOF
    
    echo ""
    log_info "Comandos para configurar o serviço:"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl enable kiosk-fullscreen.service"
    echo "  sudo systemctl start kiosk-fullscreen.service"
    echo ""
    
    log_success "Configuração do systemd demonstrada"
    echo ""
}

demo_troubleshooting() {
    log_header "Solução de Problemas"
    
    log_info "Comandos úteis para diagnóstico:"
    echo ""
    
    echo "📋 Verificar status do script:"
    echo "  ./kiosk-start-fullscreen.sh --validate-only"
    echo ""
    
    echo "🔍 Verificar logs:"
    echo "  sudo tail -f /var/log/kiosk-start.log"
    echo "  journalctl -u kiosk-fullscreen.service -f"
    echo ""
    
    echo "🖥️ Verificar processos:"
    echo "  ps aux | grep -E '(chromium|openbox|X)'"
    echo ""
    
    echo "🌐 Verificar conectividade:"
    echo "  ping -c 3 google.com"
    echo "  curl -I \$KIOSK_APP_URL"
    echo ""
    
    echo "⚙️ Verificar configuração:"
    echo "  env | grep KIOSK"
    echo "  cat ~/.config/openbox/autostart"
    echo ""
    
    echo "🔧 Reiniciar serviços:"
    echo "  sudo systemctl restart kiosk-fullscreen.service"
    echo "  sudo systemctl restart lightdm  # Se usando display manager"
    echo ""
    
    log_success "Comandos de diagnóstico apresentados"
    echo ""
}

demo_integration_examples() {
    log_header "Exemplos de Integração"
    
    log_info "Integração com script principal setup-kiosk.sh:"
    echo ""
    
    cat << 'EOF'
# Adicionar ao setup-kiosk.sh na função setup_scripts():

setup_kiosk_fullscreen() {
    log_info "Configurando kiosk fullscreen..."
    
    # Copiar script
    cp "$SCRIPT_DIR/kiosk-start-fullscreen.sh" "$KIOSK_SCRIPTS_DIR/"
    chmod +x "$KIOSK_SCRIPTS_DIR/kiosk-start-fullscreen.sh"
    chown pi:pi "$KIOSK_SCRIPTS_DIR/kiosk-start-fullscreen.sh"
    
    # Criar serviço systemd
    create_kiosk_fullscreen_service
    
    log_success "Kiosk fullscreen configurado"
}

create_kiosk_fullscreen_service() {
    cat > /etc/systemd/system/kiosk-fullscreen.service << 'EOFSERVICE'
[Unit]
Description=Kiosk Fullscreen Start Service
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=/opt/kiosk/scripts/kiosk-start-fullscreen.sh
Restart=always
RestartSec=10
User=pi
Group=pi
Environment=DISPLAY=:0

[Install]
WantedBy=graphical-session.target
EOFSERVICE
    
    systemctl daemon-reload
    systemctl enable kiosk-fullscreen.service
}
EOF
    
    echo ""
    log_success "Exemplo de integração apresentado"
    echo ""
}

demo_best_practices() {
    log_header "Melhores Práticas"
    
    log_info "Recomendações para produção:"
    echo ""
    
    echo "🔒 Segurança:"
    echo "  • Configure firewall (ufw ou iptables)"
    echo "  • Desabilite SSH se não necessário"
    echo "  • Use HTTPS para aplicações kiosk"
    echo "  • Configure backup automático das configurações"
    echo ""
    
    echo "⚡ Performance:"
    echo "  • Use SSD ou cartão SD classe 10+"
    echo "  • Configure swap adequadamente"
    echo "  • Monitore uso de memória e CPU"
    echo "  • Otimize aplicação web para kiosk"
    echo ""
    
    echo "🔧 Manutenção:"
    echo "  • Configure atualizações automáticas"
    echo "  • Monitore logs regularmente"
    echo "  • Teste failover e recovery"
    echo "  • Documente configurações específicas"
    echo ""
    
    echo "📱 Usabilidade:"
    echo "  • Teste em resolução de produção"
    echo "  • Configure timeout adequado"
    echo "  • Implemente controle de acesso se necessário"
    echo "  • Considere modo offline/fallback"
    echo ""
    
    log_success "Melhores práticas apresentadas"
    echo ""
}

show_demo_conclusion() {
    log_header "Conclusão da Demonstração"
    
    echo "✨ Parabéns! Você concluiu a demonstração do kiosk-start-fullscreen.sh"
    echo ""
    
    log_info "Próximos passos:"
    echo "  1. 📋 Configure as variáveis de ambiente em /etc/environment"
    echo "  2. 🚀 Execute o script em um Raspberry Pi com X11"
    echo "  3. ⚙️ Configure como serviço systemd para inicialização automática"
    echo "  4. 🧪 Teste com sua aplicação kiosk específica"
    echo "  5. 📊 Configure monitoramento e logs"
    echo ""
    
    log_info "Recursos adicionais:"
    echo "  • Documentação: docs/development/KIOSK-START-FULLSCREEN.md"
    echo "  • Testes: tests/test-kiosk-start-fullscreen.sh"
    echo "  • Script principal: scripts/kiosk-start-fullscreen.sh"
    echo "  • Repositório: https://github.com/edywmaster/rpi-setup"
    echo ""
    
    log_success "Demonstração concluída com sucesso!"
    echo ""
    
    echo "Obrigado por usar o Raspberry Pi Setup Automation Suite! 🎉"
    echo ""
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    show_demo_intro
    demo_script_info
    demo_environment_setup
    demo_openbox_config
    demo_systemd_service
    demo_troubleshooting
    demo_integration_examples
    demo_best_practices
    show_demo_conclusion
}

# Executar demonstração
main "$@"
