-- Conserva el efectivo entregado y la devuelta de cobros nuevos.
DO $$
BEGIN
  IF current_database() <> 'onlyeyes360_test' THEN
    RAISE EXCEPTION 'Esta migración sólo puede ejecutarse en onlyeyes360_test';
  END IF;
END $$;
ALTER TABLE pagos_ventas ADD COLUMN IF NOT EXISTS monto_recibido NUMERIC;
ALTER TABLE pagos_ventas ADD COLUMN IF NOT EXISTS cambio NUMERIC;
