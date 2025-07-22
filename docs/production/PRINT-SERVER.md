# Servidor de Impressão Kiosk

> **📋 Versão**: v1.3.1 | **Servidor**: Node.js Print Server | **Atualizado em**: 2025-07-21

Servidor de impressão Node.js para sistema kiosk em Raspberry Pi. Este servidor gerencia impressão de badges em PDF via CUPS, com integração à API externa e suporte a impressoras térmicas.

## Funcionalidades

- 🖨️ **Impressão de PDFs**: Download e impressão automática de badges
- 🔍 **Health Check**: Monitoramento do status do servidor e CUPS
- 📋 **Gestão de Impressoras**: Listagem e status de impressoras disponíveis
- 📁 **Fila de Impressão**: Controle de arquivos em processamento
- 📊 **Logging Avançado**: Logs detalhados via Winston
- 🛡️ **Error Handling**: Tratamento robusto de erros
- ⚙️ **Configuração Flexível**: Variáveis de ambiente personalizáveis

## Endpoints da API

### GET /health

Verifica status do servidor e sistema CUPS

```json
{
  "status": "ok",
  "service": "kiosk-print-server",
  "version": "1.0.0",
  "cups": "✅ Serviço CUPS está em execução",
  "api_url": "https://app.ticketbay.com.br/api/v1",
  "timestamp": "2025-01-21T10:00:00.000Z"
}
```

### GET /badge/:id

Baixa e imprime badge pelo ID

```bash
curl http://localhost:50001/badge/123
```

### GET /printers

Lista impressoras disponíveis no sistema

```json
{
  "status": "ok",
  "output": "Impressoras disponíveis:\n  - Brother_QL_700",
  "timestamp": "2025-01-21T10:00:00.000Z"
}
```

### POST /test-print

Testa impressão com arquivo local

```bash
curl -X POST http://localhost:50001/test-print \
  -H "Content-Type: application/json" \
  -d '{"file_path": "/path/to/test.pdf"}'
```

### GET /queue

Verifica fila de impressão

```json
{
  "queue": [
    {
      "name": "badge_123_1641888000000.pdf",
      "size": 25600,
      "created": "2025-01-21T10:00:00.000Z",
      "modified": "2025-01-21T10:00:00.000Z"
    }
  ],
  "count": 1,
  "timestamp": "2025-01-21T10:00:00.000Z"
}
```

### GET /printer-status

Status detalhado das impressoras

```json
{
  "status": "ok",
  "printer_status": "printer Brother_QL_700 is idle. enabled since ...",
  "timestamp": "2025-01-21T10:00:00.000Z"
}
```

## Variáveis de Ambiente

| Variável           | Padrão       | Descrição                        |
| ------------------ | ------------ | -------------------------------- |
| `NODE_ENV`         | `production` | Ambiente de execução             |
| `KIOSK_PRINT_PORT` | `50001`      | Porta do servidor                |
| `KIOSK_APP_API`    | -            | URL da API externa               |
| `LOG_LEVEL`        | `info`       | Nível de logging                 |
| `MAX_FILE_SIZE`    | `10485760`   | Tamanho máximo do arquivo (10MB) |
| `PRINT_TIMEOUT`    | `45000`      | Timeout da impressão (45s)       |

## Instalação

O servidor é instalado automaticamente pelo script `setup-kiosk.sh`:

```bash
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/scripts/setup-kiosk.sh | sudo bash
```

### Instalação Manual

```bash
cd /opt/kiosk/server
npm install
cp .env.example .env
# Editar .env conforme necessário
```

## Gerenciamento do Serviço

```bash
# Status do serviço
sudo systemctl status kiosk-print-server.service

# Iniciar serviço
sudo systemctl start kiosk-print-server.service

# Parar serviço
sudo systemctl stop kiosk-print-server.service

# Reiniciar serviço
sudo systemctl restart kiosk-print-server.service

# Ver logs em tempo real
sudo journalctl -u kiosk-print-server.service -f

# Ver logs do arquivo
tail -f /var/log/kiosk-print-server.log
```

## Script Python (printer.py)

O servidor utiliza um script Python para interface com CUPS:

```bash
# Listar impressoras
python3 /opt/kiosk/utils/printer.py --list

# Verificar status
python3 /opt/kiosk/utils/printer.py --status

# Imprimir arquivo
python3 /opt/kiosk/utils/printer.py /path/to/file.pdf

# Verificar CUPS
python3 /opt/kiosk/utils/printer.py --check-cups
```

## Estrutura de Arquivos

```
/opt/kiosk/server/
├── print.js          # Servidor principal
├── package.json      # Dependências Node.js
├── .env              # Configurações
├── .env.example      # Template de configuração
└── files/            # Arquivos temporários

/opt/kiosk/utils/
└── printer.py        # Script Python para CUPS

/var/log/
├── kiosk-print-server.log  # Logs do servidor
└── kiosk-printer.log       # Logs do Python
```

## Desenvolvimento

```bash
# Modo desenvolvimento
NODE_ENV=development node print.js

# Ou usando npm
npm run dev

# Testes básicos
npm test
```

## Solução de Problemas

### Servidor não inicia

1. Verificar se Node.js está instalado: `node --version`
2. Verificar dependências: `npm install`
3. Verificar porta em uso: `lsof -i :50001`

### CUPS não encontrado

1. Verificar serviço: `systemctl status cups`
2. Instalar CUPS: `sudo apt install cups`
3. Adicionar usuário ao grupo: `sudo usermod -aG lpadmin pi`

### Impressora não encontrada

1. Listar impressoras: `lpstat -p`
2. Configurar impressora via web: `http://ip:631`
3. Definir impressora padrão: `lpoptions -d printer_name`

### Erro de permissões

1. Verificar proprietário dos arquivos: `ls -la /opt/kiosk/`
2. Corrigir permissões: `sudo chown -R pi:pi /opt/kiosk/`

## Logs Importantes

- **Servidor**: `/var/log/kiosk-print-server.log`
- **Python**: `/var/log/kiosk-printer.log`
- **Systemd**: `journalctl -u kiosk-print-server.service`
- **CUPS**: `/var/log/cups/error_log`

## Integração com Aplicação

### Exemplo JavaScript/React

```javascript
// Imprimir badge
const printBadge = async userId => {
  try {
    const response = await fetch(`http://localhost:50001/badge/${userId}`)
    const result = await response.json()

    if (result.status === "success") {
      console.log("Badge impresso com sucesso!")
    } else {
      console.error("Erro na impressão:", result.message)
    }
  } catch (error) {
    console.error("Erro de conexão:", error)
  }
}

// Verificar servidor
const checkPrintServer = async () => {
  try {
    const response = await fetch("http://localhost:50001/health")
    const health = await response.json()
    return health.status === "ok"
  } catch {
    return false
  }
}
```

## Suporte

Para problemas e sugestões, consulte:

- [Documentação do projeto](https://github.com/edywmaster/rpi-setup)
- [Issues no GitHub](https://github.com/edywmaster/rpi-setup/issues)

---

**Versão desta documentação**: v1.3.1 | **Sistema base**: prepare-system.sh v1.3.1 | **Última atualização**: 2025-07-21
