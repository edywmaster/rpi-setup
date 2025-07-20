#!/bin/bash

# =============================================================================
# Terminal Output Comparison Demo
# =============================================================================
# Purpose: Demonstrate the difference between v1.0.5 and v1.0.6 output
# Version: 1.0.0
# =============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

demo_old_output() {
    print_header "VERSÃO 1.0.5 - SAÍDA DUPLICADA"
    echo
    echo -e "${CYAN}[INFO]${NC} Verificando: wget"
    echo "[2025-07-20 00:30:07] [INFO] Verificando: wget"
    echo -e "${CYAN}[INFO]${NC} ⚡ wget já está instalado"
    echo "[2025-07-20 00:30:07] [INFO] ⚡ wget já está instalado"
    echo -e "${CYAN}[INFO]${NC} Verificando: curl"
    echo "[2025-07-20 00:30:09] [INFO] Verificando: curl"
    echo -e "${CYAN}[INFO]${NC} ⚡ curl já está instalado"
    echo "[2025-07-20 00:30:09] [INFO] ⚡ curl já está instalado"
    echo -e "${CYAN}[INFO]${NC} Verificando: jq"
    echo "[2025-07-20 00:30:11] [INFO] Verificando: jq"
    echo -e "${CYAN}[INFO]${NC} 📦 Instalando: jq"
    echo "[2025-07-20 00:30:11] [INFO] 📦 Instalando: jq"
    echo -e "${GREEN}[SUCCESS]${NC} ✅ jq instalado com sucesso"
    echo "[2025-07-20 00:30:13] [SUCCESS] ✅ jq instalado com sucesso"
    echo
    echo -e "${YELLOW}❌ Problema:${NC} Saída duplicada polui o terminal"
    echo -e "${YELLOW}❌ Problema:${NC} Timestamps desnecessários na visualização"
    echo -e "${YELLOW}❌ Problema:${NC} Dificulta leitura rápida do progresso"
}

demo_new_output() {
    print_header "VERSÃO 1.0.6 - SAÍDA LIMPA"
    echo
    echo -e "${CYAN}[INFO]${NC} Verificando: wget"
    echo -e "${CYAN}[INFO]${NC} ⚡ wget já está instalado"
    echo -e "${CYAN}[INFO]${NC} Verificando: curl"
    echo -e "${CYAN}[INFO]${NC} ⚡ curl já está instalado"
    echo -e "${CYAN}[INFO]${NC} Verificando: jq"
    echo -e "${CYAN}[INFO]${NC} 📦 Instalando: jq"
    echo -e "${GREEN}[SUCCESS]${NC} ✅ jq instalado com sucesso"
    echo
    echo -e "${GREEN}✅ Melhoria:${NC} Saída clara e concisa"
    echo -e "${GREEN}✅ Melhoria:${NC} Foco na informação essencial"
    echo -e "${GREEN}✅ Melhoria:${NC} Fácil acompanhamento do progresso"
    echo
    echo -e "${BLUE}📋 Nota:${NC} Logs detalhados ainda são salvos em /var/log/rpi-preparation.log"
}

show_comparison() {
    echo
    print_header "COMPARAÇÃO DE LEGIBILIDADE"
    echo
    echo -e "${YELLOW}Linhas de output por operação:${NC}"
    echo "  • v1.0.5: 2 linhas por mensagem (duplicada)"
    echo "  • v1.0.6: 1 linha por mensagem (limpa)"
    echo
    echo -e "${YELLOW}Redução no ruído visual:${NC}"
    echo "  • 50% menos linhas no terminal"
    echo "  • Timestamps removidos da visualização"
    echo "  • Foco na informação essencial"
    echo
    echo -e "${YELLOW}Benefícios para produção:${NC}"
    echo "  • Monitoramento mais fácil"
    echo "  • Logs SSH mais limpos"
    echo "  • Melhor experiência do usuário"
}

# Main execution
echo
print_header "DEMONSTRAÇÃO - MELHORIA DA INTERFACE"
echo
demo_old_output
echo
echo
demo_new_output
echo
show_comparison
echo
print_header "VERSÃO 1.0.6 PRONTA PARA PRODUÇÃO!"
echo
