#!/bin/bash

# =============================================================================
# Validador de Integração das Instruções do Copilot - rpi-setup
# =============================================================================
# Este script valida se as instruções do Copilot estão adequadamente
# integradas à estrutura de documentação do projeto

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
ERRORS=0
WARNINGS=0
SUCCESS=0

log_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((SUCCESS++))
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "🧠 Validando integração das instruções do Copilot..."
echo

# Verificar se arquivo de instruções existe
echo "📋 Verificando arquivo de instruções..."
if [[ -f ".github/copilot-instructions.md" ]]; then
    log_success "Arquivo de instruções existe: .github/copilot-instructions.md"
    
    # Verificar tamanho do arquivo
    local lines=$(wc -l < .github/copilot-instructions.md)
    if [[ $lines -gt 50 ]]; then
        log_success "Arquivo de instruções tem conteúdo substancial ($lines linhas)"
    else
        log_warning "Arquivo de instruções pode estar incompleto ($lines linhas)"
    fi
    
    # Verificar seções importantes
    if grep -q "Project Overview" .github/copilot-instructions.md; then
        log_success "Contém seção 'Project Overview'"
    else
        log_error "Falta seção 'Project Overview'"
    fi
    
    if grep -q "Project Structure" .github/copilot-instructions.md; then
        log_success "Contém seção 'Project Structure'"
    else
        log_error "Falta seção 'Project Structure'"
    fi
    
    if grep -q "Development" .github/copilot-instructions.md; then
        log_success "Contém diretrizes de desenvolvimento"
    else
        log_warning "Pode faltar diretrizes de desenvolvimento específicas"
    fi
    
else
    log_error "Arquivo de instruções não encontrado: .github/copilot-instructions.md"
fi

echo
echo "📚 Verificando integração com docs/README.md..."

if [[ -f "docs/README.md" ]]; then
    # Verificar se há referência às instruções do Copilot
    if grep -q "copilot-instructions.md" docs/README.md; then
        log_success "docs/README.md referencia as instruções do Copilot"
    else
        log_error "docs/README.md não referencia as instruções do Copilot"
    fi
    
    # Verificar se há seção específica para IA
    if grep -q "Instruções para IA" docs/README.md; then
        log_success "docs/README.md tem seção dedicada para instruções de IA"
    else
        log_warning "docs/README.md pode se beneficiar de uma seção dedicada para IA"
    fi
    
    # Verificar se há seção para desenvolvedores mencionando as instruções
    if grep -q "Para Desenvolvedores" docs/README.md && grep -q "copilot-instructions" docs/README.md; then
        log_success "Seção para desenvolvedores menciona as instruções do Copilot"
    else
        log_warning "Seção para desenvolvedores poderia mencionar as instruções do Copilot"
    fi
    
    # Verificar se há seção sobre ferramentas de validação
    if grep -q "Ferramentas de Validação" docs/README.md; then
        log_success "docs/README.md inclui seção sobre ferramentas de validação"
    else
        log_warning "docs/README.md poderia incluir seção sobre ferramentas de validação"
    fi
    
else
    log_error "docs/README.md não encontrado"
fi

echo
echo "🛠️ Verificando ferramentas de validação mencionadas..."

# Verificar se os scripts de validação existem e são mencionados
validation_scripts=(
    "tests/check-docs-reorganization.sh"
    "tests/validate-docs-structure.sh"
    "tests/validate-structure.sh"
)

for script in "${validation_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        log_success "Script de validação existe: $script"
        
        # Verificar se é mencionado no docs/README.md
        script_name=$(basename "$script")
        if [[ -f "docs/README.md" ]] && grep -q "$script_name" docs/README.md; then
            log_success "Script $script_name é mencionado na documentação"
        else
            log_warning "Script $script_name poderia ser mencionado na documentação"
        fi
    else
        log_error "Script de validação não encontrado: $script"
    fi
done

echo
echo "🔗 Verificando consistência das referências..."

if [[ -f "docs/README.md" ]] && [[ -f ".github/copilot-instructions.md" ]]; then
    # Verificar se a estrutura mencionada nas instruções está atualizada
    if grep -q "docs/production/" .github/copilot-instructions.md; then
        log_success "Instruções do Copilot mencionam estrutura docs/production/"
    else
        log_warning "Instruções do Copilot deveriam mencionar estrutura docs/production/"
    fi
    
    if grep -q "docs/development/" .github/copilot-instructions.md; then
        log_success "Instruções do Copilot mencionam estrutura docs/development/"
    else
        log_warning "Instruções do Copilot deveriam mencionar estrutura docs/development/"
    fi
fi

echo
echo "📊 Resumo da validação de integração:"
echo -e "  ${GREEN}Sucessos: $SUCCESS${NC}"
echo -e "  ${YELLOW}Avisos: $WARNINGS${NC}"
echo -e "  ${RED}Erros: $ERRORS${NC}"

echo
if [[ $ERRORS -eq 0 ]]; then
    if [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}🎉 Instruções do Copilot perfeitamente integradas!${NC}"
    else
        echo -e "${YELLOW}✅ Instruções do Copilot integradas com algumas melhorias possíveis.${NC}"
    fi
    exit 0
else
    echo -e "${RED}❌ Instruções do Copilot precisam de melhor integração.${NC}"
    exit 1
fi
