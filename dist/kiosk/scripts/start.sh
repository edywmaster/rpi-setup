#!/bin/bash

# Função para carregar configurações do kiosk de /etc/environment
load_kiosk_config() {
    # Verificar se /etc/environment existe
    if [[ ! -f /etc/environment ]]; then
        echo "⚠️ Arquivo /etc/environment não encontrado"
        return 1
    fi
    
    # Carregar apenas variáveis KIOSK exportadas
    set -a  # Exportar todas as variáveis definidas
    source <(grep '^export KIOSK_' /etc/environment 2>/dev/null || true)
    set +a  # Desativar exportação automática
    
    echo "✅ Configurações KIOSK carregadas de /etc/environment"
}

# Função para exibir variáveis KIOSK carregadas
show_kiosk_vars() {
    echo ""
    echo "📋 Variáveis KIOSK carregadas:"
    echo "────────────────────────────────"
    
    # Listar todas as variáveis KIOSK definidas
    env | grep '^KIOSK_' | sort | while IFS='=' read -r var value; do
        echo "  $var = $value"
    done
    
    echo "────────────────────────────────"
    echo ""
}

clear
# Mostra uma mensagem inicial no terminal
echo "🚀 Iniciando o Kiosk System"
sleep 2



kiosk_start() {
  echo ""
  echo "🚀 Iniciando o Kiosk System"
  show_kiosk_vars
  sleep 15
  startx > /dev/null 2>&1
  bash "$HOME/.config/openbox/autostart"
}

ssh_start() {
  echo ""
  echo "Kiosk System"
  load_kiosk_config
  exit 0
}


# Verificar se o script está sendo executado via SSH
if [ -n "$SSH_CONNECTION" ]; then
  ssh_start
else
  kiosk_start
fi