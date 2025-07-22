#!/bin/bash

# Kiosk Start Fullscreen Script - Version 1.4.3
# Raspberry Pi Setup Automation Suite
# Script para iniciar o kiosk com Chromium em tela cheia
# Combina funcionalidades dos scripts openbox, autostart e start existentes

set -euo pipefail

# =============================================================================
# CONFIGURAÇÕES E CONSTANTES
# =============================================================================

readonly SCRIPT_VERSION="1.4.3"
readonly SCRIPT_NAME="kiosk-start-fullscreen.sh"
readonly LOG_FILE="/var/log/kiosk-start.log"

# Diretórios do sistema kiosk (seguindo padrão do projeto)
readonly KIOSK_BASE_DIR="/opt/kiosk"
readonly KIOSK_SCRIPTS_DIR="$KIOSK_BASE_DIR/scripts"
readonly KIOSK_UTILS_DIR="$KIOSK_BASE_DIR/utils"

# Arquivos de configuração
readonly XINITRC_FILE="/home/pi/.xinitrc"
readonly OPENBOX_CONFIG_DIR="/home/pi/.config/openbox"
readonly CHROMIUM_CONFIG_DIR="/home/pi/.config/chromium/Default"

# =============================================================================
# FUNÇÕES DE LOGGING E UTILITÁRIOS
# =============================================================================

log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $*" | tee -a "$LOG_FILE"
}

# =============================================================================
# FUNÇÃO PARA CARREGAR CONFIGURAÇÕES DO KIOSK
# =============================================================================

load_kiosk_config() {
    log_info "Carregando configurações do kiosk de /etc/environment..."
    
    # Verificar se /etc/environment existe
    if [[ ! -f /etc/environment ]]; then
        log_error "Arquivo /etc/environment não encontrado"
        return 1
    fi
    
    # Carregar apenas variáveis KIOSK exportadas
    set -a  # Exportar todas as variáveis definidas
    source <(grep '^export KIOSK_' /etc/environment 2>/dev/null || true)
    set +a  # Desativar exportação automática
    
    log_success "Configurações KIOSK carregadas de /etc/environment"
    return 0
}

# =============================================================================
# FUNÇÃO PARA EXIBIR VARIÁVEIS KIOSK CARREGADAS
# =============================================================================

show_kiosk_vars() {
    echo ""
    echo "📋 Variáveis KIOSK carregadas:"
    echo "────────────────────────────────"
    
    # Listar todas as variáveis KIOSK definidas
    env | grep '^KIOSK_' | sort | while IFS='=' read -r var value; do
        echo "  $var = $value"
    done
    
    echo "────────────────────────────────"
    echo ""
}

# =============================================================================
# FUNÇÃO PARA CONFIGURAR OPENBOX
# =============================================================================

setup_openbox() {
    log_info "Configurando Openbox para kiosk..."
    
    # Criar diretórios necessários
    sudo mkdir -p "$OPENBOX_CONFIG_DIR"
    sudo mkdir -p "$CHROMIUM_CONFIG_DIR"
    sudo touch "$CHROMIUM_CONFIG_DIR/Preferences"
    
    # Criar script autostart para Openbox
    log_info "Criando script autostart para Openbox..."
    
    cat > "/tmp/autostart" << 'EOF'
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

# Verificar se KIOSK_APP_URL está definida
if [ -z "${KIOSK_APP_URL:-}" ]; then
    echo "⚠️ KIOSK_APP_URL não definida, usando página padrão"
    KIOSK_APP_URL="https://www.google.com"
fi

# Iniciar o navegador em modo kiosk com tela cheia
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

    # Mover arquivo autostart para local correto
    sudo cp "/tmp/autostart" "$OPENBOX_CONFIG_DIR/autostart"
    sudo chmod +x "$OPENBOX_CONFIG_DIR/autostart"
    
    # Configurar permissões
    sudo chmod -R 755 "/home/pi/.config"
    sudo chown -R pi:pi "/home/pi/.config"
    
    # Configurar .xinitrc se necessário
    if ! grep -q '^exec openbox-session' "$XINITRC_FILE" 2>/dev/null; then
        echo "exec openbox-session" >> "$XINITRC_FILE"
        log_info "Linha adicionada ao $XINITRC_FILE: exec openbox-session"
    else
        log_info "A linha 'exec openbox-session' já existe em $XINITRC_FILE"
    fi
    
    log_success "Openbox configurado com sucesso"
}

# =============================================================================
# FUNÇÃO PARA VALIDAR AMBIENTE
# =============================================================================

validate_environment() {
    log_info "Validando ambiente para inicialização do kiosk..."
    
    # Verificar se é Raspberry Pi
    if [[ ! -f /proc/device-tree/model ]] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        log_warn "Não parece ser um Raspberry Pi"
    fi
    
    # Verificar se X11 está disponível
    if ! command -v startx >/dev/null 2>&1; then
        log_error "startx não encontrado. Instale o X11 primeiro."
        return 1
    fi
    
    # Verificar se Openbox está disponível
    if ! command -v openbox >/dev/null 2>&1; then
        log_error "Openbox não encontrado. Instale o Openbox primeiro."
        return 1
    fi
    
    # Verificar se Chromium está disponível
    if ! command -v chromium-browser >/dev/null 2>&1; then
        log_error "Chromium não encontrado. Instale o Chromium primeiro."
        return 1
    fi
    
    # Verificar se unclutter está disponível
    if ! command -v unclutter >/dev/null 2>&1; then
        log_warn "unclutter não encontrado. O cursor do mouse pode ficar visível."
    fi
    
    log_success "Ambiente validado com sucesso"
    return 0
}

# =============================================================================
# FUNÇÃO PRINCIPAL DE INICIALIZAÇÃO DO KIOSK
# =============================================================================

kiosk_start_fullscreen() {
    clear
    echo "🚀 Iniciando Kiosk System com Chromium em Tela Cheia"
    echo "Version: $SCRIPT_VERSION"
    echo ""
    
    log_info "=== Iniciando Kiosk System Fullscreen ==="
    
    # Carregar configurações
    if ! load_kiosk_config; then
        log_error "Falha ao carregar configurações do kiosk"
        exit 1
    fi
    
    # Exibir variáveis carregadas
    show_kiosk_vars
    
    # Validar ambiente
    if ! validate_environment; then
        log_error "Falha na validação do ambiente"
        exit 1
    fi
    
    # Configurar Openbox
    setup_openbox
    
    log_info "Aguardando 3 segundos antes de iniciar X11..."
    sleep 3
    
    # Iniciar X11 com Openbox
    log_info "Iniciando X11 com Openbox..."
    exec startx
}

# =============================================================================
# FUNÇÃO PARA MODO SSH (sem interface gráfica)
# =============================================================================

ssh_start() {
    clear
    echo "🖥️  Kiosk System - Modo SSH"
    echo "Version: $SCRIPT_VERSION"
    echo ""
    
    log_info "Executando em modo SSH - sem interface gráfica"
    
    # Carregar configurações apenas para verificação
    if load_kiosk_config; then
        show_kiosk_vars
    else
        log_warn "Configurações kiosk não encontradas"
    fi
    
    echo "ℹ️  Para iniciar o kiosk com interface gráfica, execute diretamente no Raspberry Pi"
    echo "ℹ️  Comando: sudo systemctl start kiosk-start.service"
    
    exit 0
}

# =============================================================================
# FUNÇÃO DE HELP
# =============================================================================

show_help() {
    cat << EOF
$SCRIPT_NAME - Version $SCRIPT_VERSION
Script para iniciar kiosk com Chromium em tela cheia

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -h, --help          Exibir esta mensagem de ajuda
    -v, --version       Exibir versão do script
    --setup-only        Apenas configurar Openbox sem iniciar
    --validate-only     Apenas validar ambiente

ENVIRONMENT VARIABLES:
    KIOSK_APP_URL      URL da aplicação kiosk (obrigatória)

EXAMPLES:
    $SCRIPT_NAME                    # Iniciar kiosk normalmente
    $SCRIPT_NAME --setup-only       # Apenas configurar Openbox
    $SCRIPT_NAME --validate-only    # Apenas validar ambiente

NOTES:
    - Este script deve ser executado como usuário pi
    - Configurações são carregadas de /etc/environment
    - Logs são salvos em $LOG_FILE
    - Compatível com Raspberry Pi OS Lite (Debian 12 "bookworm")

EOF
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Processar argumentos da linha de comando
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "$SCRIPT_NAME version $SCRIPT_VERSION"
            exit 0
            ;;
        --setup-only)
            load_kiosk_config || true
            validate_environment || exit 1
            setup_openbox
            log_success "Configuração do Openbox concluída"
            exit 0
            ;;
        --validate-only)
            load_kiosk_config || true
            validate_environment
            log_success "Validação do ambiente concluída"
            exit 0
            ;;
        "")
            # Modo normal - continuar execução
            ;;
        *)
            echo "Opção inválida: $1"
            echo "Use $SCRIPT_NAME --help para ver as opções disponíveis"
            exit 1
            ;;
    esac
    
    # Verificar se o script está sendo executado via SSH
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        ssh_start
    else
        kiosk_start_fullscreen
    fi
}

# =============================================================================
# EXECUÇÃO PRINCIPAL
# =============================================================================

# Verificar se o script está sendo executado como root
if [[ $EUID -eq 0 ]]; then
    log_error "Este script não deve ser executado como root"
    echo "Execute como usuário pi: sudo -u pi $0"
    exit 1
fi

# Executar função principal
main "$@"
