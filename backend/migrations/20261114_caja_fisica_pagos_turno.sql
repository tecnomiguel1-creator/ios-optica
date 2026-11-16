-- ONLY EYES 360: caja física, trazabilidad de cobros y exclusión de turnos.
-- Esta migración está deliberadamente bloqueada fuera de onlyeyes360_test.
DO $$
BEGIN
  IF current_database() <> 'onlyeyes360_test' THEN
    RAISE EXCEPTION 'Esta migración sólo puede ejecutarse en onlyeyes360_test';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS cajas_fisicas (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  activa BOOLEAN NOT NULL DEFAULT true,
  creada_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO cajas_fisicas(id,nombre,activa)
VALUES (1,'Caja principal',true)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE turnos_caja ADD COLUMN IF NOT EXISTS caja_id BIGINT;
UPDATE turnos_caja SET caja_id=1 WHERE caja_id IS NULL;
ALTER TABLE turnos_caja ALTER COLUMN caja_id SET NOT NULL;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_turnos_caja_caja_fisica') THEN
    ALTER TABLE turnos_caja ADD CONSTRAINT fk_turnos_caja_caja_fisica
      FOREIGN KEY (caja_id) REFERENCES cajas_fisicas(id);
  END IF;
END $$;

-- Los pagos ya existentes permanecen válidos y sin turno asociado.
ALTER TABLE pagos_ventas ADD COLUMN IF NOT EXISTS turno_caja_id BIGINT;
ALTER TABLE pagos_ventas ADD COLUMN IF NOT EXISTS usuario_id BIGINT;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_pagos_ventas_turno_caja') THEN
    ALTER TABLE pagos_ventas ADD CONSTRAINT fk_pagos_ventas_turno_caja
      FOREIGN KEY (turno_caja_id) REFERENCES turnos_caja(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_pagos_ventas_usuario') THEN
    ALTER TABLE pagos_ventas ADD CONSTRAINT fk_pagos_ventas_usuario
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS ix_pagos_ventas_turno_caja ON pagos_ventas(turno_caja_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_turnos_caja_abierto_fisica
  ON turnos_caja(caja_id) WHERE estado='abierta';
