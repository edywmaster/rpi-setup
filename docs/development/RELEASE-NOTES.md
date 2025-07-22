# Release Notes

## Version 1.4.4 (Version Update)

### 🆕 Atualizações

- **Versão atualizada**: Projeto atualizado para versão 1.4.4
- **Data de atualização**: 2025-07-22
- **Gerenciamento centralizado**: Versões agora gerenciadas via scripts/version-manager.sh

### 🔧 Alterações Técnicas

- Atualização automática de versões em todos os componentes
- Sincronização de versões entre prepare-system.sh e setup-kiosk.sh
- Documentação atualizada com nova versão

---

## Version 1.4.4 (Ambiente Gráfico Openbox Implementado)

### 🚀 Nova Funcionalidade Principal

- **Data da implementação**: 2025-07-22
- **Componente**: Configuração automática do ambiente gráfico Openbox
- **Localização**: `scripts/setup-kiosk.sh` - função `setup_openbox_environment()`

#### Funcionalidades Adicionadas:

1. **Instalação Automática do Openbox**:

   - Openbox como window manager principal
   - Unclutter para ocultação do cursor
   - Xorg e utilitários X11 necessários
   - xserver-xorg-legacy para compatibilidade

2. **Script de Autostart Otimizado**:

   - Aguarda disponibilidade do DISPLAY=:0
   - Configurações de energia otimizadas para kiosk
   - Desabilita screensaver e gerenciamento DPMS
   - Inicia Chromium automaticamente em modo kiosk

3. **Script start.sh Aprimorado**:

   - Função `load_kiosk_config()` para carregar variáveis de `/etc/environment`
   - Função `show_kiosk_vars()` para exibir configurações
   - Diferenciação entre execução local (kiosk) e SSH
   - Integração com autostart do Openbox

4. **Configuração .xinitrc Automática**:
   - Adiciona `exec openbox-session` automaticamente
   - Configuração de permissões corretas
   - Evita duplicação se já configurado

#### Estrutura de Arquivos Criados:

```
/home/pi/.config/openbox/autostart  # Script de inicialização do Openbox
/home/pi/.config/chromium/Default/Preferences  # Configurações do navegador
/home/pi/.xinitrc  # Configuração do X11
/opt/kiosk/scripts/start.sh  # Script principal de inicialização
```

#### Melhorias de Sistema:

- **Estado de Rastreamento**: Novo passo `openbox_setup` para recuperação
- **Resumo Detalhado**: Informações completas sobre configuração Openbox
- **Testes Automatizados**: `test-openbox-setup.sh` para validação
- **Documentação**: `OPENBOX-KIOSK-SETUP.md` com detalhes técnicos

#### Fluxo de Inicialização Otimizado:

1. Serviço `kiosk-start.service` inicia `start.sh`
2. Carregamento de variáveis de ambiente KIOSK
3. Inicialização do X11 com `startx`
4. Openbox carrega e executa autostart
5. Chromium inicia em modo kiosk fullscreen

#### Benefícios:

- **Automatização Completa**: Zero configuração manual necessária
- **Otimização para Kiosk**: Configurações específicas para touchscreen
- **Robustez**: Tratamento de erros e verificações
- **Flexibilidade**: Configuração via variáveis de ambiente
- **Manutenibilidade**: Código organizado e testado

---

## Version 1.4.3 (Kiosk Fullscreen Critical Fixes)

### 🐛 Correções Críticas em Produção

- **Data da correção**: 2025-07-22
- **Problemas identificados**: Múltiplas falhas no serviço kiosk-fullscreen em produção
- **Componente afetado**: `scripts/setup-kiosk.sh` - função `setup_kiosk_fullscreen()`

#### Problemas Críticos Encontrados:

1. **KIOSK_APP_URL: unbound variable (linha 186)**:

   - Erro `set -euo pipefail` com variável não definida
   - Variável referenciada em heredoc quoted

2. **AUTOSTART_EOF: command not found (linha 194)**:

   - Estrutura heredoc mal formada
   - Código duplicado causando syntax error

3. **TERM environment variable not set**:
   - Falta de configuração de variáveis no systemd service

#### Correções Implementadas:

1. **Correção de Variáveis de Ambiente**:

   - `export KIOSK_APP_URL="${KIOSK_APP_URL:-http://localhost:3000}"` garantindo valor padrão
   - Adicionado `Environment=TERM=xterm-256color` no systemd service
   - Configurado `Environment=XDG_RUNTIME_DIR=/run/user/1000`

2. **Correção de Estrutura Heredoc**:

   - Removido aspas simples de `'AUTOSTART_EOF'` para permitir expansão de variáveis
   - Uso de variável local `$AUTOSTART_URL` para evitar referência a variável não definida
   - Escape adequado de caracteres especiais (`\$`, `\\`)
   - Remoção de código duplicado órfão

3. **Melhorias na Limpeza do Chromium**:

   - Adicionado `rm -rf ~/.cache/chromium/Default/Cache/*`
   - Adicionado `rm -rf ~/.config/chromium/Singleton*`
   - Baseado nas práticas do projeto tkb-kiosk

4. **Configurações de Segurança Systemd**:
   - `PrivateTmp=false` para acesso ao X11 socket
   - `ProtectSystem=false` para permitir acesso ao sistema gráfico
   - `ExecStartPre` aguarda X11 estar disponível

### 🧪 Ferramentas de Diagnóstico Atualizadas

- **Script de teste atualizado**: `tests/test-kiosk-fullscreen-service.sh`
  - Diagnósticos específicos para `KIOSK_APP_URL: unbound variable`
  - Detecção de problemas `AUTOSTART_EOF: command not found`
  - Comandos de limpeza do cache do Chromium
  - Validação de sintaxe do script gerado

### 🆕 Outras Atualizações

- **Versão atualizada**: Projeto atualizado para versão 1.4.3

  - Adicionado `Environment=TERM=xterm-256color`
  - Configurado `Environment=XDG_RUNTIME_DIR=/run/user/1000`
  - Mantido `Environment=DISPLAY=:0` e outras variáveis essenciais

2. **Configurações de Segurança**:

   - `PrivateTmp=false` para acesso ao X11 socket
   - `ProtectSystem=false` para permitir acesso ao sistema gráfico
   - `ProtectHome=false` para acesso ao diretório home do usuário

3. **Sincronização X11**:

   - `ExecStartPre` aguarda X11 estar disponível antes de iniciar
   - Verificação do socket `/tmp/.X11-unix/X0`

4. **Tratamento de Erros**:
   - Melhor validação de ambiente no script kiosk
   - Logs mais detalhados para debugging

### 🧪 Novos Testes

- **Criado**: `tests/test-kiosk-fullscreen-service.sh`
  - Validação completa do serviço systemd
  - Verificação de variáveis de ambiente
  - Diagnóstico X11 e Chromium
  - Guia de solução de problemas integrado

### 🆕 Outras Atualizações

- **Versão atualizada**: Projeto atualizado para versão 1.4.3
- **Gerenciamento centralizado**: Versões agora gerenciadas via scripts/version-manager.sh

---

## Version 1.4.2 (Bug Fix - Environment Variables Removal)

### 🐛 Correção de Bug Crítico

- **Problema identificado**: Script de desinstalação não removeu corretamente as variáveis de ambiente do sistema
- **Componente afetado**: `dist/kiosk/scripts/uninstall.sh` - função `remove_environment_variables()`
- **Data da correção**: 2025-07-21
- **Severidade**: Crítica - Variáveis KIOSK permaneciam no sistema após desinstalação

### 🔧 Detalhes da Correção

**Problema Original:**

- Regex `^export[[:space:]]+${var}=` não detectava corretamente variáveis como `export KIOSK_VERSION="1.2.0"`
- 18 variáveis KIOSK permaneciam em `/etc/environment` após desinstalação
- Sistema ficava com configurações órfãs do kiosk

**Solução Implementada:**

- Adicionada condição alternativa no pattern matching
- Padrão corrigido: `[[ "$line" =~ ^export[[:space:]]+${var}= ]] || [[ "$line" == "export ${var}="* ]]`
- Compatibilidade com diferentes formatos de export

**Variáveis Corrigidas (18 total):**

- Core KIOSK (15): `KIOSK_VERSION`, `KIOSK_APP_*`, `KIOSK_PRINT_*`, `KIOSK_*_DIR`
- Legacy (4): `APP_MODE`, `APP_URL`, `APP_API_URL`, `PRINT_PORT`

### ✅ Validação e Testes

- **Teste criado**: `tests/test-uninstall-environment-fix.sh`
- **Validação**: Confirmado remoção de todas as 19 variáveis identificadas
- **Preservação**: Variáveis do sistema (PATH, LANG, HOME, USER) mantidas
- **Backup**: Lógica de backup do arquivo `/etc/environment` preservada

### 🔄 Impacto e Compatibilidade

- **Retrocompatibilidade**: Mantida (script funciona com instalações anteriores)
- **Requisitos**: Nenhum requisito adicional
- **Ambiente de desenvolvimento**: Testado em macOS (desenvolvimento) para deployment Linux
- **Validações**: Todas as validações obrigatórias do projeto executadas

### 🚀 Próximos Passos Recomendados

- Teste da correção em ambiente real Raspberry Pi
- Execução de desinstalação completa para validar limpeza
- Verificação de que `cat /etc/environment` não contém mais variáveis KIOSK

---

## Version 1.4.1 (Version Update)

### 🆕 Atualizações

- **Versão atualizada**: Projeto atualizado para versão 1.4.1
- **Data de atualização**: 2025-07-21
- **Gerenciamento centralizado**: Versões agora gerenciadas via scripts/version-manager.sh

### 🔧 Alterações Técnicas

- Atualização automática de versões em todos os componentes
- Sincronização de versões entre prepare-system.sh e setup-kiosk.sh
- Documentação atualizada com nova versão

---

## Version 1.4.1 (Version Update)

### 🆕 Atualizações

- **Versão atualizada**: Projeto atualizado para versão 1.4.1
- **Data de atualização**: 2025-07-21
- **Gerenciamento centralizado**: Versões agora gerenciadas via scripts/version-manager.sh

### 🔧 Alterações Técnicas

- Atualização automática de versões em todos os componentes
- Sincronização de versões entre prepare-system.sh e setup-kiosk.sh
- Documentação atualizada com nova versão

---

## Version 1.4.0 (Version Update)

### 🆕 Atualizações

- **Versão atualizada**: Projeto atualizado para versão 1.4.0
- **Data de atualização**: 2025-07-21
- **Gerenciamento centralizado**: Versões agora gerenciadas via scripts/version-manager.sh

### 🔧 Alterações Técnicas

- Atualização automática de versões em todos os componentes
- Sincronização de versões entre prepare-system.sh e setup-kiosk.sh
- Documentação atualizada com nova versão

---

## Version 1.3.1 (Version Manager Implementation)

### 🆕 Atualizações

- **Versão atualizada**: Projeto atualizado para versão 1.3.1
- **Data de atualização**: 2025-07-21
- **Gerenciamento centralizado**: Versões agora gerenciadas via scripts/version-manager.sh

### 🔧 Alterações Técnicas

- Atualização automática de versões em todos os componentes
- Sincronização de versões entre prepare-system.sh e setup-kiosk.sh
- Documentação atualizada com nova versão

---

## Version 1.3.0 (Kiosk Start Service Integration)

### 🆕 Nova Funcionalidade Principal

- **Serviço Kiosk Start**: Novo serviço systemd que inicializa automaticamente com o sistema
- **Hello World Demo**: Script de demonstração que exibe "Hello World!" localmente e remotamente
- **Monitoramento Contínuo**: Serviço mantém execução contínua com heartbeat a cada 5 minutos
- **Logs Detalhados**: Sistema de logging completo em `/var/log/kiosk-start.log`

### 🔧 Componentes Adicionados

**Serviço systemd (`kiosk-start.service`):**

- Inicialização automática após boot
- Execução como usuário 'pi'
- Reinicialização automática em caso de falha
- Dependência do serviço de rede

**Script de inicialização (`/opt/kiosk/scripts/kiosk-start.sh`):**

- Carregamento automático de configurações
- Exibição de informações do sistema
- Mensagens "Hello World!" para terminal local e remoto
- Loop contínuo com status periódico

**Scripts de teste e demonstração:**

- `tests/test-kiosk-start.sh` - Teste completo do serviço (10 testes automatizados)
- `tests/demo-kiosk-hello.sh` - Demonstração local e remota do Hello World

### 📁 Estrutura de Arquivos

**Novo diretório dist/kiosk/:**

- Template do script kiosk-start.sh
- Estrutura base para server/, utils/, templates/
- Documentação da estrutura

### 🔄 Integração com Setup

- Novo passo "kiosk_service" no processo de instalação
- Estado persistente e recuperação automática
- Configuração automática durante setup-kiosk.sh

### 📋 Comandos Úteis

```bash
# Status do serviço
sudo systemctl status kiosk-start.service

# Logs em tempo real
sudo journalctl -u kiosk-start.service -f

# Teste local
sudo ./tests/test-kiosk-start.sh

# Demo remoto
./tests/demo-kiosk-hello.sh 192.168.1.100
```

### 🎯 Compatibilidade

- Totalmente compatível com versões anteriores
- Funciona em conjunto com splash screen (kiosk-splash.service)
- Integração com prepare-system.sh v1.2.0

---

## Version 1.0.7 (Boot Configuration Optimization)

### 🆕 Nova Funcionalidade Principal

- **Configuração automática de boot**: Otimizações específicas para sistemas kiosk/display
- **Supressão de elementos visuais**: Remove splash screens, logos e mensagens verbosas durante o boot
- **Configuração segura**: Backup automático dos arquivos originais antes das modificações

### 🔧 Configurações Aplicadas

**Arquivo `/boot/firmware/config.txt`:**

- `disable_splash=1` - Remove tela de splash do Raspberry Pi
- `avoid_warnings=1` - Remove avisos de undervoltage durante o boot

**Arquivo `/boot/firmware/cmdline.txt`:**

- `logo.nologo` - Remove logo do kernel Linux
- `vt.global_cursor_default=0` - Remove cursor piscando no console
- `consoleblank=0` - Desabilita blank automático do console
- `loglevel=0 quiet` - Reduz mensagens verbosas de boot

### 🎯 Benefícios para Sistemas Kiosk

- ✅ Boot limpo e profissional sem logos ou splash screens
- ✅ Inicialização mais rápida com menos output visual
- ✅ Experiência consistente para displays dedicados
- ✅ Backup automático para reversão se necessário

### 🛡️ Segurança e Validação

- **Detecção de arquivos**: Verifica existência dos arquivos de boot antes de modificar
- **Verificação de duplicatas**: Não aplica configurações se já existirem
- **Backup automático**: Cria `cmdline.txt.backup` antes das modificações
- **Compatibilidade**: Funciona com Raspberry Pi OS Lite (Bookworm)

### 📋 Nova Etapa de Rastreamento

- Adicionada etapa `boot_config` ao sistema de recuperação
- Suporte completo à detecção de interrupções durante configuração de boot
- Logs detalhados de todas as modificações realizadas

---

## Version 1.0.6 (Clean Terminal Output)

### 🎨 UI/UX Improvement

- **Limpeza da saída do terminal**: Removidas mensagens duplicadas com timestamp que poluíam a visualização
- **Interface mais limpa**: Terminal agora exibe apenas mensagens coloridas e diretas
- **Logging mantido**: Logs completos com timestamps continuam sendo salvos no arquivo `/var/log/rpi-preparation.log`

### 🔄 Antes vs Depois

**Antes (v1.0.5):**

```
[INFO] Verificando: wget
[2025-07-20 00:30:07] [INFO] Verificando: wget
[INFO] ⚡ wget já está instalado
[2025-07-20 00:30:07] [INFO] ⚡ wget já está instalado
```

**Depois (v1.0.6):**

```
[INFO] Verificando: wget
[INFO] ⚡ wget já está instalado
```

### 📋 Benefícios

- ✅ Terminal 50% mais limpo e legível
- ✅ Foco na informação essencial
- ✅ Experiência de usuário aprimorada
- ✅ Logs detalhados mantidos para debugging

---

## Version 1.0.5 (State File Format Fix)

### 🐛 Bug Fix

- **Fixed state file format issue**: Corrigido erro de formato do timestamp no arquivo de estado que causava mensagens de erro como `/var/lib/rpi-preparation-state: line 2: 00:28:51: command not found`
- **Improved variable quoting**: Adicionadas aspas adequadas para todas as variáveis no arquivo de estado
- **Enhanced timestamp format**: Alterado formato de timestamp de `%Y-%m-%d %H:%M:%S` para `%Y-%m-%d_%H:%M:%S` para melhor compatibilidade com shell

### 🔧 Technical Details

- Problema identificado durante teste real no Raspberry Pi 4B
- Arquivo de estado agora usa formato compatível com `source` command
- Eliminadas mensagens de erro durante carregamento do estado

### 📊 Validação

- ✅ Sistema de detecção de interrupções funcionando perfeitamente
- ✅ Recuperação automática testada e validada
- ✅ Instalação de 18 pacotes concluída com sucesso
- ✅ Sistema pronto para uso em produção

---

## Version 1.0.4 (Interruption Detection & Recovery)

### 🆕 Nova Funcionalidade Principal

- **Sistema de Detecção de Interrupções**: O script agora detecta automaticamente quando uma instalação anterior foi interrompida
- **Recuperação Inteligente**: Oferece opções para continuar, reiniciar ou cancelar quando uma interrupção é detectada
- **Rastreamento de Estado**: Cada etapa da instalação é salva em arquivo de estado para permitir recuperação precisa

### 🔧 Recursos de Recuperação

- **Detecção Automática**: Identifica interrupções por perda de energia, desligamento acidental ou outros motivos
- **Opções Flexíveis**:
  - ✅ Continuar instalação (recomendado)
  - 🆕 Reiniciar do zero
  - ❌ Cancelar instalação
- **Estado Detalhado**: Mostra exatamente onde a instalação foi interrompida
- **Validação de Processo**: Verifica se outro processo de instalação está em execução

### 📋 Etapas Rastreadas

1. `validation` - Validações iniciais do sistema
2. `update_lists` - Atualização das listas de pacotes
3. `system_upgrade` - Upgrade do sistema operacional
4. `locale_config` - Configuração de locales
5. `package_install` - Instalação de pacotes essenciais
6. `cleanup` - Limpeza do sistema
7. `completion` - Finalização da instalação

### 🛠️ Melhorias Técnicas

- **Arquivo de Estado**: `/var/lib/rpi-preparation-state` para persistência
- **Lock File Inteligente**: Verificação de processos órfãos
- **Cleanup Automático**: Marcação de conclusão bem-sucedida
- **Skip Logic**: Pula etapas já concluídas na recuperação

### 🧪 Ferramentas de Teste

- **Script de Teste**: `tests/test-interruption-recovery.sh`
- **Simulação de Interrupções**: Teste todas as etapas de recuperação
- **Validação de Estado**: Verificação do sistema de rastreamento

### 📖 Como Usar

Quando uma interrupção é detectada, o script exibirá:

```
⚠️  INTERRUPÇÃO DETECTADA!
Uma instalação anterior foi interrompida:
   • Última etapa: package_install
   • Data/Hora: 2025-01-20 14:30:45
   • Status: Incompleta

🔧 Opções disponíveis:
   1️⃣  Continuar instalação (recomendado)
   2️⃣  Reiniciar do zero
   3️⃣  Cancelar

Escolha uma opção (1/2/3):
```

---

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
