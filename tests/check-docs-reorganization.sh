#!/bin/bash

# =============================================================================
# Validador Simples de Estrutura de Documentação - rpi-setup
# =============================================================================

echo "🔍 Validando estrutura de documentação reorganizada..."
echo

# Verificar arquivos na raiz que devem existir
echo "📄 Arquivos principais na raiz:"
[[ -f "README.md" ]] && echo "✓ README.md (minimal, focado no usuário)" || echo "✗ README.md não encontrado"
[[ -f "prepare-system.sh" ]] && echo "✓ prepare-system.sh (script principal)" || echo "✗ prepare-system.sh não encontrado"

echo

# Verificar estrutura de documentação
echo "📚 Estrutura de documentação:"
[[ -d "docs" ]] && echo "✓ docs/" || echo "✗ docs/ não encontrado"
[[ -d "docs/production" ]] && echo "✓ docs/production/" || echo "✗ docs/production/ não encontrado"
[[ -d "docs/development" ]] && echo "✓ docs/development/" || echo "✗ docs/development/ não encontrado"

echo

# Verificar documentação de produção
echo "🏭 Documentação de produção:"
[[ -f "docs/production/DEPLOYMENT.md" ]] && echo "✓ docs/production/DEPLOYMENT.md" || echo "✗ DEPLOYMENT.md não encontrado"
[[ -f "docs/production/PREPARE-SYSTEM.md" ]] && echo "✓ docs/production/PREPARE-SYSTEM.md" || echo "✗ PREPARE-SYSTEM.md não encontrado"

echo

# Verificar documentação de desenvolvimento
echo "🔧 Documentação de desenvolvimento:"
[[ -f "docs/development/README-DETAILED.md" ]] && echo "✓ docs/development/README-DETAILED.md" || echo "✗ README-DETAILED.md não encontrado"
[[ -f "docs/development/RELEASE-NOTES.md" ]] && echo "✓ docs/development/RELEASE-NOTES.md" || echo "✗ RELEASE-NOTES.md não encontrado"

echo

# Verificar índice de navegação
echo "📋 Índice de navegação:"
[[ -f "docs/README.md" ]] && echo "✓ docs/README.md (índice)" || echo "✗ docs/README.md não encontrado"

echo

# Verificar scripts e testes
echo "🧰 Scripts e testes:"
[[ -d "scripts" ]] && echo "✓ scripts/" || echo "✗ scripts/ não encontrado"
[[ -f "scripts/deploy-multiple.sh" ]] && echo "✓ scripts/deploy-multiple.sh" || echo "✗ deploy-multiple.sh não encontrado"
[[ -d "tests" ]] && echo "✓ tests/" || echo "✗ tests/ não encontrado"

echo

# Verificar se arquivos duplicados foram removidos
echo "🧹 Verificando arquivos duplicados removidos:"
[[ ! -f "DEPLOYMENT.md" ]] && echo "✓ DEPLOYMENT.md removido da raiz" || echo "⚠ DEPLOYMENT.md ainda existe na raiz"
[[ ! -f "PREPARE-SYSTEM.md" ]] && echo "✓ PREPARE-SYSTEM.md removido da raiz" || echo "⚠ PREPARE-SYSTEM.md ainda existe na raiz"
[[ ! -f "RELEASE-NOTES.md" ]] && echo "✓ RELEASE-NOTES.md removido da raiz" || echo "⚠ RELEASE-NOTES.md ainda existe na raiz"
[[ ! -f "deploy-multiple.sh" ]] && echo "✓ deploy-multiple.sh removido da raiz" || echo "⚠ deploy-multiple.sh ainda existe na raiz"
[[ ! -f "test-script.sh" ]] && echo "✓ test-script.sh removido da raiz" || echo "⚠ test-script.sh ainda existe na raiz"

echo
echo "✅ Reorganização da estrutura de documentação concluída!"
echo
echo "📁 Estrutura final conforme diretrizes:"
echo "├── README.md                    # Minimal, focado no usuário"
echo "├── prepare-system.sh            # Script principal de produção"
echo "├── docs/"
echo "│   ├── README.md               # Índice de navegação"
echo "│   ├── production/             # Documentação de produção"
echo "│   │   ├── DEPLOYMENT.md       # Guia de implantação"
echo "│   │   └── PREPARE-SYSTEM.md   # Manual do script"
echo "│   └── development/            # Documentação de desenvolvimento"
echo "│       ├── README-DETAILED.md  # README original detalhado"
echo "│       └── RELEASE-NOTES.md    # Histórico de versões"
echo "├── scripts/                    # Scripts de automação"
echo "│   └── deploy-multiple.sh      # Implantação múltipla"
echo "└── tests/                      # Scripts de teste"
echo "    └── *.sh                   # Vários testes"
