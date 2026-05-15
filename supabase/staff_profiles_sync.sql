-- ─────────────────────────────────────────────────────────────────────────────
-- staff_profiles_sync.sql
-- Keeps the `staff` table (web app) in sync with `profiles` (mobile app).
-- Safe to re-run: uses CREATE OR REPLACE + ON CONFLICT.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Trigger function: mirrors therapist/staff profile changes to `staff` ──────
CREATE OR REPLACE FUNCTION sync_profile_to_staff()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role IN ('therapist', 'receptionist', 'reception', 'admin') THEN
    INSERT INTO staff (id, full_name, email, phone, role, active)
    VALUES (
      NEW.id,
      NEW.full_name,
      COALESCE(NEW.email, ''),
      COALESCE(NEW.phone, ''),
      NEW.role,
      COALESCE(NEW.is_active, true)
    )
    ON CONFLICT (id) DO UPDATE SET
      full_name = EXCLUDED.full_name,
      email     = EXCLUDED.email,
      phone     = EXCLUDED.phone,
      role      = EXCLUDED.role,
      active    = EXCLUDED.active;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Attach trigger to profiles table ─────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_sync_profile_to_staff ON profiles;
CREATE TRIGGER trg_sync_profile_to_staff
  AFTER INSERT OR UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION sync_profile_to_staff();

-- 3. Backfill: sync all existing profiles into staff ──────────────────────────
INSERT INTO staff (id, full_name, email, phone, role, active)
SELECT
  id,
  full_name,
  COALESCE(email, ''),
  COALESCE(phone, ''),
  role,
  COALESCE(is_active, true)
FROM profiles
WHERE role IN ('therapist', 'receptionist', 'reception', 'admin')
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email     = EXCLUDED.email,
  phone     = EXCLUDED.phone,
  role      = EXCLUDED.role,
  active    = EXCLUDED.active;
