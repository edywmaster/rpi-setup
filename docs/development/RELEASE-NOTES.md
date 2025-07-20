# Release Notes - v1.0.1

## 🐛 Correções de Bugs

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
