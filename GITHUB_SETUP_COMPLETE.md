# 🚀 CONFIGURAÇÃO DO GITHUB - PASSO A PASSSO

## OBJETIVO
Enviar todo o projeto Flutter + Supabase para o GitHub de forma organizada e segura.

---

## ⚠️ ANTES DE COMEÇAR: SEGURANÇA

### NUNCA COMMITAR DADOS SENSÍVEIS!

Crie um arquivo `.gitignore` na raiz do projeto:

```bash
cd /workspace/flutter_apps
cat > .gitignore << 'EOF'
# Chaves de API e Segredos
.env
.env.local
.env.production
**/keys/
**/secrets/

# Build outputs
build/
dist/
*.apk
*.ipa
*.aab

# Dependências
.dart_tool/
.packages
pubspec.lock

# IDE
.idea/
.vscode/
*.iml

# Logs
*.log
audit_logs_export.csv

# Credenciais
google-services.json
GoogleService-Info.plist
firebase_options.dart

# Banco de dados com dados reais
database/dump_with_data.sql
EOF
```

---

## 📦 ESTRUTURA DO REPOSITÓRIO

Seu repositório deve ficar assim:

```
flutter-delivery-app/
├── README.md                    # Visão geral do projeto
├── SECURITY_DOCUMENTATION.md    # Documentação de segurança (IMPORTANTE!)
├── SETUP_GUIDE.md               # Guia de configuração
├── .gitignore                   # Arquivos ignorados
│
├── database/
│   ├── schema.sql               # Estrutura do banco (pode commitar)
│   └── security_schema.sql      # Configurações de segurança (pode commitar)
│
├── app-cliente/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/
│   │   │   ├── security_service.dart
│   │   │   └── payment_security_service.dart
│   │   └── screens/
│   └── README.md
│
├── app-restaurante/
│   ├── pubspec.yaml
│   └── lib/
│   └── README.md
│
├── app-entregador/
│   ├── pubspec.yaml
│   └── lib/
│   └── README.md
│
└── app-web/
    ├── pubspec.yaml
    └── lib/
    └── README.md
```

---

## 🔧 PASSO 1: INICIALIZAR REPOSITÓRIO LOCAL

```bash
# Navegar até a pasta do projeto
cd /workspace/flutter_apps

# Inicializar repositório Git
git init

# Adicionar todos os arquivos
git add .

# Primeiro commit
git commit -m "feat: Initial commit - Flutter delivery app with Supabase

- 4 apps Flutter (cliente, restaurante, entregador, web)
- Sistema de segurança em 4 camadas
- Schema completo do Supabase com RLS
- Documentação completa em português
- Prevenção de fraudes e auditoria"
```

---

## 🌐 PASSO 2: CRIAR REPOSITÓRIO NO GITHUB

### Opção A: Via Terminal (Recomendado)

```bash
# Substitua SEU_USUARIO pelo seu usuário do GitHub
gh repo create flutter-delivery-multivendor --public --source=. --remote=origin
```

### Opção B: Via Site

1. Acesse https://github.com/new
2. Nome do repositório: `flutter-delivery-multivendor`
3. Descrição: "Sistema de delivery multi-vendor com Flutter + Supabase - Rede social gastronômica"
4. Marque como **Public** (ou Private se preferir)
5. **NÃO** marque "Initialize this repository with a README"
6. Clique em "Create repository"

Após criar, copie o comando mostrado e execute:

```bash
# Exemplo do comando que o GitHub vai mostrar:
git remote add origin https://github.com/SEU_USUARIO/flutter-delivery-multivendor.git
git branch -M main
git push -u origin main
```

---

## 🔐 PASSO 3: CONFIGURAR AUTENTICAÇÃO

### Opção A: SSH (Recomendado para uso frequente)

```bash
# Gerar chave SSH (se não tiver)
ssh-keygen -t ed25519 -C "seu_email@email.com"

# Adicionar chave ao SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copiar chave pública
cat ~/.ssh/id_ed25519.pub

# Adicionar no GitHub:
# 1. Acesse https://github.com/settings/keys
# 2. Clique em "New SSH key"
# 3. Cole o conteúdo copiado
# 4. Salve

# Testar conexão
ssh -T git@github.com
```

### Opção B: HTTPS com Token

1. Acesse https://github.com/settings/tokens
2. Gere um token com permissão `repo`
3. Use o token ao invés da senha:
```bash
git push https://SEU_USUARIO:SEU_TOKEN@github.com/SEU_USUARIO/flutter-delivery-multivendor.git
```

---

## 📤 PASSO 4: ENVIAR PARA O GITHUB

```bash
# Garantir que está na branch main
git branch -M main

# Adicionar remote (se ainda não fez)
git remote add origin https://github.com/SEU_USUARIO/flutter-delivery-multivendor.git

# Enviar código
git push -u origin main
```

---

## ✅ PASSO 5: VERIFICAR NO GITHUB

1. Acesse: https://github.com/SEU_USUARIO/flutter-delivery-multivendor
2. Verifique se todos os arquivos estão lá
3. Confira se `.gitignore` funcionou (não deve ter arquivos sensíveis)

---

## 🔄 TRABALHANDO COM O REPOSITÓRIO

### Fazer alterações:

```bash
# Editar arquivos...

# Adicionar mudanças
git add .

# Commitar
git commit -m "feat: adicionar nova funcionalidade X

- Descrição detalhada do que foi feito
- Issue relacionada: #123"

# Enviar
git push origin main
```

### Boas práticas de commit:

Use convenção semântica:
- `feat:` nova funcionalidade
- `fix:` correção de bug
- `docs:` documentação
- `style:` formatação
- `refactor:` refatoração
- `test:` testes
- `chore:` configurações

Exemplo:
```bash
git commit -m "feat: implementar detecção de root no Android

- Adicionado MethodChannel para verificar root
- Bloqueio automático se dispositivo comprometido
- Testes unitários incluídos"
```

---

## 🛡️ SEGURANÇA DO REPOSITÓRIO

### 1. Proteger Branch Main

No GitHub:
1. Settings → Branches → Add branch protection rule
2. Pattern: `main`
3. Marque:
   - Require pull request reviews
   - Require status checks to pass before merging
   - Require branches to be up to date before merging

### 2. Revisar Commits Automaticamente

Instale apps no repositório:
- **Dependabot**: atualiza dependências automaticamente
- **CodeQL**: análise de segurança
- **Secret Scanner**: detecta chaves vazadas

### 3. LICENSE

Adicione uma licença para proteger seu código:

```bash
# Licença MIT (mais permissiva)
curl -o LICENSE https://raw.githubusercontent.com/github/gitignore/main/MIT.gitignore

# Ou Licença Proprietária (fechado)
cat > LICENSE << 'EOF'
Copyright (c) 2024 [Seu Nome]

Todos os direitos reservados.

É proibida a cópia, distribuição ou uso deste código
sem autorização expressa do autor.
EOF
```

---

## 📝 README DO GITHUB

Atualize o `README.md` principal com:

```markdown
# 🍔 Flutter Delivery Multivendor

Sistema completo de delivery com rede social gastronômica.

## 🚀 Funcionalidades

- ✅ App Cliente com feed estilo Instagram/TikTok
- ✅ App Restaurante para gestão
- ✅ App Entregador com rotas
- ✅ Cardápio Web via QR Code
- ✅ Pagamentos seguros
- ✅ 4 camadas de segurança anti-fraude

## 🛡️ Segurança

Este projeto implementa:
- Detecção de Root/Jailbreak
- Row Level Security (Supabase)
- Auditoria imutável
- Análise de fraude com IA

Leia [SECURITY_DOCUMENTATION.md](./SECURITY_DOCUMENTATION.md) para detalhes.

## 📱 Tecnologias

- Flutter 3.x
- Supabase (PostgreSQL + Auth + Storage)
- Stripe/PayPal para pagamentos

## 🏁 Começar

1. Clone o repositório
2. Configure Supabase (veja SETUP_GUIDE.md)
3. Execute cada app

## 📄 Licença

[MIT](LICENSE) ou [Proprietária](LICENSE)
```

---

## 🎯 PRÓXIMOS PASSOS APÓS PUBLICAR

1. **Configurar CI/CD** (GitHub Actions):
   - Tests automáticos a cada push
   - Build automático de APK/IPA
   - Deploy automático na Play Store/App Store

2. **Adicionar Issues e Projects**:
   - Crie issues para bugs e features
   - Use Projects para gerenciar sprint

3. **Convidar Colaboradores**:
   - Settings → Collaborators
   - Adicione emails da equipe

4. **Configurar Releases**:
   - Tags versionadas (v1.0.0, v1.1.0)
   - Release notes automáticas

---

## 🆘 PROBLEMAS COMUNS

### Erro: "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/SEU_USUARIO/repo.git
```

### Erro: "Permission denied (publickey)"
```bash
# Verificar se SSH está configurado
ssh -T git@github.com

# Se falhar, regenere a chave SSH
```

### Esqueci de adicionar .gitignore antes do primeiro commit
```bash
# Remover arquivos sensíveis do histórico
git rm -r --cached .
git add .
git commit -m "fix: remover arquivos sensíveis do git"
git push origin main --force
```

---

## 📞 SUPORTE

Dúvidas? Consulte:
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Docs](https://docs.github.com)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)

---

**🎉 Parabéns! Seu projeto está seguro no GitHub!**
