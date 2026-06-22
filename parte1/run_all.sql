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
