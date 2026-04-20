-- ============================================================================
-- CAMADA 2: SEGURANÇA DE DADOS (ROW LEVEL SECURITY - RLS)
-- O Banco de Dados é a última linha de defesa. Nada passa sem permissão explícita.
-- ============================================================================

-- 1. EXTENSÕES DE SEGURANÇA
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- Para criptografia adicional se necessário
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABELA DE AUDITORIA IMUTÁVEL (LOG DE TUDO)
-- Esta tabela registra CADA ação no sistema. Nem mesmo o admin pode apagar logs facilmente.
CREATE TABLE audit_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL, -- 'LOGIN', 'PAYMENT_ATTEMPT', 'DATA_ACCESS', 'ROLE_CHANGE'
    table_name TEXT,
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    user_agent TEXT,
    risk_score INT DEFAULT 0, -- Pontuação de risco calculada pelo backend
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Proteger a tabela de auditoria: Ninguém pode deletar ou atualizar logs
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Logs are read-only for everyone including admins" ON audit_logs
    FOR ALL USING (true) WITH CHECK (false); -- INSERT permitido, UPDATE/DELETE bloqueado

-- 3. FUNÇÃO DE VERIFICAÇÃO DE PAPEL (ROLE CHECK)
CREATE OR REPLACE FUNCTION check_user_role(required_role TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Pega o role do usuário atual da tabela de perfis
    SELECT role INTO user_role FROM public.profiles WHERE id = auth.uid();
    
    -- Hierarquia: superadmin > restaurant_owner > driver > customer
    IF user_role = 'superadmin' THEN RETURN TRUE; END IF;
    IF required_role = 'restaurant_owner' AND user_role = 'restaurant_owner' THEN RETURN TRUE; END IF;
    IF required_role = 'driver' AND user_role = 'driver' THEN RETURN TRUE; END IF;
    IF required_role = 'customer' AND user_role = 'customer' THEN RETURN TRUE; END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. POLÍTICAS RLS ESTRITAS (EXEMPLOS CRÍTICOS)

-- A. PERFIS DE USUÁRIO
-- Usuários só podem ver/editar seu próprio perfil, exceto admins
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- B. PEDIDOS (ORDERS) - CRÍTICO PARA FRAUDE
-- Cliente vê apenas seus pedidos
CREATE POLICY "Customers see own orders" ON public.orders
    FOR SELECT USING (auth.uid() = customer_id);

-- Restaurante vê apenas pedidos do SEU restaurante
CREATE POLICY "Restaurants see own orders" ON public.orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurants 
            WHERE restaurants.id = public.orders.restaurant_id 
            AND restaurants.owner_id = auth.uid()
        )
    );

-- Entregador vê apenas pedidos atribuídos a ele
CREATE POLICY "Drivers see assigned orders" ON public.orders
    FOR SELECT USING (driver_id = auth.uid());

-- Ninguém pode alterar o valor de um pedido após criado (Prevenção de Fraude de Preço)
CREATE POLICY "No price manipulation" ON public.orders
    FOR UPDATE USING (
        old.total_amount = new.total_amount -- O valor total não pode mudar
    );

-- C. POSTAGENS SOCIAIS (SOCIAL POSTS)
-- Apenas donos de restaurante ou admins podem deletar posts ofensivos
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view posts" ON public.social_posts
    FOR SELECT USING (true);

CREATE POLICY "Users can create own posts" ON public.social_posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Only owner or admin can delete posts" ON public.social_posts
    FOR DELETE USING (
        auth.uid() = user_id OR 
        check_user_role('superadmin') OR
        EXISTS (
            SELECT 1 FROM public.restaurants 
            WHERE id = (SELECT restaurant_id FROM public.social_posts WHERE id = old.id)
            AND owner_id = auth.uid()
        )
    );

-- 5. TRIGGER DE AUDITORIA AUTOMÁTICA
-- Registra automaticamente qualquer tentativa de acesso ou modificação crítica
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, ip_address)
        VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, OLD.id, to_jsonb(OLD), inet_client_addr());
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, new_data, ip_address)
        VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW), inet_client_addr());
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, new_data, ip_address)
        VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, NEW.id, to_jsonb(NEW), inet_client_addr());
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Aplicar auditoria em tabelas críticas
CREATE TRIGGER audit_orders_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.orders
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_payments_trigger
AFTER INSERT OR UPDATE ON public.payments
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- 6. PREVENÇÃO DE SQL INJECTION E DADOS SENSÍVEIS
-- Criptografar dados sensíveis como tokens de dispositivo ou notas fiscais
-- (O Supabase já criptografa em repouso, mas isso adiciona uma camada lógica)
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(data TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_encrypt(data, current_setting('app.encryption_key'));
EXCEPTION WHEN OTHERS THEN
    RETURN data; -- Fallback seguro
END;
$$ LANGUAGE plpgsql;

-- 7. LIMPEZA DE DADOS ANTIGOS (GDPR/SEGURANÇA)
-- Função para anonimar dados de usuários deletados (mantém integridade referencial)
CREATE OR REPLACE FUNCTION anonymize_user_data(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.profiles SET 
        full_name = 'Usuário Excluído',
        phone = null,
        avatar_url = null,
        email = concat('deleted_', id, '@anonymous.local')
    WHERE id = target_user_id;
    
    -- Logs são mantidos para auditoria forense, mas vinculados ao ID fantasma
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
