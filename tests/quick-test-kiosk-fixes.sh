#!/bin/bash

# Script de teste rápido para verificar as correções do kiosk fullscreen
# Version 1.4.3

echo "🔧 Testando correções do kiosk-fullscreen..."
echo ""

# 1. Verificar sintaxe do script principal
echo "1️⃣ Verificando sintaxe do setup-kiosk.sh..."
if bash -n /Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/setup-kiosk.sh; then
    echo "✅ Sintaxe válida"
else
    echo "❌ Erro de sintaxe encontrado"
    exit 1
fi

# 2. Verificar se as correções estão presentes
echo ""
echo "2️⃣ Verificando correções implementadas..."

# Verificar se KIOSK_APP_URL está sendo exportada com valor padrão
if grep -q 'export KIOSK_APP_URL="${KIOSK_APP_URL:-http://localhost:3000}"' /Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/setup-kiosk.sh; then
    echo "✅ KIOSK_APP_URL com valor padrão configurada"
else
    echo "❌ KIOSK_APP_URL não configurada adequadamente"
fi

# Verificar se heredoc está sem aspas simples
if grep -q "cat > \"/tmp/autostart\" << AUTOSTART_EOF" /Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/setup-kiosk.sh; then
    echo "✅ Heredoc AUTOSTART_EOF corrigido (sem aspas simples)"
else
    echo "❌ Heredoc AUTOSTART_EOF ainda tem problemas"
fi

# Verificar se limpeza do cache foi adicionada
if grep -q "rm -rf ~/.cache/chromium/Default/Cache/\*" /Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/setup-kiosk.sh; then
    echo "✅ Limpeza de cache do Chromium adicionada"
else
    echo "❌ Limpeza de cache não encontrada"
fi

# Verificar se TERM está no serviço systemd
if grep -q "Environment=TERM=xterm-256color" /Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/setup-kiosk.sh; then
    echo "✅ Variável TERM configurada no systemd service"
else
    echo "❌ Variável TERM não encontrada no service"
fi

# 3. Verificar se código duplicado foi removido
echo ""
echo "3️⃣ Verificando remoção de código duplicado..."

duplicate_count=$(grep -c "AUTOSTART_EOF" /Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/scripts/setup-kiosk.sh)
if [ $duplicate_count -eq 2 ]; then
    echo "✅ Código duplicado removido (AUTOSTART_EOF encontrado 2 vezes - início e fim)"
else
    echo "⚠️ AUTOSTART_EOF encontrado $duplicate_count vezes (esperado: 2)"
fi

# 4. Verificar se script de teste foi atualizado
echo ""
echo "4️⃣ Verificando script de teste..."

if grep -q "KIOSK_APP_URL: unbound variable" /Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/tests/test-kiosk-fullscreen-service.sh; then
    echo "✅ Diagnóstico para KIOSK_APP_URL adicionado ao teste"
else
    echo "❌ Diagnóstico para KIOSK_APP_URL não encontrado"
fi

if grep -q "AUTOSTART_EOF: command not found" /Users/edmarj.cruz/Development/projects/raspberry/rpi-setup/tests/test-kiosk-fullscreen-service.sh; then
    echo "✅ Diagnóstico para AUTOSTART_EOF adicionado ao teste"
else
    echo "❌ Diagnóstico para AUTOSTART_EOF não encontrado"
fi

echo ""
echo "🎉 Verificação concluída!"
echo ""
echo "📋 Próximos passos para produção:"
echo "1. Deploy do script corrigido: scp scripts/setup-kiosk.sh pi@kiosk-tkb-09:/tmp/"
echo "2. Executar setup: sudo /tmp/setup-kiosk.sh (apenas função kiosk fullscreen)"
echo "3. Recarregar systemd: sudo systemctl daemon-reload"
echo "4. Restart service: sudo systemctl restart kiosk-fullscreen.service"
echo "5. Monitorar logs: sudo journalctl -u kiosk-fullscreen.service -f"
