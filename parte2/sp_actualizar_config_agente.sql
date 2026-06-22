
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

    SELECT NVL(MAX(version), 0) INTO v_ultima_version
      FROM CONFIGURACION_HISTORICA
     WHERE id_agente = p_id_agente;

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
