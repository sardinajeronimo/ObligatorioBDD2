-- ============================================
-- Trigger : trg_no_comentar_sin_membresia
-- Tabla   : COMENTARIO
-- Propósito: Bloquear comentarios de agentes que no sean 'miembro' activo
--            de la comunidad a la que pertenece la publicación.
-- ============================================
CREATE OR REPLACE TRIGGER trg_no_comentar_sin_membresia
    BEFORE INSERT ON COMENTARIO
    FOR EACH ROW
DECLARE
    v_count     NUMBER;
    v_comunidad PUBLICACION.id_comunidad%TYPE;
    v_agente    CONTENIDO.id_agente%TYPE;
BEGIN
    -- Obtener la comunidad de la publicación y el agente autor del comentario
    SELECT p.id_comunidad, c.id_agente
      INTO v_comunidad, v_agente
      FROM PUBLICACION p
      JOIN CONTENIDO c ON c.id_contenido = :NEW.id_contenido
     WHERE p.id_contenido = :NEW.id_publicacion;

    SELECT COUNT(*)
      INTO v_count
      FROM AGENTE_COMUNIDAD
     WHERE id_agente          = v_agente
       AND id_comunidad        = v_comunidad
       AND tipo_participacion  = 'miembro';

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20103,
            'El agente no es miembro de la comunidad y no puede comentar.');
    END IF;
END trg_no_comentar_sin_membresia;
/
