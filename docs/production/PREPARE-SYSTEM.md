# Script de Preparação do Sistema - prepare-system.sh

## Visão Geral

Script de preparação inicial para Raspberry Pi OS Lite que automatiza:

- Atualização completa do sistema
- Instalação de pacotes essenciais para sistemas kiosk/display
- Validações de ambiente e conectividade
- Logging abrangente de todas as operações

## Pacotes Instalados

O script instala os seguintes pacotes essenciais:

### Ferramentas de Sistema

- `wget` - Ferramenta de download
- `curl` - Cliente HTTP
- `jq` - Processador JSON
- `lsof` - Lista arquivos abertos
- `unzip` - Extração de arquivos

### Sistema Gráfico e Display

- `fbi` - Visualizador de imagens no framebuffer
- `xserver-xorg` - Servidor X11
- `x11-xserver-utils` - Utilitários X11
- `dbus-x11` - Integração D-Bus com X11
- `xinit` - Inicialização do X11
- `openbox` - Gerenciador de janelas leve
- `chromium-browser` - Navegador web
- `unclutter` - Oculta cursor do mouse
- `imagemagick` - Manipulação de imagens

### Desenvolvimento e Suporte

- `python3-pyxdg` - Suporte XDG para Python
- `libgbm-dev` - Gerenciador de buffer gráfico
- `libasound2` - Biblioteca de som ALSA
- `build-essential` - Ferramentas de compilação

## Como Usar

### Pré-requisitos

- Raspberry Pi com Raspberry Pi OS Lite (Debian 12 "bookworm")
- Acesso root (sudo)
- Conexão com internet ativa

### Execução Direta do GitHub (Recomendado)

Para executar o script diretamente do repositório em qualquer Raspberry Pi:

```bash
# Comando único - execução direta
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash
```

### Execução Local

```bash
# Baixar e verificar antes de executar
wget https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh
less prepare-system.sh  # Verificar conteúdo (opcional)
chmod +x prepare-system.sh
sudo ./prepare-system.sh

# Ou clonar o repositório completo
git clone https://github.com/edywmaster/rpi-setup.git
cd rpi-setup
sudo ./prepare-system.sh
```

### Execução em Múltiplos Dispositivos

#### Via SSH (Comando Direto)

```bash
# Executar em dispositivo remoto via SSH
ssh pi@192.168.1.100 "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
```

#### Script de Implantação em Lote

Crie um arquivo `deploy-multiple.sh`:

```bash
#!/bin/bash
# Lista de IPs dos dispositivos Raspberry Pi
DEVICES=(
    "192.168.1.100"
    "192.168.1.101"
    "192.168.1.102"
)

SCRIPT_URL="https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh"

for device in "${DEVICES[@]}"; do
    echo "🔧 Configurando dispositivo: $device"

    if ssh -o ConnectTimeout=5 pi@$device "echo 'Conectado'" 2>/dev/null; then
        ssh pi@$device "curl -fsSL $SCRIPT_URL | sudo bash"
        echo "✅ $device - Configuração concluída"
    else
        echo "❌ $device - Falha na conexão SSH"
    fi

    echo "----------------------------------------"
done
```

Execute com:

```bash
chmod +x deploy-multiple.sh
./deploy-multiple.sh
```

## Funcionalidades

### ✅ Validações Automáticas

- Verifica privilégios de root
- Detecta modelo do Raspberry Pi
- Testa conectividade com internet
- Previne execução simultânea (lock file)

### 📊 Logging Abrangente

- Logs coloridos no terminal
- Arquivo de log persistente: `/var/log/rpi-preparation.log`
- Timestamps em todas as operações
- Relatório final de instalação

### 🔄 Operações Idempotentes

- Pode ser executado múltiplas vezes
- Detecta pacotes já instalados
- Não quebra em re-execuções

### 🛡️ Tratamento de Erros

- Verificação de sucesso de cada operação
- Relatório de pacotes que falharam
- Instruções para correção manual

## Estrutura do Script

```
├── Validações iniciais
│   ├── Verificação de privilégios
│   ├── Detecção do hardware
│   └── Teste de conectividade
├── Preparação do sistema
│   ├── Atualização de listas
│   ├── Upgrade do sistema
│   └── Instalação de pacotes
├── Limpeza
└── Relatório final
```

## Logs e Debugging

### Arquivo de Log

```bash
# Visualizar logs em tempo real
tail -f /var/log/rpi-preparation.log

# Buscar erros específicos
grep "ERROR" /var/log/rpi-preparation.log
```

### Informações do Sistema

O script automaticamente detecta e registra:

- Modelo do Raspberry Pi
- Versão do sistema operacional
- Status de conectividade
- Resultado de cada instalação

## Resolução de Problemas

### Conectividade

Se houver problemas de rede:

```bash
# Testar conectividade DNS
nslookup google.com

# Verificar configuração de rede
ip route show
```

### Repositórios

Se houver problemas com repositórios:

```bash
# Verificar sources.list
cat /etc/apt/sources.list

# Atualizar manualmente
sudo apt-get update
```

### Pacotes Específicos

Para instalar pacotes que falharam:

```bash
# Instalar individualmente
sudo apt-get install nome-do-pacote

# Verificar dependências
apt-cache depends nome-do-pacote
```

## Próximos Passos

Após a execução bem-sucedida, você pode:

1. Configurar serviços específicos (SSH, firewall, etc.)
2. Instalar software adicional conforme necessário
3. Configurar ambiente gráfico para aplicações kiosk
4. Implementar scripts de monitoramento

## Compatibilidade

- **Testado**: Raspberry Pi 4B com Pi OS Lite
- **Suportado**: Outros modelos de Raspberry Pi
- **Requerido**: Debian 12 "bookworm" ou superior
