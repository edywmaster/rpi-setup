# Script de Preparação do Sistema - prepare-system.sh

## Visão Geral

Script de preparação inicial para Raspberry Pi OS Lite que automatiza:

- Atualização completa do sistema
- Instalação de pacotes essenciais para sistemas kiosk/display
- Validações de ambiente e conectividade
- Logging abrangente de todas as operações

## Pacotes Instalados

O script instala os seguintes pacotes essenciais:

### Ferramentas de Sistema

- `wget` - Ferramenta de download
- `curl` - Cliente HTTP
- `jq` - Processador JSON
- `lsof` - Lista arquivos abertos
- `unzip` - Extração de arquivos

### Sistema Gráfico e Display

- `fbi` - Visualizador de imagens no framebuffer
- `xserver-xorg` - Servidor X11
- `x11-xserver-utils` - Utilitários X11
- `dbus-x11` - Integração D-Bus com X11
- `xinit` - Inicialização do X11
- `openbox` - Gerenciador de janelas leve
- `chromium-browser` - Navegador web
- `unclutter` - Oculta cursor do mouse
- `imagemagick` - Manipulação de imagens

### Desenvolvimento e Suporte

- `python3-pyxdg` - Suporte XDG para Python
- `libgbm-dev` - Gerenciador de buffer gráfico
- `libasound2` - Biblioteca de som ALSA
- `build-essential` - Ferramentas de compilação

## Como Usar

### Pré-requisitos

- Raspberry Pi com Raspberry Pi OS Lite (Debian 12 "bookworm")
- Acesso root (sudo)
- Conexão com internet ativa

### Execução

```bash
# Baixar e executar diretamente
sudo bash prepare-system.sh

# Ou tornar executável e executar
chmod +x prepare-system.sh
sudo ./prepare-system.sh
```

## Funcionalidades

### ✅ Validações Automáticas

- Verifica privilégios de root
- Detecta modelo do Raspberry Pi
- Testa conectividade com internet
- Previne execução simultânea (lock file)

### 📊 Logging Abrangente

- Logs coloridos no terminal
- Arquivo de log persistente: `/var/log/rpi-preparation.log`
- Timestamps em todas as operações
- Relatório final de instalação

### 🔄 Operações Idempotentes

- Pode ser executado múltiplas vezes
- Detecta pacotes já instalados
- Não quebra em re-execuções

### 🛡️ Tratamento de Erros

- Verificação de sucesso de cada operação
- Relatório de pacotes que falharam
- Instruções para correção manual

## Estrutura do Script

```
├── Validações iniciais
│   ├── Verificação de privilégios
│   ├── Detecção do hardware
│   └── Teste de conectividade
├── Preparação do sistema
│   ├── Atualização de listas
│   ├── Upgrade do sistema
│   └── Instalação de pacotes
├── Limpeza
└── Relatório final
```

## Logs e Debugging

### Arquivo de Log

```bash
# Visualizar logs em tempo real
tail -f /var/log/rpi-preparation.log

# Buscar erros específicos
grep "ERROR" /var/log/rpi-preparation.log
```

### Informações do Sistema

O script automaticamente detecta e registra:

- Modelo do Raspberry Pi
- Versão do sistema operacional
- Status de conectividade
- Resultado de cada instalação

## Resolução de Problemas

### Conectividade

Se houver problemas de rede:

```bash
# Testar conectividade DNS
nslookup google.com

# Verificar configuração de rede
ip route show
```

### Repositórios

Se houver problemas com repositórios:

```bash
# Verificar sources.list
cat /etc/apt/sources.list

# Atualizar manualmente
sudo apt-get update
```

### Pacotes Específicos

Para instalar pacotes que falharam:

```bash
# Instalar individualmente
sudo apt-get install nome-do-pacote

# Verificar dependências
apt-cache depends nome-do-pacote
```

## Próximos Passos

Após a execução bem-sucedida, você pode:

1. Configurar serviços específicos (SSH, firewall, etc.)
2. Instalar software adicional conforme necessário
3. Configurar ambiente gráfico para aplicações kiosk
4. Implementar scripts de monitoramento

## Compatibilidade

- **Testado**: Raspberry Pi 4B com Pi OS Lite
- **Suportado**: Outros modelos de Raspberry Pi
- **Requerido**: Debian 12 "bookworm" ou superior
