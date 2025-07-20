# Copilot Instructions - Raspberry Pi Setup Automation

## Project Overview

This is a Bash automation suite for Raspberry Pi OS Lite (Debian 12 "bookworm") targeting Raspberry Pi 4B devices with portability considerations for other models.

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
