# Script de Preparação do Sistema - prepare-system.sh

> **📋 Versão**: v1.3.1 | **Atualizado em**: 2025-07-21 | **Status**: Produção Estável

## Visão Geral

Script de preparação inicial para Raspberry Pi OS Lite que automatiza:

- Atualização completa do sistema
- Instalação de pacotes essenciais para sistemas kiosk/display
- **Node.js LTS**: Instalação e configuração global
- **PM2**: Gerenciador de processos para aplicações Node.js
- **CUPS**: Sistema de impressão com interface web
- **Autologin**: Configuração automática para usuário 'pi'
- **Boot otimizado**: Configurações para sistemas kiosk/display
- Validações de ambiente e conectividade
- Sistema de recuperação após interrupções
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

### Sistemas Avançados (v1.2.0)

- **Node.js LTS (v22.13.1)** - Ambiente JavaScript no servidor
  - Instalação global com npm e npx
  - Detecção automática de arquitetura (ARM64, ARMv7, x64)
  - Configuração de permissões globais
- **PM2** - Gerenciador de processos Node.js
  - Instalação global para todos os usuários
  - Configuração para usuário 'pi'
  - Comandos de processo management
- **CUPS** - Sistema de impressão
  - Interface web em http://ip:631
  - Acesso remoto configurado
  - Usuário 'pi' adicionado ao grupo lpadmin
  - Discovery automático desabilitado para segurança

## Como Usar

### Pré-requisitos

- Raspberry Pi com Raspberry Pi OS Lite (Debian 12 "bookworm")
- Acesso root (sudo)
- Conexão com internet ativa

## 🔄 Detecção de Interrupções e Recuperação

**Novo na versão 1.0.4**: O script agora possui um sistema robusto de detecção de interrupções que permite recuperação automática após falhas inesperadas.

### Como Funciona

O script rastreia automaticamente o progresso da instalação em 7 etapas:

1. **Validação** - Verificações iniciais do sistema
2. **Atualização de Listas** - `apt update`
3. **Upgrade do Sistema** - `apt upgrade`
4. **Configuração de Locales** - Configuração de idioma
5. **Instalação de Pacotes** - Instalação dos 18 pacotes essenciais
6. **Limpeza** - Remoção de pacotes desnecessários
7. **Finalização** - Exibição do sumário final

### Cenários de Interrupção

O sistema detecta automaticamente interrupções causadas por:

- 🔌 **Perda de energia** - Queda de energia durante a instalação
- 🔄 **Desligamento acidental** - Reinicialização inesperada do sistema
- ❌ **Falhas de rede** - Perda de conectividade durante download
- ⚠️ **Erros críticos** - Falhas que interrompem o processo

### Interface de Recuperação

Quando uma interrupção é detectada, o script exibe:

```
⚠️  INTERRUPÇÃO DETECTADA!
Uma instalação anterior foi interrompida:
   • Última etapa: package_install
   • Data/Hora: 2025-01-20 14:30:45
   • Status: Incompleta

📦 A instalação foi interrompida durante a instalação de pacotes
   ⚠️  Alguns pacotes podem estar parcialmente instalados

🔧 Opções disponíveis:
   1️⃣  Continuar instalação (recomendado)
   2️⃣  Reiniciar do zero
   3️⃣  Cancelar

Escolha uma opção (1/2/3):
```

### Benefícios da Recuperação

- ⚡ **Economia de Tempo**: Evita refazer etapas já concluídas
- 🛡️ **Segurança**: Evita corrupção por reinstalações desnecessárias
- 📊 **Transparência**: Mostra exatamente onde parou
- 🎯 **Flexibilidade**: Permite escolher entre continuar ou reiniciar

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

### Arquivos do Sistema

O script mantém controle através de arquivos específicos:

```bash
# Log principal - todas as operações
/var/log/rpi-preparation.log

# Estado da instalação - para recuperação
/var/lib/rpi-preparation-state

# Lock file - previne execuções simultâneas
/tmp/rpi-preparation.lock
```

### Visualizando Logs

```bash
# Visualizar logs em tempo real
tail -f /var/log/rpi-preparation.log

# Buscar erros específicos
grep "ERROR" /var/log/rpi-preparation.log

# Ver progresso da instalação atual
grep "SUCCESS\|INFO" /var/log/rpi-preparation.log | tail -10
```

### Verificando Estado de Recuperação

```bash
# Ver estado atual da instalação
sudo cat /var/lib/rpi-preparation-state

# Exemplo de conteúdo:
# LAST_STEP=package_install
# TIMESTAMP=2025-01-20 14:30:45
# PID=1234
# STATUS=running
```

### Limpeza Manual

Se necessário, limpe o estado manualmente:

```bash
# Remover estado de instalação (força reinício)
sudo rm -f /var/lib/rpi-preparation-state

# Remover lock file órfão
sudo rm -f /tmp/rpi-preparation.lock
```

### Informações do Sistema

O script automaticamente detecta e registra:

- Modelo do Raspberry Pi
- Versão do sistema operacional
- Status de conectividade
- Resultado de cada instalação
- Estado de recuperação (se aplicável)

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

## Verificação Pós-Instalação

### Verificar Node.js e npm

```bash
# Verificar versão do Node.js
node --version
# Saída esperada: v22.13.1

# Verificar npm
npm --version

# Verificar npx
npx --version

# Testar instalação global
npm list -g --depth=0
```

### Verificar PM2

```bash
# Verificar versão do PM2
pm2 --version

# Verificar status (deve estar vazio inicialmente)
pm2 status

# Verificar se está acessível globalmente
which pm2
# Saída esperada: /usr/bin/pm2
```

### Verificar CUPS

```bash
# Verificar status do serviço
sudo systemctl status cups

# Verificar se usuário pi está no grupo lpadmin
groups pi | grep lpadmin

# Testar interface web (substituir por IP real)
curl -I http://localhost:631
```

### Verificar Autologin

```bash
# Verificar configuração do serviço
sudo systemctl status getty@tty1.service

# Verificar arquivo de configuração
cat /etc/systemd/system/getty@tty1.service.d/override.conf
```

### Verificar Configurações de Boot

```bash
# Verificar config.txt
grep -E "disable_splash|boot_delay_ms|disable_overscan" /boot/firmware/config.txt

# Verificar cmdline.txt
cat /boot/firmware/cmdline.txt | grep -o "quiet\|splash\|plymouth"
```

## Próximos Passos

Após a execução bem-sucedida, você pode:

1. **Instalar Sistema Kiosk**: Execute `setup-kiosk.sh` para interface touchscreen
2. **Configurar aplicações Node.js**: Use PM2 para gerenciar processos
3. **Configurar impressoras**: Acesse http://ip:631 para adicionar impressoras
4. **Desenvolver aplicações**: Use Node.js/npm para projetos personalizados
5. Configurar serviços específicos (SSH, firewall, etc.)
6. Implementar scripts de monitoramento

## Compatibilidade

- **Testado**: Raspberry Pi 4B com Pi OS Lite
- **Suportado**: Outros modelos de Raspberry Pi
- **Requerido**: Debian 12 "bookworm" ou superior

---

**Versão deste manual**: v1.3.1 | **Script**: prepare-system.sh v1.3.1 | **Última atualização**: 2025-07-21
