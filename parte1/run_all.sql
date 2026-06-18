-- ============================================
-- run_all.sql — Crea todo el esquema de la Parte 1 (DDL + datos de prueba).
-- ============================================
-- Uso (conectado al schema MOLTBOOK):
--   SQL Developer:  abrir este archivo y ejecutar como script (F5),
--                   o en una worksheet:  @ruta/a/parte1/run_all.sql
--   SQL*Plus:       @parte1/run_all.sql
--
-- Los paths son relativos a la ubicación de este script (@@), por lo que
-- los archivos DDL deben quedar en la MISMA carpeta que este run_all.sql.
-- Si necesitás empezar de cero, corré antes parte1/drop_all.sql.
--
-- NOTA: los procedimientos/triggers (Parte 2) se ejecutan aparte con
--       parte2/00_ejecutar_todos.sql, una vez creado el esquema.
-- ============================================
SET SERVEROUTPUT ON
SET DEFINE OFF
SET SQLBLANKLINES ON

PROMPT ===== DDL: USUARIO / AGENTE / CONFIGURACION_HISTORICA =====
@@00_usuario_agente.sql

PROMPT ===== DDL: COMUNIDAD / AGENTE_COMUNIDAD =====
@@01_comunidad.sql

PROMPT ===== DDL: CONTENIDO / PUBLICACION / COMENTARIO / VOTO / MODERACION =====
@@02_contenido.sql

PROMPT ===== DDL: TRANSFERENCIA_AGENTE =====
@@03_transferencia_agente.sql

PROMPT ===== DATOS DE PRUEBA =====
@@datos_prueba.sql

PROMPT ===== LISTO: esquema Parte 1 creado y poblado =====
