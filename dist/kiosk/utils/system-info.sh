#!/bin/bash

# =============================================================================
# Kiosk System Information Display Script - Production Version
# =============================================================================
# Purpose: Display comprehensive kiosk system status and information
# Target: Raspberry Pi OS Lite (Debian 12 "bookworm") - Production Only
# Version: 1.0.0
# Usage: ./utils/system-info.sh
# Dependencies: Linux system commands only
# =============================================================================

# Script configuration
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "${0:-system-info.sh}")"
readonly RPI_SETUP_VERSION="1.2.0"

# Configuration and state files
readonly GLOBAL_ENV_FILE="/etc/environment"
readonly PREPARATION_LOG="/var/log/rpi-preparation.log"
readonly KIOSK_LOG="/var/log/kiosk-setup.log"
readonly PREPARATION_STATE="/var/lib/rpi-preparation-state"
readonly KIOSK_STATE="/var/lib/kiosk-setup-state"

# Load kiosk configuration from global environment
load_kiosk_config() {
    # Source the environment variables if file exists
    if [[ -f "$GLOBAL_ENV_FILE" ]]; then
        # Extract only the kiosk-related exports
        while IFS= read -r line; do
            if [[ "$line" =~ ^export\ KIOSK_.*= ]]; then
                # Remove 'export ' prefix and evaluate
                eval "${line#export }"
            fi
        done < "$GLOBAL_ENV_FILE"
    fi
}

# Load configuration on script start
load_kiosk_config

# Use loaded variables or defaults
readonly KIOSK_BASE_DIR="${KIOSK_BASE_DIR:-/opt/kiosk}"
readonly KIOSK_SCRIPTS_DIR="${KIOSK_SCRIPTS_DIR:-$KIOSK_BASE_DIR/scripts}"
readonly KIOSK_SERVER_DIR="${KIOSK_SERVER_DIR:-$KIOSK_BASE_DIR/server}"
readonly KIOSK_UTILS_DIR="${KIOSK_UTILS_DIR:-$KIOSK_BASE_DIR/utils}"
readonly KIOSK_TEMPLATES_DIR="${KIOSK_TEMPLATES_DIR:-$KIOSK_BASE_DIR/templates}"
readonly KIOSK_TEMP_DIR="${KIOSK_TEMP_DIR:-$KIOSK_BASE_DIR/tmp}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BLACK='\033[0;30m'
readonly DARKGRAY='\033[1;30m'
readonly NC='\033[0m' # No Color

# =============================================================================
# DISPLAY FUNCTIONS
# =============================================================================

# Exibe uma linha horizontal
echo_divider() {
    echo -e "${DARKGRAY}--------------------------------------------------------${NC}"
}

# Exibe um título
echo_title() {
    echo ""
    echo -e "${1}# ${2}${NC}"
    echo_divider
}

# Exibe o texto com a cor passada como parâmetro em linha
echo_text_line() {
    echo -e -n "${1}${2}:"
    echo -e " ${3}${NC}"
}

# Exibe logo customizado do Kiosk
echo_logo() {
    echo -e "${BLUE}"
    echo "     ██╗  ██╗██╗ ██████╗ ███████╗██╗  ██╗    ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗"
    echo "     ██║ ██╔╝██║██╔═══██╗██╔════╝██║ ██╔╝    ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║"
    echo "     █████╔╝ ██║██║   ██║███████╗█████╔╝     ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║"
    echo "     ██╔═██╗ ██║██║   ██║╚════██║██╔═██╗     ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║"
    echo "     ██║  ██╗██║╚██████╔╝███████║██║  ██╗    ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║"
    echo "     ╚═╝  ╚═╝╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝"
    echo -e "${NC}${CYAN}     ╔═══════════════════════════════════════════════════════════════════════════════════════╗"
    echo "     ║                              RASPBERRY PI KIOSK SYSTEM                                    ║"
    echo -e "     ╚═══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Exibe a versão
echo_version() {
    echo -e "${PURPLE}                                    KIOSK SYSTEM V${SCRIPT_VERSION}${NC}"
}

# Pegar o ID do device (Serial do Raspberry Pi)
get_device_id() {
    grep Serial /proc/cpuinfo | cut -d ' ' -f 2 2>/dev/null || echo "Unknown"
}

# Pegar modelo do Raspberry Pi
get_pi_model() {
    cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo "Unknown"
}

# =============================================================================
# SYSTEM INFORMATION FUNCTIONS
# =============================================================================

# Exibe informações sobre o sistema
echo_info_system() {
    echo_title "${CYAN}" "Informações do Sistema"
    
    local hostname=$(hostname)
    local arch=$(uname -m)
    local device_id=$(get_device_id)
    local pi_model=$(get_pi_model)
    local system=$(lsb_release -ds 2>/dev/null || echo "Unknown")
    local kernel=$(uname -r)
    local datetime=$(date)
    local processors=$(nproc)
    local memory=$(free -h | grep 'Mem:' | awk '{print $2}')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    local uptime_info=$(uptime -p 2>/dev/null || uptime | cut -d, -f1)
    
    echo_text_line "${YELLOW}" "Hostname" "${hostname}"
    echo_text_line "${CYAN}" "Modelo" "${pi_model}"
    echo_text_line "${CYAN}" "Device ID" "${device_id}"
    echo_text_line "${CYAN}" "Arquitetura" "${arch}"
    echo_text_line "${CYAN}" "Sistema" "${system}"
    echo_text_line "${CYAN}" "Kernel" "${kernel}"
    echo_text_line "${CYAN}" "Processadores" "${processors}"
    echo_text_line "${CYAN}" "Memória RAM" "${memory}"
    echo_text_line "${CYAN}" "Uso do disco" "${disk_usage}"
    echo_text_line "${CYAN}" "Tempo ativo" "${uptime_info}"
    echo_text_line "${CYAN}" "Data e hora" "${datetime}"
    echo_text_line "${CYAN}" "Display" "DISPLAY=${DISPLAY:-not set}"
}

# Exibe informações do setup de preparação
echo_setup_preparation() {
    echo_title "${CYAN}" "Status do Setup de Preparação"
    
    local preparation_status="❌ Não executado"
    local last_run="Nunca"
    local log_size="0"
    
    # Verificar se o setup de preparação foi executado
    if [[ -f "$PREPARATION_STATE" ]]; then
        preparation_status="✅ Concluído"
        local state_info=$(cat "$PREPARATION_STATE" 2>/dev/null)
        if [[ -n "$state_info" ]]; then
            last_run=$(echo "$state_info" | grep "timestamp=" | cut -d'=' -f2 | tr -d '"' 2>/dev/null || echo "Unknown")
        fi
    fi
    
    # Verificar tamanho do log
    if [[ -f "$PREPARATION_LOG" ]]; then
        log_size=$(du -h "$PREPARATION_LOG" 2>/dev/null | cut -f1)
    fi
    
    echo_text_line "${YELLOW}" "Status" "${preparation_status}"
    echo_text_line "${CYAN}" "Última execução" "${last_run}"
    echo_text_line "${CYAN}" "Log de preparação" "${PREPARATION_LOG}"
    echo_text_line "${CYAN}" "Tamanho do log" "${log_size}"
    
    # Verificar Node.js
    local nodejs_status="❌ Não instalado"
    local nodejs_version=""
    if command -v node >/dev/null 2>&1; then
        nodejs_version=$(node -v 2>/dev/null)
        nodejs_status="✅ Instalado ($nodejs_version)"
    fi
    echo_text_line "${CYAN}" "Node.js" "${nodejs_status}"
    
    # Verificar PM2
    local pm2_status="❌ Não instalado"
    local pm2_processes="0"
    if command -v pm2 >/dev/null 2>&1; then
        pm2_status="✅ Instalado"
        pm2_processes=$(pm2 list 2>/dev/null | grep -c "online\|stopped\|errored" || echo "0")
    fi
    echo_text_line "${CYAN}" "PM2" "${pm2_status} (${pm2_processes} processos)"
    
    # Verificar CUPS
    local cups_status="❌ Não instalado"
    if command -v lp >/dev/null 2>&1; then
        if systemctl is-active cups >/dev/null 2>&1; then
            cups_status="✅ Ativo"
        else
            cups_status="⚠️ Instalado (inativo)"
        fi
    fi
    echo_text_line "${CYAN}" "CUPS (Impressão)" "${cups_status}"
}

# Exibe informações do setup do kiosk
echo_setup_kiosk() {
    echo_title "${CYAN}" "Status do Setup do Kiosk"
    
    local kiosk_status="❌ Não executado"
    local last_run="Nunca"
    local log_size="0"
    local base_dir_status="❌ Não encontrado"
    
    # Verificar se o setup do kiosk foi executado
    if [[ -f "$KIOSK_STATE" ]]; then
        kiosk_status="✅ Concluído"
        local state_info=$(cat "$KIOSK_STATE" 2>/dev/null)
        if [[ -n "$state_info" ]]; then
            last_run=$(echo "$state_info" | grep "timestamp=" | cut -d'=' -f2 | tr -d '"' 2>/dev/null || echo "Unknown")
        fi
    fi
    
    # Verificar diretório base do kiosk
    if [[ -d "$KIOSK_BASE_DIR" ]]; then
        base_dir_status="✅ Encontrado"
        
        # Verificar subdiretórios
        echo_text_line "${CYAN}" "Scripts dir" "$([[ -d "$KIOSK_SCRIPTS_DIR" ]] && echo "✅" || echo "❌") ($KIOSK_SCRIPTS_DIR)"
        echo_text_line "${CYAN}" "Server dir" "$([[ -d "$KIOSK_SERVER_DIR" ]] && echo "✅" || echo "❌") ($KIOSK_SERVER_DIR)"
        echo_text_line "${CYAN}" "Utils dir" "$([[ -d "$KIOSK_UTILS_DIR" ]] && echo "✅" || echo "❌") ($KIOSK_UTILS_DIR)"
        echo_text_line "${CYAN}" "Templates dir" "$([[ -d "$KIOSK_TEMPLATES_DIR" ]] && echo "✅" || echo "❌") ($KIOSK_TEMPLATES_DIR)"
    fi
    
    # Verificar tamanho do log
    if [[ -f "$KIOSK_LOG" ]]; then
        log_size=$(du -h "$KIOSK_LOG" 2>/dev/null | cut -f1)
    fi
    
    echo_text_line "${YELLOW}" "Status" "${kiosk_status}"
    echo_text_line "${CYAN}" "Última execução" "${last_run}"
    echo_text_line "${CYAN}" "Diretório base" "${base_dir_status} (${KIOSK_BASE_DIR})"
    echo_text_line "${CYAN}" "Log do kiosk" "${KIOSK_LOG}"
    echo_text_line "${CYAN}" "Tamanho do log" "${log_size}"
}

# Exibe status dos serviços do kiosk
echo_kiosk_services() {
    echo_title "${CYAN}" "Serviços do Kiosk"
    
    local services=(
        "kiosk-splash.service"
        "kiosk-start.service" 
        "kiosk-print-server.service"
    )
    
    for service in "${services[@]}"; do
        local status="❌ Não encontrado"
        local enabled="❌ Desabilitado"
        
        if systemctl list-unit-files 2>/dev/null | grep -q "^${service}"; then
            status="✅ Instalado"
            
            if systemctl is-enabled "$service" >/dev/null 2>&1; then
                enabled="✅ Habilitado"
            fi
            
            if systemctl is-active "$service" >/dev/null 2>&1; then
                status="🟢 Ativo"
            elif systemctl is-failed "$service" >/dev/null 2>&1; then
                status="🔴 Falhou"
            fi
        fi
        
        echo_text_line "${CYAN}" "${service}" "${status} | ${enabled}"
    done
    
    # Verificar status adicional do X11 e desktop
    echo ""
    echo_text_line "${CYAN}" "X11 Server" "$(pgrep Xorg >/dev/null && echo "🟢 Ativo" || echo "❌ Inativo")"
    echo_text_line "${CYAN}" "Chromium" "$(pgrep chromium >/dev/null && echo "🟢 Ativo" || echo "❌ Inativo")"
    echo_text_line "${CYAN}" "Openbox" "$(pgrep openbox >/dev/null && echo "🟢 Ativo" || echo "❌ Inativo")"
}

# Exibe variáveis de ambiente do kiosk
echo_env_vars() {
    echo_title "${CYAN}" "Variáveis de Ambiente do Kiosk"
    
    # Verificar se o arquivo global de ambiente existe
    if [[ -f "$GLOBAL_ENV_FILE" ]]; then
        echo_text_line "${YELLOW}" "Arquivo global env" "✅ Encontrado (${GLOBAL_ENV_FILE})"
        
        # Contar quantas variáveis KIOSK existem
        local kiosk_vars_count=$(grep -c "^export KIOSK_" "$GLOBAL_ENV_FILE" 2>/dev/null)
        echo_text_line "${CYAN}" "Variáveis KIOSK" "${kiosk_vars_count} encontradas"
        
        # Recarregar as variáveis para garantir que estão atualizadas
        load_kiosk_config
        
        echo ""
        echo_text_line "${CYAN}" "Configuração do Sistema:"
        
        # Exibir variáveis principais do kiosk lidas do /etc/environment
        echo_text_line "${CYAN}" "KIOSK_VERSION" "${KIOSK_VERSION:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_APP_MODE" "${KIOSK_APP_MODE:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_APP_URL" "${KIOSK_APP_URL:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_APP_API" "${KIOSK_APP_API:-Not set}"
        
        echo ""
        echo_text_line "${CYAN}" "Servidor de Impressão:"
        echo_text_line "${CYAN}" "KIOSK_PRINT_PORT" "${KIOSK_PRINT_PORT:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_PRINT_HOST" "${KIOSK_PRINT_HOST:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_PRINT_URL" "${KIOSK_PRINT_URL:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_PRINT_SERVER" "${KIOSK_PRINT_SERVER:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_PRINT_SCRIPT" "${KIOSK_PRINT_SCRIPT:-Not set}"
        
        echo ""
        echo_text_line "${CYAN}" "Diretórios do Sistema:"
        echo_text_line "${CYAN}" "KIOSK_BASE_DIR" "${KIOSK_BASE_DIR:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_SCRIPTS_DIR" "${KIOSK_SCRIPTS_DIR:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_SERVER_DIR" "${KIOSK_SERVER_DIR:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_UTILS_DIR" "${KIOSK_UTILS_DIR:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_TEMPLATES_DIR" "${KIOSK_TEMPLATES_DIR:-Not set}"
        echo_text_line "${CYAN}" "KIOSK_TEMP_DIR" "${KIOSK_TEMP_DIR:-Not set}"
        
    else
        echo_text_line "${YELLOW}" "Arquivo global env" "❌ Não encontrado (${GLOBAL_ENV_FILE})"
        echo_text_line "${RED}" "Aviso" "Sistema kiosk pode não estar configurado corretamente"
    fi
    
    # Verificar variáveis de ambiente do sistema
    echo ""
    echo_text_line "${CYAN}" "Variáveis do Sistema:"
    echo_text_line "${CYAN}" "DISPLAY" "${DISPLAY:-not set}"
    echo_text_line "${CYAN}" "USER" "${USER:-not set}"
    echo_text_line "${CYAN}" "HOME" "${HOME:-not set}"
    echo_text_line "${CYAN}" "PATH" "${PATH:0:60}..."
    
    # Verificar autologin
    echo_text_line "${CYAN}" "Usuário logado" "$(who | head -1 | awk '{print $1}' 2>/dev/null || echo "Unknown")"
}

# Exibe informações de rede
echo_network_info() {
    echo_title "${CYAN}" "Informações de Rede"
    
    # IP addresses
    local ip_addresses=$(hostname -I | tr ' ' '\n' | head -3 | tr '\n' ' ')
    echo_text_line "${CYAN}" "IP Addresses" "${ip_addresses:-Unknown}"
    
    # Conectividade de internet
    local internet_status="❌ Sem conexão"
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        internet_status="✅ Conectado"
    fi
    echo_text_line "${CYAN}" "Internet" "${internet_status}"
    
    # Gateway padrão
    local gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    echo_text_line "${CYAN}" "Gateway" "${gateway:-Unknown}"
    
    # DNS servers
    local dns_servers=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
    echo_text_line "${CYAN}" "DNS Servers" "${dns_servers:-Unknown}"
    
    # Interfaces de rede ativas
    local active_interfaces=$(ip -o link show | grep "state UP" | cut -d: -f2 | tr '\n' ' ')
    echo_text_line "${CYAN}" "Interfaces ativas" "${active_interfaces:-Unknown}"
    
    # WiFi information (se disponível)
    if command -v iwgetid >/dev/null 2>&1; then
        local wifi_ssid=$(iwgetid -r 2>/dev/null || echo "Not connected")
        echo_text_line "${CYAN}" "WiFi SSID" "${wifi_ssid}"
    fi
}

# Exibe status de hardware específico do Raspberry Pi
echo_hardware_status() {
    echo_title "${CYAN}" "Status do Hardware"
    
    # Temperatura da CPU
    local cpu_temp="Unknown"
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
        cpu_temp="$((temp_raw / 1000))°C"
    fi
    echo_text_line "${CYAN}" "Temperatura CPU" "${cpu_temp}"
    
    # Status do throttling
    local throttle_status="Unknown"
    if command -v vcgencmd >/dev/null 2>&1; then
        throttle_status=$(vcgencmd get_throttled 2>/dev/null | cut -d'=' -f2)
        if [[ "$throttle_status" == "0x0" ]]; then
            throttle_status="✅ Normal"
        else
            throttle_status="⚠️ Throttled ($throttle_status)"
        fi
    fi
    echo_text_line "${CYAN}" "Throttling" "${throttle_status}"
    
    # GPU Memory
    local gpu_mem="Unknown"
    if command -v vcgencmd >/dev/null 2>&1; then
        gpu_mem=$(vcgencmd get_mem gpu 2>/dev/null | cut -d'=' -f2)
    fi
    echo_text_line "${CYAN}" "GPU Memory" "${gpu_mem}"
    
    # Voltagem
    local core_volt="Unknown"
    if command -v vcgencmd >/dev/null 2>&1; then
        core_volt=$(vcgencmd measure_volts core 2>/dev/null | cut -d'=' -f2)
    fi
    echo_text_line "${CYAN}" "Core Voltage" "${core_volt}"
    
    # Frequência da CPU
    local cpu_freq="Unknown"
    if command -v vcgencmd >/dev/null 2>&1; then
        cpu_freq=$(vcgencmd measure_clock arm 2>/dev/null | cut -d'=' -f2)
        if [[ -n "$cpu_freq" && "$cpu_freq" != "Unknown" ]]; then
            cpu_freq="$((cpu_freq / 1000000))MHz"
        fi
    fi
    echo_text_line "${CYAN}" "CPU Frequency" "${cpu_freq}"
}

# Exibe informações de impressão
echo_print_server_status() {
    echo_title "${CYAN}" "Status do Servidor de Impressão"
    
    # Status do servidor de impressão - usar variável do ambiente ou padrão
    local print_server_port="${KIOSK_PRINT_PORT:-50001}"
    local print_server_host="${KIOSK_PRINT_HOST:-localhost}"
    local print_server_status="❌ Inativo"
    
    if lsof -i :$print_server_port >/dev/null 2>&1; then
        print_server_status="✅ Ativo (porta $print_server_port)"
    fi
    echo_text_line "${CYAN}" "Print Server" "${print_server_status}"
    echo_text_line "${CYAN}" "URL do servidor" "http://${print_server_host}:${print_server_port}"
    
    # Verificar impressoras CUPS
    local cups_printers="0"
    if command -v lpstat >/dev/null 2>&1; then
        cups_printers=$(lpstat -p 2>/dev/null | wc -l)
    fi
    echo_text_line "${CYAN}" "Impressoras CUPS" "${cups_printers} configuradas"
    
    # Verificar arquivos PDF no servidor - usar diretório do ambiente
    local pdf_files="0"
    local server_files_dir="${KIOSK_TEMP_DIR:-/opt/kiosk/tmp}"
    if [[ -d "$server_files_dir" ]]; then
        pdf_files=$(find "$server_files_dir" -name "*.pdf" 2>/dev/null | wc -l)
    fi
    echo_text_line "${CYAN}" "PDFs temporários" "${pdf_files} arquivos em ${server_files_dir}"
    
    # Status dos scripts Python de impressão - usar caminhos do ambiente
    local print_script="${KIOSK_PRINT_SCRIPT:-${KIOSK_SCRIPTS_DIR:-/opt/kiosk/scripts}/print.py}"
    local server_script="${KIOSK_PRINT_SERVER:-${KIOSK_SERVER_DIR:-/opt/kiosk/server}/print.js}"
    
    echo ""
    echo_text_line "${CYAN}" "Script Python" "$([[ -f "$print_script" ]] && echo "✅ Encontrado" || echo "❌ Não encontrado") ($print_script)"
    echo_text_line "${CYAN}" "Server Node.js" "$([[ -f "$server_script" ]] && echo "✅ Encontrado" || echo "❌ Não encontrado") ($server_script)"
    
    # Scripts adicionais comuns
    local common_scripts=(
        "${KIOSK_SCRIPTS_DIR:-/opt/kiosk/scripts}/print-badge.py"
        "${KIOSK_SCRIPTS_DIR:-/opt/kiosk/scripts}/download-pdf.py"
    )
    
    for script in "${common_scripts[@]}"; do
        local script_name=$(basename "$script")
        local script_status="❌ Não encontrado"
        if [[ -f "$script" ]]; then
            script_status="✅ Encontrado"
        fi
        echo_text_line "${CYAN}" "${script_name}" "${script_status}"
    done
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

# Exibe todas as variáveis KIOSK do /etc/environment
echo_all_kiosk_vars() {
    echo_title "${CYAN}" "Todas as Variáveis KIOSK (/etc/environment)"
    
    if [[ -f "$GLOBAL_ENV_FILE" ]]; then
        # Extrair e exibir todas as variáveis KIOSK
        local kiosk_vars=$(grep "^export KIOSK_" "$GLOBAL_ENV_FILE" 2>/dev/null)
        
        if [[ -n "$kiosk_vars" ]]; then
            echo "$kiosk_vars" | while IFS= read -r line; do
                # Remover 'export ' e extrair nome=valor
                local var_line="${line#export }"
                local var_name="${var_line%%=*}"
                local var_value="${var_line#*=}"
                # Remover aspas se existirem
                var_value="${var_value#\"}"
                var_value="${var_value%\"}"
                
                echo_text_line "${CYAN}" "$var_name" "$var_value"
            done
        else
            echo_text_line "${YELLOW}" "Aviso" "Nenhuma variável KIOSK encontrada em $GLOBAL_ENV_FILE"
        fi
    else
        echo_text_line "${RED}" "Erro" "Arquivo $GLOBAL_ENV_FILE não encontrado"
    fi
}

# Função principal
main() {
    clear
    echo_logo
    echo_version
    echo ""
    
    echo_info_system
    echo_setup_preparation
    echo_setup_kiosk
    echo_kiosk_services
    echo_env_vars
    echo_all_kiosk_vars
    echo_network_info
    echo_hardware_status
    echo_print_server_status
    
    echo ""
    echo_divider
    echo -e "${GREEN}✅ Informações do sistema kiosk exibidas com sucesso!${NC}"
    echo -e "${CYAN}💡 Para atualizar as informações, execute novamente: ${SCRIPT_NAME}${NC}"
    echo -e "${CYAN}📋 Sistema: $(get_pi_model) | Device: $(get_device_id)${NC}"
    echo -e "${CYAN}🔧 Configuração: ${KIOSK_VERSION:-Não configurado} | Modo: ${KIOSK_APP_MODE:-Não definido}${NC}"
    echo ""
}

# =============================================================================
# EXECUTION
# =============================================================================

# Verificar se está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
