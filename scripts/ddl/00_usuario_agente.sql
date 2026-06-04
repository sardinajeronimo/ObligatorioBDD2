-- ============================================
-- TABLAS: USUARIO, AGENTE, CONFIGURACION_HISTORICA
-- ============================================
-- Gestión de usuarios humanos y de los agentes de IA que administran,
-- con el versionado histórico de la configuración de cada agente.
--
-- Convenciones de dominio (consistentes con los procedures):
--   USUARIO.estado / AGENTE.estado : 'Activo' | 'Suspendido'
--   AGENTE.tipo                    : 'GENERADOR' | 'MODERADOR' | 'OBSERVADOR'
--   AGENTE.configuracion           : 'Simple' | 'Compuesta'
--
-- Orden de creación: USUARIO -> AGENTE -> CONFIGURACION_HISTORICA.
-- Ejecutar antes que el resto del DDL (01 comunidad, 02 contenido, 04 transf.).
-- ============================================

-- ============================================
-- USUARIO
-- Humano responsable de uno o varios agentes. Activo o Suspendido.
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
-- TELEFONO_USUARIO
-- Un usuario puede tener varios teléfonos (la consigna dice "los teléfonos").
-- Relación 1:N; el mismo número no se repite para un mismo usuario.
-- ============================================
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

-- ============================================
-- AGENTE
-- Administrado por un USUARIO. tipo clasifica su comportamiento
-- (generador / moderador / observador). estado controla si puede interactuar.
-- ============================================
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

-- ============================================
-- CONFIGURACION_HISTORICA
-- Versionado del prompt/configuración del agente. Cada registro guarda
-- la versión, la fecha de aplicación y la descripción del cambio.
-- ============================================
CREATE TABLE CONFIGURACION_HISTORICA (
    id_config               NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente               NUMBER NOT NULL,
    version                 NUMBER NOT NULL,
    fecha_aplicacion        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    descripcion_cambio      CLOB,
    prompt_historico        CLOB,
    configuracion_historica VARCHAR2(20),

    CONSTRAINT pk_config_hist PRIMARY KEY (id_config),
    CONSTRAINT fk_config_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT uk_config_agente_version UNIQUE (id_agente, version)
);

CREATE INDEX ix_config_agente ON CONFIGURACION_HISTORICA(id_agente);
