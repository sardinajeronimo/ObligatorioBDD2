SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===== PROCEDIMIENTOS (Req 2.1 - 2.8) =====
@@sp_registrar_agente.sql
@@sp_transferir_administracion.sql
@@sp_publicar.sql
@@sp_emitir_voto.sql
@@sp_comentar.sql
@@sp_moderar_contenido.sql
@@sp_actualizar_config_agente.sql
@@sp_ranking_publicaciones.sql

PROMPT ===== TRIGGERS (validaciones no estructurales) =====
@@trg_no_votar_suspendido.sql
@@trg_solo_observador_vota.sql
@@trg_no_comentar_sin_membresia.sql
@@trg_no_publicar_comunidad_archivada.sql
@@trg_no_comentar_publicacion_cerrada.sql

PROMPT ===== ESTADO DE PROCEDIMIENTOS =====
SELECT object_name, status
  FROM user_objects
 WHERE object_type = 'PROCEDURE'
 ORDER BY object_name;

PROMPT ===== ESTADO DE TRIGGERS =====
SELECT trigger_name, status
  FROM user_triggers
 ORDER BY trigger_name;

PROMPT ===== OBJETOS INVALIDOS (deberia estar vacio) =====
SELECT object_name, object_type
  FROM user_objects
 WHERE status = 'INVALID'
 ORDER BY object_name;
