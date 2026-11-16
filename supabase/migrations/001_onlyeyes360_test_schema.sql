-- ONLY EYES 360 — esquema remoto para Supabase.
-- Origen: onlyeyes360_test (solo estructura; no contiene datos, usuarios ni contraseñas).
-- Ejecutar una sola vez en Supabase SQL Editor con el proyecto correcto abierto.
-- FastAPI sigue siendo la única capa autorizada para ventas, pagos, Caja e inventario.

--
-- PostgreSQL database dump
--


-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6


--
-- Name: SCHEMA "public"; Type: COMMENT; Schema: -; Owner: -
--





--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."auditoria" (
    "id" bigint NOT NULL,
    "usuario_id" bigint,
    "accion" character varying(100) NOT NULL,
    "modulo" character varying(100) NOT NULL,
    "registro_id" bigint,
    "datos_anteriores" "jsonb",
    "datos_nuevos" "jsonb",
    "descripcion" "text",
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."auditoria" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."auditoria_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auditoria_operaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."auditoria_operaciones" (
    "id" bigint NOT NULL,
    "usuario_id" bigint,
    "accion" character varying(100) NOT NULL,
    "entidad" character varying(100) NOT NULL,
    "entidad_id" bigint,
    "datos" "jsonb",
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: auditoria_operaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."auditoria_operaciones_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditoria_operaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."auditoria_operaciones_id_seq" OWNED BY "public"."auditoria_operaciones"."id";


--
-- Name: cajas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."cajas" (
    "id" bigint NOT NULL,
    "nombre" character varying(100) NOT NULL,
    "activa" boolean DEFAULT true NOT NULL
);


--
-- Name: cajas_fisicas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."cajas_fisicas" (
    "id" bigint NOT NULL,
    "nombre" character varying(100) NOT NULL,
    "activa" boolean DEFAULT true NOT NULL,
    "creada_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: cajas_fisicas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."cajas_fisicas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cajas_fisicas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."cajas_fisicas_id_seq" OWNED BY "public"."cajas_fisicas"."id";


--
-- Name: cajas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."cajas" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."cajas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: citas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."citas" (
    "id" bigint NOT NULL,
    "paciente_id" bigint NOT NULL,
    "usuario_id" bigint,
    "fecha_hora" timestamp with time zone NOT NULL,
    "motivo" character varying(200) NOT NULL,
    "estado" character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    "profesional" character varying(150),
    "observaciones" "text",
    "fecha_registro" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "citas_estado_check" CHECK ((("estado")::"text" = ANY (ARRAY[('pendiente'::character varying)::"text", ('confirmada'::character varying)::"text", ('completada'::character varying)::"text", ('cancelada'::character varying)::"text", ('no_asistio'::character varying)::"text"])))
);


--
-- Name: citas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."citas" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."citas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: claves_idempotencia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."claves_idempotencia" (
    "id" bigint NOT NULL,
    "operacion" character varying(100) NOT NULL,
    "clave" character varying(128) NOT NULL,
    "usuario_id" bigint NOT NULL,
    "solicitud_hash" character varying(64) NOT NULL,
    "respuesta" "jsonb",
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completado_en" timestamp with time zone
);


--
-- Name: claves_idempotencia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."claves_idempotencia_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claves_idempotencia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."claves_idempotencia_id_seq" OWNED BY "public"."claves_idempotencia"."id";


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."clientes" (
    "id" bigint NOT NULL,
    "nombres" character varying(100) NOT NULL,
    "apellidos" character varying(100),
    "telefono" character varying(30),
    "correo" character varying(150),
    "direccion" "text",
    "fecha_registro" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: clientes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."clientes" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."clientes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: compras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."compras" (
    "id" bigint NOT NULL,
    "proveedor_id" bigint NOT NULL,
    "numero_factura" character varying(100),
    "fecha_compra" "date" DEFAULT CURRENT_DATE NOT NULL,
    "subtotal" numeric(12,2) DEFAULT 0 NOT NULL,
    "impuestos" numeric(12,2) DEFAULT 0 NOT NULL,
    "total" numeric(12,2) DEFAULT 0 NOT NULL,
    "estado" character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    "observaciones" "text",
    "fecha_registro" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "compras_estado_check" CHECK ((("estado")::"text" = ANY (ARRAY[('pendiente'::character varying)::"text", ('recibida'::character varying)::"text", ('anulada'::character varying)::"text"]))),
    CONSTRAINT "compras_impuestos_check" CHECK (("impuestos" >= (0)::numeric)),
    CONSTRAINT "compras_subtotal_check" CHECK (("subtotal" >= (0)::numeric)),
    CONSTRAINT "compras_total_check" CHECK (("total" >= (0)::numeric))
);


--
-- Name: compras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."compras" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."compras_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: configuracion_empresa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."configuracion_empresa" (
    "id" bigint NOT NULL,
    "nombre" character varying(150) NOT NULL,
    "rnc" character varying(20),
    "telefono" character varying(30),
    "correo" character varying(150),
    "direccion" "text",
    "logo_ruta" "text",
    "moneda" character varying(10) DEFAULT 'DOP'::character varying NOT NULL,
    "fecha_actualizacion" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: configuracion_empresa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."configuracion_empresa" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."configuracion_empresa_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: configuracion_fiscal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."configuracion_fiscal" (
    "id" bigint NOT NULL,
    "rnc" character varying(20),
    "usa_ncf" boolean DEFAULT false NOT NULL,
    "usa_ecf" boolean DEFAULT false NOT NULL,
    "ambiente" character varying(20) DEFAULT 'pruebas'::character varying NOT NULL,
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: configuracion_fiscal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."configuracion_fiscal" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."configuracion_fiscal_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: configuracion_impresoras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."configuracion_impresoras" (
    "id" bigint NOT NULL,
    "nombre" character varying(150) NOT NULL,
    "tipo" character varying(30) NOT NULL,
    "nombre_sistema" character varying(200),
    "predeterminada" boolean DEFAULT false NOT NULL
);


--
-- Name: configuracion_impresoras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."configuracion_impresoras" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."configuracion_impresoras_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: configuracion_sistema; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."configuracion_sistema" (
    "clave" character varying(100) NOT NULL,
    "valor" "jsonb" NOT NULL,
    "descripcion" "text",
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: consentimientos_notificacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."consentimientos_notificacion" (
    "cliente_id" bigint NOT NULL,
    "whatsapp_habilitado" boolean DEFAULT false NOT NULL,
    "otorgado_en" timestamp with time zone,
    "revocado_en" timestamp with time zone,
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: datos_negocio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."datos_negocio" (
    "id" smallint DEFAULT 1 NOT NULL,
    "nombre_comercial" character varying(150) DEFAULT 'Óptica ONLY EYES S.R.L.'::character varying NOT NULL,
    "eslogan" character varying(200),
    "rnc" character varying(30),
    "direccion" "text",
    "telefono" character varying(40),
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "datos_negocio_id_check" CHECK (("id" = 1))
);


--
-- Name: detalle_compras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."detalle_compras" (
    "id" bigint NOT NULL,
    "compra_id" bigint NOT NULL,
    "producto_id" bigint NOT NULL,
    "cantidad" integer NOT NULL,
    "precio_unitario" numeric(12,2) NOT NULL,
    "subtotal" numeric(12,2) GENERATED ALWAYS AS ((("cantidad")::numeric * "precio_unitario")) STORED,
    CONSTRAINT "detalle_compras_cantidad_check" CHECK (("cantidad" > 0)),
    CONSTRAINT "detalle_compras_precio_unitario_check" CHECK (("precio_unitario" >= (0)::numeric))
);


--
-- Name: detalle_compras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."detalle_compras" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."detalle_compras_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: detalle_ventas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."detalle_ventas" (
    "id" bigint NOT NULL,
    "venta_id" bigint NOT NULL,
    "producto_id" bigint NOT NULL,
    "cantidad" integer NOT NULL,
    "precio_unitario" numeric(12,2) NOT NULL,
    "descuento" numeric(12,2) DEFAULT 0 NOT NULL,
    "subtotal" numeric(12,2) GENERATED ALWAYS AS (((("cantidad")::numeric * "precio_unitario") - "descuento")) STORED,
    CONSTRAINT "chk_descuento_valido" CHECK (("descuento" <= (("cantidad")::numeric * "precio_unitario"))),
    CONSTRAINT "detalle_ventas_cantidad_check" CHECK (("cantidad" > 0)),
    CONSTRAINT "detalle_ventas_descuento_check" CHECK (("descuento" >= (0)::numeric)),
    CONSTRAINT "detalle_ventas_precio_unitario_check" CHECK (("precio_unitario" >= (0)::numeric))
);


--
-- Name: detalle_ventas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."detalle_ventas" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."detalle_ventas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: documentos_electronicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."documentos_electronicos" (
    "id" bigint NOT NULL,
    "venta_id" bigint,
    "identificador" character varying(100),
    "tipo" character varying(30),
    "estado" character varying(30) DEFAULT 'pendiente'::character varying NOT NULL,
    "xml_ruta" "text",
    "respuesta_dgii" "jsonb",
    "fecha_creacion" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: documentos_electronicos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."documentos_electronicos" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."documentos_electronicos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: facturas_comerciales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."facturas_comerciales" (
    "id" bigint NOT NULL,
    "venta_id" bigint NOT NULL,
    "numero" character varying(40) NOT NULL,
    "emitida_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "emitida_por" bigint NOT NULL,
    "formato" character varying(12) DEFAULT 'comercial'::character varying NOT NULL,
    "nota_legal" character varying(300) DEFAULT 'Documento comercial no fiscal. No sustituye comprobantes fiscales ni obligaciones legales.'::character varying NOT NULL,
    "anulada_en" timestamp with time zone,
    "motivo_anulacion" character varying(500),
    CONSTRAINT "facturas_comerciales_formato_check" CHECK ((("formato")::"text" = 'comercial'::"text"))
);


--
-- Name: facturas_comerciales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."facturas_comerciales_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: facturas_comerciales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."facturas_comerciales_id_seq" OWNED BY "public"."facturas_comerciales"."id";


--
-- Name: historial_estados_taller; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."historial_estados_taller" (
    "id" bigint NOT NULL,
    "tipo_trabajo" character varying(20) NOT NULL,
    "trabajo_id" bigint NOT NULL,
    "estado" character varying(30) NOT NULL,
    "usuario_id" bigint,
    "observaciones" "text",
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "historial_estados_taller_tipo_trabajo_check" CHECK ((("tipo_trabajo")::"text" = ANY ((ARRAY['pedido'::character varying, 'reparacion'::character varying])::"text"[])))
);


--
-- Name: historial_estados_taller_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."historial_estados_taller_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historial_estados_taller_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."historial_estados_taller_id_seq" OWNED BY "public"."historial_estados_taller"."id";


--
-- Name: movimientos_caja; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."movimientos_caja" (
    "id" bigint NOT NULL,
    "caja_id" bigint NOT NULL,
    "usuario_id" bigint,
    "tipo" character varying(30) NOT NULL,
    "monto" numeric(14,2) NOT NULL,
    "descripcion" "text",
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "movimientos_caja_monto_check" CHECK (("monto" >= (0)::numeric))
);


--
-- Name: movimientos_caja_app; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."movimientos_caja_app" (
    "id" bigint NOT NULL,
    "turno_id" bigint NOT NULL,
    "usuario_id" bigint NOT NULL,
    "tipo" character varying(12) NOT NULL,
    "origen" character varying(20) NOT NULL,
    "monto" numeric(12,2) NOT NULL,
    "concepto" character varying(500) NOT NULL,
    "referencia" character varying(100),
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "movimientos_caja_app_monto_check" CHECK (("monto" > (0)::numeric)),
    CONSTRAINT "movimientos_caja_app_origen_check" CHECK ((("origen")::"text" = ANY ((ARRAY['manual'::character varying, 'venta'::character varying, 'pago'::character varying, 'ajuste'::character varying])::"text"[]))),
    CONSTRAINT "movimientos_caja_app_tipo_check" CHECK ((("tipo")::"text" = ANY ((ARRAY['ingreso'::character varying, 'egreso'::character varying])::"text"[])))
);


--
-- Name: movimientos_caja_app_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."movimientos_caja_app_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movimientos_caja_app_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."movimientos_caja_app_id_seq" OWNED BY "public"."movimientos_caja_app"."id";


--
-- Name: movimientos_caja_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."movimientos_caja" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."movimientos_caja_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: movimientos_inventario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."movimientos_inventario" (
    "id" bigint NOT NULL,
    "producto_id" bigint NOT NULL,
    "tipo" character varying(20) NOT NULL,
    "cantidad" integer NOT NULL,
    "stock_anterior" integer NOT NULL,
    "stock_nuevo" integer NOT NULL,
    "motivo" character varying(200) NOT NULL,
    "observaciones" "text",
    "fecha_movimiento" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "movimientos_inventario_cantidad_check" CHECK (("cantidad" > 0)),
    CONSTRAINT "movimientos_inventario_stock_anterior_check" CHECK (("stock_anterior" >= 0)),
    CONSTRAINT "movimientos_inventario_stock_nuevo_check" CHECK (("stock_nuevo" >= 0)),
    CONSTRAINT "movimientos_inventario_tipo_check" CHECK ((("tipo")::"text" = ANY (ARRAY[('entrada'::character varying)::"text", ('salida'::character varying)::"text", ('ajuste'::character varying)::"text"])))
);


--
-- Name: movimientos_inventario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."movimientos_inventario" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."movimientos_inventario_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notificaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."notificaciones" (
    "id" bigint NOT NULL,
    "cliente_id" bigint,
    "canal" character varying(30) NOT NULL,
    "asunto" character varying(200),
    "mensaje" "text" NOT NULL,
    "estado" character varying(30) DEFAULT 'pendiente'::character varying NOT NULL,
    "programada_para" timestamp with time zone,
    "enviada_en" timestamp with time zone,
    "fecha_creacion" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: notificaciones_cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."notificaciones_cliente" (
    "id" bigint NOT NULL,
    "cliente_id" bigint NOT NULL,
    "canal" character varying(20) DEFAULT 'whatsapp'::character varying NOT NULL,
    "tipo" character varying(40) NOT NULL,
    "trabajo_tipo" character varying(20),
    "trabajo_id" bigint,
    "cita_id" bigint,
    "plantilla" character varying(80) NOT NULL,
    "deduplicacion_clave" character varying(160) NOT NULL,
    "estado" character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    "proveedor" character varying(30) DEFAULT 'simulado'::character varying NOT NULL,
    "proveedor_id" character varying(100),
    "intentos" integer DEFAULT 0 NOT NULL,
    "programado_para" timestamp with time zone DEFAULT "now"() NOT NULL,
    "enviado_en" timestamp with time zone,
    "error" "text",
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: notificaciones_cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."notificaciones_cliente_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notificaciones_cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."notificaciones_cliente_id_seq" OWNED BY "public"."notificaciones_cliente"."id";


--
-- Name: notificaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."notificaciones" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."notificaciones_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pacientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."pacientes" (
    "id" bigint NOT NULL,
    "cliente_id" bigint NOT NULL,
    "fecha_nacimiento" "date",
    "antecedentes" "text",
    "alergias" "text",
    "observaciones" "text",
    "fecha_registro" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: pacientes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."pacientes" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."pacientes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pagos_compras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."pagos_compras" (
    "id" bigint NOT NULL,
    "compra_id" bigint NOT NULL,
    "monto" numeric(12,2) NOT NULL,
    "metodo_pago" character varying(30) NOT NULL,
    "referencia" character varying(100),
    "fecha_pago" timestamp with time zone DEFAULT "now"() NOT NULL,
    "observaciones" "text",
    CONSTRAINT "pagos_compras_metodo_pago_check" CHECK ((("metodo_pago")::"text" = ANY (ARRAY[('efectivo'::character varying)::"text", ('tarjeta'::character varying)::"text", ('transferencia'::character varying)::"text", ('deposito'::character varying)::"text", ('cheque'::character varying)::"text", ('otro'::character varying)::"text"]))),
    CONSTRAINT "pagos_compras_monto_check" CHECK (("monto" > (0)::numeric))
);


--
-- Name: pagos_compras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."pagos_compras" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."pagos_compras_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pagos_ventas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."pagos_ventas" (
    "id" bigint NOT NULL,
    "venta_id" bigint NOT NULL,
    "monto" numeric(12,2) NOT NULL,
    "metodo_pago" character varying(30) NOT NULL,
    "referencia" character varying(100),
    "fecha_pago" timestamp with time zone DEFAULT "now"() NOT NULL,
    "observaciones" "text",
    "turno_caja_id" bigint,
    "usuario_id" bigint,
    "monto_recibido" numeric,
    "cambio" numeric,
    CONSTRAINT "pagos_ventas_metodo_pago_check" CHECK ((("metodo_pago")::"text" = ANY (ARRAY[('efectivo'::character varying)::"text", ('tarjeta'::character varying)::"text", ('transferencia'::character varying)::"text", ('deposito'::character varying)::"text", ('cheque'::character varying)::"text", ('otro'::character varying)::"text"]))),
    CONSTRAINT "pagos_ventas_monto_check" CHECK (("monto" > (0)::numeric))
);


--
-- Name: pagos_ventas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."pagos_ventas" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."pagos_ventas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pedidos_lentes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."pedidos_lentes" (
    "id" bigint NOT NULL,
    "cliente_id" bigint NOT NULL,
    "receta_id" bigint,
    "venta_id" bigint,
    "usuario_id" bigint,
    "fecha_pedido" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fecha_estimada" "date",
    "fecha_entrega" timestamp with time zone,
    "tipo_cristal" character varying(100),
    "tipo_montura" character varying(100),
    "laboratorio" character varying(150),
    "estado" character varying(30) DEFAULT 'pendiente'::character varying NOT NULL,
    "observaciones" "text",
    "codigo" character varying(32) NOT NULL,
    CONSTRAINT "pedidos_lentes_estado_check" CHECK ((("estado")::"text" = ANY (ARRAY[('pendiente'::character varying)::"text", ('en_preparacion'::character varying)::"text", ('en_laboratorio'::character varying)::"text", ('listo'::character varying)::"text", ('entregado'::character varying)::"text", ('cancelado'::character varying)::"text"])))
);


--
-- Name: pedidos_lentes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."pedidos_lentes" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."pedidos_lentes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."permisos" (
    "id" bigint NOT NULL,
    "codigo" character varying(100) NOT NULL,
    "descripcion" "text"
);


--
-- Name: permisos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."permisos" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."permisos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: productos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."productos" (
    "id" bigint NOT NULL,
    "codigo" character varying(50) NOT NULL,
    "nombre" character varying(150) NOT NULL,
    "categoria" character varying(30) NOT NULL,
    "marca" character varying(100),
    "descripcion" "text",
    "precio_compra" numeric(12,2) DEFAULT 0 NOT NULL,
    "precio_venta" numeric(12,2) DEFAULT 0 NOT NULL,
    "stock_actual" integer DEFAULT 0 NOT NULL,
    "stock_minimo" integer DEFAULT 5 NOT NULL,
    "activo" boolean DEFAULT true NOT NULL,
    "fecha_registro" timestamp with time zone DEFAULT "now"() NOT NULL,
    "itbis_tasa" numeric(5,2) DEFAULT 18.00 NOT NULL,
    CONSTRAINT "ck_productos_itbis_tasa" CHECK ((("itbis_tasa" >= (0)::numeric) AND ("itbis_tasa" <= (100)::numeric))),
    CONSTRAINT "productos_categoria_check" CHECK ((("categoria")::"text" = ANY (ARRAY[('montura'::character varying)::"text", ('cristal'::character varying)::"text", ('medicamento'::character varying)::"text", ('accesorio'::character varying)::"text", ('otro'::character varying)::"text"]))),
    CONSTRAINT "productos_precio_compra_check" CHECK (("precio_compra" >= (0)::numeric)),
    CONSTRAINT "productos_precio_venta_check" CHECK (("precio_venta" >= (0)::numeric)),
    CONSTRAINT "productos_stock_actual_check" CHECK (("stock_actual" >= 0)),
    CONSTRAINT "productos_stock_minimo_check" CHECK (("stock_minimo" >= 0))
);


--
-- Name: productos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."productos" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."productos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: proveedores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."proveedores" (
    "id" bigint NOT NULL,
    "nombre" character varying(150) NOT NULL,
    "rnc" character varying(20),
    "telefono" character varying(30),
    "correo" character varying(150),
    "direccion" "text",
    "contacto" character varying(150),
    "observaciones" "text",
    "activo" boolean DEFAULT true NOT NULL,
    "fecha_registro" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: proveedores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."proveedores" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."proveedores_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recetas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."recetas" (
    "id" bigint NOT NULL,
    "paciente_id" bigint NOT NULL,
    "fecha_receta" "date" DEFAULT CURRENT_DATE NOT NULL,
    "od_esfera" numeric(5,2),
    "od_cilindro" numeric(5,2),
    "od_eje" smallint,
    "oi_esfera" numeric(5,2),
    "oi_cilindro" numeric(5,2),
    "oi_eje" smallint,
    "adicion" numeric(5,2),
    "distancia_pupilar" numeric(5,2),
    "diagnostico" "text",
    "observaciones" "text",
    "profesional" character varying(150),
    "fecha_registro" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recetas_od_eje_check" CHECK ((("od_eje" >= 0) AND ("od_eje" <= 180))),
    CONSTRAINT "recetas_oi_eje_check" CHECK ((("oi_eje" >= 0) AND ("oi_eje" <= 180)))
);


--
-- Name: recetas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."recetas" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."recetas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reparaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reparaciones" (
    "id" bigint NOT NULL,
    "cliente_id" bigint NOT NULL,
    "venta_id" bigint,
    "usuario_id" bigint,
    "tipo" character varying(20) NOT NULL,
    "descripcion" "text" NOT NULL,
    "fecha_recepcion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fecha_estimada" "date",
    "fecha_entrega" timestamp with time zone,
    "costo" numeric(12,2) DEFAULT 0 NOT NULL,
    "estado" character varying(30) DEFAULT 'recibido'::character varying NOT NULL,
    "observaciones" "text",
    "codigo" character varying(32) NOT NULL,
    CONSTRAINT "reparaciones_costo_check" CHECK (("costo" >= (0)::numeric)),
    CONSTRAINT "reparaciones_estado_check" CHECK ((("estado")::"text" = ANY (ARRAY[('recibido'::character varying)::"text", ('en_revision'::character varying)::"text", ('en_reparacion'::character varying)::"text", ('listo'::character varying)::"text", ('entregado'::character varying)::"text", ('cancelado'::character varying)::"text"]))),
    CONSTRAINT "reparaciones_tipo_check" CHECK ((("tipo")::"text" = ANY (ARRAY[('reparacion'::character varying)::"text", ('garantia'::character varying)::"text"])))
);


--
-- Name: reparaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."reparaciones" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."reparaciones_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."roles" (
    "id" bigint NOT NULL,
    "nombre" character varying(80) NOT NULL,
    "descripcion" "text"
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."roles" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."roles_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles_permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."roles_permisos" (
    "rol_id" bigint NOT NULL,
    "permiso_id" bigint NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."schema_migrations" (
    "version" character varying(100) NOT NULL,
    "applied_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


--
-- Name: secuencias_ncf; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."secuencias_ncf" (
    "id" bigint NOT NULL,
    "tipo_comprobante" character varying(30) NOT NULL,
    "prefijo" character varying(20) NOT NULL,
    "numero_inicial" bigint NOT NULL,
    "numero_final" bigint NOT NULL,
    "proximo_numero" bigint NOT NULL,
    "fecha_vencimiento" "date",
    "activa" boolean DEFAULT true NOT NULL,
    CONSTRAINT "secuencias_ncf_check" CHECK (("numero_inicial" <= "numero_final")),
    CONSTRAINT "secuencias_ncf_check1" CHECK ((("proximo_numero" >= "numero_inicial") AND ("proximo_numero" <= ("numero_final" + 1))))
);


--
-- Name: secuencias_ncf_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."secuencias_ncf" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."secuencias_ncf_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sucursales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."sucursales" (
    "id" bigint NOT NULL,
    "nombre" character varying(150) NOT NULL,
    "direccion" "text",
    "telefono" character varying(30),
    "activa" boolean DEFAULT true NOT NULL
);


--
-- Name: sucursales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."sucursales" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."sucursales_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: turnos_caja; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."turnos_caja" (
    "id" bigint NOT NULL,
    "usuario_id" bigint NOT NULL,
    "abierto_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cerrado_en" timestamp with time zone,
    "fondo_inicial" numeric(12,2) NOT NULL,
    "monto_esperado" numeric(12,2),
    "monto_contado" numeric(12,2),
    "diferencia" numeric(12,2),
    "estado" character varying(12) DEFAULT 'abierta'::character varying NOT NULL,
    "observaciones" character varying(5000),
    "caja_id" bigint NOT NULL,
    CONSTRAINT "turnos_caja_estado_check" CHECK ((("estado")::"text" = ANY ((ARRAY['abierta'::character varying, 'cerrada'::character varying])::"text"[]))),
    CONSTRAINT "turnos_caja_fondo_inicial_check" CHECK (("fondo_inicial" >= (0)::numeric))
);


--
-- Name: turnos_caja_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "public"."turnos_caja_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: turnos_caja_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "public"."turnos_caja_id_seq" OWNED BY "public"."turnos_caja"."id";


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."usuarios" (
    "id" bigint NOT NULL,
    "nombre" character varying(150) NOT NULL,
    "usuario" character varying(50) NOT NULL,
    "password_hash" "text" NOT NULL,
    "rol" character varying(20) NOT NULL,
    "telefono" character varying(30),
    "correo" character varying(150),
    "activo" boolean DEFAULT true NOT NULL,
    "fecha_creacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ultimo_acceso" timestamp with time zone,
    CONSTRAINT "usuarios_rol_check" CHECK ((("rol")::"text" = ANY ((ARRAY['administrador'::character varying, 'cajero'::character varying, 'gerente'::character varying, 'supervisor'::character varying])::"text"[])))
);


--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."usuarios" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."usuarios_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ventas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."ventas" (
    "id" bigint NOT NULL,
    "cliente_id" bigint,
    "numero_factura" character varying(50),
    "ncf" character varying(30),
    "tipo_comprobante" character varying(30) DEFAULT 'sin_ncf'::character varying NOT NULL,
    "fecha_venta" timestamp with time zone DEFAULT "now"() NOT NULL,
    "subtotal" numeric(12,2) DEFAULT 0 NOT NULL,
    "descuento" numeric(12,2) DEFAULT 0 NOT NULL,
    "impuestos" numeric(12,2) DEFAULT 0 NOT NULL,
    "total" numeric(12,2) DEFAULT 0 NOT NULL,
    "monto_pagado" numeric(12,2) DEFAULT 0 NOT NULL,
    "estado" character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    "observaciones" "text",
    "usuario_id" bigint,
    CONSTRAINT "ventas_descuento_check" CHECK (("descuento" >= (0)::numeric)),
    CONSTRAINT "ventas_estado_check" CHECK ((("estado")::"text" = ANY (ARRAY[('pendiente'::character varying)::"text", ('parcial'::character varying)::"text", ('pagada'::character varying)::"text", ('anulada'::character varying)::"text"]))),
    CONSTRAINT "ventas_impuestos_check" CHECK (("impuestos" >= (0)::numeric)),
    CONSTRAINT "ventas_monto_pagado_check" CHECK (("monto_pagado" >= (0)::numeric)),
    CONSTRAINT "ventas_subtotal_check" CHECK (("subtotal" >= (0)::numeric)),
    CONSTRAINT "ventas_tipo_comprobante_check" CHECK ((("tipo_comprobante")::"text" = ANY (ARRAY[('sin_ncf'::character varying)::"text", ('credito_fiscal'::character varying)::"text", ('consumo'::character varying)::"text", ('gubernamental'::character varying)::"text", ('regimen_especial'::character varying)::"text", ('otro'::character varying)::"text"]))),
    CONSTRAINT "ventas_total_check" CHECK (("total" >= (0)::numeric))
);


--
-- Name: ventas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."ventas" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."ventas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auditoria_operaciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."auditoria_operaciones" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."auditoria_operaciones_id_seq"'::"regclass");


--
-- Name: cajas_fisicas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."cajas_fisicas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."cajas_fisicas_id_seq"'::"regclass");


--
-- Name: claves_idempotencia id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."claves_idempotencia" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."claves_idempotencia_id_seq"'::"regclass");


--
-- Name: facturas_comerciales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."facturas_comerciales" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."facturas_comerciales_id_seq"'::"regclass");


--
-- Name: historial_estados_taller id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."historial_estados_taller" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."historial_estados_taller_id_seq"'::"regclass");


--
-- Name: movimientos_caja_app id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_caja_app" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."movimientos_caja_app_id_seq"'::"regclass");


--
-- Name: notificaciones_cliente id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."notificaciones_cliente" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."notificaciones_cliente_id_seq"'::"regclass");


--
-- Name: turnos_caja id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."turnos_caja" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."turnos_caja_id_seq"'::"regclass");


--
-- Name: auditoria_operaciones auditoria_operaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."auditoria_operaciones"
    ADD CONSTRAINT "auditoria_operaciones_pkey" PRIMARY KEY ("id");


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."auditoria"
    ADD CONSTRAINT "auditoria_pkey" PRIMARY KEY ("id");


--
-- Name: cajas_fisicas cajas_fisicas_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."cajas_fisicas"
    ADD CONSTRAINT "cajas_fisicas_nombre_key" UNIQUE ("nombre");


--
-- Name: cajas_fisicas cajas_fisicas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."cajas_fisicas"
    ADD CONSTRAINT "cajas_fisicas_pkey" PRIMARY KEY ("id");


--
-- Name: cajas cajas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."cajas"
    ADD CONSTRAINT "cajas_pkey" PRIMARY KEY ("id");


--
-- Name: citas citas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "citas_pkey" PRIMARY KEY ("id");


--
-- Name: claves_idempotencia claves_idempotencia_operacion_clave_usuario_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."claves_idempotencia"
    ADD CONSTRAINT "claves_idempotencia_operacion_clave_usuario_id_key" UNIQUE ("operacion", "clave", "usuario_id");


--
-- Name: claves_idempotencia claves_idempotencia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."claves_idempotencia"
    ADD CONSTRAINT "claves_idempotencia_pkey" PRIMARY KEY ("id");


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."clientes"
    ADD CONSTRAINT "clientes_pkey" PRIMARY KEY ("id");


--
-- Name: compras compras_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."compras"
    ADD CONSTRAINT "compras_pkey" PRIMARY KEY ("id");


--
-- Name: configuracion_empresa configuracion_empresa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."configuracion_empresa"
    ADD CONSTRAINT "configuracion_empresa_pkey" PRIMARY KEY ("id");


--
-- Name: configuracion_fiscal configuracion_fiscal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."configuracion_fiscal"
    ADD CONSTRAINT "configuracion_fiscal_pkey" PRIMARY KEY ("id");


--
-- Name: configuracion_impresoras configuracion_impresoras_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."configuracion_impresoras"
    ADD CONSTRAINT "configuracion_impresoras_pkey" PRIMARY KEY ("id");


--
-- Name: configuracion_sistema configuracion_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."configuracion_sistema"
    ADD CONSTRAINT "configuracion_sistema_pkey" PRIMARY KEY ("clave");


--
-- Name: consentimientos_notificacion consentimientos_notificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consentimientos_notificacion"
    ADD CONSTRAINT "consentimientos_notificacion_pkey" PRIMARY KEY ("cliente_id");


--
-- Name: datos_negocio datos_negocio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."datos_negocio"
    ADD CONSTRAINT "datos_negocio_pkey" PRIMARY KEY ("id");


--
-- Name: detalle_compras detalle_compras_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."detalle_compras"
    ADD CONSTRAINT "detalle_compras_pkey" PRIMARY KEY ("id");


--
-- Name: detalle_ventas detalle_ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."detalle_ventas"
    ADD CONSTRAINT "detalle_ventas_pkey" PRIMARY KEY ("id");


--
-- Name: documentos_electronicos documentos_electronicos_identificador_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."documentos_electronicos"
    ADD CONSTRAINT "documentos_electronicos_identificador_key" UNIQUE ("identificador");


--
-- Name: documentos_electronicos documentos_electronicos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."documentos_electronicos"
    ADD CONSTRAINT "documentos_electronicos_pkey" PRIMARY KEY ("id");


--
-- Name: facturas_comerciales facturas_comerciales_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."facturas_comerciales"
    ADD CONSTRAINT "facturas_comerciales_numero_key" UNIQUE ("numero");


--
-- Name: facturas_comerciales facturas_comerciales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."facturas_comerciales"
    ADD CONSTRAINT "facturas_comerciales_pkey" PRIMARY KEY ("id");


--
-- Name: facturas_comerciales facturas_comerciales_venta_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."facturas_comerciales"
    ADD CONSTRAINT "facturas_comerciales_venta_id_key" UNIQUE ("venta_id");


--
-- Name: historial_estados_taller historial_estados_taller_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."historial_estados_taller"
    ADD CONSTRAINT "historial_estados_taller_pkey" PRIMARY KEY ("id");


--
-- Name: movimientos_caja_app movimientos_caja_app_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_caja_app"
    ADD CONSTRAINT "movimientos_caja_app_pkey" PRIMARY KEY ("id");


--
-- Name: movimientos_caja movimientos_caja_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_caja"
    ADD CONSTRAINT "movimientos_caja_pkey" PRIMARY KEY ("id");


--
-- Name: movimientos_inventario movimientos_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_inventario"
    ADD CONSTRAINT "movimientos_inventario_pkey" PRIMARY KEY ("id");


--
-- Name: notificaciones_cliente notificaciones_cliente_deduplicacion_clave_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."notificaciones_cliente"
    ADD CONSTRAINT "notificaciones_cliente_deduplicacion_clave_key" UNIQUE ("deduplicacion_clave");


--
-- Name: notificaciones_cliente notificaciones_cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."notificaciones_cliente"
    ADD CONSTRAINT "notificaciones_cliente_pkey" PRIMARY KEY ("id");


--
-- Name: notificaciones notificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."notificaciones"
    ADD CONSTRAINT "notificaciones_pkey" PRIMARY KEY ("id");


--
-- Name: pacientes pacientes_cliente_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pacientes"
    ADD CONSTRAINT "pacientes_cliente_id_key" UNIQUE ("cliente_id");


--
-- Name: pacientes pacientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pacientes"
    ADD CONSTRAINT "pacientes_pkey" PRIMARY KEY ("id");


--
-- Name: pagos_compras pagos_compras_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pagos_compras"
    ADD CONSTRAINT "pagos_compras_pkey" PRIMARY KEY ("id");


--
-- Name: pagos_ventas pagos_ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pagos_ventas"
    ADD CONSTRAINT "pagos_ventas_pkey" PRIMARY KEY ("id");


--
-- Name: pedidos_lentes pedidos_lentes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pedidos_lentes"
    ADD CONSTRAINT "pedidos_lentes_pkey" PRIMARY KEY ("id");


--
-- Name: permisos permisos_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."permisos"
    ADD CONSTRAINT "permisos_codigo_key" UNIQUE ("codigo");


--
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."permisos"
    ADD CONSTRAINT "permisos_pkey" PRIMARY KEY ("id");


--
-- Name: productos productos_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."productos"
    ADD CONSTRAINT "productos_codigo_key" UNIQUE ("codigo");


--
-- Name: productos productos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."productos"
    ADD CONSTRAINT "productos_pkey" PRIMARY KEY ("id");


--
-- Name: proveedores proveedores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."proveedores"
    ADD CONSTRAINT "proveedores_pkey" PRIMARY KEY ("id");


--
-- Name: recetas recetas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_pkey" PRIMARY KEY ("id");


--
-- Name: reparaciones reparaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reparaciones"
    ADD CONSTRAINT "reparaciones_pkey" PRIMARY KEY ("id");


--
-- Name: roles roles_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_nombre_key" UNIQUE ("nombre");


--
-- Name: roles_permisos roles_permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."roles_permisos"
    ADD CONSTRAINT "roles_permisos_pkey" PRIMARY KEY ("rol_id", "permiso_id");


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."schema_migrations"
    ADD CONSTRAINT "schema_migrations_pkey" PRIMARY KEY ("version");


--
-- Name: secuencias_ncf secuencias_ncf_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."secuencias_ncf"
    ADD CONSTRAINT "secuencias_ncf_pkey" PRIMARY KEY ("id");


--
-- Name: sucursales sucursales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."sucursales"
    ADD CONSTRAINT "sucursales_pkey" PRIMARY KEY ("id");


--
-- Name: turnos_caja turnos_caja_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."turnos_caja"
    ADD CONSTRAINT "turnos_caja_pkey" PRIMARY KEY ("id");


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id");


--
-- Name: usuarios usuarios_usuario_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_usuario_key" UNIQUE ("usuario");


--
-- Name: ventas ventas_ncf_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."ventas"
    ADD CONSTRAINT "ventas_ncf_key" UNIQUE ("ncf");


--
-- Name: ventas ventas_numero_factura_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."ventas"
    ADD CONSTRAINT "ventas_numero_factura_key" UNIQUE ("numero_factura");


--
-- Name: ventas ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."ventas"
    ADD CONSTRAINT "ventas_pkey" PRIMARY KEY ("id");


--
-- Name: ix_historial_estados_taller_trabajo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ix_historial_estados_taller_trabajo" ON "public"."historial_estados_taller" USING "btree" ("tipo_trabajo", "trabajo_id", "creado_en");


--
-- Name: ix_notificaciones_estado_programacion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ix_notificaciones_estado_programacion" ON "public"."notificaciones_cliente" USING "btree" ("estado", "programado_para");


--
-- Name: ix_pagos_ventas_turno_caja; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ix_pagos_ventas_turno_caja" ON "public"."pagos_ventas" USING "btree" ("turno_caja_id");


--
-- Name: ux_citas_paciente_hora_activa; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ux_citas_paciente_hora_activa" ON "public"."citas" USING "btree" ("paciente_id", "fecha_hora") WHERE (("estado")::"text" <> ALL ((ARRAY['cancelada'::character varying, 'no_asistio'::character varying])::"text"[]));


--
-- Name: ux_citas_profesional_hora_activa; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ux_citas_profesional_hora_activa" ON "public"."citas" USING "btree" ("profesional", "fecha_hora") WHERE (("profesional" IS NOT NULL) AND (("estado")::"text" <> ALL ((ARRAY['cancelada'::character varying, 'no_asistio'::character varying])::"text"[])));


--
-- Name: ux_pedidos_lentes_codigo; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ux_pedidos_lentes_codigo" ON "public"."pedidos_lentes" USING "btree" ("codigo");


--
-- Name: ux_reparaciones_codigo; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ux_reparaciones_codigo" ON "public"."reparaciones" USING "btree" ("codigo");


--
-- Name: ux_turnos_caja_abierto_fisica; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ux_turnos_caja_abierto_fisica" ON "public"."turnos_caja" USING "btree" ("caja_id") WHERE (("estado")::"text" = 'abierta'::"text");


--
-- Name: ux_turnos_caja_abierto_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ux_turnos_caja_abierto_usuario" ON "public"."turnos_caja" USING "btree" ("usuario_id") WHERE (("estado")::"text" = 'abierta'::"text");


--
-- Name: auditoria_operaciones auditoria_operaciones_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."auditoria_operaciones"
    ADD CONSTRAINT "auditoria_operaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: claves_idempotencia claves_idempotencia_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."claves_idempotencia"
    ADD CONSTRAINT "claves_idempotencia_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: consentimientos_notificacion consentimientos_notificacion_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."consentimientos_notificacion"
    ADD CONSTRAINT "consentimientos_notificacion_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id");


--
-- Name: documentos_electronicos documentos_electronicos_venta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."documentos_electronicos"
    ADD CONSTRAINT "documentos_electronicos_venta_id_fkey" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id");


--
-- Name: facturas_comerciales facturas_comerciales_emitida_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."facturas_comerciales"
    ADD CONSTRAINT "facturas_comerciales_emitida_por_fkey" FOREIGN KEY ("emitida_por") REFERENCES "public"."usuarios"("id");


--
-- Name: facturas_comerciales facturas_comerciales_venta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."facturas_comerciales"
    ADD CONSTRAINT "facturas_comerciales_venta_id_fkey" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id");


--
-- Name: auditoria fk_auditoria_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."auditoria"
    ADD CONSTRAINT "fk_auditoria_usuario" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE SET NULL;


--
-- Name: citas fk_cita_paciente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "fk_cita_paciente" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id");


--
-- Name: citas fk_cita_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "fk_cita_usuario" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: compras fk_compra_proveedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."compras"
    ADD CONSTRAINT "fk_compra_proveedor" FOREIGN KEY ("proveedor_id") REFERENCES "public"."proveedores"("id");


--
-- Name: detalle_compras fk_detalle_compra; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."detalle_compras"
    ADD CONSTRAINT "fk_detalle_compra" FOREIGN KEY ("compra_id") REFERENCES "public"."compras"("id");


--
-- Name: detalle_compras fk_detalle_producto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."detalle_compras"
    ADD CONSTRAINT "fk_detalle_producto" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id");


--
-- Name: detalle_ventas fk_detalle_venta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."detalle_ventas"
    ADD CONSTRAINT "fk_detalle_venta" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id");


--
-- Name: detalle_ventas fk_detalle_venta_producto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."detalle_ventas"
    ADD CONSTRAINT "fk_detalle_venta_producto" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id");


--
-- Name: movimientos_inventario fk_movimiento_producto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_inventario"
    ADD CONSTRAINT "fk_movimiento_producto" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id");


--
-- Name: pacientes fk_paciente_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pacientes"
    ADD CONSTRAINT "fk_paciente_cliente" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id");


--
-- Name: pagos_compras fk_pago_compra; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pagos_compras"
    ADD CONSTRAINT "fk_pago_compra" FOREIGN KEY ("compra_id") REFERENCES "public"."compras"("id");


--
-- Name: pagos_ventas fk_pago_venta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pagos_ventas"
    ADD CONSTRAINT "fk_pago_venta" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id");


--
-- Name: pagos_ventas fk_pagos_ventas_turno_caja; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pagos_ventas"
    ADD CONSTRAINT "fk_pagos_ventas_turno_caja" FOREIGN KEY ("turno_caja_id") REFERENCES "public"."turnos_caja"("id");


--
-- Name: pagos_ventas fk_pagos_ventas_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pagos_ventas"
    ADD CONSTRAINT "fk_pagos_ventas_usuario" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: pedidos_lentes fk_pedido_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pedidos_lentes"
    ADD CONSTRAINT "fk_pedido_cliente" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id");


--
-- Name: pedidos_lentes fk_pedido_receta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pedidos_lentes"
    ADD CONSTRAINT "fk_pedido_receta" FOREIGN KEY ("receta_id") REFERENCES "public"."recetas"("id");


--
-- Name: pedidos_lentes fk_pedido_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pedidos_lentes"
    ADD CONSTRAINT "fk_pedido_usuario" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: pedidos_lentes fk_pedido_venta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."pedidos_lentes"
    ADD CONSTRAINT "fk_pedido_venta" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id");


--
-- Name: recetas fk_receta_paciente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "fk_receta_paciente" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id");


--
-- Name: reparaciones fk_reparacion_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reparaciones"
    ADD CONSTRAINT "fk_reparacion_cliente" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id");


--
-- Name: reparaciones fk_reparacion_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reparaciones"
    ADD CONSTRAINT "fk_reparacion_usuario" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: reparaciones fk_reparacion_venta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reparaciones"
    ADD CONSTRAINT "fk_reparacion_venta" FOREIGN KEY ("venta_id") REFERENCES "public"."ventas"("id");


--
-- Name: turnos_caja fk_turnos_caja_caja_fisica; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."turnos_caja"
    ADD CONSTRAINT "fk_turnos_caja_caja_fisica" FOREIGN KEY ("caja_id") REFERENCES "public"."cajas_fisicas"("id");


--
-- Name: ventas fk_venta_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."ventas"
    ADD CONSTRAINT "fk_venta_cliente" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id");


--
-- Name: ventas fk_venta_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."ventas"
    ADD CONSTRAINT "fk_venta_usuario" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: historial_estados_taller historial_estados_taller_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."historial_estados_taller"
    ADD CONSTRAINT "historial_estados_taller_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: movimientos_caja_app movimientos_caja_app_turno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_caja_app"
    ADD CONSTRAINT "movimientos_caja_app_turno_id_fkey" FOREIGN KEY ("turno_id") REFERENCES "public"."turnos_caja"("id");


--
-- Name: movimientos_caja_app movimientos_caja_app_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_caja_app"
    ADD CONSTRAINT "movimientos_caja_app_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: movimientos_caja movimientos_caja_caja_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_caja"
    ADD CONSTRAINT "movimientos_caja_caja_id_fkey" FOREIGN KEY ("caja_id") REFERENCES "public"."cajas"("id");


--
-- Name: movimientos_caja movimientos_caja_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."movimientos_caja"
    ADD CONSTRAINT "movimientos_caja_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


--
-- Name: notificaciones_cliente notificaciones_cliente_cita_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."notificaciones_cliente"
    ADD CONSTRAINT "notificaciones_cliente_cita_id_fkey" FOREIGN KEY ("cita_id") REFERENCES "public"."citas"("id");


--
-- Name: notificaciones_cliente notificaciones_cliente_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."notificaciones_cliente"
    ADD CONSTRAINT "notificaciones_cliente_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id");


--
-- Name: notificaciones notificaciones_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."notificaciones"
    ADD CONSTRAINT "notificaciones_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("id");


--
-- Name: roles_permisos roles_permisos_permiso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."roles_permisos"
    ADD CONSTRAINT "roles_permisos_permiso_id_fkey" FOREIGN KEY ("permiso_id") REFERENCES "public"."permisos"("id");


--
-- Name: roles_permisos roles_permisos_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."roles_permisos"
    ADD CONSTRAINT "roles_permisos_rol_id_fkey" FOREIGN KEY ("rol_id") REFERENCES "public"."roles"("id");


--
-- Name: turnos_caja turnos_caja_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."turnos_caja"
    ADD CONSTRAINT "turnos_caja_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");


-- Seguridad Supabase: las tablas comerciales nunca quedan disponibles por la
-- Data API pública. FastAPI se conecta con la credencial de base de datos del
-- servidor y conserva autenticación, permisos, transacciones e idempotencia.
REVOKE ALL ON SCHEMA "public" FROM "anon", "authenticated";
REVOKE ALL ON ALL TABLES IN SCHEMA "public" FROM "anon", "authenticated";
REVOKE ALL ON ALL SEQUENCES IN SCHEMA "public" FROM "anon", "authenticated";

DO $$
DECLARE
  item record;
BEGIN
  FOR item IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', item.tablename);
  END LOOP;
END
$$;

-- Impide que tablas nuevas creadas por el propietario del proyecto se
-- publiquen accidentalmente para los roles de cliente.
ALTER DEFAULT PRIVILEGES IN SCHEMA "public"
  REVOKE ALL ON TABLES FROM "anon", "authenticated";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public"
  REVOKE ALL ON SEQUENCES FROM "anon", "authenticated";


--
-- PostgreSQL database dump complete
--


