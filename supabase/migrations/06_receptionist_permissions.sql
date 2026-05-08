-- Add permissions column to profiles for receptionist access control
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS permissions TEXT[]
    DEFAULT ARRAY['ver_caja', 'ver_gastos', 'ver_clientes', 'cancelar_citas']::TEXT[];

-- Backfill existing receptionist profiles with full permissions
UPDATE profiles
SET permissions = ARRAY['ver_caja', 'ver_gastos', 'ver_clientes', 'cancelar_citas']::TEXT[]
WHERE permissions IS NULL;
