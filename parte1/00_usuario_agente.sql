
CREATE TABLE USUARIO (
    id_usuario          NUMBER GENERATED ALWAYS AS IDENTITY,
    email               VARCHAR2(255) NOT NULL,
    alias               VARCHAR2(100) NOT NULL,
    nombre_completo     VARCHAR2(255) NOT NULL,
    pais_residencia     VARCHAR2(100),
    estado              VARCHAR2(20) DEFAULT 'Activo' NOT NULL,
    fecha_registro      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
    CONSTRAINT uk_usuario_email UNIQUE (email),
    CONSTRAINT uk_usuario_alias UNIQUE (alias),
    CONSTRAINT chk_usuario_estado CHECK (estado IN ('Activo', 'Suspendido'))
);

CREATE TABLE TELEFONO_USUARIO (
    id_telefono     NUMBER GENERATED ALWAYS AS IDENTITY,
    id_usuario      NUMBER NOT NULL,
    telefono        VARCHAR2(50) NOT NULL,

    CONSTRAINT pk_telefono_usuario PRIMARY KEY (id_telefono),
    CONSTRAINT fk_telefono_usuario FOREIGN KEY (id_usuario)
        REFERENCES USUARIO(id_usuario) ON DELETE CASCADE,
    CONSTRAINT uk_telefono_usuario UNIQUE (id_usuario, telefono)
);

CREATE INDEX ix_telefono_usuario ON TELEFONO_USUARIO(id_usuario);

CREATE TABLE AGENTE (
    id_agente           NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre              VARCHAR2(255) NOT NULL,
    identificador       VARCHAR2(50) NOT NULL,
    descripcion         CLOB,
    prompt              CLOB,
    tipo                VARCHAR2(20) NOT NULL,
    configuracion       VARCHAR2(20) DEFAULT 'Simple' NOT NULL,
    estado              VARCHAR2(20) DEFAULT 'Activo' NOT NULL,
    id_usuario_admin    NUMBER NOT NULL,
    fecha_creacion      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_agente PRIMARY KEY (id_agente),
    CONSTRAINT uk_agente_identificador UNIQUE (identificador),
    CONSTRAINT fk_agente_usuario FOREIGN KEY (id_usuario_admin)
        REFERENCES USUARIO(id_usuario),
    CONSTRAINT chk_agente_tipo CHECK (tipo IN ('GENERADOR', 'MODERADOR', 'OBSERVADOR')),
    CONSTRAINT chk_agente_config CHECK (configuracion IN ('Simple', 'Compuesta')),
    CONSTRAINT chk_agente_estado CHECK (estado IN ('Activo', 'Suspendido'))
);

CREATE INDEX ix_agente_usuario ON AGENTE(id_usuario_admin);

CREATE TABLE CONFIGURACION_HISTORICA (
    id_config               NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente               NUMBER NOT NULL,
    version                 NUMBER NOT NULL,
    fecha_aplicacion        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    descripcion_cambio      CLOB,
    prompt_historico        CLOB,
    configuracion_historica VARCHAR2(20),

    CONSTRAINT pk_config_historica PRIMARY KEY (id_config),
    CONSTRAINT fk_config_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT uk_config_agente_version UNIQUE (id_agente, version),
    CONSTRAINT chk_config_version CHECK (version > 0)
);

CREATE INDEX ix_config_agente ON CONFIGURACION_HISTORICA(id_agente);
