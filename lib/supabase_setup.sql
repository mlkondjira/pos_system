-- Code SQL pour corriger/créer la table shops sur Supabase
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Activer l'extension UUID si nécessaire
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Créer la table 'shops' si elle n'existe pas (avec la bonne orthographe 'address')
CREATE TABLE IF NOT EXISTS public.shops (
    id text NOT NULL DEFAULT uuid_generate_v4()::text PRIMARY KEY,
    name text NOT NULL,
    address text,
    owner_id text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- 3. Création des autres tables nécessaires pour la synchronisation
-- Ces tables doivent exister pour que les politiques de sécurité (RLS) puissent s'appliquer.

CREATE TABLE IF NOT EXISTS public.sales (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id text NOT NULL,
    local_id int NOT NULL,
    total_ttc double precision DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    synced_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.products (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id text NOT NULL,
    local_id int NOT NULL,
    name text,
    price_ht double precision,
    stock_qty double precision DEFAULT 0,
    updated_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.sale_items (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id text NOT NULL,
    local_id int NOT NULL,
    product_name text,
    quantity double precision,
    total_ttc double precision DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.customers (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id text NOT NULL,
    local_id int NOT NULL,
    name text,
    phone text,
    email text,
    UNIQUE(shop_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.stock_movements (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id text NOT NULL,
    local_id int NOT NULL,
    quantity_change double precision,
    reason text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id)
);

CREATE TABLE IF NOT EXISTS public.inventory_sessions (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    shop_id text NOT NULL,
    local_id int NOT NULL,
    status text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, local_id)
);

-- 4. Activer la sécurité RLS sur TOUTES les tables (Sécurité par défaut)
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_sessions ENABLE ROW LEVEL SECURITY;

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
FOR ALL USING (auth.uid()::text = owner_id)
WITH CHECK (auth.uid()::text = owner_id);

-- 6. Politiques pour la table 'sales'
DROP POLICY IF EXISTS "Owners can manage sales from their own shops" ON public.sales;
CREATE POLICY "Owners can manage sales from their own shops" ON public.sales FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = sales.shop_id::text AND shops.owner_id = auth.uid()::text) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = sales.shop_id::text AND shops.owner_id = auth.uid()::text) );

-- 7. Politiques pour les autres tables (exemple avec 'products')
DROP POLICY IF EXISTS "Owners can manage products in their own shops" ON public.products;
CREATE POLICY "Owners can manage products in their own shops" ON public.products FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = products.shop_id::text AND shops.owner_id = auth.uid()::text) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = products.shop_id::text AND shops.owner_id = auth.uid()::text) );

-- 8. Politiques pour 'sale_items' (Détails des ventes)
DROP POLICY IF EXISTS "Owners can manage sale_items" ON public.sale_items;
CREATE POLICY "Owners can manage sale_items" ON public.sale_items FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = sale_items.shop_id::text AND shops.owner_id = auth.uid()::text) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = sale_items.shop_id::text AND shops.owner_id = auth.uid()::text) );

-- 9. Politiques pour 'customers' (Clients)
DROP POLICY IF EXISTS "Owners can manage customers" ON public.customers;
CREATE POLICY "Owners can manage customers" ON public.customers FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = customers.shop_id::text AND shops.owner_id = auth.uid()::text) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = customers.shop_id::text AND shops.owner_id = auth.uid()::text) );

-- 10. Politiques pour 'stock_movements' (Historique des stocks)
DROP POLICY IF EXISTS "Owners can manage stock_movements" ON public.stock_movements;
CREATE POLICY "Owners can manage stock_movements" ON public.stock_movements FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = stock_movements.shop_id::text AND shops.owner_id = auth.uid()::text) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = stock_movements.shop_id::text AND shops.owner_id = auth.uid()::text) );

-- 11. Politiques pour 'inventory_sessions' (Inventaires)
DROP POLICY IF EXISTS "Owners can manage inventory_sessions" ON public.inventory_sessions;
CREATE POLICY "Owners can manage inventory_sessions" ON public.inventory_sessions FOR ALL USING ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = inventory_sessions.shop_id::text AND shops.owner_id = auth.uid()::text) ) WITH CHECK ( EXISTS (SELECT 1 FROM public.shops WHERE shops.id = inventory_sessions.shop_id::text AND shops.owner_id = auth.uid()::text) );

-- 12. Ajouter la colonne total_ttc à sale_items
-- Nécessaire pour calculer le chiffre d'affaires par produit
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS total_ttc double precision DEFAULT 0;

-- 13. Ajouter la colonne created_at à sale_items
-- Nécessaire pour les rapports de ventes par période (Top produits)
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

-- 14. Fonction RPC pour le Dashboard (Calculs côté serveur)
-- Cette fonction agrège les données et renvoie un JSON léger
CREATE OR REPLACE FUNCTION get_dashboard_stats(
    p_shop_id text,
    p_start_date timestamptz
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result json;
    v_total_revenue double precision;
    v_total_sales int;
    v_daily_stats json;
    v_top_products json;
BEGIN
    -- 1. Totaux globaux sur la période
    SELECT COALESCE(SUM(total_ttc), 0), COUNT(*)
    INTO v_total_revenue, v_total_sales
    FROM public.sales
    WHERE shop_id = p_shop_id AND created_at >= p_start_date;

    -- 2. Stats journalières (Graphique)
    SELECT json_agg(t) INTO v_daily_stats FROM (
        SELECT date_trunc('day', created_at) as day, SUM(total_ttc) as amount
        FROM public.sales
        WHERE shop_id = p_shop_id AND created_at >= p_start_date
        GROUP BY 1 ORDER BY 1
    ) t;

    -- 3. Top Produits (Quantity)
    SELECT json_agg(t) INTO v_top_products FROM (
        SELECT product_name, SUM(quantity) as qty
        FROM public.sale_items
        WHERE shop_id = p_shop_id AND created_at >= p_start_date
        GROUP BY 1 ORDER BY 2 DESC LIMIT 5
    ) t;

    -- Construction de l'objet JSON final
    RETURN json_build_object(
        'total_revenue', v_total_revenue,
        'total_sales', v_total_sales,
        'daily_stats', COALESCE(v_daily_stats, '[]'::json),
        'top_products', COALESCE(v_top_products, '[]'::json)
    );
END;
$$;