#!/bin/bash

# =============================================================================
# Validador de Estrutura de Documentação - rpi-setup
# =============================================================================
# Este script valida se a estrutura de documentação segue as diretrizes do projeto

set -o pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo "🔍 Validando estrutura de documentação do rpi-setup..."
echo

# Função para verificar se arquivo existe
check_file() {
    local file=$1
    local description=$2
    
    if [[ -f "$file" ]]; then
        log_success "$description existe: $file"
        return 0
    else
        log_error "$description não encontrado: $file"
        return 1
    fi
}

# Função para verificar se diretório existe
check_dir() {
    local dir=$1
    local description=$2
    
    if [[ -d "$dir" ]]; then
        log_success "$description existe: $dir"
        return 0
    else
        log_error "$description não encontrado: $dir"
        return 1
    fi
}

# Função para verificar se arquivo não existe (não deveria estar lá)
check_file_not_exists() {
    local file=$1
    local description=$2
    
    if [[ ! -f "$file" ]]; then
        log_success "$description removido corretamente: $file"
        return 0
    else
        log_warning "$description ainda existe (deveria ter sido removido): $file"
        return 1
    fi
}

echo "📁 Verificando estrutura de diretórios..."

# Verificar diretórios principais
check_dir "docs" "Diretório de documentação principal"
check_dir "docs/production" "Diretório de documentação de produção"
check_dir "docs/development" "Diretório de documentação de desenvolvimento"
check_dir "scripts" "Diretório de scripts"
check_dir "tests" "Diretório de testes"
check_dir ".github" "Diretório de configuração GitHub"

echo
echo "📄 Verificando arquivos principais..."

# Verificar arquivos na raiz (devem existir)
check_file "README.md" "README principal (mínimo, focado no usuário)"
check_file "prepare-system.sh" "Script principal de produção"

echo
echo "📚 Verificando documentação de produção..."

# Verificar documentação de produção
check_file "docs/production/DEPLOYMENT.md" "Guia de implantação"
check_file "docs/production/PREPARE-SYSTEM.md" "Documentação do script principal"

echo
echo "🔧 Verificando documentação de desenvolvimento..."

# Verificar documentação de desenvolvimento
check_file "docs/development/README-DETAILED.md" "README detalhado original"
check_file "docs/development/RELEASE-NOTES.md" "Notas de versão"

echo
echo "📋 Verificando arquivos de navegação..."

# Verificar arquivo de índice
check_file "docs/README.md" "Índice de navegação da documentação"

echo
echo "🧰 Verificando scripts e testes..."

# Verificar scripts
check_file "scripts/deploy-multiple.sh" "Script de implantação múltipla"

# Verificar pelo menos um teste
check_file "tests/test-script.sh" "Script de teste principal"

echo
echo "🧹 Verificando arquivos que deveriam ter sido removidos..."

# Verificar arquivos que não deveriam existir na raiz
check_file_not_exists "DEPLOYMENT.md" "Arquivo duplicado DEPLOYMENT.md"
check_file_not_exists "PREPARE-SYSTEM.md" "Arquivo duplicado PREPARE-SYSTEM.md"
check_file_not_exists "RELEASE-NOTES.md" "Arquivo duplicado RELEASE-NOTES.md"
check_file_not_exists "README-NEW.md" "Arquivo temporário README-NEW.md"
check_file_not_exists "deploy-multiple.sh" "Arquivo duplicado deploy-multiple.sh"
check_file_not_exists "test-script.sh" "Arquivo duplicado test-script.sh"

echo
echo "🔍 Verificando conteúdo dos arquivos principais..."

# Verificar se README.md é minimal
if [[ -f "README.md" ]]; then
    lines=$(wc -l < README.md)
    if [[ $lines -lt 100 ]]; then
        log_success "README.md é minimal ($lines linhas)"
    else
        log_warning "README.md pode estar muito detalhado ($lines linhas) - considere mover detalhes para docs/development/"
    fi
fi

# Verificar se docs/README.md tem links de navegação
if [[ -f "docs/README.md" ]]; then
    if grep -q "production/" docs/README.md && grep -q "development/" docs/README.md; then
        log_success "docs/README.md contém links de navegação"
    else
        log_error "docs/README.md não contém links de navegação adequados"
    fi
fi

echo
echo "📊 Resumo da validação:"
echo -e "  ${GREEN}Sucessos: $SUCCESS${NC}"
echo -e "  ${YELLOW}Avisos: $WARNINGS${NC}"
echo -e "  ${RED}Erros: $ERRORS${NC}"

echo
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}🎉 Estrutura de documentação está correta!${NC}"
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}💡 Há alguns avisos para considerar.${NC}"
    fi
    exit 0
else
    echo -e "${RED}❌ Estrutura de documentação precisa de correções.${NC}"
    exit 1
fi
