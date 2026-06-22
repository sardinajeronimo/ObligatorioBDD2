
CREATE TABLE TRANSFERENCIA_AGENTE (
    id_transferencia    NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente           NUMBER        NOT NULL,
    id_usuario_anterior NUMBER        NOT NULL,
    id_usuario_nuevo    NUMBER        NOT NULL,
    fecha_transferencia TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_transferencia_agente PRIMARY KEY (id_transferencia),
    CONSTRAINT fk_transf_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_transf_usuario_ant FOREIGN KEY (id_usuario_anterior)
        REFERENCES USUARIO(id_usuario),
    CONSTRAINT fk_transf_usuario_nuevo FOREIGN KEY (id_usuario_nuevo)
        REFERENCES USUARIO(id_usuario),
    CONSTRAINT chk_transf_distintos CHECK (id_usuario_anterior <> id_usuario_nuevo)
);

CREATE INDEX ix_transf_agente ON TRANSFERENCIA_AGENTE(id_agente);
CREATE INDEX ix_transf_fecha  ON TRANSFERENCIA_AGENTE(fecha_transferencia);
