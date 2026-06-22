
CREATE OR REPLACE PROCEDURE sp_moderar_contenido (
    p_id_agente    IN NUMBER,
    p_id_contenido IN NUMBER,
    p_id_comunidad IN NUMBER,
    p_tipo_accion  IN VARCHAR2
)
AS
    v_estado_agente  AGENTE.estado%TYPE;
    v_tipo_agente    AGENTE.tipo%TYPE;
    v_es_miembro     NUMBER;
    v_id_comunidad_contenido  NUMBER;
BEGIN
    BEGIN
        SELECT estado, tipo
          INTO v_estado_agente, v_tipo_agente
          FROM AGENTE
         WHERE id_agente = p_id_agente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,
                'El agente con id ' || p_id_agente || ' no existe.');
    END;

    IF v_estado_agente <> 'Activo' THEN
        RAISE_APPLICATION_ERROR(-20002,
            'El agente con id ' || p_id_agente ||
            ' está suspendido (estado: ' || v_estado_agente || ').');
    END IF;

    IF v_tipo_agente <> 'MODERADOR' THEN
        RAISE_APPLICATION_ERROR(-20003,
            'El agente con id ' || p_id_agente ||
            ' no es de tipo MODERADOR (tipo actual: ' || v_tipo_agente || ').');
    END IF;

    SELECT COUNT(*)
      INTO v_es_miembro
      FROM AGENTE_COMUNIDAD
     WHERE id_agente      = p_id_agente
       AND id_comunidad   = p_id_comunidad
       AND tipo_participacion = 'miembro';

    IF v_es_miembro = 0 THEN
        RAISE_APPLICATION_ERROR(-20004,
            'El agente con id ' || p_id_agente ||
            ' no es miembro de la comunidad con id ' || p_id_comunidad || '.');
    END IF;

    SELECT NVL(
        (SELECT id_comunidad FROM PUBLICACION WHERE id_contenido = p_id_contenido),
        (SELECT p.id_comunidad
           FROM COMENTARIO c
           JOIN PUBLICACION p ON p.id_contenido = c.id_publicacion
          WHERE c.id_contenido = p_id_contenido)
    ) INTO v_id_comunidad_contenido
    FROM dual;

    IF v_id_comunidad_contenido IS NULL THEN
        RAISE_APPLICATION_ERROR(-20005,
            'El contenido con id ' || p_id_contenido || ' no existe.');
    END IF;

    IF v_id_comunidad_contenido <> p_id_comunidad THEN
        RAISE_APPLICATION_ERROR(-20006,
            'El contenido ' || p_id_contenido || ' no pertenece a la comunidad ' ||
            p_id_comunidad || ' (pertenece a la ' || v_id_comunidad_contenido || ').');
    END IF;

    INSERT INTO MODERACION (id_agente, id_contenido, id_comunidad, tipo_accion, fecha_hora)
    VALUES (p_id_agente, p_id_contenido, p_id_comunidad, p_tipo_accion, SYSDATE);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_moderar_contenido;
/
