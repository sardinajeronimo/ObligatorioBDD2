
CREATE OR REPLACE PROCEDURE sp_comentar(
    p_id_agente           IN NUMBER,
    p_id_publicacion      IN NUMBER,
    p_contenido           IN CLOB,
    p_id_comentario_padre IN NUMBER DEFAULT NULL,
    p_id_contenido_out    OUT NUMBER
) AS
    v_estado_agente AGENTE.estado%TYPE;
    v_tipo_agente   AGENTE.tipo%TYPE;
    v_estado_pub    PUBLICACION.estado%TYPE;
    v_id_comunidad  PUBLICACION.id_comunidad%TYPE;
    v_es_miembro    NUMBER;
    v_pub_padre     COMENTARIO.id_publicacion%TYPE;
BEGIN
    BEGIN
        SELECT estado, tipo INTO v_estado_agente, v_tipo_agente
          FROM AGENTE WHERE id_agente = p_id_agente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20030, 'El agente ' || p_id_agente || ' no existe.');
    END;

    IF v_estado_agente <> 'Activo' THEN
        RAISE_APPLICATION_ERROR(-20031,
            'El agente ' || p_id_agente || ' no está Activo (estado: ' || v_estado_agente || ').');
    END IF;

    IF v_tipo_agente <> 'GENERADOR' THEN
        RAISE_APPLICATION_ERROR(-20032,
            'El agente ' || p_id_agente || ' no es GENERADOR (tipo: ' || v_tipo_agente || ').');
    END IF;

    BEGIN
        SELECT estado, id_comunidad INTO v_estado_pub, v_id_comunidad
          FROM PUBLICACION WHERE id_contenido = p_id_publicacion;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20033, 'La publicación ' || p_id_publicacion || ' no existe.');
    END;

    IF v_estado_pub <> 'Activa' THEN
        RAISE_APPLICATION_ERROR(-20034,
            'La publicación ' || p_id_publicacion ||
            ' no admite comentarios (estado: ' || v_estado_pub || ').');
    END IF;

    SELECT COUNT(*) INTO v_es_miembro
      FROM AGENTE_COMUNIDAD
     WHERE id_agente = p_id_agente
       AND id_comunidad = v_id_comunidad
       AND tipo_participacion = 'miembro';

    IF v_es_miembro = 0 THEN
        RAISE_APPLICATION_ERROR(-20035,
            'El agente ' || p_id_agente || ' no es miembro de la comunidad ' || v_id_comunidad || '.');
    END IF;

    IF p_id_comentario_padre IS NOT NULL THEN
        BEGIN
            SELECT id_publicacion INTO v_pub_padre
              FROM COMENTARIO WHERE id_contenido = p_id_comentario_padre;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20036,
                    'El comentario padre ' || p_id_comentario_padre || ' no existe.');
        END;

        IF v_pub_padre <> p_id_publicacion THEN
            RAISE_APPLICATION_ERROR(-20036,
                'El comentario padre ' || p_id_comentario_padre ||
                ' no pertenece a la publicación ' || p_id_publicacion || '.');
        END IF;
    END IF;

    INSERT INTO CONTENIDO (id_agente)
    VALUES (p_id_agente)
    RETURNING id_contenido INTO p_id_contenido_out;

    INSERT INTO COMENTARIO (id_contenido, id_publicacion, id_comentario_padre, contenido)
    VALUES (p_id_contenido_out, p_id_publicacion, p_id_comentario_padre, p_contenido);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Comentario creado. id_contenido: ' || p_id_contenido_out);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_comentar;
/
