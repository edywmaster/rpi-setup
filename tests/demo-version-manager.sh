#!/bin/bash

# =============================================================================
# Version Manager Integration Test
# =============================================================================
# Purpose: Demonstrate the complete version management workflow
# Version: 1.0.0
# =============================================================================

set -eo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Project root
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
readonly VERSION_MANAGER="$PROJECT_ROOT/scripts/version-manager.sh"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_header() {
    echo
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
}

# Demonstrate complete workflow
demonstrate_workflow() {
    log_header "Demonstração do Workflow de Versionamento"
    
    echo "Este script demonstra como usar o sistema centralizado de"
    echo "versionamento do projeto rpi-setup:"
    echo
    
    # 1. Show current version
    log_info "1. Mostrando informações da versão atual:"
    echo "   Comando: ./scripts/version-manager.sh --current"
    echo
    "$VERSION_MANAGER" --current
    echo
    
    # 2. Validate consistency
    log_info "2. Validando consistência de versões:"
    echo "   Comando: ./scripts/version-manager.sh --validate"
    echo
    "$VERSION_MANAGER" --validate
    echo
    
    # 3. Show help
    log_info "3. Mostrando ajuda completa:"
    echo "   Comando: ./scripts/version-manager.sh --help"
    echo
    "$VERSION_MANAGER" --help
    echo
}

# Show integration with development workflow
show_development_workflow() {
    log_header "Workflow Recomendado para Desenvolvedores"
    
    cat << 'EOF'
PASSO A PASSO PARA DESENVOLVIMENTO:

1. ANTES DE FAZER MUDANÇAS:
   • Verificar versão atual:
     ./scripts/version-manager.sh --current
   
   • Validar consistência:
     ./scripts/version-manager.sh --validate

2. DURANTE O DESENVOLVIMENTO:
   • Fazer suas alterações normalmente
   • Testar funcionalidades
   • Validar estrutura com: ./tests/validate-structure.sh

3. APÓS IMPLEMENTAR NOVA FUNCIONALIDADE:
   • Atualizar versão do projeto:
     ./scripts/version-manager.sh --update X.Y.Z "Descrição da mudança"
   
   • Validar que tudo foi atualizado:
     ./scripts/version-manager.sh --validate

4. ANTES DE COMMIT:
   • Executar todos os testes:
     ./tests/test-version-manager.sh
   
   • Verificar estrutura:
     ./tests/validate-structure.sh
   
   • Se tudo OK, fazer commit

EXEMPLOS DE USO:

# Atualização de patch (bug fix)
./scripts/version-manager.sh --update 1.3.2 "Bug Fix: Corrigido erro no setup"

# Atualização minor (nova funcionalidade)
./scripts/version-manager.sh --update 1.4.0 "New Feature: Sistema de backup"

# Atualização major (mudanças incompatíveis)
./scripts/version-manager.sh --update 2.0.0 "Major Update: Nova arquitetura"

BENEFÍCIOS DO SISTEMA:

✅ Versionamento centralizado e consistente
✅ Atualização automática em todos os arquivos
✅ Histórico de versões mantido automaticamente
✅ Validação de consistência integrada
✅ Release notes geradas automaticamente
✅ Integração com workflow de desenvolvimento

EOF
}

# Show file locations and structure
show_file_structure() {
    log_header "Estrutura de Arquivos de Versionamento"
    
    echo "ARQUIVOS GERENCIADOS PELO SISTEMA:"
    echo
    echo "📁 Arquivo de Configuração:"
    echo "   .version                     # Configuração central de versões"
    echo
    echo "📁 Scripts Principais:"
    echo "   prepare-system.sh            # Script principal (SCRIPT_VERSION)"
    echo "   scripts/setup-kiosk.sh       # Setup do kiosk (SCRIPT_VERSION)"
    echo
    echo "📁 Documentação:"
    echo "   docs/development/RELEASE-NOTES.md  # Release notes atualizadas"
    echo "   README.md                    # README principal"
    echo "   docs/README.md               # README da documentação"
    echo "   docs/production/*.md         # Documentação de produção"
    echo
    echo "📁 Scripts de Gestão:"
    echo "   scripts/version-manager.sh   # Gerenciador de versões"
    echo "   tests/test-version-manager.sh # Testes do sistema"
    echo
    echo "COMANDO PARA VERIFICAR ARQUIVOS:"
    echo "   find . -name '*.sh' -o -name '*.md' | grep -E '(version|VERSION|prepare|setup)'"
    echo
}

# Test workflow simulation
test_workflow_simulation() {
    log_header "Simulação de Workflow de Desenvolvimento"
    
    echo "Esta seção simula um workflow completo de desenvolvimento:"
    echo
    
    # Save current state
    local current_version
    current_version=$("$VERSION_MANAGER" --current 2>/dev/null | grep "Versão Principal:" | cut -d: -f2 | xargs)
    
    log_info "Estado inicial: Versão $current_version"
    echo
    
    # Simulate making changes
    log_info "Simulando desenvolvimento de nova funcionalidade..."
    echo "   (Normalmente você faria suas mudanças no código aqui)"
    echo
    
    # Show what developer would do
    log_info "Desenvolvedor terminou a funcionalidade e quer atualizar versão:"
    echo "   Comando que seria executado:"
    echo "   ./scripts/version-manager.sh --update 1.3.2 \"New Feature: Exemplo\""
    echo
    
    log_info "Após atualização, desenvolvedor validaria:"
    echo "   ./scripts/version-manager.sh --validate"
    echo
    
    log_info "E executaria testes:"
    echo "   ./tests/test-version-manager.sh"
    echo "   ./tests/validate-structure.sh"
    echo
    
    log_warn "NOTA: Esta é apenas uma simulação. Para atualizar realmente,"
    log_warn "execute os comandos diretamente."
}

# Main function
main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-}" in
        --demo|"")
            demonstrate_workflow
            ;;
        --workflow)
            show_development_workflow
            ;;
        --structure)
            show_file_structure
            ;;
        --simulate)
            test_workflow_simulation
            ;;
        --all)
            demonstrate_workflow
            show_development_workflow
            show_file_structure
            test_workflow_simulation
            ;;
        --help|-h)
            cat << 'EOF'
Version Manager Integration Demo

USAGE:
    ./tests/demo-version-manager.sh [OPTION]

OPTIONS:
    --demo                 Demonstra funcionalidades básicas (padrão)
    --workflow             Mostra workflow recomendado
    --structure            Mostra estrutura de arquivos
    --simulate             Simula workflow de desenvolvimento
    --all                  Executa todas as demonstrações
    --help                 Mostra esta ajuda

EXAMPLES:
    ./tests/demo-version-manager.sh
    ./tests/demo-version-manager.sh --workflow
    ./tests/demo-version-manager.sh --all

EOF
            ;;
        *)
            log_error "Opção inválida: $1"
            log_info "Use --help para ver opções disponíveis"
            return 1
            ;;
    esac
}

# Execute main function
main "$@"
