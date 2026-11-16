-- Solo desarrollo: verificar current_database() = 'onlyeyes360_test' antes de aplicar.
CREATE TABLE IF NOT EXISTS consentimientos_notificacion (
    cliente_id BIGINT PRIMARY KEY REFERENCES clientes(id),
    whatsapp_habilitado BOOLEAN NOT NULL DEFAULT false,
    otorgado_en TIMESTAMPTZ,
    revocado_en TIMESTAMPTZ,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notificaciones_cliente (
    id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL REFERENCES clientes(id),
    canal VARCHAR(20) NOT NULL DEFAULT 'whatsapp',
    tipo VARCHAR(40) NOT NULL,
    trabajo_tipo VARCHAR(20),
    trabajo_id BIGINT,
    cita_id BIGINT REFERENCES citas(id),
    plantilla VARCHAR(80) NOT NULL,
    deduplicacion_clave VARCHAR(160) NOT NULL UNIQUE,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    proveedor VARCHAR(30) NOT NULL DEFAULT 'simulado',
    proveedor_id VARCHAR(100),
    intentos INTEGER NOT NULL DEFAULT 0,
    programado_para TIMESTAMPTZ NOT NULL DEFAULT now(),
    enviado_en TIMESTAMPTZ,
    error TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_notificaciones_estado_programacion
    ON notificaciones_cliente(estado, programado_para);
