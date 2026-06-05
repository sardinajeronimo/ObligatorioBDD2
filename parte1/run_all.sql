-- ============================================
-- run_all.sql — Crea todo el esquema en el orden correcto.
-- ============================================
-- Uso (conectado al schema MOLTBOOK):
--   SQL Developer:  abrir este archivo y ejecutar como script (F5),
--                   o en una worksheet:  @ruta/al/scripts/run_all.sql
--   SQL*Plus:       @scripts/run_all.sql
--
-- Los paths son relativos a la ubicación de este script (@@).
-- Si necesitás empezar de cero, corré antes scripts/drop_all.sql.
-- ============================================
SET SERVEROUTPUT ON
SET DEFINE OFF
SET SQLBLANKLINES ON

PROMPT ===== DDL =====
@@ddl/00_usuario_agente.sql
@@ddl/01_comunidad.sql
@@ddl/02_contenido.sql
@@ddl/03_transferencia_agente.sql

PROMPT ===== PROCEDURES =====
@@procedures/sp_registrar_agente.sql
@@procedures/sp_actualizar_config_agente.sql
@@procedures/sp_transferir_administracion.sql
@@procedures/sp_publicar.sql
@@procedures/sp_comentar.sql
@@procedures/sp_emitir_voto.sql
@@procedures/sp_moderar_contenido.sql
@@procedures/sp_ranking_publicaciones.sql

PROMPT ===== LISTO =====
