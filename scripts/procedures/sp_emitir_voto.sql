-- ============================================
-- PROCEDIMIENTO: Emitir voto en publicación
-- Requerimiento: 2.x
-- Responsable: Jero
-- ============================================

CREATE OR REPLACE PROCEDURE sp_emitir_voto(
    p_id_agente      NUMBER,
    p_id_publicacion NUMBER,
    p_tipo_voto      VARCHAR2   -- 'Positivo' o 'Negativo'
) AS
    v_estado_agente VARCHAR2(20);
    v_existe        NUMBER;
    v_delta         NUMBER;
BEGIN
    -- Validar tipo de voto antes de ir a la BD
    IF p_tipo_voto NOT IN ('Positivo', 'Negativo') THEN
        RAISE_APPLICATION_ERROR(-20013, 'Tipo de voto invalido. Usar: Positivo o Negativo');
    END IF;

    -- Validar agente existe y está activo (un solo SELECT)
    BEGIN
        SELECT estado INTO v_estado_agente
        FROM AGENTE
        WHERE id_agente = p_id_agente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Agente ' || p_id_agente || ' no existe');
    END;

    IF v_estado_agente != 'Activo' THEN
        RAISE_APPLICATION_ERROR(-20011, 'Agente ' || p_id_agente || ' no esta activo (estado: ' || v_estado_agente || ')');
    END IF;

    -- Validar publicación existe
    SELECT COUNT(*) INTO v_existe
    FROM PUBLICACION
    WHERE id_publicacion = p_id_publicacion;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Publicacion ' || p_id_publicacion || ' no existe');
    END IF;

    -- Validar voto duplicado
    SELECT COUNT(*) INTO v_existe
    FROM VOTO
    WHERE id_agente = p_id_agente AND id_publicacion = p_id_publicacion;

    IF v_existe > 0 THEN
        RAISE_APPLICATION_ERROR(-20014,
            'Agente ' || p_id_agente || ' ya voto en la publicacion ' || p_id_publicacion);
    END IF;

    -- Insertar voto
    INSERT INTO VOTO (id_agente, id_publicacion, tipo_voto, fecha_voto)
    VALUES (p_id_agente, p_id_publicacion, p_tipo_voto, SYSDATE);

    -- Actualizar puntaje_total (+1 Positivo, -1 Negativo)
    v_delta := CASE p_tipo_voto WHEN 'Positivo' THEN 1 ELSE -1 END;

    UPDATE PUBLICACION
    SET puntaje_total = puntaje_total + v_delta
    WHERE id_publicacion = p_id_publicacion;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Voto ' || p_tipo_voto || ' registrado. Agente: ' || p_id_agente ||
        ' | Publicacion: ' || p_id_publicacion
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_emitir_voto;
/


-- ============================================
-- TESTING
-- ============================================

SET SERVEROUTPUT ON;

-- Caso exitoso: voto positivo
BEGIN
    sp_emitir_voto(1, 1, 'Positivo');
END;
/

-- Error esperado: voto duplicado (ORA-20014)
BEGIN
    sp_emitir_voto(1, 1, 'Negativo');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ERROR esperado: ' || SQLERRM);
END;
/

-- Error esperado: agente inexistente (ORA-20010)
BEGIN
    sp_emitir_voto(9999, 1, 'Positivo');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ERROR esperado: ' || SQLERRM);
END;
/

-- Error esperado: tipo inválido (ORA-20013)
BEGIN
    sp_emitir_voto(1, 2, 'Neutral');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ERROR esperado: ' || SQLERRM);
END;
/

-- Verificar resultado
SELECT id_publicacion, puntaje_total FROM PUBLICACION WHERE id_publicacion = 1;
SELECT * FROM VOTO WHERE id_agente = 1 AND id_publicacion = 1;
