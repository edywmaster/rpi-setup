# 🚀 Guia de Implantação em Produção

## Execução Rápida - Um Comando

Para configurar qualquer Raspberry Pi instantaneamente:

```bash
curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash
```

## 🏭 Implantação em Múltiplos Dispositivos

### Método 1: Script Automatizado (Recomendado)

1. **Baixar o script de implantação:**

```bash
wget https://raw.githubusercontent.com/edywmaster/rpi-setup/main/deploy-multiple.sh
chmod +x deploy-multiple.sh
```

2. **Configurar dispositivos:**

```bash
# Editar o script e adicionar IPs dos dispositivos
nano deploy-multiple.sh

# Encontre a seção DEVICES e configure:
DEVICES=(
    "192.168.1.100"
    "192.168.1.101"
    "192.168.1.102"
    "pi-kiosk-01.local"
    "pi-kiosk-02.local"
)
```

3. **Executar implantação:**

```bash
./deploy-multiple.sh
```

### Método 2: SSH Manual

Para configurar dispositivos individuais via SSH:

```bash
# Configurar um dispositivo específico
ssh pi@192.168.1.100 "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
```

### Método 3: Loop Bash Simples

```bash
#!/bin/bash
for ip in 192.168.1.{100..105}; do
    echo "Configurando: $ip"
    ssh pi@$ip "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
done
```

## 🔑 Preparação do Ambiente

### Configuração SSH (Recomendado)

Para facilitar a implantação, configure chaves SSH:

```bash
# Gerar chave SSH (se não existir)
ssh-keygen -t rsa -b 4096

# Copiar chave para cada Raspberry Pi
ssh-copy-id pi@192.168.1.100
ssh-copy-id pi@192.168.1.101
# ... para cada dispositivo
```

### Descoberta de Dispositivos na Rede

```bash
# Escanear rede local para encontrar Raspberry Pi
nmap -sn 192.168.1.0/24 | grep -B 2 "Raspberry Pi"

# Ou usar arp-scan (instalar se necessário)
sudo arp-scan --localnet | grep -i raspberry
```

## 📋 Checklist de Implantação

### Antes da Execução

- [ ] Raspberry Pi OS Lite instalado
- [ ] Conectividade com internet ativa
- [ ] Acesso SSH configurado (usuário 'pi')
- [ ] IPs dos dispositivos conhecidos

### Durante a Execução

- [ ] Monitorar logs de cada dispositivo
- [ ] Verificar conectividade de rede
- [ ] Acompanhar progresso da instalação

### Após a Execução

- [ ] Verificar logs em `/var/log/rpi-preparation.log`
- [ ] Testar funcionalidades básicas
- [ ] Documentar dispositivos configurados

## 🔍 Monitoramento e Logs

### Verificar Status da Execução

```bash
# Ver logs em tempo real durante execução remota
ssh pi@192.168.1.100 "tail -f /var/log/rpi-preparation.log"

# Verificar se script foi executado com sucesso
ssh pi@192.168.1.100 "grep 'PREPARAÇÃO CONCLUÍDA' /var/log/rpi-preparation.log"
```

### Logs do Script de Implantação

O script `deploy-multiple.sh` gera logs locais:

- Nome: `deployment-YYYYMMDD-HHMMSS.log`
- Localização: Diretório atual
- Conteúdo: Logs de todos os dispositivos

## 🚨 Resolução de Problemas

### Erro de Conectividade

```bash
# Testar conectividade básica
ping 192.168.1.100

# Testar SSH
ssh pi@192.168.1.100 "echo 'SSH OK'"
```

### Erro de Permissões

```bash
# Verificar usuário e sudo
ssh pi@192.168.1.100 "whoami && sudo whoami"
```

### Erro de Internet no Dispositivo

```bash
# Testar conectividade do dispositivo
ssh pi@192.168.1.100 "ping -c 1 google.com"
```

### Script Incompleto

```bash
# Verificar se há lock files antigos
ssh pi@192.168.1.100 "sudo rm -f /tmp/rpi-preparation.lock"

# Re-executar script
ssh pi@192.168.1.100 "curl -fsSL https://raw.githubusercontent.com/edywmaster/rpi-setup/main/prepare-system.sh | sudo bash"
```

## 📊 Validação Pós-Instalação

### Verificar Pacotes Instalados

```bash
# Verificar alguns pacotes essenciais
ssh pi@192.168.1.100 "dpkg -l | grep -E '(chromium|openbox|imagemagick)'"
```

### Verificar Logs

```bash
# Verificar se não há erros críticos
ssh pi@192.168.1.100 "grep ERROR /var/log/rpi-preparation.log"
```

### Teste de Funcionalidade Básica

```bash
# Testar comando básico do sistema gráfico
ssh pi@192.168.1.100 "which startx && which openbox"
```

## 🔄 Atualizações Futuras

Para atualizar todos os dispositivos com novas versões:

```bash
# O script é idempotente, pode ser executado novamente
./deploy-multiple.sh
```

## 📞 Suporte

- **Repositório**: https://github.com/edywmaster/rpi-setup
- **Issues**: Reporte problemas no GitHub Issues
- **Logs**: Sempre inclua logs ao reportar problemas
