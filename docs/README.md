# 📚 Documentação do Projeto rpi-setup

## 📁 Estrutura de Documentação

### 🏭 Produção (`docs/production/`)

Documentação para uso em ambientes de produção:

- **[DEPLOYMENT.md](production/DEPLOYMENT.md)** - Guia completo de implantação em larga escala
- **[PREPARE-SYSTEM.md](production/PREPARE-SYSTEM.md)** - Manual detalhado do script principal
- **[SYSTEM-INFO.md](production/SYSTEM-INFO.md)** - Guia de uso do utilitário system-info.sh
- **[PRINT-SERVER.md](production/PRINT-SERVER.md)** - Documentação do servidor de impressão
- **[etc-environment-example.txt](production/etc-environment-example.txt)** - Exemplo de configuração /etc/environment

### 🔧 Desenvolvimento (`docs/development/`)

Documentação técnica e de desenvolvimento:

- **[README-DETAILED.md](development/README-DETAILED.md)** - README original com todas as informações técnicas
- **[RELEASE-NOTES.md](development/RELEASE-NOTES.md)** - Histórico de versões e correções de bugs
- **[SYSTEM-INFO-ENVIRONMENT-INTEGRATION.md](development/SYSTEM-INFO-ENVIRONMENT-INTEGRATION.md)** - Detalhes técnicos da integração com /etc/environment
- **[SYSTEM-INFO-PRODUCTION-SUMMARY.md](development/SYSTEM-INFO-PRODUCTION-SUMMARY.md)** - Resumo completo da implementação do system-info.sh

### 🧠 Instruções para IA (`.github/`)

Documentação especializada para desenvolvimento assistido por IA:

- **[copilot-instructions.md](../.github/copilot-instructions.md)** - Diretrizes completas para agentes de IA
  - Arquitetura do projeto e padrões de código
  - Convenções de nomenclatura e estrutura
  - Diretrizes de segurança e validação
  - Fluxo de desenvolvimento e testes

## � Scripts e Ferramentas (`scripts/`)

- **[setup-kiosk.sh](../scripts/setup-kiosk.sh)** - Setup completo do sistema kiosk
- **[deploy-multiple.sh](../scripts/deploy-multiple.sh)** - Deploy em múltiplos dispositivos

## 📋 Documentação de Produção (`docs/production/`)

- **[DEPLOYMENT.md](production/DEPLOYMENT.md)** - Guia de implantação em produção
- **[PREPARE-SYSTEM.md](production/PREPARE-SYSTEM.md)** - Documentação detalhada do prepare-system.sh
- **[PRINT-SERVER.md](production/PRINT-SERVER.md)** - Documentação do servidor de impressão
- **[PRINT-SERVER-EXAMPLES.sh](production/PRINT-SERVER-EXAMPLES.sh)** - Exemplos de uso do servidor de impressão

### 🗑️ Scripts de Desinstalação (`dist/kiosk/scripts/`)

- **[uninstall.sh](../dist/kiosk/scripts/uninstall.sh)** - Remoção segura do sistema kiosk

### 🧪 Testes (`tests/`)

Scripts de validação e teste do projeto:

- **[test-script.sh](../tests/test-script.sh)** - Script de validação principal
- **[check-docs-reorganization.sh](../tests/check-docs-reorganization.sh)** - Validação da estrutura de documentação
- **[validate-docs-structure.sh](../tests/validate-docs-structure.sh)** - Validador completo da organização
- **[validate-copilot-integration.sh](../tests/validate-copilot-integration.sh)** - Validação da integração das instruções do Copilot
- **[test-autologin.sh](../tests/test-autologin.sh)** - Teste da funcionalidade de autologin
- **[test-boot-config.sh](../tests/test-boot-config.sh)** - Teste de configurações de boot
- **[test-nodejs.sh](../tests/test-nodejs.sh)** - Teste da instalação do Node.js LTS
- **[test-pm2.sh](../tests/test-pm2.sh)** - Teste da instalação do PM2 (gerenciador de processos)
- **[test-cups.sh](../tests/test-cups.sh)** - Teste da configuração do CUPS (sistema de impressão)
- **[test-kiosk-setup.sh](../tests/test-kiosk-setup.sh)** - Teste do script de setup do kiosk
- **[test-kiosk-integration.sh](../tests/test-kiosk-integration.sh)** - Teste da integração do kiosk no prepare-system.sh
- **[test-print-server.sh](../tests/test-print-server.sh)** - Teste do servidor de impressão Node.js
- **[validate-structure.sh](../tests/validate-structure.sh)** - Validação geral da estrutura

## 🎯 Script Principal

- **[prepare-system.sh](../prepare-system.sh)** - Script principal de preparação do sistema

## 📋 Como Navegar na Documentação

### 📁 Documentação de Desenvolvimento

### Guias Técnicos

- **[Estrutura de Diretórios do Kiosk](development/KIOSK-DIRECTORY-STRUCTURE.md)**: Padrão obrigatório para organização de diretórios do sistema kiosk
- **[README Detalhado](development/README-DETAILED.md)**: Informações técnicas completas do projeto
- **[Notas de Versão](development/RELEASE-NOTES.md)**: Histórico de mudanças e correções

### Arquitetura e Padrões

- **[Instruções do Copilot](../.github/copilot-instructions.md)**: Diretrizes de desenvolvimento e padrões de código
- **[Scripts de Teste](../tests/)**: Ferramentas de validação e qualidade

## 🚀 Para Usuários Finais

1. Comece com o [README principal](../README.md)
2. Para implantação avançada: [DEPLOYMENT.md](production/DEPLOYMENT.md)
3. Para detalhes técnicos: [PREPARE-SYSTEM.md](production/PREPARE-SYSTEM.md)

### Para Desenvolvedores

1. **Entenda a arquitetura** nas [instruções do Copilot](../.github/copilot-instructions.md)
2. **IMPORTANTE**: Siga a [estrutura de diretórios do kiosk](development/KIOSK-DIRECTORY-STRUCTURE.md) para consistência
3. Consulte o [README detalhado](development/README-DETAILED.md) para informações técnicas
4. Verifique o [histórico de versões](development/RELEASE-NOTES.md) para mudanças
5. **Valide suas mudanças** com os scripts de teste

### Para Contribuidores e IA

1. **OBRIGATÓRIO**: Leia as [instruções do Copilot](../.github/copilot-instructions.md) antes de fazer alterações
2. **CRÍTICO**: Siga a [estrutura de diretórios do kiosk](development/KIOSK-DIRECTORY-STRUCTURE.md) rigorosamente
3. Use os [scripts de validação](../tests/) para verificar conformidade:
   - `./tests/check-docs-reorganization.sh` - Validação rápida da estrutura
   - `./tests/validate-docs-structure.sh` - Validação completa
4. Siga os padrões de código e documentação estabelecidos
5. Teste todas as mudanças antes de committar

## 🔄 Atualizações

Esta documentação é atualizada a cada versão. Consulte o [RELEASE-NOTES.md](development/RELEASE-NOTES.md) para mudanças recentes.

## 🛠️ Ferramentas de Validação

O projeto inclui ferramentas automatizadas para validar a estrutura e organização:

### Validação da Estrutura de Documentação

```bash
# Validação rápida - verificação visual da estrutura
./tests/check-docs-reorganization.sh

# Validação completa - análise detalhada com contadores
./tests/validate-docs-structure.sh

# Validação da integração das instruções do Copilot
./tests/validate-copilot-integration.sh
```

### Outras Validações Disponíveis

```bash
# Validação geral da estrutura do projeto
./tests/validate-structure.sh

# Validação específica da estrutura de diretórios do kiosk
./tests/test-uninstall-directories.sh

# Teste de configurações de boot
./tests/test-boot-config.sh

# Script de teste principal
./tests/test-script.sh
```

### Como Usar as Ferramentas

1. **Antes de fazer mudanças**: Execute `./tests/check-docs-reorganization.sh` para ver o estado atual
2. **Após mudanças**: Execute `./tests/validate-docs-structure.sh` para validação completa
3. **Para validar integração do Copilot**: Execute `./tests/validate-copilot-integration.sh`
4. **Em caso de erros**: As ferramentas fornecem feedback específico sobre o que precisa ser corrigido

### Workflow Recomendado para Desenvolvedores

```bash
# 1. Verificar estado atual
./tests/check-docs-reorganization.sh

# 2. Fazer suas mudanças seguindo a estrutura de diretórios...

# 3. Validar estrutura completa
./tests/validate-docs-structure.sh

# 4. Validar estrutura de diretórios do kiosk
./tests/test-uninstall-directories.sh

# 5. Validar integração das instruções
./tests/validate-copilot-integration.sh

# 6. Se tudo estiver OK, committar
```
