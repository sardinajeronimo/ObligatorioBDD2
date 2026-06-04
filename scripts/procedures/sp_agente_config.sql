-- ============================================
-- PROCEDIMIENTO: Registrar nuevo agente
-- Requerimiento: 2.1 (OBLIGATORIO)
-- Responsable: Jero
-- ============================================

CREATE OR REPLACE PROCEDURE sp_registrar_agente(
    p_nombre VARCHAR2,
    p_identificador VARCHAR2,
    p_descripcion CLOB,
    p_prompt CLOB,
    p_tipo_agente VARCHAR2,  -- 'generador', 'moderador', 'observador'
    p_configuracion VARCHAR2, -- 'Simple' o 'Compuesta'
    p_id_usuario_admin NUMBER,
    p_id_agente_out OUT NUMBER
) AS
    v_existe_identificador NUMBER;
    v_usuario_existe NUMBER;
BEGIN
    -- Validar que usuario existe y está activo
    SELECT COUNT(*) INTO v_usuario_existe
    FROM USUARIO
    WHERE id_usuario = p_id_usuario_admin AND estado = 'Activo';

    IF v_usuario_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Usuario no existe o está suspendido');
    END IF;

    -- Validar identificador único
    SELECT COUNT(*) INTO v_existe_identificador
    FROM AGENTE
    WHERE identificador = p_identificador;

    IF v_existe_identificador > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'El identificador ya existe');
    END IF;

    -- Validar tipo agente
    IF p_tipo_agente NOT IN ('generador', 'moderador', 'observador') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Tipo de agente inválido');
    END IF;

    -- Insertar agente
    INSERT INTO AGENTE (
        nombre,
        identificador,
        descripcion,
        prompt,
        configuracion,
        id_usuario_admin
    ) VALUES (
        p_nombre,
        p_identificador,
        p_descripcion,
        p_prompt,
        p_configuracion,
        p_id_usuario_admin
    ) RETURNING id_agente INTO p_id_agente_out;

    -- Crear primera configuración histórica (versión 1)
    INSERT INTO CONFIGURACION_HISTORICA (
        id_agente,
        version,
        descripcion_cambio,
        prompt_historico,
        configuracion_historica
    ) VALUES (
        p_id_agente_out,
        1,
        'Configuración inicial - Tipo: ' || p_tipo_agente,
        p_prompt,
        p_configuracion
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Agente creado exitosamente. ID: ' || p_id_agente_out);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
-- ============================================
-- PROCEDIMIENTO: Actualizar configuración agente
-- Requerimiento: 2.7
-- Responsable: Jero
-- ============================================

CREATE OR REPLACE PROCEDURE sp_actualizar_config_agente(
    p_id_agente NUMBER,
    p_descripcion_cambio CLOB,
    p_nuevo_prompt CLOB DEFAULT NULL,
    p_nueva_config VARCHAR2 DEFAULT NULL
) AS
    v_agente_existe NUMBER;
    v_ultima_version NUMBER;
    v_prompt_actual CLOB;
    v_config_actual VARCHAR2(20);
BEGIN
    -- Validar que agente existe
    SELECT COUNT(*) INTO v_agente_existe
    FROM AGENTE
    WHERE id_agente = p_id_agente;

    IF v_agente_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Agente no existe');
    END IF;

    -- Obtener configuración actual
    SELECT prompt, configuracion
    INTO v_prompt_actual, v_config_actual
    FROM AGENTE
    WHERE id_agente = p_id_agente;

    -- Obtener última versión
    SELECT NVL(MAX(version), 0) INTO v_ultima_version
    FROM CONFIGURACION_HISTORICA
    WHERE id_agente = p_id_agente;

    -- Registrar nueva versión histórica
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

    -- Actualizar agente solo si hay cambios
    IF p_nuevo_prompt IS NOT NULL OR p_nueva_config IS NOT NULL THEN
        UPDATE AGENTE
        SET prompt = NVL(p_nuevo_prompt, prompt),
            configuracion = NVL(p_nueva_config, configuracion)
        WHERE id_agente = p_id_agente;
    END IF;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Configuración actualizada. Nueva versión: ' || (v_ultima_version + 1));

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
