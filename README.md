# rpi-setup 🚀

Automação completa para Raspberry Pi OS Lite - Configure múltiplos dispositivos com um único comando.

> **📋 Versão Atual**: v1.3.1 | **Última Atualização**: 2025-07-21 | **🆕 Sistema de Versionamento Centralizado**

## ⚡ Execução Rápida

Execute este comando em qualquer Raspberry Pi para configuração automática:

```bash
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash
```

> **🔄 Novo**: Sistema de recuperação automática - O script detecta interrupções (perda de energia, desligamentos) e permite continuar de onde parou!

## 📦 O que é configurado automaticamente

- **Sistema**: wget, curl, jq, lsof, unzip, build-essential
- **Interface Gráfica**: xserver-xorg, xinit, openbox, chromium-browser
- **Display**: fbi, unclutter, imagemagick, libgbm-dev
- **Áudio**: libasound2
- **Python**: python3-pyxdg
- **Node.js**: Instalação automática da versão LTS (v22.13.1) com npm e npx
- **PM2**: Gerenciador de processos para aplicações Node.js (instalação global)
- **CUPS**: Sistema de impressão com interface web (http://ip:631) e acesso remoto
- **Boot**: Configurações otimizadas para kiosk/display
- **Login**: Autologin automático para usuário 'pi'

## 📱 Múltiplos Dispositivos

### Via SSH Individual

```bash
ssh pi@192.168.1.100 "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
```

### Script Automatizado

```bash
# Baixar e configurar script de deployment
wget https://raw.githubusercontent.com/edywmaster/rpi-setup/main/scripts/deploy-multiple.sh
chmod +x deploy-multiple.sh

# Editar IPs dos dispositivos e executar
nano deploy-multiple.sh
./deploy-multiple.sh
```

## 🖥️ Sistema Kiosk (Opcional)

Para configurar um sistema kiosk completo após a preparação básica:

```bash
# Executar após prepare-system.sh
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/scripts/setup-kiosk.sh | sudo bash
```

**Funcionalidades do Kiosk:**

- Interface touchscreen para ReactJS
- **Servidor de impressão Node.js**: API completa para impressão de badges (porta 50001)
- **Script Python**: Interface com CUPS para impressão otimizada
- Splash screen personalizado no boot
- **Serviço Kiosk Start**: Inicialização automática com "Hello World!" e monitoramento
- Estrutura organizada em `/opt/kiosk/`
- Logs detalhados e recuperação automática

**Comandos úteis do Kiosk:**

```bash
# Verificar status dos serviços
sudo systemctl status kiosk-start.service
sudo systemctl status kiosk-print-server.service

# Ver logs em tempo real
sudo journalctl -u kiosk-start.service -f
sudo journalctl -u kiosk-print-server.service -f

# Testar funcionamento
sudo ./tests/test-kiosk-start.sh
sudo ./tests/test-print-server.sh

# Testar servidor de impressão
curl http://localhost:50001/health
curl http://localhost:50001/printers

# Ver documentação completa do servidor de impressão
cat docs/production/PRINT-SERVER.md

# Executar exemplos de uso
./docs/production/PRINT-SERVER-EXAMPLES.sh
```

### Desinstalação do Sistema Kiosk

Para remover completamente o sistema kiosk (mantendo o sistema base):

```bash
# Desinstalação automática
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/dist/kiosk/scripts/uninstall.sh | sudo bash

# Ou modo forçado (sem confirmações)
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/dist/kiosk/scripts/uninstall.sh | sudo bash -s -- --force
```

**O que é removido na desinstalação:**

- Diretórios `/opt/kiosk/` e conteúdo
- Serviços systemd relacionados ao kiosk
- Configurações específicas do kiosk
- Logs e arquivos de estado do kiosk
- **Preserva**: Sistema base (Node.js, PM2, CUPS)

## 🔍 Utilitários de Sistema

### Informações do Sistema

Para verificar o status completo do sistema e configurações instaladas:

```bash
# Executar localmente
./utils/system-info.sh

# Ou via download direto
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/utils/system-info.sh | bash
```

**Informações exibidas:**

- Status do hardware (CPU, memória, disco, temperatura)
- Status dos scripts de preparação e kiosk
- Serviços systemd relacionados
- Configurações de rede e conectividade
- Variáveis de ambiente do sistema
- Logs e arquivos de estado

## 🎯 Compatibilidade

- **Sistema**: Raspberry Pi OS Lite (Debian 12 "bookworm")
- **Hardware**: Raspberry Pi 4B (portável para outros modelos)
- **Requisitos**: Acesso sudo + Conexão com internet

## 📚 Documentação

- **[Guia de Produção](docs/production/DEPLOYMENT.md)** - Implantação em larga escala
- **[Manual Completo](docs/production/PREPARE-SYSTEM.md)** - Documentação detalhada
- **[Desenvolvimento](docs/development/)** - Informações técnicas e correções
- **[Gerenciamento de Versões](docs/development/VERSION-MANAGEMENT.md)** - 🆕 Sistema centralizado de versionamento

---

**Versão atual**: v1.3.1 | **Última Atualização**: 2025-07-21 | **Repositório**: [edywmaster/rpi-setup](https://github.com/edywmaster/rpi-setup)
