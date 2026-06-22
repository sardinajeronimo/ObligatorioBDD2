
CREATE OR REPLACE PROCEDURE sp_publicar(
    p_id_agente             IN NUMBER,
    p_id_comunidad          IN NUMBER,
    p_titulo                IN VARCHAR2,
    p_contenido             IN CLOB,
    p_id_publicacion_citada IN NUMBER DEFAULT NULL,
    p_id_contenido_out      OUT NUMBER
) AS
    v_estado_agente   AGENTE.estado%TYPE;
    v_tipo_agente     AGENTE.tipo%TYPE;
    v_estado_comunidad COMUNIDAD.estado%TYPE;
    v_es_miembro      NUMBER;
    v_cantidad          NUMBER;
BEGIN
    BEGIN
        SELECT estado, tipo INTO v_estado_agente, v_tipo_agente
          FROM AGENTE WHERE id_agente = p_id_agente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20020, 'El agente ' || p_id_agente || ' no existe.');
    END;

    IF v_estado_agente <> 'Activo' THEN
        RAISE_APPLICATION_ERROR(-20021,
            'El agente ' || p_id_agente || ' no está Activo (estado: ' || v_estado_agente || ').');
    END IF;

    IF v_tipo_agente <> 'GENERADOR' THEN
        RAISE_APPLICATION_ERROR(-20022,
            'El agente ' || p_id_agente || ' no es GENERADOR (tipo: ' || v_tipo_agente || ').');
    END IF;

    BEGIN
        SELECT estado INTO v_estado_comunidad
          FROM COMUNIDAD WHERE id_comunidad = p_id_comunidad;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20023, 'La comunidad ' || p_id_comunidad || ' no existe.');
    END;

    IF v_estado_comunidad = 'Archivada' THEN
        RAISE_APPLICATION_ERROR(-20024,
            'La comunidad ' || p_id_comunidad || ' está archivada: no admite nuevas publicaciones.');
    END IF;

    SELECT COUNT(*) INTO v_es_miembro
      FROM AGENTE_COMUNIDAD
     WHERE id_agente = p_id_agente
       AND id_comunidad = p_id_comunidad
       AND tipo_participacion = 'miembro';

    IF v_es_miembro = 0 THEN
        RAISE_APPLICATION_ERROR(-20025,
            'El agente ' || p_id_agente || ' no es miembro de la comunidad ' || p_id_comunidad || '.');
    END IF;

    IF p_contenido IS NULL OR TRIM(TO_CHAR(p_contenido)) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20027,
            'El contenido de la publicación no puede estar vacío.');
    END IF;

    IF p_id_publicacion_citada IS NOT NULL THEN
        SELECT COUNT(*) INTO v_cantidad
          FROM PUBLICACION WHERE id_contenido = p_id_publicacion_citada;
        IF v_cantidad = 0 THEN
            RAISE_APPLICATION_ERROR(-20026,
                'La publicación citada ' || p_id_publicacion_citada || ' no existe.');
        END IF;
    END IF;

    INSERT INTO CONTENIDO (id_agente)
    VALUES (p_id_agente)
    RETURNING id_contenido INTO p_id_contenido_out;

    INSERT INTO PUBLICACION (
        id_contenido, id_comunidad, titulo, contenido,
        id_publicacion_citada, fecha_cita
    ) VALUES (
        p_id_contenido_out, p_id_comunidad, p_titulo, p_contenido,
        p_id_publicacion_citada,
        CASE WHEN p_id_publicacion_citada IS NULL THEN NULL ELSE SYSDATE END
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Publicación creada. id_contenido: ' || p_id_contenido_out);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_publicar;
/
