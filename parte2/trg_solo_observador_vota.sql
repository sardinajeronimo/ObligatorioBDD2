CREATE OR REPLACE TRIGGER trg_solo_observador_vota
    BEFORE INSERT ON VOTO
    FOR EACH ROW
DECLARE
    v_tipo AGENTE.tipo%TYPE;
BEGIN
    SELECT tipo
      INTO v_tipo
      FROM AGENTE
     WHERE id_agente = :NEW.id_agente;

    IF v_tipo <> 'OBSERVADOR' THEN
        RAISE_APPLICATION_ERROR(-20102,
            'Solo los agentes de tipo OBSERVADOR pueden emitir votos.');
    END IF;
END trg_solo_observador_vota;
/
