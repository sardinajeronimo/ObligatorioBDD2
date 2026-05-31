CREATE OR REPLACE PROCEDURE sp_publicar_en_comunidad(
    p_id_agente     IN NUMBER,
    p_id_comunidad  IN NUMBER,
    p_titulo        IN VARCHAR2,
    p_contenido     IN CLOB
) AS
    v_estado_agente  VARCHAR2(20);
    v_tipo_agente    VARCHAR2(20);
    v_archivado      DATE;
    v_es_miembro     NUMBER;
    v_id_contenido   NUMBER;
BEGIN
    Begin
	Select estado, tipo
	Into v_estado_agente, v_tipo_agente
	FROM AGENTE
	WHERE id = p_id_agente
    Exception
	When NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20001, 'Agente No Existe')
    End;
  IF v_estado_agente != 'Activo' THEN
	RAISE_APPLICATION_ERROR(-20002, 'Agente suspendido')
  End if;

  IF v_tipo_agente != 'GENERADOR' THEN
	RAISE_APPLICATION_ERROR(-20003, 'El agente no es tipo GENERADOR')
  End IF;


  BEGIN
	SELECT fecha_archivado
	INTO v_fecha_archivado
	FROM comunidad
	WHERE ID= p_id_comunidad;
    Exception
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20004,'Comundiad No Existe')
	END;

   IF v_fecha_archivado IS NOT NULL THEN
	RAISE_APPLICATION_ERROR(-20005, 'Comunidad archivada')
   End if;

Select Count(*)
INTO v_es_miembro
FROM Agente_comunidad
WHERE id_agente = p_id_agente
	AND id_comunidad = p_id_comunidad
      AND tipo_participacion = 'miembro';
IF v_es_miembro = 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'El agente no es miembro de la comunidad');
    END IF;

    -- 5. Contenido no vacío
    IF p_contenido IS NULL OR TRIM(TO_CHAR(p_contenido)) = '' THEN
        RAISE_APPLICATION_ERROR(-20007, 'El contenido no puede ser vacío');
    END IF;

    -- 6. Insertar en CONTENIDO
    INSERT INTO CONTENIDO (fecha_hora_creacion, id_agente)
    VALUES (SYSDATE, p_id_agente)
    RETURNING id INTO v_id_contenido;

    -- 7. Insertar en PUBLICACION
    INSERT INTO PUBLICACION (id_contenido, titulo, contenido, id_comunidad, estado, puntaje_total)
    VALUES (v_id_contenido, p_titulo, p_contenido, p_id_comunidad, 'Activa', 0);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
