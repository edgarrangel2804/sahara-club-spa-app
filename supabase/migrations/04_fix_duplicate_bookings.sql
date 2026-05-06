-- ============================================================
-- 1. Eliminar citas duplicadas — conserva la más antigua
--    (misma combinación de client_id + booking_date + booking_time)
-- ============================================================
DELETE FROM public.bookings
WHERE id IN (
  SELECT id FROM (
    SELECT
      id,
      ROW_NUMBER() OVER (
        PARTITION BY client_id, booking_date, booking_time
        ORDER BY created_at ASC   -- conserva la primera (más antigua)
      ) AS rn
    FROM public.bookings
  ) ranked
  WHERE rn > 1
);

-- ============================================================
-- 2. Restricción única para evitar que vuelva a ocurrir:
--    Un cliente no puede tener dos citas el mismo día y hora.
-- ============================================================
ALTER TABLE public.bookings
  ADD CONSTRAINT bookings_client_date_time_unique
  UNIQUE (client_id, booking_date, booking_time);

-- ============================================================
-- 3. Restricción única: una terapeuta no puede tener dos citas
--    al mismo tiempo (cuando therapist_id no es NULL)
-- ============================================================
CREATE UNIQUE INDEX IF NOT EXISTS bookings_therapist_date_time_unique
  ON public.bookings (therapist_id, booking_date, booking_time)
  WHERE therapist_id IS NOT NULL;
