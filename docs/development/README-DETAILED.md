# rpi-setup

> **📋 Versão**: v1.3.1 | **Documentação Técnica** | **Atualizada em**: 2025-07-21

## 🔧 Validação e Versionamento Obrigatórios

### ⚠️ CRÍTICO: Workflow de Validação Mandatório

**Antes de QUALQUER criação, modificação ou correção de código neste projeto, você DEVE executar o seguinte workflow de validação e versionamento:**

#### 1. Validação Pré-Mudança (OBRIGATÓRIA)

```bash
# Execute ANTES de fazer qualquer alteração
./tests/validate-all.sh --pre-change
```

#### 2. Validação Pós-Mudança (OBRIGATÓRIA)

```bash
# Execute APÓS fazer qualquer alteração
./tests/validate-all.sh --post-change --with-version
```

#### 3. Validação Completa (Recomendada)

```bash
# Validação completa do projeto
./tests/validate-all.sh
```

#### 4. Atualização de Versão (Para Mudanças Significativas)

```bash
# Verificar versão atual
./scripts/version-manager.sh --current

# Atualizar versão (incrementar apropriadamente)
./scripts/version-manager.sh --update <NOVA_VERSÃO>

# Validar consistência da versão
./scripts/version-manager.sh --validate
```

#### 5. Diretrizes de Incremento de Versão

- **Versão de patch** (x.x.X): Correções de bugs, correções de documentação, melhorias menores
- **Versão menor** (x.X.x): Novos recursos, adições de scripts, documentação significativa
- **Versão maior** (X.x.x): Mudanças que quebram compatibilidade, grandes mudanças de arquitetura

### 🛠️ Ferramentas de Validação Disponíveis

- `./tests/validate-all.sh` - Script de validação completa
- `./tests/validate-structure.sh` - Validação da estrutura do projeto
- `./tests/validate-docs-structure.sh` - Validação da estrutura de documentação
- `./tests/validate-copilot-integration.sh` - Validação da integração com Copilot
- `./scripts/version-manager.sh` - Gerenciamento de versões
- `./scripts/pre-commit.sh` - Hook de pré-commit para Git

### 📋 Installation do Hook de Pré-Commit

```bash
# Instalar o hook de pré-commit
cp scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 🔄 Workflow de Desenvolvimento Recomendado

```bash
# 1. Antes de fazer mudanças
./tests/validate-all.sh --pre-change

# 2. Fazer as alterações necessárias
# ... suas modificações ...

# 3. Após as mudanças
./tests/validate-all.sh --post-change

# 4. Se mudanças significativas, atualizar versão
./scripts/version-manager.sh --update 1.3.2

# 5. Commit com validação
git add .
git commit -m "feat: descrição - validado estrutura e versão"
```

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

**Versão atual**: v1.2.0 - Sistema completo com Node.js LTS, PM2, CUPS e sistema kiosk

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
- 🆕 **[Gerenciamento de Versões](VERSION-MANAGEMENT.md)** - Sistema centralizado de versionamento
- 🛠️ **[Instruções para Copilot](../.github/copilot-instructions.md)** - Guia para desenvolvimento

---

**Versão desta documentação**: v1.3.1 | **Projeto**: rpi-setup v1.3.1 | **Última atualização**: 2025-07-21
