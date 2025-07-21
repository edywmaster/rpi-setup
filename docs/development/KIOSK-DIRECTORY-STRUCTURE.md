# Kiosk System - Directory Structure Standard

## Overview

Este documento define a estrutura padrão de diretórios do sistema kiosk que **DEVE ser seguida** em todo o projeto. Esta estrutura é criada pelo `setup-kiosk.sh` e removida pelo `uninstall.sh`.

## 📁 Standard Directory Structure

### Base Structure

```
/opt/kiosk/                          # KIOSK_BASE_DIR (Base principal)
├── scripts/                         # KIOSK_SCRIPTS_DIR (Scripts do sistema)
├── server/                          # KIOSK_SERVER_DIR (Servidor Node.js)
│   ├── print.js                     # Servidor de impressão
│   ├── package.json                 # Dependências Node.js
│   └── .env                         # Configurações do servidor
├── utils/                           # KIOSK_UTILS_DIR (Utilitários Python)
│   └── printer.py                   # Script de impressão CUPS
├── templates/                       # KIOSK_TEMPLATES_DIR (Templates visuais)
│   ├── splash.jpg                   # Splash screen base
│   └── splash_version.jpg           # Splash screen com versão
├── tmp/                             # KIOSK_TEMP_DIR (Arquivos temporários e PDFs)
└── kiosk.conf                       # KIOSK_CONFIG_FILE (Configuração principal)
```

## 🔧 Directory Constants

### Setup Script Constants

**File**: `scripts/setup-kiosk.sh`

```bash
# Kiosk system structure
readonly KIOSK_BASE_DIR="/opt/kiosk"
readonly KIOSK_SCRIPTS_DIR="$KIOSK_BASE_DIR/scripts"
readonly KIOSK_SERVER_DIR="$KIOSK_BASE_DIR/server"
readonly KIOSK_UTILS_DIR="$KIOSK_BASE_DIR/utils"
readonly KIOSK_TEMPLATES_DIR="$KIOSK_BASE_DIR/templates"
readonly KIOSK_TEMP_DIR="$KIOSK_BASE_DIR/tmp"

# Configuration files
readonly KIOSK_CONFIG_FILE="$KIOSK_BASE_DIR/kiosk.conf"
readonly GLOBAL_ENV_FILE="/etc/environment"
readonly STATE_FILE="/var/lib/kiosk-setup-state"
```

### Uninstall Script Constants

**File**: `dist/kiosk/scripts/uninstall.sh`

```bash
# Kiosk system structure (must match setup-kiosk.sh)
readonly KIOSK_BASE_DIR="/opt/kiosk"
readonly KIOSK_SCRIPTS_DIR="$KIOSK_BASE_DIR/scripts"
readonly KIOSK_SERVER_DIR="$KIOSK_BASE_DIR/server"
readonly KIOSK_UTILS_DIR="$KIOSK_BASE_DIR/utils"
readonly KIOSK_TEMPLATES_DIR="$KIOSK_BASE_DIR/templates"
readonly KIOSK_TEMP_DIR="$KIOSK_BASE_DIR/tmp"
```

## 📂 Directory Creation Process

### Automatic Creation (setup-kiosk.sh)

1. **Base Directory**:

   ```bash
   mkdir -p "$KIOSK_BASE_DIR"
   ```

2. **Main Subdirectories**:

   ```bash
   local directories=(
       "scripts"
       "server"
       "utils"
       "templates"
   )

   for dir in "${directories[@]}"; do
       mkdir -p "$KIOSK_BASE_DIR/$dir"
   done
   ```

3. **Server and Temp Directories**:
   ```bash
   mkdir -p "$KIOSK_TEMP_DIR"
   ```

### Directory Removal (uninstall.sh)

```bash
local directories_to_remove=(
    "$KIOSK_SCRIPTS_DIR"
    "$KIOSK_SERVER_DIR"
    "$KIOSK_UTILS_DIR"
    "$KIOSK_TEMPLATES_DIR"
    "$KIOSK_TEMP_DIR"
    "$KIOSK_BASE_DIR"
    "$PDF_DOWNLOAD_DIR"  # Legacy cleanup
)
```

## 🎯 Purpose of Each Directory

### `/opt/kiosk/scripts/`

- **Purpose**: System automation scripts
- **Contents**: Initialization scripts, helper scripts
- **Example**: `start.sh`, `kiosk.sh`

### `/opt/kiosk/server/`

- **Purpose**: Node.js print server application
- **Contents**:
  - `print.js` - Main server application
  - `package.json` - Node.js dependencies
  - `.env` - Environment configuration

### `/opt/kiosk/utils/`

- **Purpose**: Python utility scripts
- **Contents**:
  - `printer.py` - CUPS printing interface
  - Other Python helper scripts

### `/opt/kiosk/templates/`

- **Purpose**: Visual templates and assets
- **Contents**:
  - `splash.jpg` - Base splash screen
  - `splash_version.jpg` - Versioned splash screen
  - Other visual assets

### `/opt/kiosk/tmp/`

- **Purpose**: Temporary files and PDF downloads
- **Contents**:
  - Runtime temporary files
  - Downloaded PDF files for printing
  - Print queue temporary storage
- **Note**: Different from `/tmp/kiosk-badges` (legacy)

## 🔄 System Integration Files

### Configuration Files

```
/opt/kiosk/kiosk.conf              # Main configuration
/etc/environment                   # Global environment variables
/var/lib/kiosk-setup-state         # Installation state
```

### Systemd Services

```
/etc/systemd/system/kiosk-splash.service       # Boot splash screen
/etc/systemd/system/kiosk-start.service        # Kiosk startup
/etc/systemd/system/kiosk-print-server.service # Print server
```

### Log Files

```
/var/log/kiosk-setup.log           # Setup log
/var/log/kiosk-uninstall.log       # Uninstall log
/var/log/kiosk-print-server.log    # Print server log
/var/log/kiosk-printer.log         # Python printer log
```

## ⚠️ Important Rules

### 1. **Consistency Requirement**

- All scripts must use the same directory constants
- Setup and uninstall scripts must be synchronized
- No hardcoded paths outside of constants

### 2. **Cross-Script Compatibility**

- Directory structure must work across all scripts
- Environment variables must match directory constants
- Validation scripts must check consistency

### 3. **Development Guidelines**

- Always define directories as constants at script top
- Use variables, never hardcode paths in functions
- Include comments explaining directory purpose

### 4. **Testing Requirements**

- Test directory creation on clean systems
- Validate complete removal during uninstall
- Check permissions and ownership

## 🔍 Validation

### Structure Validation Script

**File**: `tests/test-uninstall-directories.sh`

Validates:

- ✅ Directory constant consistency between setup and uninstall
- ✅ Proper directory creation order
- ✅ Complete removal during uninstall
- ✅ Environment variable alignment

### Manual Validation

```bash
# Check setup constants
grep "readonly KIOSK.*_DIR=" scripts/setup-kiosk.sh

# Check uninstall constants
grep "readonly KIOSK.*_DIR=" dist/kiosk/scripts/uninstall.sh

# Validate syntax
bash -n scripts/setup-kiosk.sh
bash -n dist/kiosk/scripts/uninstall.sh
```

## 📋 Development Checklist

When creating or modifying scripts:

- [ ] Use defined directory constants
- [ ] Don't hardcode paths
- [ ] Test directory creation
- [ ] Test directory removal
- [ ] Update uninstall script if needed
- [ ] Validate syntax on macOS
- [ ] Test functionality on Raspberry Pi
- [ ] Update documentation if structure changes

---

**Remember**: This directory structure is the foundation of the kiosk system. All components depend on it being consistent and properly maintained!
