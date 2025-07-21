# Uninstall Script - Print Server Integration

## Overview

O script de desinstalação (`dist/kiosk/scripts/uninstall.sh`) foi atualizado para incluir a remoção completa dos componentes do servidor de impressão implementados no sistema kiosk.

## Componentes Adicionados

### 1. Constantes e Variáveis

Adicionadas novas constantes para o servidor de impressão:

```bash
# Service files
readonly PRINT_SERVER_SERVICE_PATH="/etc/systemd/system/kiosk-print-server.service"

# Print server directories and files
readonly KIOSK_TEMP_DIR="/tmp/kiosk"
readonly PRINT_SERVER_LOG="/var/log/kiosk-print-server.log"
readonly PRINTER_SCRIPT_LOG="/var/log/kiosk-printer.log"
```

### 2. Remoção de Serviços

A função `remove_kiosk_services()` foi expandida para incluir:

- **kiosk-print-server.service**: Parada, desabilitação e remoção do serviço systemd
- Remoção do arquivo de serviço `/etc/systemd/system/kiosk-print-server.service`
- Logs detalhados de cada etapa do processo

### 3. Nova Função: remove_print_server_processes()

Implementada função dedicada para remoção de processos relacionados ao servidor de impressão:

#### Funcionalidades:

- **Limpeza PM2**: Remove processos PM2 relacionados ao servidor de impressão

  - `kiosk-print-server`
  - `print-server`
  - `kiosk-print`

- **Limpeza de Porta**: Identifica e encerra processos rodando na porta de impressão (50001)

  - Usa `lsof -ti:porta` para identificar PIDs
  - Encerra graciosamente com SIGTERM
  - Força encerramento com SIGKILL se necessário

- **Limpeza de Processos print.js**: Remove qualquer processo Node.js executando print.js

### 4. Remoção de Diretórios

Adicionado à lista de diretórios para remoção:

```bash
"$KIOSK_TEMP_DIR"  # /tmp/kiosk
```

### 5. Remoção de Logs

A função `remove_setup_status()` foi expandida para remover:

- `/var/log/kiosk-print-server.log` - Log do servidor Node.js
- `/var/log/kiosk-printer.log` - Log do script Python

### 6. Variáveis de Ambiente

Expandida a lista de variáveis de ambiente para remoção:

```bash
"KIOSK_PRINT_PORT"
"KIOSK_PRINT_HOST"
"KIOSK_PRINT_URL"
"KIOSK_PRINT_SERVER"
"KIOSK_PRINT_SCRIPT"
"KIOSK_PRINT_TEMP"
"KIOSK_SCRIPTS_DIR"
"KIOSK_SERVER_DIR"
"KIOSK_UTILS_DIR"
"KIOSK_TEMPLATES_DIR"
```

### 7. Mensagens Atualizadas

#### Aviso de Confirmação:

```
• Serviços do systemd (kiosk-splash, kiosk-start, kiosk-print-server)
• Processos Node.js e PM2 do servidor de impressão
• Logs do servidor de impressão
```

#### Resumo da Desinstalação:

```
• Serviços removidos: kiosk-splash.service, kiosk-start.service, kiosk-print-server.service
• Logs do servidor removidos: /var/log/kiosk-print-server.log, /var/log/kiosk-printer.log
• Diretórios removidos: /opt/kiosk, /tmp/kiosk
```

## Fluxo de Execução

1. **remove_print_server_processes()** - Remove processos ativos
2. **remove_kiosk_services()** - Remove serviços systemd
3. **remove_kiosk_directories()** - Remove diretórios e arquivos
4. **remove_setup_status()** - Remove logs e configurações
5. **remove_environment_variables()** - Limpa variáveis de ambiente

## Compatibilidade

- ✅ Compatível com versões anteriores (não quebra funcionalidade existente)
- ✅ Failsafe: Funciona mesmo se componentes não estiverem instalados
- ✅ Logs detalhados para troubleshooting
- ✅ Modo não-interativo para execução remota

## Uso

```bash
# Local
sudo ./uninstall.sh

# Local (forçado)
sudo ./uninstall.sh --force

# Remoto
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/dist/kiosk/scripts/uninstall.sh | sudo bash -s -- --force
```

## Validação

Implementado script de teste (`tests/test-uninstall-print-server.sh`) que valida:

- ✅ Presença de todas as constantes necessárias
- ✅ Implementação da função de remoção de processos
- ✅ Integração na função main
- ✅ Sintaxe correta do script
- ✅ Permissões de execução

## Logs

Durante a execução, todos os logs são gravados em `/var/log/kiosk-uninstall.log` para auditoria e troubleshooting.
