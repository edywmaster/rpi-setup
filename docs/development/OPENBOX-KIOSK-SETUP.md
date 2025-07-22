# Configuração do Ambiente Openbox para Kiosk

## Visão Geral

Esta documentação descreve a implementação da configuração automática do ambiente gráfico Openbox no sistema de kiosk Raspberry Pi. A funcionalidade foi adicionada ao script `setup-kiosk.sh` para fornecer um ambiente gráfico completo e otimizado para aplicações kiosk.

## Funcionalidades Implementadas

### 1. Instalação Automática do Openbox

O sistema agora instala automaticamente:

- **Openbox**: Window manager leve e configurável
- **Unclutter**: Para ocultar o cursor do mouse
- **Xorg**: Sistema de janelas X11
- **xserver-xorg-legacy**: Servidor X legacy
- **x11-xserver-utils**: Utilitários essenciais do X11

### 2. Configuração do Autostart

O script cria automaticamente `/home/pi/.config/openbox/autostart` com:

```bash
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

# Iniciar o navegador em modo kiosk
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences
chromium --kiosk $KIOSK_APP_URL --noerrdialogs --disable-infobars --disable-translate --disable-features=Translate --start-fullscreen &
```

### 3. Configuração do .xinitrc

O sistema configura automaticamente o arquivo `.xinitrc` para:

- Iniciar o Openbox automaticamente com `exec openbox-session`
- Garantir que o ambiente gráfico seja iniciado corretamente

### 4. Script de Inicialização Melhorado

O novo `start.sh` inclui:

#### Função `load_kiosk_config()`

```bash
load_kiosk_config() {
    # Verificar se /etc/environment existe
    if [[ ! -f /etc/environment ]]; then
        echo "⚠️ Arquivo /etc/environment não encontrado"
        return 1
    fi

    # Carregar apenas variáveis KIOSK exportadas
    set -a  # Exportar todas as variáveis definidas
    source <(grep '^export KIOSK_' /etc/environment 2>/dev/null || true)
    set +a  # Desativar exportação automática

    echo "✅ Configurações KIOSK carregadas de /etc/environment"
}
```

#### Função `show_kiosk_vars()`

```bash
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
```

#### Diferenciação SSH vs Local

```bash
# Verificar se o script está sendo executado via SSH
if [ -n "$SSH_CONNECTION" ]; then
  ssh_start
else
  kiosk_start
fi
```

## Estrutura de Arquivos

```
/home/pi/
├── .config/
│   ├── openbox/
│   │   └── autostart          # Script de autostart do Openbox
│   └── chromium/
│       └── Default/
│           └── Preferences    # Configurações do Chromium
└── .xinitrc                   # Configuração do X11

/opt/kiosk/
└── scripts/
    └── start.sh               # Script principal de inicialização
```

## Fluxo de Inicialização

1. **Sistema inicia** → Serviço `kiosk-start.service`
2. **start.sh executa** → Carrega configurações do ambiente
3. **startx inicia** → Ambiente gráfico X11
4. **Openbox carrega** → Window manager
5. **autostart executa** → Configurações e aplicações

### Fluxo Detalhado do Autostart

1. **Aguarda display** → Verifica disponibilidade do DISPLAY=:0
2. **Inicia unclutter** → Remove cursor do mouse
3. **Configura energia** → Desabilita screensaver e gerenciamento de energia
4. **Limpa histórico** → Remove flags de crash do Chromium
5. **Inicia kiosk** → Chromium em modo fullscreen

## Otimizações para Kiosk

### Gerenciamento de Energia

- `xset s off` - Desabilita screensaver
- `xset -dpms` - Desabilita gerenciamento de energia DPMS
- `xset s noblank` - Evita tela em branco

### Chromium Otimizado

- `--kiosk` - Modo kiosk fullscreen
- `--noerrdialogs` - Remove diálogos de erro
- `--disable-infobars` - Remove barras de informação
- `--disable-translate` - Desabilita tradução automática
- `--start-fullscreen` - Inicia em tela cheia

### Cursor do Mouse

- `unclutter -idle 0.5 -root` - Oculta cursor após 0.5s de inatividade

## Detecção de Ambiente

O script `start.sh` diferencia entre:

### Execução Local (Kiosk)

- Carrega configurações completas
- Exibe variáveis do sistema
- Aguarda 15 segundos para leitura
- Inicia ambiente gráfico
- Executa autostart do Openbox

### Execução SSH (Remota)

- Carrega apenas configurações básicas
- Exibe mensagem simples
- Sai imediatamente
- Não inicia ambiente gráfico

## Integração com o Sistema

### Adição ao Fluxo Principal

O novo passo `setup_openbox_environment` foi adicionado ao fluxo principal:

```bash
# Setup process
setup_kiosk_directories
configure_kiosk_variables
setup_print_server
setup_splash_screen
setup_openbox_environment  # ← Nova funcionalidade
setup_startup_service
configure_services
```

### Estado e Rastreamento

- Novo estado `openbox_setup` na lista `INSTALLATION_STEPS`
- Suporte completo ao sistema de rastreamento de estado
- Permite retomada da instalação em caso de interrupção

## Permissões e Segurança

### Permissões de Arquivo

- `/home/pi/.config/openbox/autostart` → 755 (pi:pi)
- `/home/pi/.xinitrc` → 644 (pi:pi)
- `/opt/kiosk/scripts/start.sh` → 755 (pi:pi)

### Criação de Diretórios

- Criação automática de diretórios necessários
- Configuração correta de propriedade (pi:pi)
- Permissões apropriadas para execução

## Resumo no Final da Instalação

O sistema agora exibe informações completas sobre o Openbox:

```
🖥️ Ambiente Gráfico (Openbox):
   • Window Manager: Openbox instalado e configurado
   • Autostart: /home/pi/.config/openbox/autostart
   • .xinitrc: /home/pi/.xinitrc
   • Unclutter: Para ocultar cursor do mouse
   • Configurações de energia: Desabilitadas para kiosk
   • Navegador: Chromium em modo kiosk fullscreen
```

## Variáveis de Ambiente

O sistema utiliza a variável `KIOSK_APP_URL` definida em `/etc/environment` para:

- Configurar a URL da aplicação no Chromium
- Permitir configuração flexível sem modificar código
- Integrar com o sistema de variáveis do kiosk

## Benefícios da Implementação

1. **Automatização Completa**: Não requer configuração manual
2. **Otimização para Kiosk**: Configurações específicas para uso em kiosk
3. **Robustez**: Tratamento de erros e verificações
4. **Flexibilidade**: Configurável através de variáveis de ambiente
5. **Manutenibilidade**: Código organizado e documentado
6. **Rastreabilidade**: Sistema de estados para recuperação

## Testes e Validação

A implementação inclui teste automatizado (`test-openbox-setup.sh`) que valida:

- Sintaxe e estrutura do código
- Integração no fluxo principal
- Conteúdo dos scripts gerados
- Instalação de dependências
- Informações no resumo de conclusão

Este sistema garante que o ambiente Openbox seja configurado corretamente e funcione de forma otimizada para aplicações kiosk em Raspberry Pi.
