
CREATE TABLE COMUNIDAD (
    id_comunidad        NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre              VARCHAR2(200) NOT NULL,
    descripcion         CLOB,
    tema                VARCHAR2(100) NOT NULL,
    estado              VARCHAR2(20) DEFAULT 'Activa' NOT NULL,
    fecha_creacion      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_archivado     TIMESTAMP,

    CONSTRAINT pk_comunidad PRIMARY KEY (id_comunidad),
    CONSTRAINT uk_comunidad_nombre UNIQUE (nombre),
    CONSTRAINT chk_comunidad_estado CHECK (estado IN ('Activa', 'Archivada')),
    CONSTRAINT chk_comunidad_archivado CHECK (
        (estado = 'Archivada' AND fecha_archivado IS NOT NULL)
        OR (estado = 'Activa' AND fecha_archivado IS NULL)
    )
);

CREATE TABLE AGENTE_COMUNIDAD (
    id_agente_comunidad  NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente            NUMBER NOT NULL,
    id_comunidad         NUMBER NOT NULL,
    tipo_participacion   VARCHAR2(20) NOT NULL,
    fecha_alta           TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_agente_comunidad PRIMARY KEY (id_agente_comunidad),
    CONSTRAINT fk_ac_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_ac_comunidad FOREIGN KEY (id_comunidad)
        REFERENCES COMUNIDAD(id_comunidad) ON DELETE CASCADE,
    CONSTRAINT chk_ac_tipo CHECK (tipo_participacion IN ('seguidor', 'miembro')),
    CONSTRAINT uk_ac_agente_comunidad UNIQUE (id_agente, id_comunidad)
);

CREATE INDEX ix_ac_comunidad ON AGENTE_COMUNIDAD(id_comunidad);
