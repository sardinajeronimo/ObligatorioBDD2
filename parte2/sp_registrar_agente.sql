
CREATE OR REPLACE PROCEDURE sp_registrar_agente (
    p_nombre             IN VARCHAR2,
    p_identificador      IN VARCHAR2,
    p_descripcion        IN CLOB,
    p_prompt             IN CLOB,
    p_tipo               IN VARCHAR2,
    p_configuracion      IN VARCHAR2,
    p_id_usuario_admin   IN NUMBER,
    p_descripcion_config IN CLOB
)
AS
    v_estado_usuario  USUARIO.estado%TYPE;
    v_id_agente       AGENTE.id_agente%TYPE;
BEGIN
    BEGIN
        SELECT estado
          INTO v_estado_usuario
          FROM USUARIO
         WHERE id_usuario = p_id_usuario_admin;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,
                'El usuario administrador con id ' || p_id_usuario_admin || ' no existe.');
    END;

    IF v_estado_usuario <> 'Activo' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'El usuario administrador con id ' || p_id_usuario_admin ||
            ' no está Activo (estado actual: ' || v_estado_usuario || ').');
    END IF;

    IF p_tipo NOT IN ('GENERADOR', 'MODERADOR', 'OBSERVADOR') THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Tipo de agente inválido: "' || p_tipo ||
            '". Valores: GENERADOR | MODERADOR | OBSERVADOR.');
    END IF;

    INSERT INTO AGENTE (
        nombre,
        identificador,
        descripcion,
        prompt,
        tipo,
        configuracion,
        estado,
        fecha_creacion,
        id_usuario_admin
    ) VALUES (
        p_nombre,
        p_identificador,
        p_descripcion,
        p_prompt,
        p_tipo,
        p_configuracion,
        'Activo',
        SYSDATE,
        p_id_usuario_admin
    )
    RETURNING id_agente INTO v_id_agente;

    INSERT INTO CONFIGURACION_HISTORICA (
        id_agente,
        version,
        fecha_aplicacion,
        descripcion_cambio,
        prompt_historico,
        configuracion_historica
    ) VALUES (
        v_id_agente,
        1,
        SYSDATE,
        p_descripcion_config,
        p_prompt,
        p_configuracion
    );

    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002,
            'El identificador de agente "' || p_identificador || '" ya está registrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_registrar_agente;
/
