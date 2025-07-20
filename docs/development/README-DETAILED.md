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

**Versão atual**: v1.0.1 - Corrigido para execução via `curl | bash`

## 🔧 Execução Rápida (Recomendado)

### Comando Único - Execução Direta do GitHub

Para executar o script diretamente em qualquer Raspberry Pi com uma única linha:

```bash
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash
```

### Comando com Download e Verificação

Para baixar, verificar e executar:

```bash
# Baixar o script
wget https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh

# Verificar o conteúdo (opcional)
less prepare-system.sh

# Tornar executável e executar
chmod +x prepare-system.sh
sudo ./prepare-system.sh
```

### Usando Git Clone (Para desenvolvimento)

```bash
# Clonar o repositório completo
git clone https://github.com/edywmaster/rpi-setup.git
cd rpi-setup

# Executar o script
sudo ./prepare-system.sh
```

## 📱 Implantação em Múltiplos Dispositivos

### Método 1: SSH + Comando Direto

Execute em cada Raspberry Pi via SSH:

```bash
# Conectar via SSH e executar
ssh pi@192.168.1.100 "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
```

### Método 2: Script de Implantação em Lote

Crie um script local para automatizar múltiplos dispositivos:

```bash
#!/bin/bash
# deploy-multiple.sh

DEVICES=(
    "192.168.1.100"
    "192.168.1.101"
    "192.168.1.102"
)

for device in "${DEVICES[@]}"; do
    echo "Configurando: $device"
    ssh pi@$device "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
done
```

### Método 3: Ansible (Para ambientes avançados)

```yaml
# playbook.yml
---
- hosts: raspberries
  become: yes
  tasks:
    - name: Execute rpi-setup script
      shell: curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | bash
```

📖 **Documentação completa:** [PREPARE-SYSTEM.md](PREPARE-SYSTEM.md)

📖 **Guia de implantação em produção:** [DEPLOYMENT.md](DEPLOYMENT.md)

## 📋 Pacotes Essenciais Incluídos

O script `prepare-system.sh` instala automaticamente:

- **Sistema**: wget, curl, jq, lsof, unzip, build-essential
- **Gráfico**: xserver-xorg, xinit, openbox, chromium-browser
- **Display**: fbi, unclutter, imagemagick, libgbm-dev
- **Áudio**: libasound2
- **Python**: python3-pyxdg

## 📚 Documentação Adicional

- 📋 **[Release Notes](RELEASE-NOTES.md)** - Histórico de versões e correções
- 🛠️ **[Instruções para Copilot](.github/copilot-instructions.md)** - Guia para desenvolvimento
