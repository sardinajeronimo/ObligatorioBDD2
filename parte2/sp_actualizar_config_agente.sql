-- ============================================
-- PROCEDIMIENTO: sp_actualizar_config_agente
-- Parte 2 — Req 2.7: Iniciar/actualizar la configuración de un agente
-- Responsable: Jero
-- ============================================
-- Registra una nueva versión en CONFIGURACION_HISTORICA (versión = última + 1,
-- con su fecha de aplicación por DEFAULT y la descripción del cambio) y
-- actualiza la configuración activa del agente (prompt y/o configuracion).
--
-- Parámetros:
--   p_id_agente          Agente a actualizar
--   p_descripcion_cambio Descripción del cambio para el historial
--   p_nuevo_prompt       Nuevo prompt (NULL = conserva el actual)
--   p_nueva_config       Nueva configuración (NULL = conserva la actual)
--
-- Errores de aplicación:
--   -20004  El agente no existe
-- ============================================

CREATE OR REPLACE PROCEDURE sp_actualizar_config_agente(
    p_id_agente          NUMBER,
    p_descripcion_cambio CLOB,
    p_nuevo_prompt       CLOB DEFAULT NULL,
    p_nueva_config       VARCHAR2 DEFAULT NULL
) AS
    v_ultima_version  NUMBER;
    v_prompt_actual   AGENTE.prompt%TYPE;
    v_config_actual   AGENTE.configuracion%TYPE;
BEGIN
    -- 1. Validar que el agente exista y obtener su configuración actual
    BEGIN
        SELECT prompt, configuracion
          INTO v_prompt_actual, v_config_actual
          FROM AGENTE
         WHERE id_agente = p_id_agente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004,
                'El agente con id ' || p_id_agente || ' no existe.');
    END;

    -- 2. Determinar la próxima versión del historial
    SELECT NVL(MAX(version), 0) INTO v_ultima_version
      FROM CONFIGURACION_HISTORICA
     WHERE id_agente = p_id_agente;

    -- 3. Registrar la nueva versión histórica (fecha_aplicacion por DEFAULT)
    INSERT INTO CONFIGURACION_HISTORICA (
        id_agente,
        version,
        descripcion_cambio,
        prompt_historico,
        configuracion_historica
    ) VALUES (
        p_id_agente,
        v_ultima_version + 1,
        p_descripcion_cambio,
        NVL(p_nuevo_prompt, v_prompt_actual),
        NVL(p_nueva_config, v_config_actual)
    );

    -- 4. Actualizar la configuración activa del agente si hubo cambios
    IF p_nuevo_prompt IS NOT NULL OR p_nueva_config IS NOT NULL THEN
        UPDATE AGENTE
           SET prompt        = NVL(p_nuevo_prompt, prompt),
               configuracion = NVL(p_nueva_config, configuracion)
         WHERE id_agente = p_id_agente;
    END IF;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Configuración actualizada. Nueva versión: ' || (v_ultima_version + 1));

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_actualizar_config_agente;
/
