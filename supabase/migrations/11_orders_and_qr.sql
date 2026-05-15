-- ── Orders ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_session_id TEXT,
  user_id           UUID        REFERENCES auth.users(id),
  customer_email    TEXT        NOT NULL,
  customer_name     TEXT        NOT NULL DEFAULT '',
  customer_phone    TEXT        NOT NULL DEFAULT '',
  notes             TEXT        NOT NULL DEFAULT '',
  status            TEXT        NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','paid','cancelled','refunded')),
  total_amount      NUMERIC(10,2) NOT NULL DEFAULT 0,
  currency          TEXT        NOT NULL DEFAULT 'mxn',
  items             JSONB,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Order items (one row per item, each gets a QR code) ────────────────────────
CREATE TABLE IF NOT EXISTS public.order_items (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      UUID        NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id    TEXT,
  product_name  TEXT        NOT NULL,
  product_type  TEXT        NOT NULL,
  unit_price    NUMERIC(10,2) NOT NULL DEFAULT 0,
  quantity      INT         NOT NULL DEFAULT 1,
  currency      TEXT        NOT NULL DEFAULT 'mxn',
  category_key  TEXT,
  image_url     TEXT,
  redeemed_at   TIMESTAMPTZ,
  redeemed_by   UUID        REFERENCES public.profiles(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON public.order_items(order_id);

-- ── RLS ────────────────────────────────────────────────────────────────────────
ALTER TABLE public.orders     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Clients see their own orders
CREATE POLICY "users_see_own_orders" ON public.orders FOR SELECT
  USING (auth.uid() = user_id OR customer_email = auth.email());

-- Staff see all orders
CREATE POLICY "staff_see_all_orders" ON public.orders FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin','receptionist')
  ));

-- Service role can insert/update
CREATE POLICY "service_manage_orders" ON public.orders FOR ALL
  USING (auth.role() = 'service_role');

-- Clients see their own items
CREATE POLICY "users_see_own_items" ON public.order_items FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.orders
    WHERE id = order_id
      AND (user_id = auth.uid() OR customer_email = auth.email())
  ));

-- Staff see all items
CREATE POLICY "staff_see_all_items" ON public.order_items FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin','receptionist')
  ));

-- Staff can redeem items
CREATE POLICY "staff_redeem_items" ON public.order_items FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin','receptionist')
  ));

-- Service role full access to items
CREATE POLICY "service_manage_items" ON public.order_items FOR ALL
  USING (auth.role() = 'service_role');

-- updated_at trigger for orders
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
