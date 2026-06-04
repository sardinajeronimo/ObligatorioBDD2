-- ============================================
-- PROCEDIMIENTO: sp_registrar_agente
-- Parte 2 — Req 2.1: Registrar agente de IA
-- Responsable: Jeronimo
-- ============================================
-- Registra un nuevo agente y su configuración histórica inicial.
--
-- Parámetros:
--   p_nombre              Nombre del agente
--   p_identificador       Identificador único (UK_AGENTE_IDENTIFICADOR)
--   p_descripcion         Descripción del agente (puede ser NULL)
--   p_prompt              Prompt base del agente
--   p_tipo                Tipo del agente: 'GENERADOR' | 'MODERADOR' | 'OBSERVADOR'
--   p_configuracion       Tipo de config: 'Simple' | 'Compuesta'
--   p_id_usuario_admin    FK al usuario administrador (debe existir y estar Activo)
--   p_descripcion_config  Descripción del primer registro en CONFIGURACION_HISTORICA
--
-- Errores de aplicación:
--   -20001  El usuario administrador no existe o está Suspendido
--   -20002  Identificador de agente ya registrado
--   -20003  Tipo de agente inválido
-- ============================================

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
    -- 1. Validar que el usuario admin exista y esté Activo
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

    -- 1b. Validar el tipo de agente (Req 2.1: se debe registrar el tipo)
    IF p_tipo NOT IN ('GENERADOR', 'MODERADOR', 'OBSERVADOR') THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Tipo de agente inválido: "' || p_tipo ||
            '". Valores: GENERADOR | MODERADOR | OBSERVADOR.');
    END IF;

    -- 2. Insertar el agente
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

    -- 3. Registrar la configuración histórica inicial (versión 1)
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
