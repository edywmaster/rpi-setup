# System Info Utility - Guia de Uso

> **📋 Versão**: v1.3.1 | **Utilitário**: system-info.sh | **Atualizado em**: 2025-07-21

## Visão Geral

O utilitário `system-info.sh` é uma ferramenta de diagnóstico que exibe informações abrangentes sobre o sistema Raspberry Pi e o status das configurações de automação instaladas.

## 🚀 Execução Rápida

### Local (após clone do repositório)

```bash
./utils/system-info.sh
```

### Remoto (execução direta)

```bash
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/utils/system-info.sh | bash
```

## 📊 Informações Exibidas

### 1. Informações do Sistema

- **Hardware**: Modelo do Raspberry Pi, Serial/Device ID
- **Sistema**: Hostname, arquitetura, kernel, SO
- **Recursos**: CPU cores, memória RAM, uso do disco
- **Status**: Tempo ativo, data/hora atual
- **Display**: Configuração do DISPLAY

### 2. Status do Setup de Preparação

- **Status de execução**: Se o `prepare-system.sh` foi executado
- **Última execução**: Timestamp da última execução
- **Dependências instaladas**:
  - Node.js (versão)
  - PM2 (status de instalação)
  - CUPS (sistema de impressão)
- **Logs**: Localização e tamanho dos arquivos de log

### 3. Status do Setup do Kiosk

- **Status de execução**: Se o `setup-kiosk.sh` foi executado
- **Estrutura de diretórios**: Verificação do `/opt/kiosk/`
- **Serviços systemd**:
  - `kiosk-splash.service`
  - `kiosk-start.service`
  - `kiosk-print-server.service`
- **Estado dos serviços**: Instalado, habilitado, ativo/inativo

### 4. Variáveis de Ambiente

- **Configuração do kiosk**: Arquivo `/opt/kiosk/kiosk.conf`
- **Variáveis do sistema**: PATH, USER, HOME
- **Configurações específicas**:
  - KIOSK_CONNECTION
  - KIOSK_NETWORK_URL
  - KIOSK_ONLINE_URL
  - KIOSK_APP_URL

### 5. Informações de Rede

- **Endereços IP**: Todos os IPs ativos do sistema
- **Conectividade**: Teste de conexão com a internet
- **Interfaces**: Lista de interfaces de rede ativas

### 6. Status do Hardware

- **Temperatura da CPU**: Monitoramento térmico
- **Throttling**: Status de limitação por temperatura/voltagem
- **GPU Memory**: Memória alocada para GPU

## 🖥️ Exemplo de Saída

```
     ██████╗ ██████╗ ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗
     ██╔══██╗██╔══██╗██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
     ██████╔╝██████╔╝██║    ███████╗█████╗     ██║   ██║   ██║██████╔╝
     ██╔══██╗██╔═══╝ ██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
     ██║  ██║██║     ██║    ███████║███████╗   ██║   ╚██████╔╝██║
     ╚═╝  ╚═╝╚═╝     ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝
     ╔══════════════════════════════════════════════════════╗
     ║         RASPBERRY PI AUTOMATION SETUP                 ║
     ╚══════════════════════════════════════════════════════╝
                   RPI SETUP V1.2.0

# Informações do Sistema
--------------------------------------------------------
Hostname: raspberrypi
Modelo: Raspberry Pi 4 Model B Rev 1.4
Device ID: 10000000b827eb01
Arquitetura: aarch64
Sistema: Raspbian GNU/Linux 12 (bookworm)
Kernel: 6.6.31+v8
Processadores: 4
Memória RAM: 7.6Gi
Uso do disco: 25%
Tempo ativo: up 2 days, 14:32
Data e hora: Mon 21 Jul 2025 15:30:45 -03
Display: DISPLAY=:0
```

## 🔧 Casos de Uso

### 1. Verificação Pós-Instalação

Após executar `prepare-system.sh` ou `setup-kiosk.sh`:

```bash
./utils/system-info.sh
```

Verifica se todos os componentes foram instalados corretamente.

### 2. Diagnóstico de Problemas

Para troubleshooting de serviços ou configurações:

```bash
./utils/system-info.sh | grep -E "(❌|🔴|⚠️)"
```

Filtra apenas problemas identificados.

### 3. Monitoramento Remoto

Para verificar status de múltiplos dispositivos:

```bash
# Criar script de monitoramento
for ip in 192.168.1.{100..110}; do
    echo "=== Checking $ip ==="
    ssh pi@$ip "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/utils/system-info.sh | bash"
done
```

### 4. Relatórios de Sistema

Para gerar relatórios de status:

```bash
./utils/system-info.sh > system-report-$(date +%Y%m%d-%H%M%S).txt
```

## 🔍 Interpretação dos Status

### Códigos de Status

- **✅ (Verde)**: Configurado e funcionando corretamente
- **❌ (Vermelho)**: Não instalado ou não encontrado
- **⚠️ (Amarelo)**: Instalado mas com problemas ou limitações
- **🟢 (Verde)**: Serviço ativo
- **🔴 (Vermelho)**: Serviço falhou

### Status de Serviços

- **Instalado**: Serviço existe no systemd
- **Habilitado**: Serviço configurado para iniciar no boot
- **Ativo**: Serviço está executando atualmente
- **Falhou**: Serviço tentou iniciar mas falhou

## 🛠️ Limitações no Desenvolvimento

O script é desenvolvido no macOS mas direcionado para Linux. Algumas funcionalidades mostrarão limitações quando executado no ambiente de desenvolvimento:

- **systemctl**: Não disponível no macOS
- **vcgencmd**: Comando específico do Raspberry Pi
- **/proc files**: Estrutura diferente entre macOS e Linux
- **Hardware info**: Informações específicas do Pi não disponíveis

Todas essas funcionalidades estarão disponíveis quando executado no Raspberry Pi.

## 📝 Logs e Arquivos Importantes

### Logs do Sistema

- `/var/log/rpi-preparation.log` - Log do script de preparação
- `/var/log/kiosk-setup.log` - Log do setup do kiosk

### Arquivos de Estado

- `/var/lib/rpi-preparation-state` - Estado da preparação do sistema
- `/var/lib/kiosk-setup-state` - Estado do setup do kiosk

### Configurações

- `/opt/kiosk/kiosk.conf` - Configuração principal do kiosk
- `/etc/environment` - Variáveis de ambiente globais

## 🚨 Troubleshooting

### Problema: Script não executa

```bash
# Verificar permissões
ls -la utils/system-info.sh
chmod +x utils/system-info.sh
```

### Problema: Informações incompletas

```bash
# Executar com sudo para acessar mais informações do sistema
sudo ./utils/system-info.sh
```

### Problema: Serviços não detectados

```bash
# Verificar se systemctl está disponível
command -v systemctl && echo "systemctl disponível" || echo "systemctl não encontrado"

# Listar todos os serviços
systemctl list-unit-files | grep kiosk
```

## 🔗 Integração com Outros Scripts

O `system-info.sh` pode ser integrado com outros scripts de automação:

```bash
#!/bin/bash
# Script de verificação automatizada

echo "Verificando status do sistema..."
./utils/system-info.sh

if ./utils/system-info.sh | grep -q "❌.*Node.js"; then
    echo "Node.js não encontrado, executando preparação..."
    sudo ./prepare-system.sh
fi
```

---

**Versão deste guia**: v1.3.1 | **Utilitário**: system-info.sh | **Sistema base**: prepare-system.sh v1.3.1 | **Atualizado em**: 2025-07-21
