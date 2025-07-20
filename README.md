# rpi-setup 🚀

Automação completa para Raspberry Pi OS Lite - Configure múltiplos dispositivos com um único comando.

## ⚡ Execução Rápida

Execute este comando em qualquer Raspberry Pi para configuração automática:

```bash
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash
```

> **🔄 Novo**: Sistema de recuperação automática - O script detecta interrupções (perda de energia, desligamentos) e permite continuar de onde parou!

## 📦 O que é instalado automaticamente

- **Sistema**: wget, curl, jq, lsof, unzip, build-essential
- **Interface Gráfica**: xserver-xorg, xinit, openbox, chromium-browser
- **Display**: fbi, unclutter, imagemagick, libgbm-dev
- **Áudio**: libasound2
- **Python**: python3-pyxdg

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

## 🎯 Compatibilidade

- **Sistema**: Raspberry Pi OS Lite (Debian 12 "bookworm")
- **Hardware**: Raspberry Pi 4B (portável para outros modelos)
- **Requisitos**: Acesso sudo + Conexão com internet

## 📚 Documentação

- **[Guia de Produção](docs/production/DEPLOYMENT.md)** - Implantação em larga escala
- **[Manual Completo](docs/production/PREPARE-SYSTEM.md)** - Documentação detalhada
- **[Desenvolvimento](docs/development/)** - Informações técnicas e correções

---

**Versão atual**: v1.0.2 | **Repositório**: [edywmaster/rpi-setup](https://github.com/edywmaster/rpi-setup)
