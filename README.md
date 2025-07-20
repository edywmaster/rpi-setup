# rpi-setup

## 🧠 Instruções para o GitHub Copilot

### Objetivo do Projeto:

Desenvolver um conjunto de scripts Shell (Bash) para Raspberry Pi com Raspberry Pi OS Lite (Debian 12 "bookworm") que automatizem tarefas de:

- Instalação de pacotes
- Configurações de sistema
- Atualizações de segurança
- Customizações de ambiente
- Padronização de rede e serviços
- Geração de logs e validações

Esses scripts serão reutilizados em múltiplos dispositivos Raspberry Pi (modelo 4B, mas idealmente portáveis para outros modelos).

## 🚀 Scripts Disponíveis

### prepare-system.sh

Script de preparação inicial do sistema que automatiza:

- Atualização completa do Raspberry Pi OS
- Instalação de pacotes essenciais para sistemas kiosk/display
- Validações de ambiente e conectividade
- Logging abrangente de todas as operações

**Uso:**

```bash
sudo ./prepare-system.sh
```

📖 **Documentação completa:** [PREPARE-SYSTEM.md](PREPARE-SYSTEM.md)

## 📋 Pacotes Essenciais Incluídos

O script `prepare-system.sh` instala automaticamente:

- **Sistema**: wget, curl, jq, lsof, unzip, build-essential
- **Gráfico**: xserver-xorg, xinit, openbox, chromium-browser
- **Display**: fbi, unclutter, imagemagick, libgbm-dev
- **Áudio**: libasound2
- **Python**: python3-pyxdg
