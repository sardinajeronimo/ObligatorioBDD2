
CREATE OR REPLACE PROCEDURE sp_transferir_administracion (
    p_id_agente        IN NUMBER,
    p_id_usuario_nuevo IN NUMBER
)
AS
    v_admin_actual    AGENTE.id_usuario_admin%TYPE;
    v_estado_usuario  USUARIO.estado%TYPE;
BEGIN
    BEGIN
        SELECT id_usuario_admin
          INTO v_admin_actual
          FROM AGENTE
         WHERE id_agente = p_id_agente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010,
                'El agente con id ' || p_id_agente || ' no existe.');
    END;

    BEGIN
        SELECT estado
          INTO v_estado_usuario
          FROM USUARIO
         WHERE id_usuario = p_id_usuario_nuevo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20011,
                'El usuario con id ' || p_id_usuario_nuevo || ' no existe.');
    END;

    IF v_estado_usuario <> 'Activo' THEN
        RAISE_APPLICATION_ERROR(-20011,
            'El usuario con id ' || p_id_usuario_nuevo ||
            ' no está Activo (estado actual: ' || v_estado_usuario || ').');
    END IF;

    IF v_admin_actual = p_id_usuario_nuevo THEN
        RAISE_APPLICATION_ERROR(-20012,
            'El usuario con id ' || p_id_usuario_nuevo ||
            ' ya es el administrador actual del agente ' || p_id_agente || '.');
    END IF;

    INSERT INTO TRANSFERENCIA_AGENTE (
        id_agente,
        id_usuario_anterior,
        id_usuario_nuevo,
        fecha_transferencia
    ) VALUES (
        p_id_agente,
        v_admin_actual,
        p_id_usuario_nuevo,
        SYSDATE
    );

    UPDATE AGENTE
       SET id_usuario_admin = p_id_usuario_nuevo
     WHERE id_agente = p_id_agente;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_transferir_administracion;
/
