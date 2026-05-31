-- ============================================
-- TABLAS MOCK: Comunidad, Contenido, Publicacion,
--              Comentario, Voto, Agente_Comunidad, Moderacion
-- Responsable: Feli / Renzo  (mock generado por Jero para desarrollo)
-- Requerimientos dependientes: 2.3, 2.6, 2.8
-- NOTA: Este archivo es un mock mínimo para poder desarrollar y probar
--       los procedimientos a cargo de Jero. No reemplaza los scripts
--       definitivos de Feli y Renzo.
-- ============================================

-- ============================================
-- TABLA: COMUNIDAD
-- ============================================

CREATE TABLE COMUNIDAD (
    id_comunidad     NUMBER          GENERATED ALWAYS AS IDENTITY,
    nombre           VARCHAR2(200)   NOT NULL,
    descripcion      CLOB,
    fecha_creacion   TIMESTAMP       DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tema             VARCHAR2(100)   NOT NULL,
    fecha_archivado  TIMESTAMP,
    estado           VARCHAR2(20)    DEFAULT 'Activa' NOT NULL,

    CONSTRAINT pk_comunidad          PRIMARY KEY (id_comunidad),
    CONSTRAINT uq_comunidad_nombre   UNIQUE (nombre),
    CONSTRAINT chk_comunidad_estado  CHECK (estado IN ('Activa', 'Archivada'))
);

-- ============================================
-- TABLA: CONTENIDO (entidad base para PUBLICACION y COMENTARIO)
-- ============================================

CREATE TABLE CONTENIDO (
    id_contenido        NUMBER      GENERATED ALWAYS AS IDENTITY,
    fecha_hora_creacion TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_agente           NUMBER      NOT NULL,

    CONSTRAINT pk_contenido       PRIMARY KEY (id_contenido),
    CONSTRAINT fk_contenido_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE
);

CREATE INDEX ix_contenido_agente ON CONTENIDO(id_agente);

-- ============================================
-- TABLA: PUBLICACION (hereda de CONTENIDO via id_contenido compartido)
-- ============================================

CREATE TABLE PUBLICACION (
    id_contenido    NUMBER          NOT NULL,
    titulo          VARCHAR2(500)   NOT NULL,
    contenido       CLOB            NOT NULL,
    id_comunidad    NUMBER          NOT NULL,
    estado          VARCHAR2(20)    DEFAULT 'Activa' NOT NULL,
    puntaje_total   NUMBER          DEFAULT 0 NOT NULL,

    CONSTRAINT pk_publicacion          PRIMARY KEY (id_contenido),
    CONSTRAINT fk_pub_contenido        FOREIGN KEY (id_contenido)
        REFERENCES CONTENIDO(id_contenido) ON DELETE CASCADE,
    CONSTRAINT fk_pub_comunidad        FOREIGN KEY (id_comunidad)
        REFERENCES COMUNIDAD(id_comunidad),
    CONSTRAINT chk_pub_estado          CHECK (estado IN ('Activa', 'Cerrada', 'Eliminada')),
    CONSTRAINT chk_pub_puntaje         CHECK (puntaje_total >= 0)
);

CREATE INDEX ix_pub_comunidad ON PUBLICACION(id_comunidad);
CREATE INDEX ix_pub_estado    ON PUBLICACION(estado);

-- ============================================
-- TABLA: COMENTARIO (hereda de CONTENIDO via id_contenido compartido)
-- ============================================

CREATE TABLE COMENTARIO (
    id_contenido        NUMBER  NOT NULL,
    contenido           CLOB    NOT NULL,
    id_publicacion      NUMBER  NOT NULL,
    id_comentario_padre NUMBER,

    CONSTRAINT pk_comentario          PRIMARY KEY (id_contenido),
    CONSTRAINT fk_com_contenido       FOREIGN KEY (id_contenido)
        REFERENCES CONTENIDO(id_contenido) ON DELETE CASCADE,
    CONSTRAINT fk_com_publicacion     FOREIGN KEY (id_publicacion)
        REFERENCES PUBLICACION(id_contenido),
    CONSTRAINT fk_com_padre           FOREIGN KEY (id_comentario_padre)
        REFERENCES COMENTARIO(id_contenido)
);

CREATE INDEX ix_com_publicacion ON COMENTARIO(id_publicacion);
CREATE INDEX ix_com_padre       ON COMENTARIO(id_comentario_padre);

-- ============================================
-- TABLA: VOTO
-- ============================================

CREATE TABLE VOTO (
    id_voto         NUMBER      GENERATED ALWAYS AS IDENTITY,
    id_agente       NUMBER      NOT NULL,
    id_publicacion  NUMBER      NOT NULL,
    tipo            VARCHAR2(10) NOT NULL,
    fecha_hora      TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_voto              PRIMARY KEY (id_voto),
    CONSTRAINT fk_voto_agente       FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_voto_publicacion  FOREIGN KEY (id_publicacion)
        REFERENCES PUBLICACION(id_contenido),
    CONSTRAINT chk_voto_tipo        CHECK (tipo IN ('positivo', 'negativo')),
    CONSTRAINT uq_voto_agente_pub   UNIQUE (id_agente, id_publicacion)
);

CREATE INDEX ix_voto_publicacion ON VOTO(id_publicacion);

-- ============================================
-- TABLA: AGENTE_COMUNIDAD
-- ============================================

CREATE TABLE AGENTE_COMUNIDAD (
    id_agente_comunidad  NUMBER      GENERATED ALWAYS AS IDENTITY,
    id_agente            NUMBER      NOT NULL,
    id_comunidad         NUMBER      NOT NULL,
    tipo_participacion   VARCHAR2(20) NOT NULL,

    CONSTRAINT pk_agente_comunidad      PRIMARY KEY (id_agente_comunidad),
    CONSTRAINT fk_ac_agente             FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_ac_comunidad          FOREIGN KEY (id_comunidad)
        REFERENCES COMUNIDAD(id_comunidad) ON DELETE CASCADE,
    CONSTRAINT chk_ac_tipo              CHECK (tipo_participacion IN ('seguidor', 'miembro')),
    CONSTRAINT uq_ac_agente_comunidad   UNIQUE (id_agente, id_comunidad)
);

CREATE INDEX ix_ac_comunidad ON AGENTE_COMUNIDAD(id_comunidad);

-- ============================================
-- TABLA: MODERACION
-- ============================================

CREATE TABLE MODERACION (
    id_moderacion   NUMBER          GENERATED ALWAYS AS IDENTITY,
    id_agente       NUMBER          NOT NULL,
    id_contenido    NUMBER          NOT NULL,
    id_comunidad    NUMBER          NOT NULL,
    tipo_accion     VARCHAR2(50)    NOT NULL,
    fecha_hora      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_moderacion         PRIMARY KEY (id_moderacion),
    CONSTRAINT fk_mod_agente         FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente),
    CONSTRAINT fk_mod_contenido      FOREIGN KEY (id_contenido)
        REFERENCES CONTENIDO(id_contenido),
    CONSTRAINT fk_mod_comunidad      FOREIGN KEY (id_comunidad)
        REFERENCES COMUNIDAD(id_comunidad)
);

CREATE INDEX ix_mod_contenido  ON MODERACION(id_contenido);
CREATE INDEX ix_mod_comunidad  ON MODERACION(id_comunidad);
CREATE INDEX ix_mod_fecha      ON MODERACION(fecha_hora);
