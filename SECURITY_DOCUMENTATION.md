# 🛡️ SISTEMA DE SEGURANÇA MULTICAMADAS - DOCUMENTAÇÃO COMPLETA

## VISÃO GERAL

Este sistema implementa **4 BARREIRAS DE SEGURANÇA** independentes para proteger contra:
- ✅ Acesso não autorizado
- ✅ Fraudes de pagamento
- ✅ Injeção de SQL
- ✅ Engenharia reversa
- ✅ Dispositivos comprometidos (Root/Jailbreak)
- ✅ Vazamento de dados
- ✅ Ataques de força bruta
- ✅ Manipulação de pedidos/preços

---

## 🏗️ ARQUITETURA DE SEGURANÇA EM 4 CAMADAS

### CAMADA 1: SEGURANÇA NO CLIENTE (App Flutter)
**Arquivo:** `app-cliente/lib/services/security_service.dart`

#### Barreiras Implementadas:
1. **Detecção de Root/Jailbreak**
   - Bloqueia execução em dispositivos comprometidos
   - Usa canais nativos (MethodChannel) para verificação profunda

2. **Criptografia Local**
   - Dados sensíveis criptografados com AES-256
   - Chaves únicas por dispositivo
   - Uso do `flutter_secure_storage` (Keychain/Keystore)

3. **Proteção Anti-Tampering**
   - Verifica integridade do APK/IPA
   - Detecta modificações no código
   - Compara hash do build com valor esperado

4. **Prevenção de Screenshots**
   - `SecureScreenWrapper` bloqueia captura de tela em telas críticas
   - Detecta screenshots no iOS e notifica servidor

5. **Monitoramento Contínuo**
   - Re-verifica segurança a cada 5 minutos
   - Reporta incidentes em tempo real para auditoria

---

### CAMADA 2: SEGURANÇA NO BANCO DE DADOS (Supabase RLS)
**Arquivo:** `database/security_schema.sql`

#### Barreiras Implementadas:
1. **Row Level Security (RLS)**
   - Cada usuário vê APENAS seus próprios dados
   - Políticas estritas por tipo de usuário (cliente, restaurante, entregador)
   - Impossível acessar dados de outros usuários mesmo com SQL injection

2. **Tabela de Auditoria Imutável**
   - LOG de TODAS as operações (INSERT, UPDATE, DELETE)
   - Ninguém pode deletar logs (nem admins)
   - Registra: usuário, ação, IP, user-agent, dados antigos/novos

3. **Prevenção de Manipulação de Preços**
   - Política `No price manipulation`: impede alteração de `total_amount` após criação
   - Valores de pedidos são imutáveis

4. **Funções de Verificação de Papel (Role Check)**
   - `check_user_role()`: valida permissões antes de cada operação crítica
   - Hierarquia: superadmin > restaurant_owner > driver > customer

5. **Triggers de Auditoria Automática**
   - Qualquer operação em tabelas críticas gera log automático
   - Inclui IP e timestamp de cada ação

6. **Anonimização de Dados (GDPR)**
   - Função `anonymize_user_data()` para excluir usuários mantendo integridade
   - Logs forenses preservados mesmo após exclusão

---

### CAMADA 3: SEGURANÇA NO SERVIDOR (Cloud Functions)
**Arquivo:** `app-cliente/lib/services/payment_security_service.dart`

#### Barreiras Implementadas:
1. **Análise de Fraude em Tempo Real**
   - Calcula `fraud_score` baseado em:
     - Valor acima da média do usuário (>3x = +0.3 risco)
     - Dispositivo novo (+0.25 risco)
     - Múltiplas contas no mesmo dispositivo (+0.35 risco)
     - Primeira compra (+0.15 risco)
   - Bloqueia automaticamente se `fraud_score > 0.7`

2. **Validação de Integridade do Pedido**
   - Busca valor REAL no banco de dados
   - Compara com valor enviado pelo cliente
   - Rejeita se diferença > 1 centavo
   - **NUNCA confia no valor enviado pelo app**

3. **Rate Limiting (Anti-Força Bruta)**
   - Máximo 5 tentativas de pagamento em 30 minutos
   - Previne ataques de teste de cartões

4. **Verificação de Localização**
   - Compara localização atual com histórico
   - Detecta transações suspeitas (>500km das últimas)
   - Marca para revisão manual se suspeito

5. **Processamento Server-Side**
   - Chaves de API do Stripe/PayPal NUNCA expostas no cliente
   - Toda lógica de pagamento roda em Cloud Functions
   - Cliente só envia solicitação, não processa nada

6. **Detector de Comportamento Suspeito (ML)**
   - Padrões detectados:
     - **Velocity Attack**: múltiplas compras rápidas
     - **Account Takeover**: mudança súbita de comportamento
     - **Friendly Fraud**: estornos indevidos
     - **Card Testing**: pequenas compras para testar cartões roubados

---

### CAMADA 4: SEGURANÇA NA REDE E INFRAESTRUTURA

#### Configurações Recomendadas (Supabase/Firebase):

1. **SSL/TLS Obrigatório**
   - Todas as comunicações criptografadas
   - Certificate pinning no app Flutter

2. **CORS Restritivo**
   - Apenas domínios autorizados podem acessar API
   - Bloqueia requisições de sites maliciosos

3. **WAF (Web Application Firewall)**
   - Filtra SQL injection, XSS, CSRF
   - Bloqueia IPs suspeitos automaticamente

4. **DDoS Protection**
   - Rate limiting por IP
   - Detecção de tráfego anômalo

5. **Segredos Gerenciados**
   - Chaves de API no Firebase Secrets / Supabase Vault
   - Rotação automática de chaves
   - Nunca hardcoded no código

---

## 🔒 FLUXO DE PAGAMENTO SEGURO

```
┌─────────────┐
│   CLIENTE   │
│   (Flutter) │
└──────┬──────┘
       │ 1. Solicita pagamento
       │    - Envia: user_id, order_id, device_fingerprint
       │    - NÃO envia: valor (buscado no DB)
       ▼
┌─────────────────────┐
│  CAMADA 1: Cliente  │
│  - Verifica Root    │
│  - Valida Integrity │
│  - Criptografa      │
└──────┬──────────────┘
       │ 2. Chamada HTTPS segura
       ▼
┌─────────────────────┐
│  CAMADA 3: Server   │
│  (Cloud Function)   │
│                     │
│  3. Análise Fraude  │◄─── ML/AI
│  4. Valida Pedido   │◄─── Busca valor REAL no DB
│  5. Rate Limiting   │◄─── Max 5/30min
│  6. Geo Verification│◄─── Haversine formula
│                     │
│  7. Processa Stripe │◄─── Server-side only
└──────┬──────────────┘
       │ 8. Grava log
       ▼
┌─────────────────────┐
│  CAMADA 2: Database │
│  (Supabase + RLS)   │
│                     │
│  - Trigger de Audit │
│  - RLS Policies     │
│  - Immutable Logs   │
└─────────────────────┘
```

---

## 📋 CHECKLIST DE IMPLEMENTAÇÃO

### No Banco de Dados (Supabase):
- [ ] Executar `security_schema.sql`
- [ ] Habilitar RLS em todas as tabelas
- [ ] Configurar políticas de acesso
- [ ] Testar que usuário não acessa dados de outros
- [ ] Verificar logs de auditoria sendo gerados

### No App Flutter:
- [ ] Adicionar dependências:
  ```yaml
  dependencies:
    flutter_secure_storage: ^9.0.0
    device_info_plus: ^9.0.0
    integrity: ^1.0.0
    encrypt: ^5.0.0
  ```
- [ ] Implementar `SecurityService.initializeSecurity()` no `main()`
- [ ] Envolver telas críticas com `SecureScreenWrapper`
- [ ] Chamar `validateSessionBeforePayment()` antes de cada pagamento
- [ ] Configurar MethodChannel para detecção de root (Android/iOS nativo)

### Nas Cloud Functions:
- [ ] Implementar `processSecurePayment()`
- [ ] Configurar análise de fraude com IA
- [ ] Integrar com Stripe/PayPal server-side
- [ ] Habilitar logs no SIEM
- [ ] Configurar alertas de segurança (email/SMS)

### Na Infraestrutura:
- [ ] Habilitar SSL/TLS
- [ ] Configurar CORS restritivo
- [ ] Ativar WAF
- [ ] Configurar DDoS protection
- [ ] Rotacionar chaves de API

---

## 🚨 RESPOSTA A INCIDENTES

### Se um ataque for detectado:

1. **Automático:**
   - App é bloqueado imediatamente
   - Sessão é encerrada
   - Log é gravado com risk_score = 100
   - Admins são notificados

2. **Manual (Equipe de Segurança):**
   - Investigar logs na tabela `audit_logs`
   - Analisar padrão de ataque
   - Bloquear IPs/usuários envolvidos
   - Revisar regras de segurança

3. **Pós-Incidente:**
   - Gerar relatório forense
   - Atualizar regras de detecção
   - Notificar usuários afetados (se necessário)
   - Aplicar correções

---

## 📊 MÉTRICAS DE SEGURANÇA

Monitore continuamente:
- Número de tentativas de acesso bloqueadas
- Score médio de fraudes detectadas
- Tempo de resposta a incidentes
- Porcentagem de dispositivos comprometidos
- Volume de logs de auditoria

---

## ⚠️ LIMITAÇÕES E CONSIDERAÇÕES

1. **Nenhum sistema é 100% seguro**
   - Este sistema eleva drasticamente a barreira para atacantes
   - Mas sempre existe risco residual

2. **Falsos Positivos**
   - Alguns usuários legítimos podem ser bloqueados
   - Implementar processo de revisão manual

3. **Performance**
   - Verificações de segurança adicionam latência (~100-300ms)
   - Balancear segurança vs experiência do usuário

4. **Manutenção**
   - Atualizar regularmente detecção de root/jailbreak
   - Revisar políticas de RLS periodicamente
   - Manter dependências atualizadas

---

## 🎯 PRÓXIMOS PASSOS

1. **Implementar detecção nativa de root** (Android Kotlin / iOS Swift)
2. **Integrar com serviço de IA** para análise de fraude (ex: Sift, Kount)
3. **Configurar SIEM** para centralizar logs (ex: Splunk, Datadog)
4. **Realizar pentest** com equipe especializada
5. **Obter certificações** (PCI-DSS para pagamentos, LGPD/GDPR)

---

## 📞 SUPORTE DE SEGURANÇA

Em caso de vulnerabilidade descoberta:
1. NÃO divulgue publicamente
2. Envie relatório detalhado para security@seuapp.com
3. Aguarde patch antes de divulgar
4. Receba crédito no changelog (bug bounty)

---

**Este sistema foi projetado com o princípio de "Defense in Depth" (Defesa em Profundidade).**
Mesmo que uma camada seja comprometida, as outras 3 continuam protegendo seu negócio.
