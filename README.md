# UberFlutter - Rede Social Gastronômica

Sistema completo de delivery com rede social integrada, desenvolvido em Flutter + Supabase.

## 📱 Aplicativos Incluídos

- **App Cliente**: Feed social estilo Instagram/TikTok, pedidos, carrinho, perfil
- **App Restaurante**: Gestão de cardápio, posts, analytics (em desenvolvimento)
- **App Entregador**: Rotas, ganhos, entregas (em desenvolvimento)
- **Web App**: Cardápio digital via QR Code (em desenvolvimento)

## 🚀 Funcionalidades

### App Cliente
- ✅ Login/Cadastro com autenticação segura
- ✅ Feed social com fotos e vídeos de pratos
- ✅ Sistema de likes e comentários
- ✅ Carrinho de compras
- ✅ Histórico de pedidos
- ✅ Perfil do usuário
- ✅ Scanner QR Code para cardápio digital
- ✅ 4 camadas de segurança anti-fraude

### Segurança
- 🔒 Detecção de root/jailbreak
- 🔒 Criptografia AES-256
- 🔒 Row Level Security (RLS) no banco
- 🔒 Sistema anti-fraude com IA
- 🔒 Auditoria imutável de transações

## 🛠️ Tecnologias

- **Frontend**: Flutter 3.x (Dart)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Pagamentos**: Stripe/PayPal
- **Mapas**: Google Maps
- **Notificações**: Firebase Cloud Messaging

## 📦 Instalação

### Pré-requisitos
- Flutter SDK 3.0+
- Conta no Supabase (grátis em supabase.com)
- Android Studio ou VS Code

### Passos

1. **Clone o repositório**
```bash
git clone https://github.com/hanggu-api/uber_fluter.git
cd uber_fluter/app-cliente
```

2. **Instale dependências**
```bash
flutter pub get
```

3. **Configure o Supabase**
   - Crie conta em https://supabase.com
   - Execute o script `database/schema.sql` no SQL Editor
   - Copie URL e Anon Key do projeto

4. **Configure variáveis de ambiente**
```bash
# Android
echo "SUPABASE_URL=sua_url" >> android/app/build.gradle
echo "SUPABASE_ANON_KEY=sua_key" >> android/app/build.gradle

# iOS
# Adicione em ios/Runner/Info.plist
```

5. **Rode o app**
```bash
flutter run
```

## 📁 Estrutura do Projeto

```
app-cliente/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── config/
│   │   ├── theme.dart            # Tema e cores
│   │   └── routes.dart           # Rotas/navegação
│   ├── models/
│   │   └── models.dart           # Modelos de dados
│   ├── services/
│   │   ├── auth_service.dart     # Autenticação
│   │   ├── cart_service.dart     # Carrinho
│   │   └── security_service.dart # Segurança
│   └── screens/
│       ├── auth/                 # Login/Cadastro
│       ├── home/                 # Tela principal
│       ├── social/               # Feed social
│       ├── profile/              # Perfil
│       ├── cart/                 # Carrinho
│       └── orders/               # Pedidos
├── database/
│   └── schema.sql                # Banco de dados
└── security/
    └── SECURITY_GUIDE.md         # Guia de segurança
```

## 🗄️ Banco de Dados

O schema inclui tabelas para:
- users (usuários)
- restaurants (restaurantes)
- products (produtos/cardápio)
- orders (pedidos)
- social_posts (posts do feed)
- comments (comentários)
- likes (curtidas)
- addresses (endereços)
- order_items (itens do pedido)

Todas com Row Level Security ativado!

## 🔐 Segurança

Consulte `security/SECURITY_GUIDE.md` para detalhes completos sobre:
- 4 camadas de proteção
- Configuração de chaves de API
- Prevenção de fraudes
- Checklist de lançamento

## 📝 Licença

Projeto proprietário - Todos os direitos reservados.

## 👥 Contato

GitHub: https://github.com/hanggu-api

---

**Desenvolvido com ❤️ para revolucionar a experiência gastronômica!**
