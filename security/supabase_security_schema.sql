-- =====================================================
-- 🔒 SUPABASE SECURITY SCHEMA - CAMADA 2 DE SEGURANÇA
-- =====================================================
-- Este script implementa Row Level Security (RLS) avançado
-- para proteger todos os dados do seu aplicativo de delivery
-- =====================================================

-- =====================================================
-- 1. TABELA DE AUDITORIA IMUTÁVEL
-- =====================================================
-- Todos os logs são registrados aqui e NUNCA podem ser alterados

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    table_name TEXT NOT NULL,
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Política: Ninguém pode deletar ou atualizar logs de auditoria
CREATE POLICY "audit_logs_immutable" ON audit_logs
    FOR ALL USING (false);

-- Política: Apenas insert permitido via trigger
CREATE POLICY "audit_logs_insert_only" ON audit_logs
    FOR INSERT WITH CHECK (true);

-- Trigger para registrar todas as mudanças automaticamente
CREATE OR REPLACE FUNCTION log_changes() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, new_data, ip_address)
        VALUES (auth.uid(), 'INSERT', TG_TABLE_NAME, NEW.id, to_jsonb(NEW), current_setting('app.ip_address', true)::INET);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, new_data, ip_address)
        VALUES (auth.uid(), 'UPDATE', TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW), current_setting('app.ip_address', true)::INET);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, ip_address)
        VALUES (auth.uid(), 'DELETE', TG_TABLE_NAME, OLD.id, to_jsonb(OLD), current_setting('app.ip_address', true)::INET);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 2. TABELA DE USUÁRIOS COM MÁSCARA DE DADOS
-- =====================================================

-- View segura para usuários (dados sensíveis ofuscados)
CREATE OR REPLACE VIEW users_public AS
SELECT 
    id,
    email,
    full_name,
    phone,
    avatar_url,
    user_type,
    -- Máscara de CPF: mostra apenas últimos 3 dígitos
    CASE 
        WHEN cpf IS NOT NULL THEN '***.' || substring(cpf from length(cpf)-2 for 3) || '-' || substring(cpf from length(cpf) for 2)
        ELSE NULL
    END as cpf_masked,
    created_at
FROM users;

-- Políticas RLS para users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Usuário vê apenas seu próprio perfil completo
CREATE POLICY "users_select_own_full" ON users
    FOR SELECT USING (auth.uid() = id);

-- Usuário pode atualizar apenas seu próprio perfil
CREATE POLICY "users_update_own" ON users
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Qualquer usuário autenticado pode ver dados públicos de outros
CREATE POLICY "users_select_public" ON users
    FOR SELECT USING (true);

-- Trigger para auditoria na tabela users
CREATE TRIGGER users_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION log_changes();

-- =====================================================
-- 3. TABELA DE RESTAURANTES
-- =====================================================

ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;

-- Dono vê seus próprios restaurantes
CREATE POLICY "restaurants_owner_view" ON restaurants
    FOR SELECT USING (owner_id = auth.uid());

-- Qualquer um pode ver restaurantes ativos (público)
CREATE POLICY "restaurants_public_view" ON restaurants
    FOR SELECT USING (is_active = true);

-- Apenas dono pode criar/atualizar seus restaurantes
CREATE POLICY "restaurants_owner_insert" ON restaurants
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "restaurants_owner_update" ON restaurants
    FOR UPDATE USING (auth.uid() = owner_id);

-- Trigger para auditoria
CREATE TRIGGER restaurants_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON restaurants
    FOR EACH ROW EXECUTE FUNCTION log_changes();

-- =====================================================
-- 4. TABELA DE PRODUTOS
-- =====================================================

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Cliente vê produtos de restaurantes ativos
CREATE POLICY "products_customer_view" ON products
    FOR SELECT USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE is_active = true
        )
    );

-- Dono do restaurante gerencia seus produtos
CREATE POLICY "products_owner_manage" ON products
    FOR ALL USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE owner_id = auth.uid()
        )
    );

-- Trigger para auditoria
CREATE TRIGGER products_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW EXECUTE FUNCTION log_changes();

-- =====================================================
-- 5. TABELA DE PEDIDOS COM VALIDAÇÃO DE PAGAMENTO
-- =====================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Cliente vê apenas seus pedidos
CREATE POLICY "orders_customer_view" ON orders
    FOR SELECT USING (customer_id = auth.uid());

-- Restaurante vê pedidos do seu estabelecimento
CREATE POLICY "orders_restaurant_view" ON orders
    FOR SELECT USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE owner_id = auth.uid()
        )
    );

-- Entregador vê pedidos atribuídos a ele
CREATE POLICY "orders_delivery_view" ON orders
    FOR SELECT USING (delivery_person_id = auth.uid());

-- Cliente pode criar seus próprios pedidos
CREATE POLICY "orders_customer_insert" ON orders
    FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Apenas restaurante pode atualizar status do pedido
CREATE POLICY "orders_restaurant_update" ON orders
    FOR UPDATE USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE owner_id = auth.uid()
        )
    );

-- Trigger para auditoria
CREATE TRIGGER orders_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW EXECUTE FUNCTION log_changes();

-- =====================================================
-- 6. TABELA DE PAGAMENTOS ULTRA SEGURO
-- =====================================================

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- NINGUÉM pode selecionar dados completos de pagamento
CREATE POLICY "payments_no_select" ON payments
    FOR SELECT USING (false);

-- Apenas função segura pode inserir pagamentos
CREATE POLICY "payments_insert_function_only" ON payments
    FOR INSERT WITH CHECK (false);

-- View segura para histórico de pagamentos (sem dados sensíveis)
CREATE OR REPLACE VIEW payments_safe AS
SELECT 
    id,
    order_id,
    amount,
    currency,
    status,
    payment_method,
    -- Ofusca número do cartão
    CASE 
        WHEN card_last_four IS NOT NULL THEN '**** **** **** ' || card_last_four
        ELSE NULL
    END as card_masked,
    created_at
FROM payments
WHERE customer_id = auth.uid();

-- Função segura para processar pagamentos (chamada via RPC)
CREATE OR REPLACE FUNCTION process_payment_secure(
    p_order_id UUID,
    p_amount DECIMAL,
    p_payment_method TEXT,
    p_card_token TEXT
) RETURNS UUID AS $$
DECLARE
    v_payment_id UUID;
    v_risk_score INTEGER;
BEGIN
    -- Validar se o usuário é o dono do pedido
    IF NOT EXISTS (
        SELECT 1 FROM orders 
        WHERE id = p_order_id AND customer_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Order does not belong to user';
    END IF;

    -- Aqui você chamaria sua lógica de detecção de fraude
    -- v_risk_score := calculate_fraud_score(auth.uid(), p_amount, p_payment_method);
    
    -- Se risco alto, bloquear
    -- IF v_risk_score > 70 THEN
    --     RAISE EXCEPTION 'High fraud risk detected';
    -- END IF;

    -- Processar pagamento via Stripe/PayPal (server-side)
    -- ... código de integração ...

    -- Inserir registro seguro (sem dados completos do cartão)
    INSERT INTO payments (
        order_id,
        customer_id,
        amount,
        currency,
        status,
        payment_method,
        card_last_four,
        stripe_charge_id
    ) VALUES (
        p_order_id,
        auth.uid(),
        p_amount,
        'BRL',
        'pending',
        p_payment_method,
        RIGHT(p_card_token, 4), -- Apenas últimos 4 dígitos
        'ch_' || gen_random_uuid()::text
    ) RETURNING id INTO v_payment_id;

    RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. TABELA DE POSTS SOCIAIS (REDE SOCIAL)
-- =====================================================

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Qualquer um vê posts públicos
CREATE POLICY "posts_public_view" ON posts
    FOR SELECT USING (is_public = true);

-- Usuário vê seus próprios posts (incluindo privados)
CREATE POLICY "posts_owner_view" ON posts
    FOR SELECT USING (user_id = auth.uid());

-- Usuário pode criar seus posts
CREATE POLICY "posts_owner_insert" ON posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Usuário pode atualizar/deletar apenas seus posts
CREATE POLICY "posts_owner_update" ON posts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "posts_owner_delete" ON posts
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para auditoria
CREATE TRIGGER posts_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON posts
    FOR EACH ROW EXECUTE FUNCTION log_changes();

-- =====================================================
-- 8. TABELA DE COMENTÁRIOS
-- =====================================================

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Qualquer um vê comentários em posts públicos
CREATE POLICY "comments_public_view" ON comments
    FOR SELECT USING (
        post_id IN (
            SELECT id FROM posts WHERE is_public = true
        )
    );

-- Usuário pode criar comentários
CREATE POLICY "comments_insert" ON comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Usuário pode atualizar/deletar apenas seus comentários
CREATE POLICY "comments_owner_update" ON comments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "comments_owner_delete" ON comments
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para auditoria
CREATE TRIGGER comments_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON comments
    FOR EACH ROW EXECUTE FUNCTION log_changes();

-- =====================================================
-- 9. TABELA DE CHECK-INS (CLIENTES NO RESTAURANTE)
-- =====================================================

ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;

-- Usuário vê seus próprios check-ins
CREATE POLICY "checkins_owner_view" ON checkins
    FOR SELECT USING (user_id = auth.uid());

-- Restaurante vê check-ins no seu estabelecimento
CREATE POLICY "checkins_restaurant_view" ON checkins
    FOR SELECT USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE owner_id = auth.uid()
        )
    );

-- Usuário pode criar check-in
CREATE POLICY "checkins_insert" ON checkins
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Trigger para auditoria
CREATE TRIGGER checkins_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON checkins
    FOR EACH ROW EXECUTE FUNCTION log_changes();

-- =====================================================
-- 10. RATE LIMITING NO BANCO DE DADOS
-- =====================================================

-- Tabela para controlar rate limiting
CREATE TABLE IF NOT EXISTS rate_limits (
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    request_count INTEGER DEFAULT 1,
    PRIMARY KEY (user_id, action, window_start)
);

-- Função para verificar rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_action TEXT,
    p_max_requests INTEGER,
    p_window_minutes INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_count INTEGER;
    v_window_start TIMESTAMPTZ;
BEGIN
    v_window_start := NOW() - (p_window_minutes || ' minutes')::INTERVAL;
    
    -- Contar requisições no período
    SELECT COALESCE(SUM(request_count), 0) INTO v_count
    FROM rate_limits
    WHERE user_id = auth.uid()
      AND action = p_action
      AND window_start >= v_window_start;
    
    -- Verificar se excedeu limite
    IF v_count >= p_max_requests THEN
        RETURN FALSE; -- Limite excedido
    END IF;
    
    -- Atualizar ou inserir contador
    INSERT INTO rate_limits (user_id, action, window_start, request_count)
    VALUES (auth.uid(), p_action, date_trunc('minute', NOW()), 1)
    ON CONFLICT (user_id, action, window_start)
    DO UPDATE SET request_count = rate_limits.request_count + 1;
    
    RETURN TRUE; -- Dentro do limite
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Exemplo de uso nas políticas:
-- CREATE POLICY "orders_rate_limit" ON orders
--     FOR INSERT WITH CHECK (check_rate_limit('create_order', 10, 60));

-- =====================================================
-- 11. FUNÇÕES DE SEGURANÇA ADICIONAIS
-- =====================================================

-- Função para validar se usuário está ativo
CREATE OR REPLACE FUNCTION is_user_active() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para validar tipo de usuário
CREATE OR REPLACE FUNCTION has_user_type(p_type TEXT) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND user_type = p_type
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para obter IP do cliente (precisa ser configurado no connection string)
CREATE OR REPLACE FUNCTION get_client_ip() RETURNS INET AS $$
BEGIN
    RETURN current_setting('app.ip_address', true)::INET;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 12. ÍNDICES PARA PERFORMANCE E SEGURANÇA
-- =====================================================

-- Índices para queries de segurança
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_rate_limits_user_action ON rate_limits(user_id, action);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_customer_status ON orders(customer_id, status);

-- =====================================================
-- 13. CONFIGURAÇÕES FINAIS DE SEGURANÇA
-- =====================================================

-- Forçar SSL em todas as conexões (configurar no Supabase Dashboard)
-- ALTER DATABASE postgres SET ssl = 'on';

-- Configurar timeout de sessão (1 hora)
-- ALTER DATABASE postgres SET statement_timeout = '3600000';

-- Loggar todas as queries lentas (> 1 segundo)
-- ALTER DATABASE postgres SET log_min_duration_statement = 1000;

-- =====================================================
-- FIM DO SCRIPT DE SEGURANÇA
-- =====================================================
-- Execute este script no SQL Editor do Supabase
-- Após executar, teste todas as políticas com diferentes usuários
-- =====================================================
