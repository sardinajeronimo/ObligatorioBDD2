-- ============================================
-- PROCEDIMIENTO: sp_publicar
-- Parte 2 — Req 2.3 (OBLIGATORIO): Generar una publicación en una comunidad
-- Responsable: Renzo
-- ============================================
-- Un agente GENERADOR, miembro activo de una comunidad NO archivada, crea una
-- publicación. Inserta primero el CONTENIDO (supertipo) y luego la PUBLICACION
-- (subtipo) reusando el id_contenido. Opcionalmente cita a otra publicación.
--
-- Parámetros:
--   p_id_agente             Agente autor (GENERADOR, Activo, miembro de la comunidad)
--   p_id_comunidad          Comunidad donde se publica (debe estar Activa)
--   p_titulo                Título de la publicación (no vacío)
--   p_contenido             Cuerpo de la publicación (no vacío)
--   p_id_publicacion_citada Publicación citada (opcional; NULL = sin cita)
--   p_id_contenido_out      OUT: id_contenido de la publicación creada
--
-- Errores de aplicación:
--   -20020  El agente no existe
--   -20021  El agente no está Activo
--   -20022  El agente no es de tipo GENERADOR
--   -20023  La comunidad no existe
--   -20024  La comunidad está archivada (no admite nuevas publicaciones)
--   -20025  El agente no es miembro de la comunidad
--   -20026  La publicación citada no existe
-- ============================================

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
    v_existe          NUMBER;
BEGIN
    -- 1. Agente: existe, Activo y GENERADOR
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

    -- 2. Comunidad: existe y no archivada
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

    -- 3. Agente miembro activo de la comunidad
    SELECT COUNT(*) INTO v_es_miembro
      FROM AGENTE_COMUNIDAD
     WHERE id_agente = p_id_agente
       AND id_comunidad = p_id_comunidad
       AND tipo_participacion = 'miembro';

    IF v_es_miembro = 0 THEN
        RAISE_APPLICATION_ERROR(-20025,
            'El agente ' || p_id_agente || ' no es miembro de la comunidad ' || p_id_comunidad || '.');
    END IF;

    -- 4. Si cita, la publicación citada debe existir
    IF p_id_publicacion_citada IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe
          FROM PUBLICACION WHERE id_contenido = p_id_publicacion_citada;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20026,
                'La publicación citada ' || p_id_publicacion_citada || ' no existe.');
        END IF;
    END IF;

    -- 5. Insertar CONTENIDO (supertipo) y obtener el id generado
    INSERT INTO CONTENIDO (id_agente)
    VALUES (p_id_agente)
    RETURNING id_contenido INTO p_id_contenido_out;

    -- 6. Insertar PUBLICACION (subtipo) con ese id_contenido
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
