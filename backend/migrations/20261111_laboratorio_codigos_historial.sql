-- ONLY EYES 360: trazabilidad de taller. Aplicar únicamente tras verificar
-- current_database() = 'onlyeyes360_test' en desarrollo.
ALTER TABLE pedidos_lentes ADD COLUMN IF NOT EXISTS codigo VARCHAR(32);
ALTER TABLE reparaciones ADD COLUMN IF NOT EXISTS codigo VARCHAR(32);

UPDATE pedidos_lentes
SET codigo = 'OE-PED-' || LPAD(id::text, 6, '0')
WHERE codigo IS NULL;
UPDATE reparaciones
SET codigo = 'OE-REP-' || LPAD(id::text, 6, '0')
WHERE codigo IS NULL;

ALTER TABLE pedidos_lentes ALTER COLUMN codigo SET NOT NULL;
ALTER TABLE reparaciones ALTER COLUMN codigo SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_pedidos_lentes_codigo ON pedidos_lentes(codigo);
CREATE UNIQUE INDEX IF NOT EXISTS ux_reparaciones_codigo ON reparaciones(codigo);

CREATE TABLE IF NOT EXISTS historial_estados_taller (
    id BIGSERIAL PRIMARY KEY,
    tipo_trabajo VARCHAR(20) NOT NULL CHECK (tipo_trabajo IN ('pedido', 'reparacion')),
    trabajo_id BIGINT NOT NULL,
    estado VARCHAR(30) NOT NULL,
    usuario_id BIGINT REFERENCES usuarios(id),
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_historial_estados_taller_trabajo
    ON historial_estados_taller(tipo_trabajo, trabajo_id, creado_en);
