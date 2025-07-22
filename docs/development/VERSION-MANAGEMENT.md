# Sistema de Gerenciamento de Versões - rpi-setup

## 🎯 Visão Geral

O projeto rpi-setup agora possui um sistema centralizado de gerenciamento de versões que mantém consistência entre todos os componentes do projeto. Este sistema automatiza a atualização de versões em scripts, documentação e release notes.

## 📁 Componentes do Sistema

### Scripts Principais

- **`scripts/version-manager.sh`** - Gerenciador central de versões
- **`tests/test-version-manager.sh`** - Testes do sistema de versionamento
- **`tests/demo-version-manager.sh`** - Demonstrações e workflow
- **`.version`** - Arquivo de configuração central (gerado automaticamente)

### Arquivos Gerenciados

O sistema atualiza automaticamente as versões nos seguintes arquivos:

- `prepare-system.sh` (SCRIPT_VERSION)
- `scripts/setup-kiosk.sh` (SCRIPT_VERSION)
- `docs/development/RELEASE-NOTES.md` (novas entradas)
- `README.md` (referências de versão)
- `docs/README.md` (referências de versão)
- Documentação de produção (conforme necessário)

## 🚀 Como Usar

### Comandos Básicos

```bash
# Mostrar versão atual e informações
./scripts/version-manager.sh --current

# Validar consistência de versões
./scripts/version-manager.sh --validate

# Atualizar para nova versão
./scripts/version-manager.sh --update X.Y.Z "Descrição da mudança"

# Mostrar ajuda completa
./scripts/version-manager.sh --help
```

### Exemplos Práticos

```bash
# Correção de bug (patch)
./scripts/version-manager.sh --update 1.3.2 "Bug Fix: Corrigido erro no autologin"

# Nova funcionalidade (minor)
./scripts/version-manager.sh --update 1.4.0 "New Feature: Sistema de backup automático"

# Mudança incompatível (major)
./scripts/version-manager.sh --update 2.0.0 "Major Update: Nova arquitetura de plugins"
```

## 🔄 Workflow de Desenvolvimento

### 1. Antes de Começar

```bash
# Verificar estado atual
./scripts/version-manager.sh --current
./scripts/version-manager.sh --validate
```

### 2. Durante o Desenvolvimento

- Faça suas alterações normalmente
- Teste as funcionalidades
- Execute testes de estrutura: `./tests/validate-structure.sh`

### 3. Após Implementar Mudanças

```bash
# Atualizar versão do projeto
./scripts/version-manager.sh --update 1.3.2 "Descrição clara da mudança"

# Validar que tudo foi atualizado
./scripts/version-manager.sh --validate
```

### 4. Antes do Commit

```bash
# Executar todos os testes
./tests/test-version-manager.sh
./tests/validate-structure.sh

# Se tudo OK, fazer commit
git add .
git commit -m "feat: Descrição da mudança (v1.3.2)"
```

## 🧪 Testes e Validação

### Testar o Sistema de Versionamento

```bash
# Executar todos os testes
./tests/test-version-manager.sh

# Testes específicos
./tests/test-version-manager.sh --validation-test
./tests/test-version-manager.sh --creation-test
```

### Demonstrações

```bash
# Ver workflow completo
./tests/demo-version-manager.sh --workflow

# Ver estrutura de arquivos
./tests/demo-version-manager.sh --structure

# Demonstração completa
./tests/demo-version-manager.sh --all
```

### Validação da Estrutura

```bash
# Validar estrutura completa (inclui versões)
./tests/validate-structure.sh
```

## 📊 Versionamento Semântico

O projeto segue o padrão de [Versionamento Semântico](https://semver.org/lang/pt-BR/):

- **MAJOR** (X.0.0): Mudanças incompatíveis na API/funcionalidade
- **MINOR** (0.X.0): Novas funcionalidades compatíveis
- **PATCH** (0.0.X): Correções de bugs compatíveis

### Exemplos de Cada Tipo

**PATCH (1.3.1 → 1.3.2):**

- Correção de bugs
- Melhorias de performance
- Correções de documentação
- Refatorações internas

**MINOR (1.3.2 → 1.4.0):**

- Novas funcionalidades
- Novos scripts/utilitários
- Melhorias de UX/UI
- Novas opções de configuração

**MAJOR (1.4.0 → 2.0.0):**

- Mudanças na estrutura de arquivos
- Remoção de funcionalidades
- Mudanças incompatíveis na API
- Refatoração completa da arquitetura

## 🔍 Arquivo .version

O arquivo `.version` é criado automaticamente e contém:

```bash
# Versão principal do projeto
PROJECT_VERSION=1.3.1

# Versões de componentes
NODEJS_VERSION=v22.13.1
KIOSK_API_VERSION=v1

# Informações de atualização
LAST_UPDATE=2025-07-21
LAST_UPDATE_BY=edmarj.cruz

# Histórico de versões
VERSION_HISTORY="1.3.0:2025-07-21:Initial version\n1.3.1:2025-07-21:Version Manager"
```

## 🛠️ Integração com Outros Scripts

### validate-structure.sh

O script de validação da estrutura agora inclui:

- Verificação da existência do version-manager
- Validação de consistência de versões
- Verificação de permissões executáveis

### release-notes.md

Novas versões são automaticamente adicionadas com:

- Data de atualização
- Descrição fornecida
- Template padronizado de changelog
- Integração com histórico existente

## 🔧 Solução de Problemas

### Versões Inconsistentes

```bash
# Identificar inconsistências
./scripts/version-manager.sh --validate

# Ver detalhes da versão atual
./scripts/version-manager.sh --current

# Forçar atualização para versão específica
./scripts/version-manager.sh --update X.Y.Z "Sync versions"
```

### Arquivo .version Corrompido

```bash
# Remover arquivo corrompido
rm .version

# Regenerar com versão atual
./scripts/version-manager.sh --current
```

### Testes Falhando

```bash
# Executar diagnóstico completo
./tests/test-version-manager.sh --all

# Verificar estrutura
./tests/validate-structure.sh

# Verificar sintaxe dos scripts
bash -n scripts/version-manager.sh
```

## 📋 Checklist de Uso

### Para Nova Funcionalidade

- [ ] Implementar funcionalidade
- [ ] Testar localmente
- [ ] Executar `./tests/validate-structure.sh`
- [ ] Atualizar versão: `./scripts/version-manager.sh --update X.Y.Z "Descrição"`
- [ ] Validar: `./scripts/version-manager.sh --validate`
- [ ] Executar testes: `./tests/test-version-manager.sh`
- [ ] Commit e push

### Para Correção de Bug

- [ ] Identificar e corrigir bug
- [ ] Testar correção
- [ ] Atualizar versão PATCH: `./scripts/version-manager.sh --update X.Y.Z "Bug Fix: Descrição"`
- [ ] Validar consistência
- [ ] Executar testes
- [ ] Commit e push

### Para Release

- [ ] Verificar que todas as funcionalidades estão implementadas
- [ ] Atualizar documentação se necessário
- [ ] Executar todos os testes
- [ ] Atualizar versão conforme tipo de release
- [ ] Validar RELEASE-NOTES.md
- [ ] Tag da versão: `git tag vX.Y.Z`
- [ ] Push com tags: `git push --tags`

## 🎉 Benefícios do Sistema

### ✅ Consistência

- Todas as versões sincronizadas automaticamente
- Não há mais versões desatualizadas em scripts isolados
- Release notes sempre atualizados

### ✅ Automação

- Atualização automática em múltiplos arquivos
- Geração automática de entradas em release notes
- Validação automática de consistência

### ✅ Rastreabilidade

- Histórico completo de versões
- Data e autor de cada atualização
- Descrições detalhadas de mudanças

### ✅ Qualidade

- Validação antes de cada commit
- Testes automatizados do sistema
- Workflow padronizado para toda equipe

---

**Versão desta documentação:** 1.0.0  
**Última atualização:** 2025-07-21  
**Sistema de versão:** scripts/version-manager.sh v1.3.1
