
CREATE OR REPLACE PROCEDURE sp_emitir_voto(
    p_id_agente      NUMBER,
    p_id_publicacion NUMBER,
    p_tipo           VARCHAR2
) AS
    v_estado_agente AGENTE.estado%TYPE;
    v_tipo_agente   AGENTE.tipo%TYPE;
    v_cantidad      NUMBER;
    v_delta         NUMBER;
BEGIN
    IF p_tipo NOT IN ('positivo', 'negativo') THEN
        RAISE_APPLICATION_ERROR(-20013, 'Tipo de voto invalido. Usar: positivo o negativo');
    END IF;

    BEGIN
        SELECT estado, tipo INTO v_estado_agente, v_tipo_agente
          FROM AGENTE
         WHERE id_agente = p_id_agente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Agente ' || p_id_agente || ' no existe');
    END;

    IF v_estado_agente <> 'Activo' THEN
        RAISE_APPLICATION_ERROR(-20011,
            'Agente ' || p_id_agente || ' no esta activo (estado: ' || v_estado_agente || ')');
    END IF;

    IF v_tipo_agente <> 'OBSERVADOR' THEN
        RAISE_APPLICATION_ERROR(-20015,
            'Agente ' || p_id_agente || ' no es OBSERVADOR (tipo: ' || v_tipo_agente ||
            '); solo los observadores pueden votar');
    END IF;

    SELECT COUNT(*) INTO v_cantidad
      FROM PUBLICACION
     WHERE id_contenido = p_id_publicacion;

    IF v_cantidad = 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Publicacion ' || p_id_publicacion || ' no existe');
    END IF;

    SELECT COUNT(*) INTO v_cantidad
      FROM VOTO
     WHERE id_agente = p_id_agente AND id_publicacion = p_id_publicacion;

    IF v_cantidad > 0 THEN
        RAISE_APPLICATION_ERROR(-20014,
            'Agente ' || p_id_agente || ' ya voto en la publicacion ' || p_id_publicacion);
    END IF;

    INSERT INTO VOTO (id_agente, id_publicacion, tipo, fecha_hora)
    VALUES (p_id_agente, p_id_publicacion, p_tipo, SYSDATE);

    v_delta := CASE p_tipo WHEN 'positivo' THEN 1 ELSE -1 END;

    UPDATE PUBLICACION
       SET puntaje_total = puntaje_total + v_delta
     WHERE id_contenido = p_id_publicacion;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Voto ' || p_tipo || ' registrado. Agente: ' || p_id_agente ||
        ' | Publicacion: ' || p_id_publicacion);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_emitir_voto;
/

