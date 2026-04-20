# 🍔 Uber Flutter - Rede Social Gastronômica

Sistema completo de delivery com rede social integrada, desenvolvido em Flutter + Supabase.

## 📱 Aplicativos

- **app-cliente**: App principal com feed social estilo Instagram/TikTok
- **app-restaurante**: Gestão de cardápio e posts (em desenvolvimento)
- **app-entregador**: Rotas e entregas (em desenvolvimento)
- **web-app**: Cardápio digital via QR Code (em desenvolvimento)

## 🚀 Funcionalidades do App Cliente

### Rede Social
- ✅ Feed com fotos e vídeos de pratos
- ✅ Stories temporários
- ✅ Curtidas e comentários
- ✅ Check-in em restaurantes
- ✅ QR Code para acesso rápido

### Delivery
- ✅ Catálogo de restaurantes
- ✅ Carrinho de compras
- ✅ Pagamento via Stripe
- ✅ Acompanhamento de pedidos
- ✅ Histórico de pedidos

### Segurança
- ✅ 4 camadas de proteção
- ✅ Autenticação segura com Supabase
- ✅ Detecção de fraudes
- ✅ Criptografia de dados

## 🛠️ Configuração

### 1. Instalar dependências
```bash
cd app-cliente
flutter pub get
```

### 2. Configurar Supabase
1. Crie conta em https://supabase.com
2. Execute o script `database/schema.sql`
3. Copie as credenciais para `lib/core/config/app_config.dart`

### 3. Configurar Stripe
1. Crie conta em https://stripe.com
2. Adicione a chave pública no `app_config.dart`

### 4. Rodar o app
```bash
flutter run
```

## 📁 Estrutura do Projeto

```
uber_fluter/
├── app-cliente/
│   ├── lib/
│   │   ├── core/          # Config, serviços, tema
│   │   ├── features/      # Telas por funcionalidade
│   │   ├── models/        # Modelos de dados
│   │   └── main.dart
│   └── pubspec.yaml
├── database/
│   └── schema.sql
├── security/
│   └── SECURITY_GUIDE.md
└── README.md
```

## 🔒 Segurança

O sistema possui 4 barreiras de segurança:
1. **Dispositivo**: Detecção de root/jailbreak
2. **Banco de Dados**: Row Level Security (RLS)
3. **Servidor**: Validação server-side e anti-fraude
4. **Infraestrutura**: WAF e proteção DDoS

Consulte `security/SECURITY_GUIDE.md` para detalhes.

## 📄 Licença

Projeto proprietário - Todos os direitos reservados.

## 👨‍💻 Desenvolvedor

hanggu-api

---

**Status**: ✅ App Cliente funcional | 🚧 Demais apps em desenvolvimento
