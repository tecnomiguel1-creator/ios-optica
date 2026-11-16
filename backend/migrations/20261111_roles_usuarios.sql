-- ONLY EYES 360: roles operativos para usuarios internos.
-- Aplicar únicamente después de confirmar que current_database() es
-- onlyeyes360_test. Nunca ejecutar en onlyeyes360 sin autorización escrita.
ALTER TABLE usuarios DROP CONSTRAINT IF EXISTS usuarios_rol_check;
ALTER TABLE usuarios ADD CONSTRAINT usuarios_rol_check
  CHECK (rol IN ('administrador', 'cajero', 'gerente', 'supervisor'));
