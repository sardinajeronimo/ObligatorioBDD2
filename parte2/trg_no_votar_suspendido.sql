CREATE OR REPLACE TRIGGER trg_no_votar_suspendido
    BEFORE INSERT ON VOTO
    FOR EACH ROW
DECLARE
    v_estado AGENTE.estado%TYPE;
BEGIN
    SELECT estado
      INTO v_estado
      FROM AGENTE
     WHERE id_agente = :NEW.id_agente;

    IF v_estado = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20101,
            'El agente está Suspendido y no puede emitir votos.');
    END IF;
END trg_no_votar_suspendido;
/
