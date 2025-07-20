# rpi-setup 🚀

Automação completa para Raspberry Pi OS Lite - Configure múltiplos dispositivos com um único comando.

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
- Servidor de impressão local (Node.js + PM2)
- Splash screen personalizado
- Estrutura organizada em `/opt/kiosk/`

## 🎯 Compatibilidade

- **Sistema**: Raspberry Pi OS Lite (Debian 12 "bookworm")
- **Hardware**: Raspberry Pi 4B (portável para outros modelos)
- **Requisitos**: Acesso sudo + Conexão com internet

## 📚 Documentação

- **[Guia de Produção](docs/production/DEPLOYMENT.md)** - Implantação em larga escala
- **[Manual Completo](docs/production/PREPARE-SYSTEM.md)** - Documentação detalhada
- **[Desenvolvimento](docs/development/)** - Informações técnicas e correções

---

**Versão atual**: v1.2.0 | **Repositório**: [edywmaster/rpi-setup](https://github.com/edywmaster/rpi-setup)
