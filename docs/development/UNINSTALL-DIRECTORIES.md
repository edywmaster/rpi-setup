# Directory Structure Updates - Uninstall Script

## Resumo das Correções

O script de desinstalação (`dist/kiosk/scripts/uninstall.sh`) foi ajustado para corresponder exatamente à estrutura de diretórios do script de setup atualizado (`scripts/setup-kiosk.sh`).

## ✅ Principais Correções Realizadas

### 1. **KIOSK_TEMP_DIR Corrigido**

**Antes:**

```bash
readonly KIOSK_TEMP_DIR="/tmp/kiosk"
```

**Depois:**

```bash
readonly KIOSK_TEMP_DIR="$KIOSK_BASE_DIR/tmp"
```

**Justificativa:** O setup cria o diretório temporário como `/opt/kiosk/tmp`, não `/tmp/kiosk`.

### 2. **Adicionado KIOSK_SERVER_FILES_DIR**

**Novo:**

```bash
readonly KIOSK_SERVER_FILES_DIR="$KIOSK_SERVER_DIR/files"
```

**Justificativa:** O print.js salva arquivos PDF temporários em `$KIOSK_SERVER_DIR/files`, que precisa ser limpo durante a desinstalação.

### 3. **Limpeza de Arquivos Temporários**

**Adicionado:**

```bash
# Clean up print server temporary files first
if [[ -d "$KIOSK_SERVER_FILES_DIR" ]]; then
    log_info "Limpando arquivos temporários do servidor de impressão..."
    local temp_files=$(find "$KIOSK_SERVER_FILES_DIR" -name "*.pdf" 2>/dev/null | wc -l)
    if [[ $temp_files -gt 0 ]]; then
        log_info "Removendo $temp_files arquivo(s) PDF temporário(s)..."
        rm -f "$KIOSK_SERVER_FILES_DIR"/*.pdf 2>/dev/null || true
        log_success "✅ Arquivos temporários removidos"
    fi
fi
```

**Justificativa:** Remove arquivos PDF temporários antes de remover os diretórios.

### 4. **Ordem de Remoção Corrigida**

**Antes:**

```bash
directories_to_remove=(
    "$KIOSK_SCRIPTS_DIR"
    "$KIOSK_SERVER_DIR"
    "$KIOSK_UTILS_DIR"
    "$KIOSK_TEMPLATES_DIR"
    "$KIOSK_BASE_DIR"
    "$KIOSK_TEMP_DIR"
    "$PDF_DOWNLOAD_DIR"
)
```

**Depois:**

```bash
directories_to_remove=(
    "$KIOSK_SCRIPTS_DIR"
    "$KIOSK_SERVER_DIR"
    "$KIOSK_UTILS_DIR"
    "$KIOSK_TEMPLATES_DIR"
    "$KIOSK_TEMP_DIR"
    "$KIOSK_BASE_DIR"
    "$PDF_DOWNLOAD_DIR"
)
```

**Justificativa:** Remove subdiretorios antes do diretório base para evitar erros.

### 5. **Variáveis de Ambiente Atualizadas**

**Adicionado:**

```bash
"KIOSK_TEMP_DIR"
```

**Justificativa:** Inclui a variável KIOSK_TEMP_DIR na lista de limpeza de variáveis de ambiente.

### 6. **Compatibilidade com Versões Anteriores**

**Mantido:**

```bash
# Legacy temporary directories (for backward compatibility)
readonly PDF_DOWNLOAD_DIR="/tmp/kiosk-badges"
```

**Justificativa:** Mantém compatibilidade com instalações antigas que podem ter usado este diretório.

## 📋 Estrutura Final de Diretórios

### Setup Cria:

```
/opt/kiosk/                    # KIOSK_BASE_DIR
├── scripts/                   # KIOSK_SCRIPTS_DIR
├── server/                    # KIOSK_SERVER_DIR
│   └── files/                 # KIOSK_SERVER_FILES_DIR (arquivos temporários)
├── utils/                     # KIOSK_UTILS_DIR
├── templates/                 # KIOSK_TEMPLATES_DIR
└── tmp/                       # KIOSK_TEMP_DIR
```

### Uninstall Remove:

1. Arquivos PDF temporários em `/opt/kiosk/server/files/`
2. Todos os subdiretorios (`scripts/`, `server/`, `utils/`, `templates/`, `tmp/`)
3. Diretório base `/opt/kiosk/`
4. Diretório legacy `/tmp/kiosk-badges/` (se existir)

## 🔍 Validações Realizadas

- ✅ Sintaxe do script correta
- ✅ KIOSK_TEMP_DIR consistente entre setup e uninstall
- ✅ Limpeza de arquivos temporários implementada
- ✅ Ordem de remoção otimizada
- ✅ Variáveis de ambiente completas
- ✅ Compatibilidade com versões anteriores mantida

## 📄 Arquivos Modificados

- ✅ **`dist/kiosk/scripts/uninstall.sh`** - Script principal atualizado
- ✅ **`tests/test-uninstall-directories.sh`** - Teste de validação criado
- ✅ **`docs/development/UNINSTALL-DIRECTORIES.md`** - Esta documentação

## 🎯 Resultado

O script de desinstalação agora corresponde **exatamente** à estrutura de diretórios criada pelo script de setup, garantindo uma remoção completa e consistente de todos os componentes do sistema kiosk.
