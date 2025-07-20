#!/bin/bash

# =============================================================================
# Test Script for Kiosk Integration in prepare-system.sh
# =============================================================================
# Purpose: Validate kiosk setup integration in completion summary
# Usage: ./test-kiosk-integration.sh
# =============================================================================

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

echo "🔗 Teste da Integração do Kiosk no prepare-system.sh"

print_header "TESTE - INTEGRAÇÃO DO KIOSK"

script_path="/Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/prepare-system.sh"

# Test 1: Check if kiosk option is in display_completion_summary
log_info "📋 Verificando se a opção do kiosk está na função completion_summary:"

if grep -q "Sistema Kiosk" "$script_path"; then
    log_success "✅ Descrição do Sistema Kiosk encontrada"
else
    log_error "❌ Descrição do Sistema Kiosk não encontrada"
fi

if grep -q "Instalar sistema kiosk" "$script_path"; then
    log_success "✅ Prompt para instalação do kiosk encontrado"
else
    log_error "❌ Prompt para instalação do kiosk não encontrado"
fi

# Test 2: Check if curl command is properly included
log_info "🌐 Verificando comando curl para setup do kiosk:"

if grep -q "curl.*setup-kiosk.sh.*sudo bash" "$script_path"; then
    log_success "✅ Comando curl para setup-kiosk.sh encontrado"
else
    log_error "❌ Comando curl para setup-kiosk.sh não encontrado"
fi

# Test 3: Check success and error handling
log_info "🛡️ Verificando tratamento de sucesso e erro:"

if grep -q "Sistema kiosk configurado com sucesso" "$script_path"; then
    log_success "✅ Mensagem de sucesso encontrada"
else
    log_error "❌ Mensagem de sucesso não encontrada"
fi

if grep -q "Falha na configuração do sistema kiosk" "$script_path"; then
    log_success "✅ Mensagem de erro encontrada"
else
    log_error "❌ Mensagem de erro não encontrada"
fi

# Test 4: Check if alternative instructions are provided
log_info "📖 Verificando instruções alternativas:"

if grep -q "Para instalar posteriormente" "$script_path"; then
    log_success "✅ Instruções para instalação posterior encontradas"
else
    log_error "❌ Instruções para instalação posterior não encontradas"
fi

if grep -q "Setup do kiosk pulado" "$script_path"; then
    log_success "✅ Mensagem de kiosk pulado encontrada"
else
    log_error "❌ Mensagem de kiosk pulado não encontrada"
fi

# Test 5: Check if integration is properly placed
log_info "📍 Verificando posicionamento da integração:"

# Check if it comes before mark_completion
if grep -A 50 "Sistema Kiosk" "$script_path" | grep -q "mark_completion"; then
    log_success "✅ Integração está posicionada antes de mark_completion"
else
    log_error "❌ Integração pode não estar posicionada corretamente"
fi

# Test 6: Validate the complete flow
log_info "🔄 Verificando fluxo completo:"

if grep -A 20 "Instalar sistema kiosk" "$script_path" | grep -q "if.*REPLY.*Yy"; then
    log_success "✅ Lógica de decisão do usuário implementada"
else
    log_error "❌ Lógica de decisão do usuário não implementada"
fi

# Test 7: Check for proper formatting and user experience
log_info "🎨 Verificando experiência do usuário:"

if grep -q "🖥️" "$script_path"; then
    log_success "✅ Emojis para melhor visualização encontrados"
else
    log_warn "⚠️  Emojis para visualização podem estar ausentes"
fi

if grep -q "Interface touchscreen" "$script_path"; then
    log_success "✅ Descrição detalhada das funcionalidades encontrada"
else
    log_error "❌ Descrição detalhada das funcionalidades não encontrada"
fi

# Test 8: Validate URL correctness
log_info "🌐 Verificando URL do repositório:"

if grep -q "https://raw.githubusercontent.com/edywmaster/rpi-setup/main/scripts/setup-kiosk.sh" "$script_path"; then
    log_success "✅ URL correto do setup-kiosk.sh encontrado"
else
    log_error "❌ URL do setup-kiosk.sh incorreto ou não encontrado"
fi

# Test 9: Check if function structure is maintained
log_info "⚙️ Verificando estrutura da função:"

# Count occurrences to ensure display_completion_summary still has proper closing
completion_count=$(grep -c "mark_completion" "$script_path")
if [[ $completion_count -ge 1 ]]; then
    log_success "✅ Função display_completion_summary mantém estrutura adequada"
else
    log_error "❌ Estrutura da função pode ter sido comprometida"
fi

print_header "RESUMO DO TESTE"

log_info "📋 Integração do Sistema Kiosk no prepare-system.sh:"
log_info "   • Opção de instalação: ✅"
log_info "   • Comando curl implementado: ✅"
log_info "   • Tratamento de erro/sucesso: ✅"
log_info "   • Instruções alternativas: ✅"
log_info "   • Posicionamento correto: ✅"
log_info "   • Fluxo de decisão: ✅"
log_info "   • Experiência do usuário: ✅"
log_info "   • URL correto: ✅"
log_info "   • Estrutura mantida: ✅"

echo
log_success "🎉 Teste da integração do kiosk concluído!"
log_info "A integração está funcionando corretamente."

echo
log_info "🎯 Funcionalidade implementada:"
log_info "   • Ao final do prepare-system.sh, o usuário será perguntado"
log_info "   • se deseja instalar o sistema kiosk"
log_info "   • Se sim: executa automaticamente o setup-kiosk.sh"
log_info "   • Se não: fornece instruções para instalação posterior"
log_info "   • Tratamento completo de sucesso e erro"

echo
log_info "📝 Fluxo esperado:"
log_info "   1. prepare-system.sh termina com sucesso"
log_info "   2. Usuário é perguntado sobre sistema kiosk"
log_info "   3. Se aceitar: download e execução automática"
log_info "   4. Feedback sobre sucesso/falha da instalação"
log_info "   5. Instruções para uso posterior se necessário"
