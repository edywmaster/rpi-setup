# Estrutura Kiosk - Arquivos de Template

Esta pasta contém os arquivos template que são copiados para `/opt/kiosk/` durante a execução do `setup-kiosk.sh`.

## Estrutura de Diretórios

```
dist/kiosk/
├── scripts/           # Scripts de inicialização e utilitários
│   ├── kiosk-start.sh # Script principal de inicialização do kiosk
│   └── ...            # Outros scripts utilitários
├── server/            # Aplicação Node.js do servidor de impressão
│   └── ...            # Arquivos do servidor (a ser implementado)
├── templates/         # Templates e recursos visuais
│   └── splash.jpg     # Imagem de splash (a ser adicionada)
└── utils/             # Utilitários Python e outros
    └── ...            # Scripts Python para impressão (a ser implementado)
```

## Arquivos Incluídos

### scripts/kiosk-start.sh

- Script de inicialização do serviço kiosk-start
- Exibe informações do sistema e "Hello World!"
- Mantém log detalhado em `/var/log/kiosk-start.log`
- Executa loop contínuo com heartbeat a cada 5 minutos

## Como os Arquivos são Utilizados

1. Durante a execução do `setup-kiosk.sh`, os arquivos desta pasta são baixados via wget/curl
2. A estrutura é recriada em `/opt/kiosk/` no Raspberry Pi
3. Os scripts recebem permissões adequadas e são configurados como serviços systemd
4. O serviço `kiosk-start` é habilitado para inicialização automática

## Desenvolvimento

Para adicionar novos arquivos:

1. Crie o arquivo na estrutura apropriada aqui (`dist/kiosk/`)
2. Atualize o `setup-kiosk.sh` para fazer download do novo arquivo
3. Configure permissões e serviços conforme necessário

## Testando

Use os scripts de teste para verificar o funcionamento:

- `tests/test-kiosk-start.sh` - Teste completo do serviço
- `tests/demo-kiosk-hello.sh` - Demonstração do Hello World (local/remoto)
