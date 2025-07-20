# Release Notes

## Version 1.0.3 (Critical Bug Fix)

### 🐛 Critical Bug Fixes

- **Fixed package installation loop hanging**: The script was stopping after detecting the first installed package instead of continuing with the remaining packages
- **Improved package detection**: Replaced `dpkg -l | grep` with more reliable `apt list --installed` method
- **Enhanced error isolation**: Added `set +e` and `set -e` around package installation loop to prevent premature script termination
- **Added timeout protection**: Added safety timeout for package installation operations

### 🔧 Technical Improvements

- Better error handling during package installation loop
- More robust package status detection
- Improved logging for package installation process
- Added explicit continuation logic after package checks

### 📋 Bug Details

- **Issue**: Script would halt execution after printing "wget já está instalado" instead of processing all 18 packages
- **Root Cause**: Package detection logic combined with `set -e` causing script to exit on first package check
- **Solution**: Improved package detection method and temporary error handling suspension during installation loop

---

## Version 1.0.2 (Performance & UX Improvements)

### ✨ Novas Funcionalidades

**Detecção de Pacotes Duplicados:**

- Verificação automática de pacotes já instalados
- Evita reinstalações desnecessárias
- Feedback visual aprimorado (⚡ já instalado, 📦 instalando, ✅ sucesso)

**Configuração Automática de Locales:**

- Correção automática de warnings de locale
- Configuração de en_GB.UTF-8 e en_US.UTF-8
- Eliminação de mensagens de erro relacionadas a locale

**Interface Aprimorada:**

- Emojis para melhor feedback visual
- Resumo detalhado do sistema no final
- Informações de hardware, OS, kernel e uso de disco
- Sugestões de próximos passos

### 🔧 Melhorias Técnicas

**Logging Aprimorado:**

- Supressão de output verboso desnecessário
- Logs mais limpos durante instalação de pacotes
- Melhor organização das informações

**Performance:**

- Operações de limpeza otimizadas (silenciosas)
- Verificação prévia de pacotes instalados
- Redução significativa de tempo de execução

**Validação do Sistema:**

- Detecção automática de necessidade de reboot
- Informações detalhadas do sistema
- Verificação de espaço em disco

### 📊 Baseado em Feedback Real

Implementado com base na execução real em Raspberry Pi 4 Model B, incluindo:

- Resolução de warnings de locale
- Otimização para pacotes já presentes no sistema
- Melhoria da experiência do usuário

---

## 🐛 v1.0.1 - Correções de Bugs

### Problema: Erro ao executar via curl | bash

**Erro reportado:**

```bash
bash: line 16: BASH_SOURCE[0]: unbound variable
bash: line 283: BASH_SOURCE[0]: unbound variable
```

**Causa:**

- O script usava `set -euo pipefail` que torna variáveis indefinidas como erro
- `BASH_SOURCE[0]` pode não estar definida quando executado via pipe
- A verificação condicional no final do script não funcionava com pipe execution

**Correções aplicadas:**

1. **Mudança no set options:**

   ```bash
   # Antes
   set -euo pipefail  # Exit on error, undefined vars, pipe failures

   # Depois
   set -eo pipefail   # Exit on error, pipe failures
   ```

2. **Proteção da variável BASH_SOURCE:**

   ```bash
   # Antes
   readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

   # Depois
   readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
   ```

3. **Simplificação da execução:**

   ```bash
   # Antes
   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
       main "$@"
   fi

   # Depois
   main "$@"
   ```

4. **Proteção adicional para nome do script:**

   ```bash
   # Antes
   readonly SCRIPT_NAME="$(basename "$0")"

   # Depois
   readonly SCRIPT_NAME="$(basename "${0:-prepare-system.sh}")"
   ```

## ✅ Validação

O script agora funciona corretamente com:

```bash
# Execução direta
sudo ./prepare-system.sh

# Execução via curl (método recomendado para produção)
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash

# Execução via wget
wget -qO- https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash
```

## 🔍 Testes Realizados

- ✅ Execução local direta
- ✅ Execução via curl | bash
- ✅ Execução via wget | bash
- ✅ Execução remota via SSH
- ✅ Validação de variáveis de ambiente
- ✅ Compatibilidade com diferentes shells

## 📋 Compatibilidade

- **Sistemas testados**: Raspberry Pi OS Lite (Debian 12)
- **Shells compatíveis**: bash 4.0+
- **Métodos de execução**: Local, remote, pipe
- **Dispositivos**: Raspberry Pi 4B (portável para outros modelos)

## 🚀 Próximas Atualizações

- Melhorias no sistema de logging
- Detecção automática de arquitetura ARM
- Suporte para configurações personalizadas
- Integração com systemd para serviços
