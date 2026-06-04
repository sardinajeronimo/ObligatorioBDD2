-- ============================================
-- PROCEDIMIENTO: sp_moderar_contenido
-- Parte 2 — Req 2.6: Moderar contenido en comunidad
-- Responsable: Jeronimo
-- ============================================
-- Permite a un agente MODERADOR registrar una acción de moderación
-- sobre un contenido dentro de una comunidad de la que es miembro.
--
-- Parámetros:
--   p_id_agente      FK al agente que modera
--   p_id_contenido   FK al contenido a moderar
--   p_id_comunidad   FK a la comunidad donde se modera
--   p_tipo_accion    Tipo de acción de moderación (ej: 'eliminar', 'cerrar', etc.)
--
-- Errores de aplicación:
--   -20001  El agente no existe
--   -20002  El agente está suspendido
--   -20003  El agente no es de tipo MODERADOR
--   -20004  El agente no es miembro de la comunidad
--   -20005  El contenido no existe
-- ============================================

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
    v_existe_contenido NUMBER;
BEGIN
    -- 1. Validar que el agente exista y obtener su estado y tipo
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

    -- 2. Validar que el agente esté Activo
    IF v_estado_agente <> 'Activo' THEN
        RAISE_APPLICATION_ERROR(-20002,
            'El agente con id ' || p_id_agente ||
            ' está suspendido (estado: ' || v_estado_agente || ').');
    END IF;

    -- 3. Validar que el agente sea MODERADOR
    IF v_tipo_agente <> 'MODERADOR' THEN
        RAISE_APPLICATION_ERROR(-20003,
            'El agente con id ' || p_id_agente ||
            ' no es de tipo MODERADOR (tipo actual: ' || v_tipo_agente || ').');
    END IF;

    -- 4. Validar que el agente sea miembro de la comunidad
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

    -- 5. Validar que el contenido exista
    SELECT COUNT(*)
      INTO v_existe_contenido
      FROM CONTENIDO
     WHERE id_contenido = p_id_contenido;

    IF v_existe_contenido = 0 THEN
        RAISE_APPLICATION_ERROR(-20005,
            'El contenido con id ' || p_id_contenido || ' no existe.');
    END IF;

    -- 6. Registrar la acción de moderación
    INSERT INTO MODERACION (id_agente, id_contenido, id_comunidad, tipo_accion, fecha_hora)
    VALUES (p_id_agente, p_id_contenido, p_id_comunidad, p_tipo_accion, SYSDATE);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_moderar_contenido;
/
