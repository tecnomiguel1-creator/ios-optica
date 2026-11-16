-- Datos comerciales que se imprimen en comprobantes. Sólo entorno de prueba.
DO $$
BEGIN
  IF current_database() <> 'onlyeyes360_test' THEN
    RAISE EXCEPTION 'Esta migración sólo puede ejecutarse en onlyeyes360_test';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS datos_negocio (
  id SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id=1),
  nombre_comercial VARCHAR(150) NOT NULL DEFAULT 'Óptica ONLY EYES S.R.L.',
  eslogan VARCHAR(200),
  rnc VARCHAR(30),
  direccion TEXT,
  telefono VARCHAR(40),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO datos_negocio(id,nombre_comercial,eslogan)
VALUES (1,'Óptica ONLY EYES S.R.L.','Un compromiso con tu visión')
ON CONFLICT (id) DO NOTHING;
