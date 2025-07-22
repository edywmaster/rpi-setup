# Copilot Instructions - Raspberry Pi Setup Automation

## Project Overview

This is a Bash automation suite for Raspberry Pi OS Lite (Debian 12 "bookworm") targeting Raspberry Pi 4B devices with portability considerations for other models.

## Development Environment

**Important**: All development and testing is performed on **macOS** environment, while the target deployment is **Raspberry Pi OS Lite (Linux)**.

### Development Context

- **Development OS**: macOS (x86_64/ARM64)
- **Target OS**: Raspberry Pi OS Lite (Debian 12 "bookworm", ARM)
- **Cross-platform considerations**: Scripts must work on Linux despite being developed on macOS

### Testing Limitations on macOS

- **systemctl commands**: Not available natively (systemd is Linux-specific)
- **CUPS printing**: Different implementation between macOS and Linux
- **Hardware-specific features**: GPIO, boot process, splash screens
- **Service management**: systemd services cannot be tested on macOS

### Testing Strategy

- **Static testing on macOS**: Syntax validation, structure checks, logic verification
- **Functional testing on Raspberry Pi**: Full installation, services, hardware integration
- **Cross-platform compatibility**: Ensure scripts work correctly on target Linux environment

### Development Best Practices

- Use `bash -n` for syntax validation on macOS
- Avoid macOS-specific commands in scripts
- Test file paths and permissions logic
- Document Linux-specific requirements clearly
- Validate script structure and variable consistency

## Project Structure

```
rpi-setup/
├── README.md                    # Main user-facing documentation (production-ready)
├── prepare-system.sh            # Main production script
├── docs/                        # All documentation
│   ├── README.md               # Documentation index
│   ├── production/             # Production documentation
│   │   ├── DEPLOYMENT.md       # Large-scale deployment guide
│   │   └── PREPARE-SYSTEM.md   # Detailed script documentation
│   └── development/            # Development documentation
│       ├── README-DETAILED.md  # Original detailed README
│       └── RELEASE-NOTES.md    # Version history and bug fixes
├── scripts/                    # Automation scripts
│   └── deploy-multiple.sh      # Multi-device deployment
├── tests/                      # Test scripts
│   └── test-script.sh         # Validation scripts
└── .github/
    └── copilot-instructions.md # AI development guidelines
```

### Documentation Philosophy

- **README.md**: Keep minimal, production-focused, quick-start only
- **docs/production/**: End-user production documentation
- **docs/development/**: Technical details, changes, development info
- **Separation**: User-facing vs developer-facing content clearly separated

## Core Architecture & Patterns

### Kiosk System Directory Structure

**Standard directory structure that MUST be followed throughout the project:**

```
/opt/kiosk/                          # KIOSK_BASE_DIR
├── scripts/                         # KIOSK_SCRIPTS_DIR
├── server/                          # KIOSK_SERVER_DIR
│   └── files/                       # Temporary PDF files
├── utils/                           # KIOSK_UTILS_DIR
├── templates/                       # KIOSK_TEMPLATES_DIR
└── tmp/                             # KIOSK_TEMP_DIR
```

#### Directory Constants (setup-kiosk.sh):

```bash
readonly KIOSK_BASE_DIR="/opt/kiosk"
readonly KIOSK_SCRIPTS_DIR="$KIOSK_BASE_DIR/scripts"
readonly KIOSK_SERVER_DIR="$KIOSK_BASE_DIR/server"
readonly KIOSK_UTILS_DIR="$KIOSK_BASE_DIR/utils"
readonly KIOSK_TEMPLATES_DIR="$KIOSK_BASE_DIR/templates"
readonly KIOSK_TEMP_DIR="$KIOSK_BASE_DIR/tmp"
```

#### Configuration Files:

- **Config**: `$KIOSK_BASE_DIR/kiosk.conf`
- **Environment**: `/etc/environment`
- **State**: `/var/lib/kiosk-setup-state`

#### Systemd Services:

- `/etc/systemd/system/kiosk-splash.service`
- `/etc/systemd/system/kiosk-start.service`
- `/etc/systemd/system/kiosk-print-server.service`

**Important**: All scripts must use these exact directory constants and structure.

### Script Organization

- **Modular design**: Each script handles a specific domain (network, security, packages, etc.)
- **Idempotent operations**: Scripts can be run multiple times safely
- **Cross-device compatibility**: Support Pi 4B primarily, but maintain portability
- **Logging first**: All operations must generate comprehensive logs

### Target Environment Specifics

- **OS**: Raspberry Pi OS Lite (Debian 12 "bookworm")
- **Shell**: Bash (not sh) - leverage Bash-specific features
- **Package manager**: apt (Debian-based)
- **Init system**: systemd
- **User context**: Expect sudo/root access for system configurations

### Critical Development Patterns

#### Error Handling & Validation

```bash
# Always check command success and provide meaningful errors
if ! command -v git >/dev/null 2>&1; then
    log_error "Git is not installed. Installing..."
    apt-get update && apt-get install -y git || exit 1
fi
```

#### Logging Standards

- Use consistent logging functions: `log_info()`, `log_warn()`, `log_error()`
- Include timestamps and script context
- Log to both stdout and files for debugging
- Validate operations before proceeding

#### System Detection

```bash
# Detect Pi model and OS version for compatibility
PI_MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
OS_VERSION=$(lsb_release -rs 2>/dev/null || echo "Unknown")
```

### Key Integration Points

#### Network Configuration

- Use `systemd-networkd` for network setup (not NetworkManager)
- Configure static IPs via `/etc/systemd/network/` files
- Validate connectivity before proceeding with remote operations

#### Service Management

- Use `systemctl` for all service operations
- Enable services with `--now` flag when appropriate
- Check service status before making changes

#### Package Management

- Always run `apt-get update` before installations
- Use `-y` flag for non-interactive operations
- Handle package conflicts and recommendations explicitly

### Security Considerations

- SSH hardening: disable root login, change default port
- Firewall configuration using `ufw`
- User account management with proper sudo setup
- Certificate and key management for secure communications

### Testing & Validation

- Each script should have a validation function
- Test on clean Pi OS Lite installations
- Verify operations don't break on re-runs
- Include rollback procedures for critical changes

## Development Workflow

### macOS Development Considerations

**All development and testing is performed on macOS targeting Linux deployment**

#### What Works on macOS:

- ✅ Script syntax validation (`bash -n script.sh`)
- ✅ File structure and directory operations
- ✅ Logic flow and variable consistency
- ✅ Documentation and code organization
- ✅ Git operations and version control

#### What Cannot be Tested on macOS:

- ❌ `systemctl` commands (systemd is Linux-specific)
- ❌ CUPS printing system (different implementation)
- ❌ Hardware GPIO and boot processes
- ❌ Service startup and management
- ❌ Raspberry Pi specific features

#### Development Strategy:

1. **Static Analysis on macOS**: Syntax, structure, consistency
2. **Cross-platform Code**: Write Linux-compatible scripts
3. **Documentation**: Clear marking of Linux-specific features
4. **Testing**: Final validation must be done on Raspberry Pi

### Script Creation Template

1. Start with environment detection and validation
2. Define logging and error handling functions
3. Implement idempotent main logic
4. Add validation and testing functions
5. Include usage documentation in script header

### Debugging Approach

- Use `set -e` for strict error handling
- Implement verbose mode with `set -x` option
- Log all system state changes
- Provide manual rollback instructions in comments

#### macOS-Specific Debugging:

- **Syntax validation**: Always use `bash -n script.sh` before deployment
- **Cross-platform testing**: Avoid hardcoded paths that differ between macOS/Linux
- **Service simulation**: Mock systemd commands for development testing
- **Dependency checks**: Verify Linux-specific commands with conditional logic
- **Terminal differences**: Some terminal behaviors may differ between macOS and Linux environments

## File Naming & Structure

- Use descriptive names: `setup-network.sh`, `install-docker.sh`
- Group related scripts in subdirectories if needed
- Include version/compatibility info in headers
- Maintain executable permissions (`chmod +x`)

### File Organization Guidelines

#### Production Files (Root Level)

- `prepare-system.sh` - Main production script
- `README.md` - Minimal, user-focused documentation

#### Documentation Structure

- `docs/production/` - End-user documentation (deployment guides, manuals)
- `docs/development/` - Technical documentation (detailed READMEs, release notes)
- `docs/README.md` - Documentation index and navigation guide

#### Scripts and Tools

- `scripts/` - Utility scripts for automation (deployment, management)
- `tests/` - Testing and validation scripts
- `.github/` - Repository configuration and AI instructions

#### Development Workflow

- Keep user-facing docs minimal and focused
- Move detailed technical content to `docs/development/`
- Use `docs/production/` for operational guides
- Test scripts go in `tests/`, utility scripts in `scripts/`

## Validation Tools and Quality Assurance

### Documentation Structure Validation

The project includes automated tools to ensure documentation structure compliance:

#### Available Validation Scripts

- `tests/check-docs-reorganization.sh` - Quick visual validation of documentation structure
- `tests/validate-docs-structure.sh` - Comprehensive validation with detailed error reporting
- `tests/validate-copilot-integration.sh` - Validates integration of Copilot instructions
- `tests/validate-structure.sh` - General project structure validation

#### Validation Workflow

1. **Before making changes**: Run `./tests/check-docs-reorganization.sh` to see current state
2. **After making changes**: Run validation scripts to ensure compliance
3. **Before committing**: Ensure all validation scripts pass

#### macOS Validation Limitations

**Important**: Since development is done on macOS while targeting Linux:

- **Syntax validation**: Works perfectly on macOS
- **Structure validation**: Fully functional
- **Service validation**: Cannot test systemd services (will show as "not found")
- **Hardware validation**: Cannot test Pi-specific features
- **Final validation**: Must be performed on actual Raspberry Pi hardware

#### Integration Requirements

- All documentation changes must maintain the established structure
- New documentation files should be placed in appropriate directories (`docs/production/` or `docs/development/`)
- The `docs/README.md` file must be updated to reference new documentation
- Validation scripts should be updated if new documentation patterns are introduced

### Quality Standards

- Documentation must be accessible from the `docs/README.md` navigation index
- Copilot instructions must be referenced in developer workflow sections
- All scripts in `tests/` should be executable and provide clear feedback
- Validation tools should provide specific, actionable error messages
- **macOS Development Note**: All code must be written for Linux compatibility despite being developed on macOS
- **Cross-platform Testing**: Static analysis on macOS, functional testing on Raspberry Pi
- **Documentation Requirements**: Clearly mark Linux-specific features and limitations

## Mandatory Validation and Versioning Workflow

### CRITICAL: Always Execute Validation and Versioning

**Before ANY code creation, modification, or correction in this project, you MUST execute the following validation and versioning workflow:**

#### 1. Pre-Change Validation (MANDATORY)

```bash
# Execute BEFORE making any changes
./tests/validate-structure.sh
./tests/validate-docs-structure.sh
./tests/validate-copilot-integration.sh
./scripts/version-manager.sh --validate
```

#### 2. Post-Change Validation (MANDATORY)

```bash
# Execute AFTER making any changes
./tests/validate-structure.sh
./tests/validate-docs-structure.sh
./tests/validate-copilot-integration.sh
./scripts/version-manager.sh --validate
```

#### 3. Version Management (MANDATORY for Significant Changes)

For any **significant changes** (new features, bug fixes, documentation updates):

```bash
# Check current version
./scripts/version-manager.sh --current

# Update version (increment appropriately)
./scripts/version-manager.sh --update <NEW_VERSION>

# Validate version consistency
./scripts/version-manager.sh --validate
```

#### 4. Version Increment Guidelines

- **Patch version** (x.x.X): Bug fixes, documentation corrections, minor improvements
- **Minor version** (x.X.x): New features, script additions, significant documentation
- **Major version** (X.x.x): Breaking changes, major architecture changes

#### 5. Validation Requirements by Change Type

##### Script Creation/Modification

```bash
# Required validations
bash -n <script.sh>                    # Syntax validation (macOS compatible)
./tests/validate-structure.sh         # Project structure
./scripts/version-manager.sh --validate # Version consistency
```

##### Documentation Changes

```bash
# Required validations
./tests/validate-docs-structure.sh    # Documentation structure
./tests/validate-copilot-integration.sh # Copilot integration
./scripts/version-manager.sh --validate # Version consistency
```

##### Configuration Changes

```bash
# Required validations
./tests/validate-structure.sh         # Project structure
./tests/validate-copilot-integration.sh # Copilot integration
./scripts/version-manager.sh --validate # Version consistency
```

### Automated Validation Integration

#### For AI Development (Copilot)

**MANDATORY WORKFLOW FOR ANY CHANGE:**

1. **Pre-execution Analysis**: Before making any file changes, run validation scripts to understand current state
2. **Change Implementation**: Execute the requested changes
3. **Post-execution Validation**: Run validation scripts to ensure compliance
4. **Version Update**: Update version if significant changes were made
5. **Final Verification**: Confirm all validations pass

#### Error Handling in Validation

- **If validation fails**: STOP all operations and report specific errors
- **Fix validation errors**: Address each error before proceeding
- **Re-run validation**: Ensure all validations pass before continuing
- **Document limitations**: Note any macOS vs Linux validation limitations

#### Integration with Git Workflow

```bash
# Pre-commit validation (recommended)
git add .
./tests/validate-structure.sh && \
./tests/validate-docs-structure.sh && \
./scripts/version-manager.sh --validate && \
git commit -m "feat: [description] - validated structure and version"
```

### Validation Script Requirements

All validation scripts MUST:

- Return proper exit codes (0 = success, 1 = failure)
- Provide clear, actionable error messages
- Work correctly on macOS development environment
- Account for macOS vs Linux differences where applicable
- Be executable and self-contained

### Version Management Requirements

All version updates MUST:

- Update version numbers consistently across all files
- Generate or update RELEASE-NOTES.md
- Validate version format (semantic versioning)
- Ensure compatibility with existing deployment scripts
- Include changelog entries for significant changes
