-- Add commission_pct to therapist profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS commission_pct numeric(5,2) DEFAULT 20.0;

-- Add RLS policy so admins can view ALL services (including inactive)
DROP POLICY IF EXISTS "Admins can view all services" ON public.services;
CREATE POLICY "Admins can view all services"
  ON public.services FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
