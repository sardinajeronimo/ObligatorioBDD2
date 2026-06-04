-- ============================================
-- PROCEDIMIENTO: sp_comentar
-- Parte 2 — Req 2.5: Comentar una publicación o responder a otro comentario
-- Responsable: Renzo
-- ============================================
-- Un agente GENERADOR, miembro de la comunidad de la publicación, crea un
-- comentario. Puede responder directamente a la publicación o a un comentario
-- previo (hilo jerárquico). Inserta CONTENIDO (supertipo) y luego COMENTARIO.
--
-- La publicación no debe estar 'Cerrada' ni 'Eliminada' (no admite comentarios).
--
-- Parámetros:
--   p_id_agente           Agente autor (GENERADOR, Activo, miembro de la comunidad)
--   p_id_publicacion      Publicación comentada (id_contenido de la publicación)
--   p_contenido           Cuerpo del comentario (no vacío)
--   p_id_comentario_padre Comentario al que responde (opcional; NULL = a la publicación)
--   p_id_contenido_out    OUT: id_contenido del comentario creado
--
-- Errores de aplicación:
--   -20030  El agente no existe
--   -20031  El agente no está Activo
--   -20032  El agente no es de tipo GENERADOR
--   -20033  La publicación no existe
--   -20034  La publicación no admite comentarios (Cerrada o Eliminada)
--   -20035  El agente no es miembro de la comunidad de la publicación
--   -20036  El comentario padre no existe o no pertenece a esa publicación
-- ============================================

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
    -- 1. Agente: existe, Activo y GENERADOR
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

    -- 2. Publicación: existe; tomar estado y comunidad
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

    -- 3. Agente miembro de la comunidad de la publicación
    SELECT COUNT(*) INTO v_es_miembro
      FROM AGENTE_COMUNIDAD
     WHERE id_agente = p_id_agente
       AND id_comunidad = v_id_comunidad
       AND tipo_participacion = 'miembro';

    IF v_es_miembro = 0 THEN
        RAISE_APPLICATION_ERROR(-20035,
            'El agente ' || p_id_agente || ' no es miembro de la comunidad ' || v_id_comunidad || '.');
    END IF;

    -- 4. Si responde a un comentario, debe existir y ser de la misma publicación
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

    -- 5. Insertar CONTENIDO (supertipo) y obtener el id generado
    INSERT INTO CONTENIDO (id_agente)
    VALUES (p_id_agente)
    RETURNING id_contenido INTO p_id_contenido_out;

    -- 6. Insertar COMENTARIO (subtipo)
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
