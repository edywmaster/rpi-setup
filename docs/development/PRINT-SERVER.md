# Servidor de Impressão Kiosk - Implementação Completa

## Resumo das Melhorias

Este documento resume as melhorias implementadas no sistema de impressão do kiosk, baseadas nos arquivos `print.js` e `printer.py` existentes.

## ✨ Funcionalidades Implementadas

### 🖨️ Servidor Node.js (`print.js`)

**Endpoints da API:**

- `GET /health` - Health check com verificação do CUPS
- `GET /badge/:id` - Download e impressão de badges
- `GET /printers` - Lista impressoras disponíveis
- `GET /queue` - Fila de impressão
- `GET /printer-status` - Status das impressoras
- `POST /test-print` - Teste de impressão com arquivo local

**Melhorias Técnicas:**

- ✅ Sistema de logging avançado com Winston
- ✅ Timeout configurável (45s) para impressão
- ✅ Limite de tamanho de arquivo (10MB)
- ✅ Limpeza automática de arquivos temporários
- ✅ Error handling robusto
- ✅ Graceful shutdown
- ✅ CORS configurado adequadamente
- ✅ Request logging middleware

### 🐍 Script Python (`printer.py`)

**Funcionalidades:**

- ✅ Impressão via CUPS com configurações otimizadas
- ✅ Verificação automática do serviço CUPS
- ✅ Listagem de impressoras disponíveis
- ✅ Verificação de status da impressora
- ✅ Validação de arquivos PDF
- ✅ Logging detalhado
- ✅ Argumentos de linha de comando
- ✅ Timeouts e tratamento de erros

**Argumentos CLI:**

```bash
python3 printer.py file.pdf           # Imprimir arquivo
python3 printer.py --list            # Listar impressoras
python3 printer.py --status          # Status da impressora
python3 printer.py --check-cups      # Verificar CUPS
python3 printer.py --queue           # Verificar fila
```

### 🔧 Integração com setup-kiosk.sh

**Nova Etapa:** `setup_print_server`

- ✅ Download automático do repositório
- ✅ Fallback para arquivos locais
- ✅ Instalação de dependências Node.js
- ✅ Criação de serviço systemd
- ✅ Configuração de permissões
- ✅ Estado de instalação rastreável

**Funções Auxiliares:**

- `create_local_print_server()` - Cria print.js local
- `create_local_printer_script()` - Cria printer.py local
- `create_print_server_package_json()` - Cria package.json
- `install_print_server_dependencies()` - Instala dependências
- `create_print_server_service()` - Configura systemd

### 📦 Arquivos de Repositório

**Novos arquivos em `dist/kiosk/`:**

```
dist/kiosk/
├── server/
│   ├── print.js          # Servidor aprimorado
│   ├── package.json      # Dependências e scripts
│   ├── .env.example      # Template de configuração
│   ├── README.md         # Documentação completa
│   └── examples.sh       # Exemplos de uso
└── utils/
    └── printer.py        # Script Python melhorado
```

### 🧪 Testes e Validação

**Novo teste:** `test-print-server.sh`

- ✅ Verifica integração no setup-kiosk.sh
- ✅ Valida arquivos do servidor
- ✅ Testa funções de instalação
- ✅ Verifica documentação
- ✅ Validação completa do sistema

## 🔄 Fluxo de Instalação

1. **Download/Criação**: Tenta baixar do repositório, cria local se falhar
2. **Dependências**: Instala pacotes Node.js necessários
3. **Configuração**: Cria .env e configurações
4. **Serviço**: Configura systemd service
5. **Permissões**: Define permissões adequadas
6. **Verificação**: Testa funcionamento básico

## 🌟 Recursos Avançados

### Monitoramento e Logging

- Logs estruturados em JSON (Winston)
- Múltiplos outputs (arquivo + console)
- Logs separados para Node.js e Python
- Integração com systemd journal

### Configuração Flexível

- Variáveis de ambiente
- Configuração via arquivo .env
- Argumentos de linha de comando
- Configuração global do kiosk

### Sistema de Serviços

- Serviço systemd dedicado
- Restart automático em falhas
- Dependências do CUPS
- Configurações de segurança

### API Robusta

- Endpoints bem documentados
- Responses padronizados JSON
- Error handling consistente
- Health checks completos

## 📋 Variáveis de Configuração

### Ambiente (.env)

```bash
NODE_ENV=production
KIOSK_PRINT_PORT=50001
KIOSK_APP_API=https://app.ticketbay.com.br/api/v1
LOG_LEVEL=info
MAX_FILE_SIZE=10485760
PRINT_TIMEOUT=45000
```

### Sistema Global (kiosk.conf)

```bash
KIOSK_PRINT_SERVER="/opt/kiosk/server/print.js"
KIOSK_PRINT_SCRIPT="/opt/kiosk/utils/printer.py"
KIOSK_PRINT_URL="http://localhost:50001"
KIOSK_PRINT_TEMP="/opt/kiosk/tmp"
```

## 🚀 Próximos Passos

Para usar o sistema de impressão:

1. **Instalar**: Execute `setup-kiosk.sh`
2. **Configurar**: Edite `/opt/kiosk/server/.env` se necessário
3. **Impressora**: Configure via CUPS (http://ip:631)
4. **Testar**: Execute `/opt/kiosk/server/examples.sh`
5. **Integrar**: Use endpoints da API na aplicação

## 📖 Documentação

- **Completa**: `/opt/kiosk/server/README.md`
- **Exemplos**: `/opt/kiosk/server/examples.sh`
- **Teste**: `./tests/test-print-server.sh`

## 🎯 Benefícios da Implementação

- ✅ **Modular**: Funciona independentemente
- ✅ **Robusto**: Error handling e recovery
- ✅ **Escalável**: Fácil de estender
- ✅ **Documentado**: Documentação completa
- ✅ **Testável**: Testes automatizados
- ✅ **Configurável**: Múltiplas opções de config
- ✅ **Monitorável**: Logs e health checks
- ✅ **Compatível**: Funciona com impressoras térmicas
