# 🔒 SISTEMA DE SEGURANÇA MULTICAMADAS - DOCUMENTAÇÃO COMPLETA

## 🛡️ Visão Geral das 4 Barreiras de Segurança

Este sistema implementa **4 camadas de segurança** para proteger contra:
- Acesso não autorizado
- Fraudes de pagamento
- Ataques hackers
- Manipulação de dados
- Injeção SQL
- XSS (Cross-Site Scripting)
- CSRF (Cross-Site Request Forgery)

---

## 📋 CAMADA 1: SEGURANÇA NO DISPOSITIVO (App Flutter)

### ✅ Implementado em: `app_security_service.dart`

#### Funcionalidades:
1. **Detecção de Root/Jailbreak**
   - Bloqueia dispositivos comprometidos
   - Verifica se o dispositivo foi modificado

2. **Criptografia Local AES-256**
   - Dados sensíveis criptografados no dispositivo
   - Chaves armazenadas no Keychain/Keystore

3. **Validação de Integridade do App**
   - Detecta se o app foi modificado/recompilado
   - Verifica assinatura digital

4. **Proteção Contra Screenshots**
   - Bloqueia captura de telas em áreas sensíveis
   - Previne vazamento de dados

5. **Timeout Automático**
   - Logout automático após inatividade
   - Sessões expiram após 15 minutos

### Como Usar:
```dart
// No main.dart de cada app
await SecurityService.initialize();

// Antes de qualquer operação sensível
if (!await SecurityService.isDeviceSecure()) {
  // Mostrar alerta e fechar app
}

// Para criptografar dados
final encrypted = await SecurityService.encrypt('dados_sensiveis');
```

---

## 📋 CAMADA 2: SEGURANÇA NO BANCO DE DADOS (Supabase RLS)

### ✅ Implementado em: `supabase_security_schema.sql`

#### Funcionalidades:
1. **Row Level Security (RLS)**
   - Cada usuário só acessa SEUS próprios dados
   - Políticas granulares por tabela

2. **Auditoria Imutável**
   - Todas as ações são registradas em `audit_logs`
   - Logs não podem ser alterados ou deletados

3. **Validação Server-Side**
   - Regras de negócio aplicadas no banco
   - Prevenção contra bypass no cliente

4. **Rate Limiting no Banco**
   - Limite de requisições por usuário
   - Previne ataques de força bruta

5. **Máscara de Dados Sensíveis**
   - CPF, cartão de crédito ofuscados
   - Apenas últimos 4 dígitos visíveis

### Políticas Principais:

#### Usuários:
```sql
-- Usuário só vê seu próprio perfil
CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

-- Usuário só atualiza seu próprio perfil
CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);
```

#### Pedidos:
```sql
-- Cliente vê apenas seus pedidos
CREATE POLICY "orders_customer_view" ON orders
  FOR SELECT USING (customer_id = auth.uid());

-- Restaurante vê apenas pedidos do seu estabelecimento
CREATE POLICY "orders_restaurant_view" ON orders
  FOR SELECT USING (restaurant_id IN (
    SELECT id FROM restaurants WHERE owner_id = auth.uid()
  ));
```

#### Pagamentos:
```sql
-- Ninguém pode selecionar dados completos de cartão
CREATE POLICY "payments_no_select" ON payments
  FOR SELECT USING (false);

-- Apenas insert permitido via função segura
CREATE POLICY "payments_insert_only" ON payments
  FOR INSERT WITH CHECK (true);
```

---

## 📋 CAMADA 3: DETECÇÃO DE FRAUDES (IA + Regras)

### ✅ Implementado em: `fraud_detection_logic.dart`

#### Sistema de Scoring de Risco:

Cada transação recebe uma pontuação de 0-100:
- **0-30**: Baixo risco ✅ (aprovar automaticamente)
- **31-70**: Médio risco ⚠️ (revisão manual)
- **71-100**: Alto risco 🚫 (bloquear e investigar)

#### Fatores Analisados:

1. **Comportamento do Usuário**
   ```dart
   - Primeira compra? (+20 pontos)
   - Valor muito acima da média? (+30 pontos)
   - Múltiplos pedidos em pouco tempo? (+25 pontos)
   - Mudança brusca de localização? (+40 pontos)
   ```

2. **Dispositivo e Rede**
   ```dart
   - Device fingerprint novo? (+15 pontos)
   - IP de proxy/VPN detectado? (+35 pontos)
   - Múltiplas contas no mesmo dispositivo? (+50 pontos)
   - Emulador detectado? (+60 pontos)
   ```

3. **Padrão de Pagamento**
   ```dart
   - Cartão recusado anteriormente? (+25 pontos)
   - Múltiplos cartões no mesmo usuário? (+20 pontos)
   - Tentativas de valores fracionados? (+30 pontos)
   - Horário incomum (3-5 AM)? (+15 pontos)
   ```

4. **Geolocalização**
   ```dart
   - Distância entre endereço e localização atual > 50km? (+25 pontos)
   - Endereço de entrega em área de alto risco? (+20 pontos)
   - Múltiplos endereços em curto período? (+30 pontos)
   ```

### Fluxo de Decisão:

```
┌─────────────┐
│   Pedido    │
│  Iniciado   │
└──────┬──────┘
       ▼
┌─────────────┐
│ Análise de  │◄─── Device Fingerprint
│   Risco     │◄─── Histórico do Usuário
└──────┬──────┘◄─── Geolocalização
       │         ◄─── Padrão de Pagamento
       ▼
┌─────────────┐
│ Score < 30? │──Sim──► Aprovar ✅
└──────┬──────┘
       │Não
       ▼
┌─────────────┐
│ Score < 70? │──Sim──► Revisão Manual ⚠️
└──────┬──────┘
       │Não
       ▼
┌─────────────┐
│  Bloquear   │──► Notificar Equipe 🚫
│   Pedido    │
└─────────────┘
```

### Exemplo de Uso:
```dart
final fraudDetector = FraudDetectionService();

final riskScore = await fraudDetector.analyzeTransaction(
  userId: 'user_123',
  amount: 150.00,
  paymentMethod: 'credit_card',
  location: LatLng(-23.5505, -46.6333),
  deviceId: 'device_fingerprint_xyz',
);

if (riskScore.level == RiskLevel.high) {
  // Bloquear transação
  await fraudDetector.blockTransaction(transactionId);
  // Notificar equipe de segurança
  await fraudDetector.notifySecurityTeam(riskScore);
}
```

---

## 📋 CAMADA 4: INFRAESTRUTURA E REDE

### Configurações Recomendadas:

#### 1. **Cloudflare (WAF + DDoS Protection)**
   - Ativar Web Application Firewall
   - Bloquear bots maliciosos
   - Rate limiting global
   - Proteção contra DDoS camada 7

#### 2. **Supabase Security Settings**
   ```
   ✅ Row Level Security: ATIVADO
   ✅ SSL/TLS: OBRIGATÓRIO
   ✅ JWT Expiration: 1 hora
   ✅ Refresh Token Rotation: ATIVADO
   ✅ Database Secrets: Environment Variables
   ```

#### 3. **API Rate Limiting**
   ```yaml
   # Limites por endpoint
   /api/auth/login: 5 requests/min
   /api/orders/create: 10 requests/min
   /api/payments/process: 3 requests/min
   /api/posts/create: 20 requests/min
   ```

#### 4. **Headers de Segurança HTTP**
   ```http
   Strict-Transport-Security: max-age=31536000; includeSubDomains
   X-Content-Type-Options: nosniff
   X-Frame-Options: DENY
   X-XSS-Protection: 1; mode=block
   Content-Security-Policy: default-src 'self'
   Referrer-Policy: strict-origin-when-cross-origin
   ```

---

## 🔑 CONFIGURAÇÃO DE CHAVES E SEGREDOS

### Variáveis de Ambiente Obrigatórias:

```bash
# .env file (NUNCA commitar no Git!)

# Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Stripe/PayPal
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
PAYPAL_CLIENT_ID=...
PAYPAL_CLIENT_SECRET=...

# Firebase (Notificações Push)
FIREBASE_SERVER_KEY=...

# Criptografia
ENCRYPTION_KEY=chave_aes_256_bits_aqui...
JWT_SECRET=segredo_jwt_muito_forte...

# APIs Externas
GOOGLE_MAPS_API_KEY=...
RECAPTCHA_SECRET_KEY=...
```

### Como Gerar Chaves Fortes:

```bash
# Gerar chave AES-256
openssl rand -base64 32

# Gerar segredo JWT
openssl rand -base64 64

# Gerar salt para senhas
openssl rand -hex 16
```

---

## 🚨 PROCEDIMENTOS DE EMERGÊNCIA

### Em Caso de Violação:

1. **Imediato (0-5 minutos)**
   ```bash
   # Rotacionar todas as chaves de API
   # Invalidar todos os tokens JWT
   # Bloquear usuários suspeitos
   ```

2. **Curto Prazo (5-30 minutos)**
   ```bash
   # Ativar modo de manutenção
   # Notificar equipe de segurança
   # Coletar logs de auditoria
   # Identificar origem do ataque
   ```

3. **Médio Prazo (30 min - 2 horas)**
   ```bash
   # Corrigir vulnerabilidade
   # Restaurar backups limpos
   # Notificar usuários afetados
   # Documentar incidente
   ```

4. **Longo Prazo (2-24 horas)**
   ```bash
   # Auditoria completa de segurança
   # Revisão de políticas de acesso
   # Treinamento da equipe
   # Relatório pós-incidente
   ```

### Contatos de Emergência:
```
Equipe de Segurança: security@suaempresa.com
Suporte Supabase: support@supabase.com
Stripe Fraud: fraud@stripe.com
Polícia Federal (Brasil): www.pf.gov.br/denuncia
```

---

## ✅ CHECKLIST DE SEGURANÇA PRÉ-LANÇAMENTO

### Antes de Lançar:

- [ ] Todas as 4 camadas implementadas
- [ ] Testes de penetração realizados
- [ ] Chaves de API rotacionadas
- [ ] Backup automático configurado
- [ ] Monitoramento de logs ativado
- [ ] SSL/TLS configurado corretamente
- [ ] Headers de segurança implementados
- [ ] Rate limiting testado
- [ ] RLS policies verificadas
- [ ] Webhooks de pagamento validados
- [ ] Termos de uso e política de privacidade publicados
- [ ] LGPD/GDPR compliance verificado

### Monitoramento Contínuo:

- [ ] Dashboard de segurança em tempo real
- [ ] Alertas de atividades suspeitas
- [ ] Revisão semanal de logs
- [ ] Atualizações de segurança mensais
- [ ] Testes de vulnerabilidade trimestrais
- [ ] Auditoria externa anual

---

## 📞 SUPORTE E MANUTENÇÃO

### Updates de Segurança:

1. **Automáticos**
   - Dependências Flutter: `flutter pub upgrade --major-versions`
   - Pacotes npm: `npm audit fix`
   - Supabase: Atualizações automáticas

2. **Manuais**
   - Revisão de código trimestral
   - Atualização de políticas RLS
   - Renovação de certificados SSL

### Recursos Adicionais:

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/database/security)
- [Flutter Security Guide](https://docs.flutter.dev/deployment/security)
- [Stripe Fraud Prevention](https://stripe.com/docs/fraud)

---

## 🎯 RESUMO DAS PROTEÇÕES

| Ameaça | Proteção | Camada |
|--------|----------|--------|
| Dispositivo Root/Jailbreak | Detecção e Bloqueio | 1 |
| Dados Locais Vazados | Criptografia AES-256 | 1 |
| Acesso Não Autorizado | RLS + JWT | 2 |
| Injeção SQL | Prepared Statements + RLS | 2 |
| Fraude de Pagamento | IA Scoring + Validação | 3 |
| Múltiplas Contas | Device Fingerprinting | 3 |
| DDoS | Cloudflare WAF | 4 |
| Man-in-the-Middle | HTTPS + Certificate Pinning | 4 |
| Vazamento de Dados | Masking + Audit Logs | 2 |
| Sessão Hijacking | Token Rotation + Timeout | 1 |

---

**Última Atualização:** Abril 2025  
**Versão:** 1.0.0  
**Status:** ✅ Produção Ready
