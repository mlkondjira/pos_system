-- Code SQL pour corriger/créer la table shops sur Supabase
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Activer l'extension UUID si nécessaire
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Créer la table 'shops' si elle n'existe pas (avec la bonne orthographe 'address')
-- Note : Assurez-vous de bien copier TOUT ce bloc, de CREATE jusqu'à la parenthèse fermante );
CREATE TABLE IF NOT EXISTS public.shops (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL,
    address text,
    owner_id uuid NOT NULL, -- Correction: owner_id doit être UUID
    created_at timestamptz NOT NULL DEFAULT now()
); 

-- NETTOYAGE DES ANCIENNES VERSIONS (ORPHELINES) DES FONCTIONS
-- Le linter détecte des versions avec 'double precision' ou des arguments différents.
DO $$
BEGIN
    -- 1. Nettoyage agressif des anciennes signatures détectées par le linter
    DROP FUNCTION IF EXISTS public.update_product_stock_delta(uuid, integer, double precision);
    DROP FUNCTION IF EXISTS public.update_product_stock_delta(uuid, uuid, integer, double precision);
    DROP FUNCTION IF EXISTS public.update_product_stock_delta(uuid, integer, float8);
    
    -- 2. Nettoyage des anciennes versions de remboursement
    DROP FUNCTION IF EXISTS public.process_sale_refund(uuid, uuid, integer, integer);
    
    -- 3. Nettoyage des versions sans paramètres par défaut explicites
    DROP FUNCTION IF EXISTS public.get_dashboard_stats(uuid, timestamptz, timestamptz, uuid);
    
END $$;

-- Forcer le rechargement du schéma
NOTIFY pgrst, 'reload schema';

-- NETTOYAGE : Supprimer la colonne shop_id qui cause l'erreur de contrainte
DO $$
BEGIN
    -- 0. Supprimer les VUES qui dépendent de la table shops (pour éviter les blocages de type)
    -- PostgreSQL interdit de modifier une table si une vue l'utilise.
    DROP VIEW IF EXISTS public.store_summary CASCADE;
    DROP VIEW IF EXISTS public.store_weekly CASCADE;
    DROP VIEW IF EXISTS public.store_weekly_summary CASCADE;
    DROP VIEW IF EXISTS public.store_monthly_summary CASCADE;
    DROP VIEW IF EXISTS public.store_low_stock CASCADE;
    DROP VIEW IF EXISTS public.global_top_products CASCADE;
    DROP VIEW IF EXISTS public.pending_transfers_details CASCADE;
    DROP VIEW IF EXISTS public.customer_debts_summary CASCADE;
    DROP VIEW IF EXISTS public.view_terminal_sync_monitoring CASCADE;
    DROP VIEW IF EXISTS public.view_sales_by_terminal_name CASCADE;
    DROP VIEW IF EXISTS public.view_owner_audit_logs CASCADE;

    -- 1. Supprimer TOUTES les politiques de manière dynamique
    -- PostgreSQL ne permet pas de modifier le type d'une colonne utilisée dans une politique,
    -- même si la politique est définie sur une autre table (dépendance croisée).
    DECLARE
        pol_rec RECORD;
    BEGIN
        FOR pol_rec IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
        LOOP
            EXECUTE format('DROP POLICY %I ON public.%I', pol_rec.policyname, pol_rec.tablename);
        END LOOP;
    END;

    -- 0.5 Supprimer les clés étrangères qui bloquent la migration des types
    -- PostgreSQL ne permet pas de changer le type d'une colonne utilisée dans une FK.
    -- On les supprime toutes pour les recréer proprement après la conversion.
    DECLARE
        fk_record RECORD;
    BEGIN
        FOR fk_record IN 
            SELECT tc.table_name, tc.constraint_name 
            FROM information_schema.table_constraints AS tc 
            JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name 
            WHERE tc.constraint_type = 'FOREIGN KEY' 
              AND tc.table_schema = 'public'
              -- On inclut product_id et les colonnes de transfert pour débloquer la migration des types
              AND (kcu.column_name IN ('shop_id', 'id', 'product_id', 'source_shop_id', 'target_shop_id'))
        LOOP
            EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT IF EXISTS %I', fk_record.table_name, fk_record.constraint_name);
        END LOOP;
    END;

    DROP POLICY IF EXISTS "Owners can manage their own shops" ON public.shops;

    -- 2. Migration de la table shops (id et owner_id)
    IF (SELECT data_type FROM information_schema.columns WHERE table_name='shops' AND column_name='id') = 'text' THEN
        ALTER TABLE public.shops DROP CONSTRAINT IF EXISTS shops_pkey CASCADE;
        DELETE FROM public.shops WHERE id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        ALTER TABLE public.shops ALTER COLUMN id TYPE uuid USING id::uuid;
        ALTER TABLE public.shops ALTER COLUMN id SET DEFAULT uuid_generate_v4();
        ALTER TABLE public.shops ADD PRIMARY KEY (id);
    END IF;

    IF (SELECT data_type FROM information_schema.columns WHERE table_name='shops' AND column_name='owner_id') = 'text' THEN
        DELETE FROM public.shops WHERE owner_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        ALTER TABLE public.shops ALTER COLUMN owner_id TYPE uuid USING owner_id::uuid;
    END IF;

    -- 3. MIGRATION CRUCIALE : Convertir shop_id dans TOUTES les autres tables
    -- Cela évite l'erreur "uuid = text" lors de la création des politiques RLS
    DECLARE
        tbl_record RECORD;
    BEGIN
        FOR tbl_record IN
            SELECT c.table_name, c.column_name 
            FROM information_schema.columns c
            JOIN information_schema.tables t 
              ON c.table_name = t.table_name AND c.table_schema = t.table_schema
            WHERE c.column_name IN ('shop_id', 'source_shop_id', 'target_shop_id', 'customer_id') 
              AND c.table_schema = 'public'
              AND t.table_type = 'BASE TABLE'
              AND c.table_name != 'shops'
        LOOP
            -- Nettoyer les données invalides pour éviter ERROR 22P02
           EXECUTE format('DELETE FROM public.%I WHERE %I::text !~* ''^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$''', tbl_record.table_name, tbl_record.column_name);
            EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I TYPE uuid USING %I::uuid', tbl_record.table_name, tbl_record.column_name, tbl_record.column_name);
        END LOOP;
    END;

    -- 4. Nettoyage final de la colonne obsolète
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='shops' AND column_name='shop_id') THEN
        ALTER TABLE public.shops DROP COLUMN shop_id CASCADE;
    END IF;

    -- 5. Assurer la présence de terminal_id dans les tables transactionnelles
    -- Indispensable pour la gestion multi-caisse et les contraintes FK
    DECLARE
        target_table text;
    BEGIN
        FOR target_table IN SELECT unnest(ARRAY['sales', 'sale_items', 'payments', 'stock_movements', 'stock_transfers', 'stock_transfer_items', 'cash_sessions', 'inventory_sessions', 'inventory_lines', 'expenses', 'purchase_orders', 'purchase_order_items', 'product_variants', 'audit_logs']) LOOP
            -- Exclure explicitement les tables qui ne devraient pas avoir de terminal_id
            IF target_table IN ('products', 'customers', 'categories', 'suppliers', 'discounts') THEN
                CONTINUE;
            END IF;
            IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = target_table AND table_schema = 'public') THEN
                EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS terminal_id uuid', target_table);
            END IF;
        END LOOP;

        -- Assurer la présence de customer_id dans les tables qui en ont besoin
        FOR target_table IN SELECT unnest(ARRAY['sales', 'payments'])
        LOOP
            IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = target_table AND table_schema = 'public') THEN
                -- Ajouter customer_id comme UUID, car il référencera customers.id (UUID)
                EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS customer_id uuid', target_table);
                -- S'assurer que la FK est bien en place
                EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT IF EXISTS %I_customer_id_fkey', target_table, target_table);
                EXECUTE format('ALTER TABLE public.%I ADD CONSTRAINT %I_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id)', target_table, target_table);
            END IF;
        END LOOP;

        -- Migration corrective pour product_id (doit être int pour correspondre à Drift)
        FOR target_table IN SELECT unnest(ARRAY['sale_items', 'stock_transfer_items', 'stock_movements', 'inventory_lines'])
        LOOP
            IF EXISTS (SELECT FROM information_schema.columns 
                       WHERE table_name = target_table AND column_name = 'product_id' AND data_type = 'uuid') THEN
                -- Si la colonne est en UUID, on la repasse en INT pour la synchro Drift
                EXECUTE format('ALTER TABLE public.%I ALTER COLUMN product_id TYPE int USING NULL', target_table);
                -- Note: On utilise USING NULL ici car convertir un UUID en INT n'est pas direct. 
                -- La synchro suivante remplira à nouveau les données.
            END IF;
        END LOOP;

        -- Assurer la présence de sale_local_id dans les tables liées aux ventes
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'sale_items' AND table_schema = 'public') THEN
            ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS sale_local_id int;
            ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS cost_price_at_sale double precision DEFAULT 0;
            ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS discount_pct double precision DEFAULT 0;
            ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS unit_price_ht double precision DEFAULT 0;
            ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS tax_rate double precision DEFAULT 0;
        END IF;
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'payments' AND table_schema = 'public') THEN
            ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS sale_local_id int;
        END IF;

        -- Migration corrective pour stock_movements (colonnes manquantes pour les transferts)
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'stock_movements' AND table_schema = 'public') THEN
            ALTER TABLE public.stock_movements ADD COLUMN IF NOT EXISTS product_id int;
            ALTER TABLE public.stock_movements ADD COLUMN IF NOT EXISTS user_id int;
            ALTER TABLE public.stock_movements ADD COLUMN IF NOT EXISTS type text;
            ALTER TABLE public.stock_movements ADD COLUMN IF NOT EXISTS qty_delta int;
            ALTER TABLE public.stock_movements ADD COLUMN IF NOT EXISTS qty_after int;
            ALTER TABLE public.stock_movements ADD COLUMN IF NOT EXISTS inventory_ref text;
        END IF;

        -- Migration corrective pour sales (amount_due et payment_status)
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'sales' AND table_schema = 'public') THEN
            ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS amount_due double precision DEFAULT 0;
            ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS payment_status text DEFAULT 'paid';
            ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS discount_type text DEFAULT 'fixed';
            ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS coupon_code text;
            ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS total_ht double precision DEFAULT 0;
            ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS total_tax double precision DEFAULT 0;
            ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS discount_amount double precision DEFAULT 0;
        END IF;

        -- Migration corrective pour inventory_sessions (colonnes manquantes)
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'inventory_sessions' AND table_schema = 'public') THEN
            ALTER TABLE public.inventory_sessions ADD COLUMN IF NOT EXISTS user_id int;
            ALTER TABLE public.inventory_sessions ADD COLUMN IF NOT EXISTS notes text;
            ALTER TABLE public.inventory_sessions ADD COLUMN IF NOT EXISTS total_products int DEFAULT 0;
            ALTER TABLE public.inventory_sessions ADD COLUMN IF NOT EXISTS discrepancies int DEFAULT 0;
            ALTER TABLE public.inventory_sessions ADD COLUMN IF NOT EXISTS completed_at timestamptz;
            ALTER TABLE public.inventory_sessions ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
        END IF;

        -- Migration corrective pour inventory_lines (colonnes manquantes)
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'inventory_lines' AND table_schema = 'public') THEN
            ALTER TABLE public.inventory_lines ADD COLUMN IF NOT EXISTS barcode text;
            ALTER TABLE public.inventory_lines ADD COLUMN IF NOT EXISTS notes text;
            ALTER TABLE public.inventory_lines ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
        END IF;

        -- Migration corrective pour la table products (ajout de is_active)
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'products') THEN
            ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;
            ALTER TABLE public.products ADD COLUMN IF NOT EXISTS cost_price double precision DEFAULT 0;
            ALTER TABLE public.products ADD COLUMN IF NOT EXISTS preferred_supplier_id int;
        END IF;

        -- Migration corrective pour la table users (ajout de shop_id et colonnes de sécurité)
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
            ALTER TABLE public.users ADD COLUMN IF NOT EXISTS shop_id uuid REFERENCES public.shops(id) ON DELETE CASCADE;
            ALTER TABLE public.users ADD COLUMN IF NOT EXISTS local_id int;
            ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pin_hash text;
            ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pin_salt text;
            ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;
            ALTER TABLE public.users ADD COLUMN IF NOT EXISTS failed_attempts int DEFAULT 0;
            ALTER TABLE public.users ADD COLUMN IF NOT EXISTS locked_until timestamptz;
            ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

            -- Ajout de la contrainte d'unicité pour éviter les doublons lors de la synchro
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name='users' AND constraint_name='users_shop_id_local_id_key') THEN
                ALTER TABLE public.users ADD CONSTRAINT users_shop_id_local_id_key UNIQUE (shop_id, local_id);
            END IF;
        END IF;

        -- Migration corrective pour stock_transfers (updated_at)
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'stock_transfers') THEN
            ALTER TABLE public.stock_transfers ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
        END IF;

        -- Migration corrective pour customers et categories
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'customers') THEN
            ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS icon text;
            ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
        END IF;

        -- Migration corrective pour suppliers
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'suppliers') THEN
            ALTER TABLE public.suppliers ADD COLUMN IF NOT EXISTS notes text;
            ALTER TABLE public.suppliers ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
            ALTER TABLE public.suppliers ADD COLUMN IF NOT EXISTS contact_name text;
        END IF;

        -- Migration corrective pour expenses
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'expenses') THEN
            ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS image_path text;
            ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS user_id int;
            ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS terminal_id uuid;
        END IF;

        -- Migration corrective pour terminals (Ajout last_sync_ip)
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'terminals') THEN
            ALTER TABLE public.terminals ADD COLUMN IF NOT EXISTS last_sync_ip text;
        END IF;

    END;
END $$;

-- S'assurer que les utilisateurs connectés peuvent interagir avec la table
GRANT SELECT, INSERT, UPDATE ON TABLE public.shops TO authenticated;
GRANT ALL ON TABLE public.shops TO service_role; -- Seul le service role peut DELETE

-- 2b. Table des utilisateurs (Miroir de la table Drift pour les rapports et FK)
CREATE TABLE IF NOT EXISTS public.users (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    local_id int NOT NULL, -- Correspond à l'ID local auto-incrémenté de Drift
    name text NOT NULL,
    shop_id uuid NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    pin_hash text,
    pin_salt text,
    role text DEFAULT 'cashier',
    email text,
    supabase_id uuid, -- Lien optionnel vers auth.users
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    failed_attempts int DEFAULT 0,
    locked_until timestamptz,
    UNIQUE(shop_id, local_id)
);

-- Table des Remises et Promotions
CREATE TABLE IF NOT EXISTS public.discounts (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    local_id int NOT NULL,
    name text NOT NULL,
    type text DEFAULT 'percentage',
    value double precision NOT NULL,
    min_amount double precision DEFAULT 0,
    is_active boolean DEFAULT true,
    start_date timestamptz,
    end_date timestamptz,
    is_archived boolean DEFAULT false,
    UNIQUE(shop_id, local_id)
);

-- Table Fournisseurs
CREATE TABLE IF NOT EXISTS public.suppliers (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid,
    local_id int NOT NULL,
    name text NOT NULL,
    contact_name text,
    phone text,
    email text,
    address text,
    notes text,
    updated_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id)
);

-- Table Variantes
CREATE TABLE IF NOT EXISTS public.product_variants (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid,
    product_local_id int, -- MODIFIED: Can be null if product is deleted
    local_id int NOT NULL,
    name text NOT NULL,
    stock_qty int DEFAULT 0,
    UNIQUE(shop_id, terminal_id, local_id)
);

-- Table Dépenses (Manquante dans le script précédent)
CREATE TABLE IF NOT EXISTS public.expenses (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    local_id int NOT NULL,
    description text NOT NULL,
    amount double precision NOT NULL,
    category text, 
    user_id int, -- AJOUTÉ
    terminal_id uuid, -- AJOUTÉ
    date timestamptz DEFAULT now(),
    image_path text, 
    UNIQUE(shop_id, terminal_id, local_id)
);

-- Table Bons de Commande (Manquante)
CREATE TABLE IF NOT EXISTS public.purchase_orders (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid,
    local_id int NOT NULL,
    supplier_id int NOT NULL, -- local_id du fournisseur
    status text DEFAULT 'pending',
    total_amount double precision DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    received_at timestamptz,
    UNIQUE(shop_id, terminal_id, local_id)
);

-- Table Logs d'Audit
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL, -- Ajouté pour l'unicité multi-caisse
    local_id int NOT NULL,
    actor_id int NOT NULL,
    action text NOT NULL,
    target_entity_type text,
    target_entity_id int,
    details text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, terminal_id, local_id) -- Contrainte CRUCIALE
);

-- Table Articles de Commande (Manquante)
CREATE TABLE IF NOT EXISTS public.purchase_order_items (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid,
    local_id int NOT NULL,
    purchase_order_id int NOT NULL, -- local_id du BC
    product_id int NOT NULL, -- local_id du produit
    quantity int NOT NULL,
    quantity_received int,
    unit_cost double precision NOT NULL,
    line_total double precision NOT NULL,
    UNIQUE(shop_id, terminal_id, local_id)
);

-- Activer le RLS pour les utilisateurs
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Helper function to avoid infinite recursion in RLS policies for the users table.
-- SECURITY DEFINER bypasses RLS for the internal query, breaking the loop.
CREATE OR REPLACE FUNCTION public.check_is_shop_member(p_shop_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE shop_id = p_shop_id AND supabase_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public, pg_temp;

-- Sécurité : Empêcher l'accès public (anon) et autoriser uniquement les utilisateurs connectés
REVOKE ALL ON FUNCTION public.check_is_shop_member(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_is_shop_member(uuid) TO authenticated;

DROP POLICY IF EXISTS "Users are viewable by shop staff and owners" ON public.users;
CREATE POLICY "Users are viewable by shop staff and owners" 
ON public.users FOR SELECT 
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.shops WHERE id = users.shop_id AND owner_id = auth.uid())
    OR public.check_is_shop_member(users.shop_id)
);

-- 3. Création des autres tables nécessaires pour la synchronisation
-- Ces tables doivent exister pour que les politiques de sécurité (RLS) puissent s'appliquer.

CREATE TABLE IF NOT EXISTS public.sales (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL, -- Ajouté pour la gestion multi-caisse
    local_id int NOT NULL,
    customer_id uuid REFERENCES public.customers(id), -- AJOUTÉ: Lien vers le client
    total_ttc double precision DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    synced_at timestamptz DEFAULT now(),
    amount_due double precision DEFAULT 0,
    payment_status text DEFAULT 'paid', -- 'paid', 'partially_paid', 'due'
    discount_type text DEFAULT 'fixed',
    coupon_code text,
    fiscal_hash text,
    previous_fiscal_hash text,
    UNIQUE(shop_id, terminal_id, local_id) -- Correction: Ajout de terminal_id à la contrainte UNIQUE
);

CREATE TABLE IF NOT EXISTS public.products (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    local_id int NOT NULL,
    name text,
    price_ht double precision,
    cost_price double precision DEFAULT 0, -- AJOUTÉ
    preferred_supplier_id int, -- AJOUTÉ
    stock_qty int DEFAULT 0, -- MODIFIED: Changed to int for consistency with Drift
    is_active boolean DEFAULT true,
    updated_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id) -- MODIFIED: Removed terminal_id from unique constraint for shared products
);

CREATE TABLE IF NOT EXISTS public.sale_items (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL, -- Ajout de la colonne manquante
    local_id int NOT NULL,
    product_id int NOT NULL, -- MODIFIED: Use int to match Drift productId
    sale_local_id int NOT NULL, -- ID local de la vente parente (int)
    product_name text,
    unit_price_ht double precision DEFAULT 0, -- AJOUTÉ
    tax_rate double precision DEFAULT 0, -- AJOUTÉ
    cost_price_at_sale double precision DEFAULT 0, -- AJOUTÉ (requis pour RPC)
    quantity int, -- MODIFIED: Changed to int for consistency with Drift
    discount_pct double precision DEFAULT 0, -- AJOUTÉ
    discount_amount double precision DEFAULT 0,
    total_ttc double precision DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, terminal_id, local_id)
);

-- Ré-application des contraintes de sale_items (pour supporter la migration)
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS fk_sale_terminal;
ALTER TABLE public.sale_items ADD CONSTRAINT fk_sale_terminal 
    FOREIGN KEY (shop_id, terminal_id, sale_local_id) 
    REFERENCES public.sales(shop_id, terminal_id, local_id) ON DELETE CASCADE;

ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS fk_sale_item_product;
-- On lie vers la clé composite (shop_id, local_id) de products
ALTER TABLE public.sale_items ADD CONSTRAINT fk_sale_item_product
    FOREIGN KEY (shop_id, product_id) 
    REFERENCES public.products(shop_id, local_id) 
    ON DELETE RESTRICT;

CREATE TABLE IF NOT EXISTS public.cash_sessions (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL,
    local_id int NOT NULL,
    user_id int,
    started_at timestamptz DEFAULT now(),
    ended_at timestamptz,
    starting_cash double precision DEFAULT 0,
    ending_cash double precision,
    expected_cash double precision,
    discrepancy double precision,
    status text DEFAULT 'open',
    notes text,
    UNIQUE(shop_id, terminal_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.payments (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL,
    local_id int NOT NULL,
    sale_local_id int NOT NULL,
    customer_id uuid REFERENCES public.customers(id), -- AJOUTÉ: Lien vers le client
    method text NOT NULL,
    amount double precision NOT NULL,
    change_given double precision DEFAULT 0,
    paid_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, terminal_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.customers (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    -- Pas de terminal_id ici, car les clients sont partagés par magasin
    local_id int NOT NULL,
    name text,
    phone text,
    email text,
    updated_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.categories (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    local_id int NOT NULL,
    name text NOT NULL,
    icon text,
    color text DEFAULT '#2196F3',
    sort_order int DEFAULT 0,
    updated_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.stock_movements (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL,
    local_id int NOT NULL,
    product_id int NOT NULL, -- Lien vers products(local_id)
    user_id int,
    type text NOT NULL, -- 'sale', 'transfer_in', 'transfer_out', 'inventory'
    qty_delta double precision NOT NULL,
    qty_after double precision NOT NULL,
    reason text,
    inventory_ref text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, terminal_id, local_id)
);

-- Ajout de la clé étrangère pour garantir que le mouvement pointe vers un produit valide du magasin
ALTER TABLE public.stock_movements DROP CONSTRAINT IF EXISTS fk_stock_movement_product;
ALTER TABLE public.stock_movements ADD CONSTRAINT fk_stock_movement_product 
    FOREIGN KEY (shop_id, product_id) 
    REFERENCES public.products(shop_id, local_id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS public.inventory_sessions (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    local_id int NOT NULL,
    user_id int, -- ID de l'utilisateur local qui a démarré la session
    status text,
    ref text,
    notes text,
    total_products int DEFAULT 0,
    discrepancies int DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    completed_at timestamptz,
    terminal_id uuid,
    CONSTRAINT unique_inventory_per_terminal UNIQUE(shop_id, terminal_id, local_id)
);

-- Cette contrainte est CRUCIALE pour que inventory_lines puisse s'y référer (clé composite)
ALTER TABLE public.inventory_sessions DROP CONSTRAINT IF EXISTS unique_inventory_per_terminal CASCADE;
ALTER TABLE public.inventory_sessions ADD CONSTRAINT unique_inventory_per_terminal UNIQUE(shop_id, terminal_id, local_id);

CREATE TABLE IF NOT EXISTS public.inventory_lines (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL,
    local_id int NOT NULL,
    session_id int NOT NULL, -- local_id de inventory_sessions
    product_id int NOT NULL, -- local_id de products
    product_name text,
    expected_qty int DEFAULT 0, -- Aligné avec Drift IntColumn
    barcode text,
    defective_qty int DEFAULT 0,
    obsolete_qty int DEFAULT 0,
    expired_qty int DEFAULT 0,
    counted_qty int, -- Aligné avec Drift IntColumn
    difference int, -- Aligné avec Drift IntColumn
    is_validated boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, terminal_id, local_id) -- CRUCIAL: Doit inclure terminal_id pour multi-caisse
);

-- Contrainte pour lier les lignes à la session (clé composite)
ALTER TABLE public.inventory_lines DROP CONSTRAINT IF EXISTS fk_inventory_session;
ALTER TABLE public.inventory_lines ADD CONSTRAINT fk_inventory_session 
    FOREIGN KEY (shop_id, terminal_id, session_id) REFERENCES public.inventory_sessions(shop_id, terminal_id, local_id) ON DELETE CASCADE;

-- Ajout de la clé étrangère pour garantir que la ligne pointe vers un produit valide du magasin
ALTER TABLE public.inventory_lines DROP CONSTRAINT IF EXISTS fk_inventory_line_product;
ALTER TABLE public.inventory_lines ADD CONSTRAINT fk_inventory_line_product
    FOREIGN KEY (shop_id, product_id) 
    REFERENCES public.products(shop_id, local_id) ON DELETE CASCADE;

-- Ajout de la clé étrangère pour garantir que la ligne pointe vers un utilisateur valide du magasin
-- (Si user_id est un UUID sur Supabase, il faudrait le changer ici aussi)
ALTER TABLE public.inventory_sessions DROP CONSTRAINT IF EXISTS fk_inventory_session_user;
ALTER TABLE public.inventory_sessions ADD CONSTRAINT fk_inventory_session_user
    FOREIGN KEY (user_id) 
    REFERENCES public.users(id) ON DELETE SET NULL; -- Assuming public.users.id is int

CREATE TABLE IF NOT EXISTS public.stock_transfers (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL,
    local_id int NOT NULL,
    ref text,
    source_shop_id uuid REFERENCES public.shops(id),
    target_shop_id uuid REFERENCES public.shops(id),
    status text,
    notes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    received_at timestamptz,
    UNIQUE(shop_id, terminal_id, local_id)
);

-- Cette contrainte est CRUCIALE pour que stock_transfer_items puisse s'y référer
ALTER TABLE public.stock_transfers DROP CONSTRAINT IF EXISTS unique_transfer_per_shop CASCADE;
ALTER TABLE public.stock_transfers ADD CONSTRAINT unique_transfer_per_shop UNIQUE(shop_id, terminal_id, local_id);

CREATE TABLE IF NOT EXISTS public.stock_transfer_items (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id),
    terminal_id uuid NOT NULL,
    local_id int NOT NULL,
    transfer_id int, 
    product_id int,
    quantity_sent int, -- MODIFIED: Changed to int for consistency with Drift
    quantity_received int, -- MODIFIED: Changed to int for consistency with Drift
    UNIQUE(shop_id, terminal_id, local_id)
);

-- Ré-application des contraintes pour garantir l'intégrité après migration
DO $$
BEGIN
    -- 1. Contraintes simples vers la table shops
    ALTER TABLE public.sales DROP CONSTRAINT IF EXISTS sales_shop_id_fkey;
    ALTER TABLE public.sales ADD CONSTRAINT sales_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id) ON DELETE CASCADE;
    
    ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_shop_id_fkey;
    ALTER TABLE public.products ADD CONSTRAINT products_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id) ON DELETE CASCADE;
    
    ALTER TABLE public.customers DROP CONSTRAINT IF EXISTS customers_shop_id_fkey;
    ALTER TABLE public.customers ADD CONSTRAINT customers_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id) ON DELETE CASCADE;

    -- 2. Contraintes de transfert (vers shops)
    ALTER TABLE public.stock_transfers DROP CONSTRAINT IF EXISTS stock_transfers_source_shop_id_fkey;
    ALTER TABLE public.stock_transfers ADD CONSTRAINT stock_transfers_source_shop_id_fkey FOREIGN KEY (source_shop_id) REFERENCES public.shops(id) ON DELETE CASCADE;
    ALTER TABLE public.stock_transfers DROP CONSTRAINT IF EXISTS stock_transfers_target_shop_id_fkey;
    ALTER TABLE public.stock_transfers ADD CONSTRAINT stock_transfers_target_shop_id_fkey FOREIGN KEY (target_shop_id) REFERENCES public.shops(id) ON DELETE CASCADE;

    -- 3. Clés composites (Crucial pour la synchro multi-caisses)
    -- Sale Items -> Sales
    ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS fk_sale_terminal;
    ALTER TABLE public.sale_items ADD CONSTRAINT fk_sale_terminal 
        FOREIGN KEY (shop_id, terminal_id, sale_local_id) 
        REFERENCES public.sales(shop_id, terminal_id, local_id) ON DELETE CASCADE;

    -- Sale Items -> Products
    ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS fk_sale_item_product;
    ALTER TABLE public.sale_items ADD CONSTRAINT fk_sale_item_product
        FOREIGN KEY (shop_id, product_id) 
        REFERENCES public.products(shop_id, local_id) ON DELETE RESTRICT;

    -- Stock Movements -> Products
    ALTER TABLE public.stock_movements DROP CONSTRAINT IF EXISTS fk_stock_movement_product;
    ALTER TABLE public.stock_movements ADD CONSTRAINT fk_stock_movement_product 
        FOREIGN KEY (shop_id, product_id) 
        REFERENCES public.products(shop_id, local_id) ON DELETE CASCADE;

    -- Inventory Lines -> Sessions
    ALTER TABLE public.inventory_lines DROP CONSTRAINT IF EXISTS fk_inventory_session;
    ALTER TABLE public.inventory_lines ADD CONSTRAINT fk_inventory_session 
        FOREIGN KEY (shop_id, terminal_id, session_id) 
        REFERENCES public.inventory_sessions(shop_id, terminal_id, local_id) ON DELETE CASCADE;

    -- Transfer Items -> Transfers
    ALTER TABLE public.stock_transfer_items DROP CONSTRAINT IF EXISTS fk_transfer_id;
    ALTER TABLE public.stock_transfer_items ADD CONSTRAINT fk_transfer_id 
        FOREIGN KEY (shop_id, terminal_id, transfer_id) 
        REFERENCES public.stock_transfers(shop_id, terminal_id, local_id) ON DELETE CASCADE;

    -- Personnel -> Shops
    ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_shop_id_fkey;
    ALTER TABLE public.users ADD CONSTRAINT users_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id) ON DELETE CASCADE;
END $$;

-- 4. Activer la sécurité RLS sur TOUTES les tables de façon robuste
DO $$ 
DECLARE 
    t text;
BEGIN
    -- On boucle sur toutes les tables du schéma public pour activer le RLS
    FOR t IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);
    END LOOP;
END $$;

-- 5. Mettre à jour la politique de sécurité
-- Nettoyage des anciennes politiques
DROP POLICY IF EXISTS "Les propriétaires voient leurs magasins" ON public.shops;
DROP POLICY IF EXISTS "owner_sees_own_shops" ON public.shops;
DROP POLICY IF EXISTS "Owners can see their own shops" ON public.shops;
DROP POLICY IF EXISTS "Owners can create shops for themselves" ON public.shops;
DROP POLICY IF EXISTS "Owners can update their own shops" ON public.shops;
DROP POLICY IF EXISTS "Owners can delete their own shops" ON public.shops;
DROP POLICY IF EXISTS "Owners can manage their own shops" ON public.shops;

-- Politique SHOPS
CREATE POLICY "Owners can manage their own shops"
ON public.shops
FOR ALL USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- 6. Politiques pour la table 'sales'
DROP POLICY IF EXISTS "Owners can manage sales from their own shops" ON public.sales;
DROP POLICY IF EXISTS "Authorized users can view sales" ON public.sales;
DROP POLICY IF EXISTS "Authorized users can insert sales" ON public.sales;
DROP POLICY IF EXISTS "Admins and Owners can update sales" ON public.sales;
-- Anciens noms (nettoyage)
DROP POLICY IF EXISTS "Owners can view sales from their own shops" ON public.sales;
DROP POLICY IF EXISTS "Owners can insert sales into their own shops" ON public.sales;
DROP POLICY IF EXISTS "Owners can update sales except if already refunded" ON public.sales;

-- 1. Lecture : Propriétaires et tout le personnel authentifié du magasin
CREATE POLICY "Authorized users can view sales" 
ON public.sales FOR SELECT 
USING ( 
    EXISTS (SELECT 1 FROM public.shops WHERE id = sales.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = sales.shop_id AND supabase_id = auth.uid())
);

-- 2. Insertion : Autorisé pour tout le personnel authentifié du magasin (synchronisation des ventes)
CREATE POLICY "Authorized users can insert sales" 
ON public.sales FOR INSERT 
WITH CHECK ( 
    EXISTS (SELECT 1 FROM public.shops WHERE id = sales.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = sales.shop_id AND supabase_id = auth.uid())
);

-- 3. Mise à jour (incluant statut paiement) : Réservé aux Propriétaires et Administrateurs
CREATE POLICY "Admins and Owners can update sales" 
ON public.sales FOR UPDATE 
USING ( 
    (
        EXISTS (SELECT 1 FROM public.shops WHERE id = sales.shop_id AND owner_id = auth.uid())
        OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = sales.shop_id AND supabase_id = auth.uid() AND role IN ('admin', 'owner'))
    )
    AND status <> 'refunded' 
);

-- 4. Empêcher la suppression des ventes (pour l'audit légal)
DROP POLICY IF EXISTS "No one can delete sales" ON public.sales;

-- Politiques pour 'payments'
DROP POLICY IF EXISTS "Owners can manage payments" ON public.payments;
CREATE POLICY "Owners can manage payments" ON public.payments FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = payments.shop_id AND shops.owner_id = auth.uid()) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = payments.shop_id AND shops.owner_id = auth.uid()) );

-- 7. Politiques pour les autres tables (exemple avec 'products')
DROP POLICY IF EXISTS "Owners can manage products in their own shops" ON public.products;
CREATE POLICY "Owners can manage products in their own shops" ON public.products FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = products.shop_id AND shops.owner_id = auth.uid()) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = products.shop_id AND shops.owner_id = auth.uid()) );

-- 8. Politiques pour 'sale_items' (Détails des ventes)
DROP POLICY IF EXISTS "Owners can manage sale_items" ON public.sale_items;
DROP POLICY IF EXISTS "Owners can view sale_items" ON public.sale_items;
DROP POLICY IF EXISTS "Owners can insert sale_items" ON public.sale_items;
DROP POLICY IF EXISTS "Owners can update sale_items except if sale is refunded" ON public.sale_items;

-- Appliquer la même logique aux articles de vente pour une sécurité totale
CREATE POLICY "Owners can view sale_items" 
ON public.sale_items FOR SELECT 
USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = sale_items.shop_id AND shops.owner_id = auth.uid()) );

CREATE POLICY "Owners can insert sale_items" 
ON public.sale_items FOR INSERT 
WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = sale_items.shop_id AND shops.owner_id = auth.uid()) );

CREATE POLICY "Owners can update sale_items except if sale is refunded" 
ON public.sale_items FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM public.sales s
        WHERE s.shop_id = sale_items.shop_id 
          AND s.terminal_id = sale_items.terminal_id 
          AND s.local_id = sale_items.sale_local_id 
          AND s.status <> 'refunded'
    )
);

-- 9. Politiques pour 'customers' (Clients)
DROP POLICY IF EXISTS "Owners can manage customers" ON public.customers;
CREATE POLICY "Owners can manage customers" ON public.customers FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = customers.shop_id AND shops.owner_id = auth.uid()) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = customers.shop_id AND shops.owner_id = auth.uid()) );

-- 9b. Politiques pour 'categories'
DROP POLICY IF EXISTS "Owners can manage categories" ON public.categories;
CREATE POLICY "Owners can manage categories" ON public.categories FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = categories.shop_id AND shops.owner_id = auth.uid()) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = categories.shop_id AND shops.owner_id = auth.uid()) );

-- 10. Politiques pour 'stock_movements' (Historique des stocks)
DROP POLICY IF EXISTS "Authorized staff can manage stock_movements" ON public.stock_movements;
DROP POLICY IF EXISTS "Owners can manage stock_movements" ON public.stock_movements;
CREATE POLICY "Authorized staff can manage stock_movements" 
ON public.stock_movements 
FOR ALL USING ( 
    EXISTS (SELECT 1 FROM public.shops WHERE id = stock_movements.shop_id AND owner_id = auth.uid())
    OR public.check_is_shop_member(stock_movements.shop_id)
) 
WITH CHECK ( 
    EXISTS (SELECT 1 FROM public.shops WHERE id = stock_movements.shop_id AND owner_id = auth.uid())
    OR public.check_is_shop_member(stock_movements.shop_id)
);

-- 11. Politiques pour 'inventory_sessions' (Inventaires)
DROP POLICY IF EXISTS "Authorized staff can manage inventory_sessions" ON public.inventory_sessions;
DROP POLICY IF EXISTS "Owners can manage inventory_sessions" ON public.inventory_sessions;
CREATE POLICY "Authorized staff can manage inventory_sessions" ON public.inventory_sessions 
FOR ALL USING ( 
    EXISTS (SELECT 1 FROM public.shops WHERE id = inventory_sessions.shop_id AND owner_id = auth.uid())
    OR public.check_is_shop_member(inventory_sessions.shop_id)
);

-- Politiques pour 'inventory_lines'
DROP POLICY IF EXISTS "Authorized staff can manage inventory_lines" ON public.inventory_lines;
DROP POLICY IF EXISTS "Owners can manage inventory_lines" ON public.inventory_lines;
CREATE POLICY "Authorized staff can manage inventory_lines" ON public.inventory_lines 
FOR ALL USING ( 
    EXISTS (SELECT 1 FROM public.shops WHERE id = inventory_lines.shop_id AND owner_id = auth.uid())
    OR public.check_is_shop_member(inventory_lines.shop_id)
);

-- Politiques pour 'audit_logs'
DROP POLICY IF EXISTS "Authorized staff can view audit_logs" ON public.audit_logs;
CREATE POLICY "Authorized staff can view audit_logs" ON public.audit_logs
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.shops WHERE id = audit_logs.shop_id AND owner_id = auth.uid())
    OR public.check_is_shop_member(audit_logs.shop_id)
);

-- 11b. Politiques pour 'stock_transfers'
-- Un propriétaire peut voir un transfert s'il possède le magasin source OU cible
DROP POLICY IF EXISTS "Users can see transfers involving their shops" ON public.stock_transfers;
CREATE POLICY "Users can see transfers involving their shops" 
ON public.stock_transfers 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.shops 
        WHERE (shops.id = source_shop_id OR shops.id = target_shop_id) 
        AND shops.owner_id = auth.uid()
    )
);

-- Politiques pour 'cash_sessions'
DROP POLICY IF EXISTS "Owners can manage cash_sessions" ON public.cash_sessions;
CREATE POLICY "Owners can manage cash_sessions" ON public.cash_sessions FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = cash_sessions.shop_id AND shops.owner_id = auth.uid()) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = cash_sessions.shop_id AND shops.owner_id = auth.uid()) );

-- 11c. Politiques pour 'stock_transfer_items'
DROP POLICY IF EXISTS "Users can manage transfer items" ON public.stock_transfer_items;
CREATE POLICY "Users can manage transfer items" 
ON public.stock_transfer_items 
FOR ALL USING (
    shop_id IN (SELECT id FROM public.shops WHERE owner_id = auth.uid()) -- Accès si propriétaire de l'émetteur
    OR public.check_is_shop_member(shop_id) -- Accès si employé de l'émetteur
    OR 
    EXISTS (
        SELECT 1 FROM public.stock_transfers st 
        WHERE st.shop_id = stock_transfer_items.shop_id 
          AND st.terminal_id = stock_transfer_items.terminal_id 
          AND st.local_id = stock_transfer_items.transfer_id 
          AND (st.target_shop_id IN (SELECT id FROM public.shops WHERE owner_id = auth.uid()) -- Accès si propriétaire du destinataire
               OR public.check_is_shop_member(st.target_shop_id)) -- Accès si employé du destinataire
    )
);

-- 12. Ajouter la colonne total_ttc à sale_items
-- Nécessaire pour calculer le chiffre d'affaires par produit
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS total_ttc double precision DEFAULT 0;

-- 13. Ajouter la colonne created_at à sale_items
-- Nécessaire pour les rapports de ventes par période (Top produits)
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

-- 14. Fonction RPC pour le Dashboard (Calculs côté serveur)
-- Cette fonction agrège les données et renvoie un JSON léger

-- NETTOYAGE RIGOUREUX : Supprimer TOUTES les versions possibles pour éviter les conflits UUID/TEXT
DROP FUNCTION IF EXISTS public.get_dashboard_stats(text, timestamptz);
DROP FUNCTION IF EXISTS public.get_dashboard_stats(text, timestamptz, timestamptz);
DROP FUNCTION IF EXISTS public.get_dashboard_stats(uuid, timestamptz);
DROP FUNCTION IF EXISTS public.get_dashboard_stats(uuid, timestamptz, timestamptz);
DROP FUNCTION IF EXISTS public.get_dashboard_stats(uuid, timestamptz, timestamptz, uuid);

CREATE OR REPLACE FUNCTION get_dashboard_stats(
    p_owner_id uuid, -- MODIFIED: Consistent type with shops.owner_id
    p_start_date timestamptz,
    p_end_date timestamptz DEFAULT now(),
    p_terminal_id uuid DEFAULT NULL, -- NOUVEAU : Filtre optionnel par caisse
    p_sort_by_revenue BOOLEAN DEFAULT TRUE -- NEW PARAMETER for top products
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_total_revenue double precision;
    v_total_sales int;
    v_daily_stats json;
    v_top_products json;
    v_shop_performances json;
    v_terminal_performances json;
    v_out_of_stock_count int;
    v_total_cost double precision;
    v_total_expenses double precision;
    v_total_margin double precision;
BEGIN
    -- 1. Totaux globaux sur la période
    SELECT COALESCE(SUM(total_ht - discount_amount), 0), COUNT(*) 
    INTO v_total_revenue, v_total_sales
    FROM public.sales s
    JOIN public.shops sh ON s.shop_id = sh.id
    WHERE sh.owner_id = p_owner_id 
      AND s.status = 'completed'
      AND (p_terminal_id IS NULL OR s.terminal_id = p_terminal_id)
      AND s.created_at >= p_start_date 
      AND s.created_at <= p_end_date;

    -- Calcul du coût des marchandises vendues (COGS)
    SELECT COALESCE(SUM(quantity * cost_price_at_sale), 0) INTO v_total_cost
    FROM public.sale_items si
    JOIN public.shops sh ON si.shop_id = sh.id
    JOIN public.sales s ON s.shop_id = si.shop_id AND s.terminal_id = si.terminal_id AND s.local_id = si.sale_local_id
    WHERE sh.owner_id = p_owner_id 
      AND s.status = 'completed'
      AND (p_terminal_id IS NULL OR s.terminal_id = p_terminal_id)
      AND si.created_at >= p_start_date 
      AND si.created_at <= p_end_date;

    -- Calcul des dépenses opérationnelles
    SELECT COALESCE(SUM(amount), 0) INTO v_total_expenses
    FROM public.expenses e
    JOIN public.shops sh ON e.shop_id = sh.id
    WHERE sh.owner_id = p_owner_id AND e.date >= p_start_date AND e.date <= p_end_date
      AND (p_terminal_id IS NULL OR e.terminal_id = p_terminal_id);

    -- 2. Stats journalières (Graphique)
    SELECT json_agg(t) INTO v_daily_stats FROM (
        SELECT date_trunc('day', s.created_at) as day, SUM(s.total_ht - s.discount_amount) as amount
        FROM public.sales s
        JOIN public.shops sh ON s.shop_id = sh.id
        WHERE sh.owner_id = p_owner_id 
          AND s.status = 'completed'
          AND (p_terminal_id IS NULL OR s.terminal_id = p_terminal_id)
          AND s.created_at >= p_start_date 
          AND s.created_at <= p_end_date
        GROUP BY 1 ORDER BY 1
    ) t;

    -- 3. Top Produits (Quantity) -- Correction: p_owner_id doit être de type UUID
    SELECT json_agg(t) INTO v_top_products FROM (
        SELECT si.product_name,
               SUM(si.total_ttc) as revenue, -- MODIFIED: Sum total_ttc for revenue
               SUM(si.quantity) as qty, -- Added qty for sorting by quantity
               MAX(p.unit) as unit -- Added unit for display
        FROM public.sale_items si
        JOIN public.shops sh ON si.shop_id = sh.id
        JOIN public.sales s ON s.shop_id = si.shop_id AND s.terminal_id = si.terminal_id AND s.local_id = si.sale_local_id
        WHERE sh.owner_id = p_owner_id 
          AND s.status = 'completed'
          AND (p_terminal_id IS NULL OR s.terminal_id = p_terminal_id)
          AND si.created_at >= p_start_date 
          AND si.created_at <= p_end_date
        GROUP BY si.product_name
        ORDER BY
            CASE WHEN p_sort_by_revenue THEN SUM(si.total_ttc) ELSE SUM(si.quantity) END DESC
        LIMIT 5
    ) t;

    -- 4. Performance par magasin (Nouveau) -- Correction: p_owner_id doit être de type UUID
    SELECT json_agg(t) INTO v_shop_performances FROM (
        SELECT 
            sh.name, 
            sh.address, 
            COALESCE(SUM(s.total_ht - s.discount_amount), 0) as revenue,
            COUNT(s.id) as count
        FROM public.shops sh
        LEFT JOIN public.sales s ON s.shop_id = sh.id AND s.created_at >= p_start_date AND s.created_at <= p_end_date 
             AND s.status = 'completed' AND (p_terminal_id IS NULL OR s.terminal_id = p_terminal_id)
        WHERE sh.owner_id = p_owner_id
        GROUP BY sh.id, sh.name, sh.address
        ORDER BY revenue DESC
    ) t;

    -- 4b. Performance par terminal (Caisse)
    SELECT json_agg(t) INTO v_terminal_performances FROM (
        SELECT 
            s.terminal_id,
            COALESCE(tm.name, 'Caisse ' || substring(s.terminal_id::text from 1 for 8)) as terminal_name,
            COALESCE(SUM(s.total_ht - s.discount_amount), 0) as revenue,
            COUNT(s.id) as count
        FROM public.sales s
        JOIN public.shops sh ON s.shop_id = sh.id
        LEFT JOIN public.terminals tm ON s.terminal_id = tm.id
        WHERE sh.owner_id = p_owner_id 
          AND s.status = 'completed'
          AND (p_terminal_id IS NULL OR s.terminal_id = p_terminal_id)
          AND s.created_at >= p_start_date 
          AND s.created_at <= p_end_date
        GROUP BY s.terminal_id, tm.name
        ORDER BY revenue DESC
    ) t;

    -- 5. Produits en rupture de stock (Stock <= 0)
    SELECT COUNT(*) INTO v_out_of_stock_count
    FROM public.products p
    JOIN public.shops sh ON p.shop_id = sh.id
    WHERE sh.owner_id = p_owner_id AND p.stock_qty <= 0 AND p.is_active = true;

    -- Calcul de la marge brute
    v_total_margin := v_total_revenue - v_total_cost;

    -- Construction de l'objet JSON final
    RETURN json_build_object(
        'total_revenue', v_total_revenue,
        'total_sales', v_total_sales,
        'gross_margin', v_total_margin,
        'net_profit', (v_total_margin - v_total_expenses),
        'total_expenses', v_total_expenses,
        'daily_stats', COALESCE(v_daily_stats, '[]'::json),
        'top_products', COALESCE(v_top_products, '[]'::json),
        'shop_performances', COALESCE(v_shop_performances, '[]'::json),
        'terminal_performances', COALESCE(v_terminal_performances, '[]'::json),
        'out_of_stock_count', v_out_of_stock_count
    );
END;
$$;

-- Sécurité : Restreindre l'accès au Dashboard
REVOKE ALL ON FUNCTION public.get_dashboard_stats(uuid, timestamptz, timestamptz, uuid, BOOLEAN) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_dashboard_stats(uuid, timestamptz, timestamptz, uuid, BOOLEAN) TO authenticated;

-- 29. Fonction RPC pour l'Expertise Conseil (Prédictions de stock)
CREATE OR REPLACE FUNCTION public.get_stock_predictions(
    p_owner_id uuid,
    p_shop_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_predictions jsonb;
BEGIN
    SELECT jsonb_agg(t) INTO v_predictions FROM (
        WITH sales_velocity AS (
            -- Calcul de la quantité vendue par produit sur les 30 derniers jours
            SELECT 
                si.product_id, -- ID local Drift
                si.shop_id,
                sh.name as shop_name,
                si.product_name,
                SUM(si.quantity) as total_sold_30d,
                (SUM(si.quantity)::float / 30.0) as avg_daily_sales
            FROM public.sale_items si
            JOIN public.sales s ON si.shop_id = s.shop_id 
                                AND si.terminal_id = s.terminal_id 
                                AND si.sale_local_id = s.local_id
            JOIN public.shops sh ON si.shop_id = sh.id
            WHERE sh.owner_id = p_owner_id
              AND (p_shop_id IS NULL OR si.shop_id = p_shop_id)
              AND s.status = 'completed'
              AND s.created_at >= now() - interval '30 days'
            GROUP BY si.product_id, si.shop_id, sh.name, si.product_name
        )
        SELECT 
            sv.product_name,
            sv.product_id,
            sv.shop_id,
            sv.shop_name,
            p.stock_qty as current_stock,
            p.unit,
            p.cost_price,
            p.preferred_supplier_id,
            ROUND(sv.avg_daily_sales::numeric, 2) as daily_velocity,
            CASE 
                WHEN sv.avg_daily_sales > 0 THEN ROUND((p.stock_qty / sv.avg_daily_sales)::numeric, 0)
                ELSE 999 
            END as days_remaining,
            -- Recommandation : commander assez pour couvrir les 30 prochains jours
            ROUND((sv.avg_daily_sales * 30 - p.stock_qty)::numeric, 0) as recommended_order_qty
        FROM sales_velocity sv
        JOIN public.products p ON sv.shop_id = p.shop_id AND sv.product_id = p.local_id
        WHERE p.is_active = true
          -- On ne montre que ce qui risque de manquer dans les 10 prochains jours
          AND (p.stock_qty / NULLIF(sv.avg_daily_sales, 0)) <= 10
        ORDER BY days_remaining ASC
        LIMIT 10
    ) t;

    RETURN COALESCE(v_predictions, '[]'::jsonb);
END;
$$;

REVOKE ALL ON FUNCTION public.get_stock_predictions(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_stock_predictions(uuid, uuid) TO authenticated;

-- Accorder les droits d'accès aux nouvelles tables pour l'API
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.suppliers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.expenses TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.purchase_orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.purchase_order_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.product_variants TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.users TO authenticated;

-- Forcer le rafraîchissement du cache de Supabase (PostgREST)
NOTIFY pgrst, 'reload schema';

-- 15. Recréation des Vues (Indispensables pour le Dashboard Flutter)
-- On utilise ::text pour garantir la compatibilité entre UUID et String
CREATE OR REPLACE VIEW public.store_summary WITH (security_invoker = true) AS
SELECT 
    shop_id, -- MODIFIED: Use native UUID type
    COUNT(*) as sale_count, 
    SUM(total_ht - discount_amount) as revenue,
    COALESCE(SUM(total_ht - discount_amount) / NULLIF(COUNT(*), 0), 0) as avg_basket
FROM public.sales
GROUP BY shop_id;

CREATE OR REPLACE VIEW public.store_weekly WITH (security_invoker = true) AS
SELECT 
    shop_id, -- MODIFIED: Use native UUID type
    date_trunc('day', created_at)::date as sale_date,
    COUNT(*) as sale_count, 
    SUM(total_ht - discount_amount) as revenue
FROM public.sales
WHERE created_at >= (now() - interval '30 days')
GROUP BY shop_id, sale_date;

CREATE OR REPLACE VIEW public.store_low_stock WITH (security_invoker = true) AS
SELECT 
    shop_id, -- MODIFIED: Use native UUID type
    COUNT(*) as low_stock_count
FROM public.products
WHERE stock_qty <= 5
GROUP BY shop_id;

CREATE OR REPLACE VIEW public.global_top_products WITH (security_invoker = true) AS
SELECT 
    shop_id, -- MODIFIED: Use native UUID type
    product_name, 
    SUM(quantity) as qty
FROM public.sale_items
GROUP BY shop_id, product_name;

-- 15b. Vue pour visualiser les transferts en attente par magasin
CREATE OR REPLACE VIEW public.pending_transfers_details WITH (security_invoker = true) AS
SELECT 
    t.id as transfer_uuid,
    t.ref as reference,
    t.status,
    t.source_shop_id,
    src.name as source_shop_name,
    t.target_shop_id,
    tgt.name as target_shop_name,
    t.notes,
    t.created_at,
    (SELECT COUNT(*) FROM public.stock_transfer_items i 
     WHERE i.shop_id = t.shop_id AND i.terminal_id = t.terminal_id AND i.transfer_id = t.local_id) as total_items
FROM public.stock_transfers t
JOIN public.shops src ON t.source_shop_id = src.id
JOIN public.shops tgt ON t.target_shop_id = tgt.id
WHERE t.status = 'pending';

-- 15c. Vue pour voir les dettes totales par client
-- Utile pour les rapports financiers et les relances clients
CREATE OR REPLACE VIEW public.customer_debts_summary WITH (security_invoker = true) AS
SELECT 
    c.id as customer_id,
    c.shop_id,
    c.name as customer_name,
    c.phone,
    COUNT(s.id) as unpaid_sales_count,
    SUM(s.amount_due) as total_debt,
    MAX(s.created_at) as last_unpaid_sale_at
FROM public.customers c
JOIN public.sales s ON c.id = s.customer_id
WHERE s.status = 'completed' AND s.payment_status <> 'paid'
GROUP BY c.id, c.shop_id, c.name, c.phone;

-- 16. OPTIMISATION DES PERFORMANCES (Indexation avancée)
-- Pour accélérer le filtrage des magasins par propriétaire
CREATE INDEX IF NOT EXISTS idx_shops_owner_id ON public.shops(owner_id);

-- Index pour la synchronisation incrémentale
CREATE INDEX IF NOT EXISTS idx_sales_synced_at ON public.sales(synced_at);

-- Index composite pour le Dashboard (Ventes par magasin et date)
-- L'ordre est important : shop_id d'abord (égalité), created_at ensuite (plage)
-- On utilise INCLUDE pour faire un "Covering Index" sur le chiffre d'affaires
CREATE INDEX IF NOT EXISTS idx_sales_dashboard_perf 
ON public.sales (shop_id, created_at DESC) 
INCLUDE (total_ttc);

-- Index pour le calcul des Top Produits
CREATE INDEX IF NOT EXISTS idx_sale_items_reporting 
ON public.sale_items (shop_id, created_at DESC) 
INCLUDE (product_name, quantity);

-- Index pour la vue de stock faible (évite le scan complet des produits)
CREATE INDEX IF NOT EXISTS idx_products_low_stock 
ON public.products (shop_id) 
WHERE (stock_qty <= 5);

-- Index pour accélérer la recherche des ventes par client (utilisé par la vue des dettes)
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON public.sales (customer_id);

-- 17. ACTIVER LE REALTIME POUR LES VENTES
-- Cela permet au dashboard de se mettre à jour automatiquement
DO $$
BEGIN
    -- 1. Ventes
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'sales') 
    AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'sales') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.sales;
    END IF;

    -- 2. Produits
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'products')
    AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'products') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
    END IF;

    -- 3. Clients
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'customers')
    AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'customers') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.customers;
    END IF;

    -- 4. Catégories
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'categories')
    AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'categories') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.categories;
    END IF;

    -- 5. Transferts
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'stock_transfers')
    AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'stock_transfers') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.stock_transfers;
    END IF;

    -- 6. Dépenses
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'expenses')
    AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'expenses') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.expenses;
    END IF;

    -- 7. Bons de commande
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'purchase_orders')
    AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'purchase_orders') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.purchase_orders;
    END IF;

    -- 8. Alertes de sécurité (Vérification double : existence table + absence publication)
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'security_alerts')
    AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'security_alerts') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.security_alerts;
    END IF;
END $$;

-- 19. Fonction RPC pour la mise à jour atomique du stock par delta
-- Cette fonction est cruciale pour la synchronisation incrémentale du stock
DROP FUNCTION IF EXISTS public.update_product_stock_delta(text, int, int);
DROP FUNCTION IF EXISTS public.update_product_stock_delta(uuid, int, int);
CREATE OR REPLACE FUNCTION public.update_product_stock_delta(
    p_shop_id uuid, -- Correction: p_owner_id doit être de type UUID
    p_local_id int,
    p_qty_delta int -- MODIFIED: Changed to int for consistency with Drift
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp -- MODIFIED: Removed p_terminal_id from parameters
AS $$ 
DECLARE
    v_new_qty double precision;
BEGIN
    UPDATE public.products
    SET 
        stock_qty = COALESCE(stock_qty, 0) + p_qty_delta,
        updated_at = now()
    WHERE
        shop_id = p_shop_id AND
        local_id = p_local_id
    RETURNING stock_qty INTO v_new_qty;

    -- Vérification de la disponibilité du stock
    IF v_new_qty < 0 THEN
        RAISE EXCEPTION 'Stock insuffisant pour le produit % (Quantité restante : %)', p_local_id, v_new_qty;
    END IF;
END;
$$;

-- Accorder les droits d'exécution aux utilisateurs authentifiés
REVOKE ALL ON FUNCTION public.update_product_stock_delta(uuid, int, int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_product_stock_delta(uuid, int, int) TO authenticated;

-- 20. Fonction RPC pour valider un remboursement globalement
DROP FUNCTION IF EXISTS public.process_sale_refund(text, text, int, int);
DROP FUNCTION IF EXISTS public.process_sale_refund(uuid, uuid, int, int);
CREATE OR REPLACE FUNCTION public.process_sale_refund(
    p_shop_id uuid,
    p_terminal_id uuid,
    p_sale_local_id int,
    p_user_id int
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_sale_id uuid;
    v_created_at timestamptz;
    v_item RECORD;
BEGIN
    -- 1. Verrouiller la vente pour éviter les doubles remboursements
    SELECT id, created_at INTO v_sale_id, v_created_at
    FROM public.sales
    WHERE shop_id = p_shop_id 
      AND terminal_id = p_terminal_id 
      AND local_id = p_sale_local_id
      AND status = 'completed'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Vente non trouvée ou déjà remboursée');
    END IF;

    -- Vérification de la date (limite 30 jours)
    IF v_created_at < now() - interval '30 days' THEN
        RETURN json_build_object('success', false, 'message', 'Le délai de remboursement de 30 jours est dépassé');
    END IF;

    -- 2. Mise à jour de la vente
    UPDATE public.sales
    SET status = 'refunded',
        is_refunded = true,
        refunded_amount = total_ttc,
        updated_at = now()
    WHERE id = v_sale_id;

    -- 3. Mise à jour des stocks des produits concernés
    FOR v_item IN 
        SELECT product_id, quantity 
        FROM public.sale_items 
        WHERE shop_id = p_shop_id AND terminal_id = p_terminal_id AND sale_local_id = p_sale_local_id
    LOOP
        UPDATE public.products
        SET stock_qty = stock_qty + v_item.quantity,
            updated_at = now()
        WHERE shop_id = p_shop_id AND local_id = v_item.product_id;
    END LOOP;

    RETURN json_build_object('success', true);
END;
$$;

REVOKE ALL ON FUNCTION public.process_sale_refund(uuid, uuid, integer, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_sale_refund(uuid, uuid, int, int) TO authenticated;

-- 22. RPC de vérification sécurisée du PIN (Protection Force Brute Serveur)
CREATE OR REPLACE FUNCTION public.verify_user_pin_v2(
    p_shop_id uuid,
    p_local_id int,
    p_pin_hash text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user record;
    v_new_attempts int;
    v_lock_time timestamptz;
BEGIN
    SELECT * INTO v_user FROM public.users 
    WHERE shop_id = p_shop_id AND local_id = p_local_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Utilisateur introuvable');
    END IF;

    IF v_user.locked_until IS NOT NULL AND v_user.locked_until > now() THEN
        RETURN jsonb_build_object('success', false, 'message', 'Compte verrouillé', 'locked_until', v_user.locked_until);
    END IF;

    IF v_user.pin_hash = p_pin_hash THEN
        UPDATE public.users SET failed_attempts = 0, locked_until = NULL WHERE id = v_user.id;
        RETURN jsonb_build_object('success', true);
    ELSE
        v_new_attempts := COALESCE(v_user.failed_attempts, 0) + 1;
        IF v_new_attempts >= 5 THEN
            v_lock_time := now() + interval '5 minutes';
        END IF;
        
        UPDATE public.users SET failed_attempts = v_new_attempts, locked_until = v_lock_time WHERE id = v_user.id;
        
        RETURN jsonb_build_object('success', false, 'message', 'PIN incorrect', 'attempts', v_new_attempts, 'locked_until', v_lock_time);
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.verify_user_pin_v2(uuid, int, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_user_pin_v2(uuid, int, text) TO authenticated;

-- 23. Mise à jour des stocks par lot (Batch)
CREATE OR REPLACE FUNCTION public.batch_update_product_stock_delta(
    p_deltas jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_result jsonb := '[]'::jsonb;
    v_item jsonb;
BEGIN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_deltas) LOOP
        BEGIN
            PERFORM public.update_product_stock_delta(
                (v_item->>'shop_id')::uuid,
                (v_item->>'product_local_id')::int,
                (v_item->>'qty_delta')::int
            );
            
            v_result := v_result || jsonb_build_object(
                'product_local_id', (v_item->>'product_local_id')::int,
                'success', true
            );
        EXCEPTION WHEN OTHERS THEN
            v_result := v_result || jsonb_build_object(
                'product_local_id', (v_item->>'product_local_id')::int,
                'success', false,
                'message', SQLERRM
            );
        END;
    END LOOP;
    RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.batch_update_product_stock_delta(jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.batch_update_product_stock_delta(jsonb) TO authenticated;

-- 24. Remboursements par lot (Batch) avec retour détaillé
CREATE OR REPLACE FUNCTION public.batch_process_sale_refund(
    p_refunds jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_result jsonb := '[]'::jsonb;
    v_item jsonb;
    v_process_res json;
BEGIN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_refunds) LOOP
        -- Appel de la fonction unitaire existante
        v_process_res := public.process_sale_refund(
            (v_item->>'shop_id')::uuid,
            (v_item->>'terminal_id')::uuid,
            (v_item->>'local_id')::int,
            (v_item->>'user_id')::int
        );

        -- On construit le résultat en incluant l'ID de la file d'attente locale
        -- pour que le client sache quel élément a réussi ou échoué.
        v_result := v_result || jsonb_build_object(
            'local_id', (v_item->>'local_id')::int,
            'success', (v_process_res->>'success')::boolean,
            'message', v_process_res->>'message'
        );
    END LOOP;

    RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.batch_process_sale_refund(jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.batch_process_sale_refund(jsonb) TO authenticated;

-- 25. Fonction RPC pour la mise à jour des attributs produit avec détection de conflit
-- Cette fonction gère les attributs du produit SAUF stock_qty, qui est géré par les deltas.
DROP FUNCTION IF EXISTS public.upsert_product_attributes_with_conflict_check(jsonb);
CREATE OR REPLACE FUNCTION public.upsert_product_attributes_with_conflict_check(
    p_product_data jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_shop_id uuid := (p_product_data->>'shop_id')::uuid;
    v_local_id int := (p_product_data->>'local_id')::int;
    v_client_updated_at timestamptz := (p_product_data->>'updated_at')::timestamptz;
    v_server_updated_at timestamptz;
    v_product_id uuid;
BEGIN
    -- Récupérer la date updated_at actuelle sur le serveur pour ce produit
    SELECT updated_at, id INTO v_server_updated_at, v_product_id
    FROM public.products
    WHERE shop_id = v_shop_id AND local_id = v_local_id;

    -- Si le produit existe et que la version du serveur est plus récente que celle du client,
    -- cela signifie qu'une modification plus récente a déjà été appliquée.
    IF FOUND AND v_server_updated_at IS NOT NULL AND v_server_updated_at > v_client_updated_at THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Conflict: Server has a newer version of this product. Please refresh and try again.',
            'server_updated_at', v_server_updated_at,
            'client_updated_at', v_client_updated_at
        );
    END IF;

    -- Effectuer l'upsert, en EXCLUANT stock_qty (géré par des deltas séparés)
    INSERT INTO public.products (
        id, shop_id, local_id, name, price_ht, cost_price, preferred_supplier_id,
        is_active, updated_at, barcode, description, category_id, tax_rate, unit, image_path, expiry_date
    ) VALUES (
        COALESCE(v_product_id, uuid_generate_v4()), -- Utiliser l'ID existant ou en générer un nouveau
        v_shop_id,
        v_local_id,
        p_product_data->>'name',
        (p_product_data->>'price_ht')::double precision,
        (p_product_data->>'cost_price')::double precision,
        (p_product_data->>'preferred_supplier_id')::int,
        (p_product_data->>'is_active')::boolean,
        now(), -- Le serveur définit sa propre date updated_at
        p_product_data->>'barcode',
        p_product_data->>'description',
        (p_product_data->>'category_id')::int,
        (p_product_data->>'tax_rate')::double precision,
        p_product_data->>'unit',
        p_product_data->>'image_path',
        (p_product_data->>'expiry_date')::timestamptz
    )
    ON CONFLICT (shop_id, local_id) DO UPDATE SET
        name = EXCLUDED.name,
        price_ht = EXCLUDED.price_ht,
        cost_price = EXCLUDED.cost_price,
        preferred_supplier_id = EXCLUDED.preferred_supplier_id,
        is_active = EXCLUDED.is_active,
        updated_at = now(), -- Le serveur définit sa propre date updated_at
        barcode = EXCLUDED.barcode,
        description = EXCLUDED.description,
        category_id = EXCLUDED.category_id,
        tax_rate = EXCLUDED.tax_rate,
        unit = EXCLUDED.unit,
        image_path = EXCLUDED.image_path,
        expiry_date = EXCLUDED.expiry_date
    RETURNING id INTO v_product_id;

    RETURN jsonb_build_object('success', true, 'id', v_product_id);
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_product_attributes_with_conflict_check(jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_product_attributes_with_conflict_check(jsonb) TO authenticated;

-- 25. Table d'historique des erreurs pour le monitoring à distance
CREATE TABLE IF NOT EXISTS public.sync_error_logs (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    terminal_id uuid NOT NULL,
    entity_type text NOT NULL,
    entity_id int NOT NULL,
    error_message text,
    payload jsonb,
    created_at timestamptz DEFAULT now()
);

-- Index pour accélérer la recherche par magasin et par date
CREATE INDEX IF NOT EXISTS idx_sync_error_logs_shop_date ON public.sync_error_logs(shop_id, created_at DESC);

-- Sécurité RLS
ALTER TABLE public.sync_error_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authorized staff can view sync_error_logs" ON public.sync_error_logs;
CREATE POLICY "Authorized staff can view sync_error_logs" ON public.sync_error_logs
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.shops WHERE id = sync_error_logs.shop_id AND owner_id = auth.uid())
    OR public.check_is_shop_member(sync_error_logs.shop_id)
);

GRANT ALL ON TABLE public.sync_error_logs TO authenticated;

-- 26. Vue de monitoring des erreurs de synchro par terminal
-- Cette vue permet de voir en un coup d'œil quelles caisses ont des problèmes
CREATE OR REPLACE VIEW public.view_terminal_sync_monitoring WITH (security_invoker = true) AS
SELECT 
    l.shop_id,
    sh.name as shop_name,
    l.terminal_id,
    COALESCE(t.name, 'Caisse (ID: ' || substring(l.terminal_id::text from 1 for 8) || ')') as terminal_name,
    l.entity_type,
    COUNT(*) as total_errors,
    MAX(l.created_at) as last_error_at,
    -- Astuce Postgres : récupère le message le plus récent du groupe
    (ARRAY_AGG(l.error_message ORDER BY l.created_at DESC))[1] as last_error_message
FROM public.sync_error_logs l
JOIN public.shops sh ON l.shop_id = sh.id
LEFT JOIN public.terminals t ON l.terminal_id = t.id
GROUP BY l.shop_id, sh.name, l.terminal_id, t.name, l.entity_type
ORDER BY last_error_at DESC;

-- 27. Fonction de nettoyage automatique (Retention Policy)
-- Supprime les logs vieux de plus de 15 jours pour ne pas saturer le stockage
CREATE OR REPLACE FUNCTION public.purge_old_sync_error_logs()
RETURNS void LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    DELETE FROM public.sync_error_logs WHERE created_at < now() - interval '15 days';
END;
$$;

-- Sécurité : Empêcher l'exécution publique pour la maintenance
REVOKE ALL ON FUNCTION public.purge_old_sync_error_logs() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.purge_old_sync_error_logs() TO postgres, service_role;

-- 28. Configuration du Cron Job pour le nettoyage automatique
-- Note : L'extension pg_cron est activée par défaut sur les projets Supabase récents.
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- On s'assure que le job n'existe pas déjà pour éviter les doublons lors des ré-exécutions du script
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'purge-sync-logs-nightly';

-- Planification du job : tous les jours à minuit (00:00)
-- Syntaxe cron : 'minute heure jour_mois mois jour_semaine'
SELECT cron.schedule(
    'purge-sync-logs-nightly',
    '0 0 * * *',
    'SELECT public.purge_old_sync_error_logs();'
);

-- Donner les permissions au rôle postgres (utilisé par pg_cron)
GRANT USAGE ON SCHEMA public TO postgres;
GRANT EXECUTE ON FUNCTION public.purge_old_sync_error_logs() TO postgres;

-- Forcer le rafraîchissement du cache de Supabase (PostgREST)
NOTIFY pgrst, 'reload schema';

-- 22. Fonction pour vérifier la consommation du quota (Usage)
-- On supprime toute version existante pour éviter les conflits de signature
DROP FUNCTION IF EXISTS public.get_project_usage();
CREATE OR REPLACE FUNCTION get_project_usage()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog, storage, pg_temp
AS $$
DECLARE
    db_size_bytes bigint;
    storage_size_bytes bigint;
BEGIN
    -- Taille de la base de données actuelle
    SELECT pg_database_size(current_database()) INTO db_size_bytes;

    -- Taille totale des objets dans le storage (via les métadonnées de Supabase)
    SELECT COALESCE(SUM((metadata->>'size')::bigint), 0)
    INTO storage_size_bytes
    FROM storage.objects;

    RETURN json_build_object(
        'db_size_bytes', db_size_bytes,
        'storage_size_bytes', storage_size_bytes,
        'db_limit_bytes', 524288000,      -- 500 MB (Limite Free Tier)
        'storage_limit_bytes', 1073741824  -- 1 GB (Limite Free Tier)
    );
END;
$$;

-- Accorder les droits d'exécution
REVOKE ALL ON FUNCTION public.get_project_usage() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_project_usage() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_project_usage() TO service_role;

-- 20. OPTIMISATION REALTIME
-- Définit l'identité de réplication sur FULL pour permettre des filtres complexes
ALTER TABLE public.sales REPLICA IDENTITY FULL;
ALTER TABLE public.products REPLICA IDENTITY FULL;
ALTER TABLE public.stock_transfers REPLICA IDENTITY FULL;
ALTER TABLE public.customers REPLICA IDENTITY FULL;
ALTER TABLE public.categories REPLICA IDENTITY FULL;

-- 21. AUTOMATISATION DU TIMESTAMP updated_at
-- Cette fonction met à jour la colonne updated_at automatiquement à chaque modification
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Sécurité : Empêcher l'exécution publique de la fonction de trigger
REVOKE ALL ON FUNCTION public.update_updated_at_column() FROM PUBLIC, anon;

-- Appliquer le trigger à la table stock_transfers
DROP TRIGGER IF EXISTS update_stock_transfers_updated_at ON public.stock_transfers;
CREATE TRIGGER update_stock_transfers_updated_at
    BEFORE UPDATE ON public.stock_transfers
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Appliquer le trigger à la table products
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Appliquer le trigger à la table customers
DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON public.customers
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Appliquer le trigger à la table categories
DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Appliquer le trigger à la table suppliers
DROP TRIGGER IF EXISTS update_suppliers_updated_at ON public.suppliers;
CREATE TRIGGER update_suppliers_updated_at
    BEFORE UPDATE ON public.suppliers
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Appliquer le trigger à la table users
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- ============================================================
--  GESTION ET RAPPORTS PAR NOM DE TERMINAL
-- ============================================================

-- 1. Table pour stocker le nom de chaque terminal/caisse
CREATE TABLE IF NOT EXISTS public.terminals (
    id uuid PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    name text NOT NULL,
    last_sync_ip text,
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.terminals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Owners can manage terminals" ON public.terminals;
CREATE POLICY "Owners can manage terminals" ON public.terminals FOR ALL USING (EXISTS (SELECT 1 FROM public.shops WHERE id = terminals.shop_id AND owner_id = auth.uid()));
GRANT ALL ON TABLE public.terminals TO authenticated;

-- Appliquer le trigger updated_at à la table terminals pour la cohérence
DROP TRIGGER IF EXISTS update_terminals_updated_at ON public.terminals;
CREATE TRIGGER update_terminals_updated_at
    BEFORE UPDATE ON public.terminals
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- 1c. Table pour les alertes de sécurité (Elite Security)
CREATE TABLE IF NOT EXISTS public.security_alerts (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    terminal_id uuid NOT NULL REFERENCES public.terminals(id) ON DELETE CASCADE,
    alert_type text NOT NULL, -- 'ip_change_detected'
    severity text DEFAULT 'warning', -- 'info', 'warning', 'critical'
    message text,
    old_value text,
    new_value text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE public.security_alerts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Owners can view alerts for their shops" ON public.security_alerts;
CREATE POLICY "Owners can view alerts for their shops" ON public.security_alerts 
FOR SELECT USING (EXISTS (SELECT 1 FROM public.shops WHERE id = security_alerts.shop_id AND owner_id = auth.uid()));
GRANT SELECT ON TABLE public.security_alerts TO authenticated;

-- 1b. Fonction et Trigger pour capturer l'IP automatiquement
CREATE OR REPLACE FUNCTION public.fn_capture_terminal_ip()
RETURNS TRIGGER AS $$
DECLARE
    v_new_ip text;
    v_old_ip text;
BEGIN
    -- Dans Supabase, les headers sont accessibles via current_setting
    -- x-forwarded-for contient l'IP réelle du client
    v_new_ip := COALESCE(
        current_setting('request.headers', true)::json->>'x-forwarded-for',
        'unknown'
    );

    -- Récupérer l'ancienne IP pour la comparaison
    v_old_ip := OLD.last_sync_ip;

    -- ALERTE : Détection de changement d'IP suspect (uniquement lors d'une mise à jour)
    IF (TG_OP = 'UPDATE' AND v_old_ip IS NOT NULL AND v_old_ip <> v_new_ip AND v_new_ip <> 'unknown' AND v_old_ip <> 'unknown') THEN
        INSERT INTO public.security_alerts (shop_id, terminal_id, alert_type, message, old_value, new_value)
        VALUES (NEW.shop_id, NEW.id, 'ip_change_detected', 
                'Changement d''IP détecté pour la caisse "' || NEW.name || '". Possible accès distant suspect.', v_old_ip, v_new_ip);
    END IF;

    NEW.last_sync_ip := v_new_ip;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Correction: Ajouter SET search_path pour la sécurité
ALTER FUNCTION public.fn_capture_terminal_ip() SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS tr_capture_terminal_ip ON public.terminals;
CREATE TRIGGER tr_capture_terminal_ip
    BEFORE INSERT OR UPDATE ON public.terminals
    FOR EACH ROW EXECUTE FUNCTION public.fn_capture_terminal_ip();

-- 2. Vue pour lister les ventes par nom de terminal
CREATE OR REPLACE VIEW public.view_sales_by_terminal_name WITH (security_invoker = true) AS
SELECT 
    s.shop_id,
    COALESCE(t.name, 'Caisse (ID: ' || substring(s.terminal_id::text from 1 for 5) || '...)') as terminal_display_name,
    s.terminal_id,
    COUNT(s.id) as sales_count,
    SUM(s.total_ttc) as revenue_ttc,
    SUM(s.total_ht - s.discount_amount) as revenue_net,
    AVG(s.total_ttc) as avg_basket
FROM public.sales s
LEFT JOIN public.terminals t ON s.terminal_id = t.id
WHERE s.status = 'completed'
-- Correction: Ajouter la clause RLS pour la vue
AND EXISTS (SELECT 1 FROM public.shops WHERE id = s.shop_id AND owner_id = auth.uid())
OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = s.shop_id AND supabase_id = auth.uid())

GROUP BY s.shop_id, t.name, s.terminal_id;

-- Politiques pour les nouvelles tables
-- On utilise une approche "Authorized Staff" (Propriétaire ou employé du magasin)
-- pour permettre la synchronisation depuis n'importe quel terminal autorisé.

-- Expenses
DROP POLICY IF EXISTS "Authorized staff can manage expenses" ON public.expenses;
DROP POLICY IF EXISTS "Owners can manage expenses" ON public.expenses;
CREATE POLICY "Authorized staff can manage expenses" ON public.expenses 
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.shops WHERE id = expenses.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = expenses.shop_id AND supabase_id = auth.uid())
)
WITH CHECK (
    EXISTS (SELECT 1 FROM public.shops WHERE id = expenses.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = expenses.shop_id AND supabase_id = auth.uid())
);

-- Purchase Orders
DROP POLICY IF EXISTS "Authorized staff can manage purchase_orders" ON public.purchase_orders;
DROP POLICY IF EXISTS "Owners can manage purchase_orders" ON public.purchase_orders;
CREATE POLICY "Authorized staff can manage purchase_orders" ON public.purchase_orders 
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.shops WHERE id = purchase_orders.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = purchase_orders.shop_id AND supabase_id = auth.uid())
)
WITH CHECK (
    EXISTS (SELECT 1 FROM public.shops WHERE id = purchase_orders.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = purchase_orders.shop_id AND supabase_id = auth.uid())
);

-- Purchase Order Items
DROP POLICY IF EXISTS "Authorized staff can manage purchase_order_items" ON public.purchase_order_items;
DROP POLICY IF EXISTS "Owners can manage purchase_order_items" ON public.purchase_order_items;
CREATE POLICY "Authorized staff can manage purchase_order_items" ON public.purchase_order_items 
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.shops WHERE id = purchase_order_items.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = purchase_order_items.shop_id AND supabase_id = auth.uid())
)
WITH CHECK (
    EXISTS (SELECT 1 FROM public.shops WHERE id = purchase_order_items.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = purchase_order_items.shop_id AND supabase_id = auth.uid())
);

-- Suppliers
DROP POLICY IF EXISTS "Authorized staff can manage suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Owners can manage suppliers" ON public.suppliers;
CREATE POLICY "Authorized staff can manage suppliers" ON public.suppliers 
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.shops WHERE id = suppliers.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = suppliers.shop_id AND supabase_id = auth.uid())
)
WITH CHECK (
    EXISTS (SELECT 1 FROM public.shops WHERE id = suppliers.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = suppliers.shop_id AND supabase_id = auth.uid())
);

-- Product Variants
DROP POLICY IF EXISTS "Authorized staff can manage product_variants" ON public.product_variants;
DROP POLICY IF EXISTS "Owners can manage product_variants" ON public.product_variants;
CREATE POLICY "Authorized staff can manage product_variants" ON public.product_variants 
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.shops WHERE id = product_variants.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = product_variants.shop_id AND supabase_id = auth.uid())
)
WITH CHECK (
    EXISTS (SELECT 1 FROM public.shops WHERE id = product_variants.shop_id AND owner_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.users WHERE shop_id = product_variants.shop_id AND supabase_id = auth.uid())
);

-- ============================================================
--  VUE D'AUDIT CONSOLIDÉE POUR L'OWNER
-- ============================================================

CREATE OR REPLACE VIEW public.view_owner_audit_logs WITH (security_invoker = true) AS
SELECT 
    l.id as log_uuid,
    l.shop_id,
    sh.name as shop_name,
    l.created_at as timestamp,
    u.name as actor_name,
    l.action,
    l.target_entity_type,
    l.target_entity_id,
    l.details,
    COALESCE(tm.name, 'Caisse ' || substring(l.terminal_id::text from 1 for 8)) as terminal_name
FROM public.audit_logs l
JOIN public.shops sh ON l.shop_id = sh.id
LEFT JOIN public.users u ON l.shop_id = u.shop_id AND l.actor_id = u.local_id
LEFT JOIN public.terminals tm ON l.terminal_id = tm.id
ORDER BY l.created_at DESC;

-- Accorder les droits de lecture
GRANT SELECT ON public.view_owner_audit_logs TO authenticated;

-- ============================================================
--  MAINTENANCE : NETTOYAGE DES TERMINAUX INACTIFS
-- ============================================================

-- Fonction RPC pour supprimer les terminaux sans activité depuis > 6 mois
CREATE OR REPLACE FUNCTION public.cleanup_inactive_terminals()
RETURNS int 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public, pg_temp
AS $$
DECLARE
    v_deleted_count int;
BEGIN
    -- Suppression des terminaux dont la dernière synchronisation (updated_at) 
    -- est antérieure à 6 mois.
    DELETE FROM public.terminals 
    WHERE updated_at < now() - interval '6 months';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$;

-- Correction: Révoquer l'exécution de PUBLIC et authenticated pour les fonctions de maintenance
REVOKE EXECUTE ON FUNCTION public.cleanup_inactive_terminals() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.cleanup_inactive_terminals() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_inactive_terminals() TO service_role;

-- Automatisation : Planification d'un job mensuel (le 1er du mois à 03:00 du matin)
SELECT cron.schedule(
    'cleanup-inactive-terminals-monthly',
    '0 3 1 * *',
    'SELECT public.cleanup_inactive_terminals();'
);

-- Correction: Révoquer l'exécution de PUBLIC et authenticated pour la fonction de trigger
REVOKE EXECUTE ON FUNCTION public.fn_capture_terminal_ip() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.fn_capture_terminal_ip() FROM authenticated;

-- Forcer la mise à jour du cache de l'API pour voir les nouvelles fonctions (get_project_usage)
NOTIFY pgrst, 'reload schema';