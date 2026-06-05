-- ============================================
-- Trigger : trg_no_comentar_publicacion_cerrada
-- Tabla   : COMENTARIO
-- Propósito: Bloquear comentarios en publicaciones con estado 'Cerrada' o 'Eliminada'.
-- ============================================
CREATE OR REPLACE TRIGGER trg_no_comentar_publicacion_cerrada
    BEFORE INSERT ON COMENTARIO
    FOR EACH ROW
DECLARE
    v_estado PUBLICACION.estado%TYPE;
BEGIN
    SELECT estado
      INTO v_estado
      FROM PUBLICACION
     WHERE id_contenido = :NEW.id_publicacion;

    IF v_estado IN ('Cerrada', 'Eliminada') THEN
        RAISE_APPLICATION_ERROR(-20105,
            'La publicación está ' || v_estado || ' y no admite nuevos comentarios.');
    END IF;
END trg_no_comentar_publicacion_cerrada;
/
