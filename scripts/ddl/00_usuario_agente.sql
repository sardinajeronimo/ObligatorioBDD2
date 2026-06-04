-- ============================================
-- TABLAS BASE: USUARIO, AGENTE, CONFIGURACION_HISTORICA
-- ============================================
-- Estas tablas faltaban en el repo y son dependencias de:
--   * Los procedures de agente (sp_registrar_agente, sp_actualizar_config_agente,
--     sp_emitir_voto) -> AGENTE, USUARIO, CONFIGURACION_HISTORICA.
--   * Las FKs hacia AGENTE en el DDL de contenido (02_mock / 03 Renzo).
--
-- COMUNIDAD NO se define aquí: la crea scripts/ddl/02_mock_tablas_feli_renzo.sql.
--
-- Columnas inferidas de:
--   * Los INSERT semilla de scripts/ddl/01_usuario_agente_config.sql.
--   * Las validaciones de los procedures (USUARIO.estado='Activo',
--     AGENTE.estado='Activo', AGENTE.configuracion IN ('Simple','Compuesta')).
--
-- Orden de creación: USUARIO -> AGENTE -> CONFIGURACION_HISTORICA.
-- Ejecutar ANTES que el resto del DDL (02/03/04) y los procedures.
-- ============================================

-- ============================================
-- USUARIO
-- Administra agentes. Puede estar Activo o Suspendido.
-- ============================================
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

-- ============================================
-- AGENTE
-- Pertenece a un usuario administrador. tipo_agente es nullable porque
-- sp_registrar_agente recibe el tipo pero (por ahora) no lo persiste;
-- queda disponible para las reglas por tipo de la Parte 2.
-- ============================================
CREATE TABLE AGENTE (
    id_agente           NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre              VARCHAR2(255) NOT NULL,
    identificador       VARCHAR2(50) NOT NULL,
    descripcion         CLOB,
    prompt              CLOB,
    tipo_agente         VARCHAR2(20),
    configuracion       VARCHAR2(20) DEFAULT 'Simple' NOT NULL,
    estado              VARCHAR2(20) DEFAULT 'Activo' NOT NULL,
    id_usuario_admin    NUMBER NOT NULL,
    fecha_creacion      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_agente PRIMARY KEY (id_agente),
    CONSTRAINT uk_agente_identificador UNIQUE (identificador),
    CONSTRAINT fk_agente_usuario FOREIGN KEY (id_usuario_admin)
        REFERENCES USUARIO(id_usuario),
    CONSTRAINT chk_agente_config CHECK (configuracion IN ('Simple', 'Compuesta')),
    CONSTRAINT chk_agente_estado CHECK (estado IN ('Activo', 'Inactivo')),
    CONSTRAINT chk_agente_tipo CHECK (tipo_agente IN ('generador', 'moderador', 'observador'))
);

CREATE INDEX ix_agente_usuario ON AGENTE(id_usuario_admin);

-- ============================================
-- CONFIGURACION_HISTORICA
-- Versionado del prompt/configuración de cada agente.
-- ============================================
CREATE TABLE CONFIGURACION_HISTORICA (
    id_config               NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente               NUMBER NOT NULL,
    version                 NUMBER NOT NULL,
    descripcion_cambio      CLOB,
    prompt_historico        CLOB,
    configuracion_historica VARCHAR2(20),
    fecha_cambio            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_config_hist PRIMARY KEY (id_config),
    CONSTRAINT fk_config_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT uk_config_agente_version UNIQUE (id_agente, version)
);

CREATE INDEX ix_config_agente ON CONFIGURACION_HISTORICA(id_agente);
