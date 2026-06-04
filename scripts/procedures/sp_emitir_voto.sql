-- ============================================
-- PROCEDIMIENTO: sp_emitir_voto
-- Parte 2 — Req 2.4: Emitir voto sobre una publicación
-- Responsable: Jero
-- ============================================
-- Registra un voto (positivo/negativo) de un agente sobre una publicación
-- y actualiza el puntaje_total de la publicación (+1 positivo, -1 negativo).
--
-- Esquema: VOTO referencia PUBLICACION por su PK id_contenido
--          (PUBLICACION es subtipo de CONTENIDO, ver scripts/ddl/02_contenido.sql).
--
-- Parámetros:
--   p_id_agente      Agente que vota (debe existir y estar Activo)
--   p_id_publicacion PK de la publicación (= CONTENIDO.id_contenido)
--   p_tipo           'positivo' | 'negativo'
--
-- Errores de aplicación:
--   -20010  El agente no existe
--   -20011  El agente no está Activo
--   -20012  La publicación no existe
--   -20013  Tipo de voto inválido
--   -20014  El agente ya votó esa publicación
-- ============================================

CREATE OR REPLACE PROCEDURE sp_emitir_voto(
    p_id_agente      NUMBER,
    p_id_publicacion NUMBER,
    p_tipo           VARCHAR2   -- 'positivo' o 'negativo'
) AS
    v_estado_agente AGENTE.estado%TYPE;
    v_existe        NUMBER;
    v_delta         NUMBER;
BEGIN
    -- Validar tipo de voto antes de ir a la BD
    IF p_tipo NOT IN ('positivo', 'negativo') THEN
        RAISE_APPLICATION_ERROR(-20013, 'Tipo de voto invalido. Usar: positivo o negativo');
    END IF;

    -- Validar que el agente exista y esté Activo
    BEGIN
        SELECT estado INTO v_estado_agente
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

    -- Validar que la publicación exista
    SELECT COUNT(*) INTO v_existe
      FROM PUBLICACION
     WHERE id_contenido = p_id_publicacion;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Publicacion ' || p_id_publicacion || ' no existe');
    END IF;

    -- Validar voto duplicado (un agente vota a lo sumo una vez la misma publicación)
    SELECT COUNT(*) INTO v_existe
      FROM VOTO
     WHERE id_agente = p_id_agente AND id_publicacion = p_id_publicacion;

    IF v_existe > 0 THEN
        RAISE_APPLICATION_ERROR(-20014,
            'Agente ' || p_id_agente || ' ya voto en la publicacion ' || p_id_publicacion);
    END IF;

    -- Insertar voto
    INSERT INTO VOTO (id_agente, id_publicacion, tipo, fecha_hora)
    VALUES (p_id_agente, p_id_publicacion, p_tipo, SYSDATE);

    -- Actualizar puntaje_total (+1 positivo, -1 negativo)
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

-- ============================================
-- Ejemplo de uso (requiere datos de prueba cargados):
--   SET SERVEROUTPUT ON;
--   BEGIN sp_emitir_voto(1, 1, 'positivo'); END;
--   /
-- ============================================
