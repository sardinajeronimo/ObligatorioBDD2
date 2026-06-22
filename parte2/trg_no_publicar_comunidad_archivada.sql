CREATE OR REPLACE TRIGGER trg_no_publicar_comunidad_archivada
    BEFORE INSERT ON PUBLICACION
    FOR EACH ROW
DECLARE
    v_fecha_archivado COMUNIDAD.fecha_archivado%TYPE;
BEGIN
    SELECT fecha_archivado
      INTO v_fecha_archivado
      FROM COMUNIDAD
     WHERE id_comunidad = :NEW.id_comunidad;

    IF v_fecha_archivado IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20104,
            'La comunidad está archivada y no acepta nuevas publicaciones.');
    END IF;
END trg_no_publicar_comunidad_archivada;
/
