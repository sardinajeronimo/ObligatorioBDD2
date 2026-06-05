-- Ejecutar desde SQL*Plus conectado a moltbook@localhost:1521/FREEPDB1
-- o abrir cada archivo por separado en SQL Developer / DBeaver.

@trg_no_votar_suspendido.sql
@trg_solo_observador_vota.sql
@trg_no_comentar_sin_membresia.sql
@trg_no_publicar_comunidad_archivada.sql
@trg_no_comentar_publicacion_cerrada.sql

-- Verificar compilación
SELECT trigger_name, status
  FROM user_triggers
 WHERE trigger_name IN (
       'TRG_NO_VOTAR_SUSPENDIDO',
       'TRG_SOLO_OBSERVADOR_VOTA',
       'TRG_NO_COMENTAR_SIN_MEMBRESIA',
       'TRG_NO_PUBLICAR_COMUNIDAD_ARCHIVADA',
       'TRG_NO_COMENTAR_PUBLICACION_CERRADA')
 ORDER BY trigger_name;
