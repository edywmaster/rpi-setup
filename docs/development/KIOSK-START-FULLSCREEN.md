# Kiosk Start Fullscreen - Script de Inicialização

## Visão Geral

O `kiosk-start-fullscreen.sh` é um script avançado para inicialização de kiosks com Chromium em tela cheia, desenvolvido como parte do Raspberry Pi Setup Automation Suite. Este script combina e aprimora as funcionalidades dos scripts `openbox.sh`, `autostart.sh` e `start.sh` existentes.

## Características Principais

### 🚀 Funcionalidades Core

- **Tela Cheia Completa**: Chromium otimizado para ocupar toda a tela
- **Configuração Automática**: Setup automático do Openbox e ambiente X11
- **Gestão de Configurações**: Carregamento automático de variáveis de ambiente
- **Detecção SSH**: Comportamento diferente quando executado via SSH
- **Logging Completo**: Registros detalhados de todas as operações

### 🎯 Otimizações para Kiosk

- **Cursor Invisível**: Desabilitação automática do cursor do mouse
- **Economia de Energia**: Configuração de energia otimizada para kiosks
- **Recuperação de Crash**: Limpeza automática de flags de crash do Chromium
- **Modo Incógnito**: Navegação sem histórico ou cache persistente

## Requisitos do Sistema

### Hardware

- Raspberry Pi (qualquer modelo com suporte a X11)
- Pelo menos 1GB de RAM recomendado
- Resolução mínima de 1024x768

### Software

- Raspberry Pi OS Lite (Debian 12 "bookworm") ou superior
- X11 Server (`xserver-xorg`)
- Openbox (`openbox`)
- Chromium Browser (`chromium-browser`)
- Utilitários: `xinit`, `unclutter` (recomendado)

## Instalação e Configuração

### 1. Preparar o Sistema

Primeiro, execute o script de preparação do sistema:

```bash
# Clonar o repositório (se ainda não foi feito)
git clone https://github.com/edywmaster/rpi-setup.git
cd rpi-setup

# Executar preparação do sistema
sudo ./prepare-system.sh

# Configurar o kiosk
sudo ./scripts/setup-kiosk.sh
```

### 2. Configurar Variáveis de Ambiente

Edite o arquivo `/etc/environment` e adicione as configurações do kiosk:

```bash
sudo nano /etc/environment
```

Adicione as seguintes linhas:

```bash
# Configurações do Kiosk
export KIOSK_APP_URL="https://sua-aplicacao-kiosk.com"
export KIOSK_DISPLAY=":0"
export KIOSK_RESOLUTION="1920x1080"
```

### 3. Instalar o Script

Copie o script para o diretório do sistema:

```bash
# Copiar script para local do sistema
sudo cp scripts/kiosk-start-fullscreen.sh /opt/kiosk/scripts/
sudo chmod +x /opt/kiosk/scripts/kiosk-start-fullscreen.sh
sudo chown pi:pi /opt/kiosk/scripts/kiosk-start-fullscreen.sh
```

## Uso do Script

### Modo Interativo

Execute diretamente no Raspberry Pi:

```bash
# Iniciar kiosk normalmente
./kiosk-start-fullscreen.sh

# Apenas configurar Openbox (sem iniciar)
./kiosk-start-fullscreen.sh --setup-only

# Apenas validar ambiente
./kiosk-start-fullscreen.sh --validate-only
```

### Modo SSH

Quando executado via SSH, o script entra em modo de informação:

```bash
ssh pi@raspberry-ip
./kiosk-start-fullscreen.sh
# Exibe informações sem iniciar interface gráfica
```

### Como Serviço Systemd

Para inicialização automática, configure como serviço:

```bash
# Criar arquivo de serviço
sudo tee /etc/systemd/system/kiosk-fullscreen.service > /dev/null << EOF
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
EOF

# Habilitar e iniciar serviço
sudo systemctl daemon-reload
sudo systemctl enable kiosk-fullscreen.service
sudo systemctl start kiosk-fullscreen.service
```

## Configurações Avançadas

### Opções do Chromium

O script usa as seguintes opções otimizadas para kiosk:

```bash
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
    "$KIOSK_APP_URL"
```

### Personalização do Autostart

O script cria automaticamente um arquivo `autostart` para o Openbox. Para personalizar:

```bash
# Editar configuração do Openbox
nano ~/.config/openbox/autostart
```

### Configurações de Energia

Para otimizar a configuração de energia:

```bash
# Adicionar ao autostart
xset s off          # Desabilitar screen saver
xset -dpms          # Desabilitar power management
xset s noblank      # Não apagar tela
```

## Solução de Problemas

### Problemas Comuns

**1. Chromium não inicia em tela cheia**

```bash
# Verificar variáveis de ambiente
./kiosk-start-fullscreen.sh --validate-only

# Verificar configuração do Openbox
ls -la ~/.config/openbox/
cat ~/.config/openbox/autostart
```

**2. Erro de permissões**

```bash
# Corrigir permissões
sudo chown -R pi:pi ~/.config/
sudo chmod -R 755 ~/.config/
```

**3. X11 não inicia**

```bash
# Verificar instalação do X11
dpkg -l | grep xserver-xorg

# Verificar configuração do usuário
cat ~/.xinitrc
```

**4. Variáveis de ambiente não carregadas**

```bash
# Verificar arquivo de configuração
cat /etc/environment | grep KIOSK

# Testar carregamento manual
source /etc/environment
env | grep KIOSK
```

### Logs e Diagnóstico

```bash
# Visualizar logs do script
sudo tail -f /var/log/kiosk-start.log

# Verificar logs do sistema
journalctl -u kiosk-fullscreen.service -f

# Verificar processos em execução
ps aux | grep -E "(chromium|openbox|X)"
```

## Monitoramento e Manutenção

### Status do Sistema

```bash
# Verificar status do serviço
systemctl status kiosk-fullscreen.service

# Verificar uso de recursos
htop

# Verificar conectividade
ping -c 3 google.com
```

### Atualizações

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade

# Atualizar script
cd rpi-setup
git pull origin main
sudo cp scripts/kiosk-start-fullscreen.sh /opt/kiosk/scripts/
```

## Integração com Outros Scripts

### Com o Setup Kiosk Principal

```bash
# O script pode ser integrado ao setup-kiosk.sh
# Adicionando a seguinte linha na função de configuração:
cp "$SCRIPT_DIR/kiosk-start-fullscreen.sh" "$KIOSK_SCRIPTS_DIR/"
```

### Com Sistema de Monitoramento

```bash
# Integrar com system-info.sh para monitoramento
./utils/system-info.sh --kiosk-status
```

## Compatibilidade

- ✅ Raspberry Pi OS Lite (Debian 12 "bookworm")
- ✅ Raspberry Pi OS Desktop (Debian 12 "bookworm")
- ✅ Raspberry Pi 3B+, 4B, 5, Zero 2W
- ✅ Resolução 1080p, 4K
- ⚠️ Testado principalmente em arquitetura ARM64

## Segurança

### Considerações de Segurança

- **Sandbox Desabilitado**: Para compatibilidade com hardware limitado
- **Modo Incógnito**: Não persiste dados de navegação
- **Usuário Não-Root**: Execução como usuário `pi`
- **Logs Auditáveis**: Todas as operações são registradas

### Recomendações

1. **Firewall**: Configure iptables para restringir acesso
2. **SSH**: Desabilite SSH em produção se não necessário
3. **Atualizações**: Mantenha o sistema sempre atualizado
4. **Backups**: Configure backups automáticos das configurações

## Suporte e Contribuição

- **Repositório**: [github.com/edywmaster/rpi-setup](https://github.com/edywmaster/rpi-setup)
- **Issues**: Reporte problemas na seção Issues do GitHub
- **Versão**: 1.4.3
- **Compatibilidade**: Raspberry Pi Setup Automation Suite

---

**Nota**: Este documento faz parte do Raspberry Pi Setup Automation Suite versão 1.4.3. Para documentação completa do projeto, consulte o [README principal](../../README.md).
