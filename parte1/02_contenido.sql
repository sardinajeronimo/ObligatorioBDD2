-- ============================================
-- TABLAS: CONTENIDO, PUBLICACION, COMENTARIO, VOTO, MODERACION
-- ============================================
-- Modelo de la generalización CONTENIDO descrita en la consigna (pág. 5):
-- "se entiende por contenido a toda unidad de información generada por los
--  agentes... los contenidos se clasifican en Publicaciones y Comentarios,
--  que comparten características comunes".
--
-- Implementación supertipo/subtipo:
--   CONTENIDO    : entidad base (id único, fecha/hora de creación, agente autor).
--   PUBLICACION  : subtipo, comparte PK con CONTENIDO (id_contenido).
--   COMENTARIO   : subtipo, comparte PK con CONTENIDO (id_contenido).
-- VOTO recae sobre PUBLICACION; MODERACION recae sobre CONTENIDO (pub o com).
--
-- Supuestos:
--   * El voto solo aplica a publicaciones (la consigna nunca menciona votos
--     sobre comentarios).
--   * Un agente vota a lo sumo una vez la misma publicación.
--   * Las publicaciones eliminadas no se borran: pasan a estado 'Eliminada'.
--   * Una publicación puede citar a otra (id_publicacion_citada + fecha_cita).
--
-- Requiere: 00_usuario_agente.sql (AGENTE), 01_comunidad.sql (COMUNIDAD).
-- ============================================

-- ============================================
-- CONTENIDO  (supertipo)
-- ============================================
CREATE TABLE CONTENIDO (
    id_contenido        NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente           NUMBER NOT NULL,
    fecha_hora_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_contenido PRIMARY KEY (id_contenido),
    CONSTRAINT fk_contenido_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE
);

CREATE INDEX ix_contenido_agente ON CONTENIDO(id_agente);

-- ============================================
-- PUBLICACION  (subtipo de CONTENIDO)
-- ============================================
CREATE TABLE PUBLICACION (
    id_contenido            NUMBER NOT NULL,
    id_comunidad            NUMBER NOT NULL,
    titulo                  VARCHAR2(500) NOT NULL,
    contenido               CLOB NOT NULL,
    estado                  VARCHAR2(20) DEFAULT 'Activa' NOT NULL,
    puntaje_total           NUMBER DEFAULT 0 NOT NULL,
    id_publicacion_citada   NUMBER,
    fecha_cita              TIMESTAMP,

    CONSTRAINT pk_publicacion PRIMARY KEY (id_contenido),
    CONSTRAINT fk_pub_contenido FOREIGN KEY (id_contenido)
        REFERENCES CONTENIDO(id_contenido) ON DELETE CASCADE,
    CONSTRAINT fk_pub_comunidad FOREIGN KEY (id_comunidad)
        REFERENCES COMUNIDAD(id_comunidad),
    CONSTRAINT fk_pub_citada FOREIGN KEY (id_publicacion_citada)
        REFERENCES PUBLICACION(id_contenido),
    CONSTRAINT chk_pub_estado CHECK (estado IN ('Activa', 'Cerrada', 'Eliminada')),
    CONSTRAINT chk_pub_titulo_nv CHECK (LENGTH(TRIM(titulo)) > 0),
    -- (CLOB no-vacío no se puede validar por CHECK: requiere trigger; NOT NULL alcanza)
    -- Cita: o ambas columnas presentes, o ninguna
    CONSTRAINT chk_pub_cita CHECK (
        (id_publicacion_citada IS NULL AND fecha_cita IS NULL)
        OR (id_publicacion_citada IS NOT NULL AND fecha_cita IS NOT NULL)
    ),
    CONSTRAINT chk_pub_autocita CHECK (id_publicacion_citada <> id_contenido)
);

CREATE INDEX ix_pub_comunidad ON PUBLICACION(id_comunidad);
CREATE INDEX ix_pub_estado    ON PUBLICACION(estado);

-- ============================================
-- COMENTARIO  (subtipo de CONTENIDO)
-- Responde a una publicación o a otro comentario (hilo jerárquico).
-- ============================================
CREATE TABLE COMENTARIO (
    id_contenido        NUMBER NOT NULL,
    id_publicacion      NUMBER NOT NULL,
    id_comentario_padre NUMBER,
    contenido           CLOB NOT NULL,

    CONSTRAINT pk_comentario PRIMARY KEY (id_contenido),
    CONSTRAINT fk_com_contenido FOREIGN KEY (id_contenido)
        REFERENCES CONTENIDO(id_contenido) ON DELETE CASCADE,
    CONSTRAINT fk_com_publicacion FOREIGN KEY (id_publicacion)
        REFERENCES PUBLICACION(id_contenido) ON DELETE CASCADE,
    CONSTRAINT fk_com_padre FOREIGN KEY (id_comentario_padre)
        REFERENCES COMENTARIO(id_contenido),
    CONSTRAINT chk_com_no_self CHECK (id_comentario_padre <> id_contenido)
);

CREATE INDEX ix_com_publicacion ON COMENTARIO(id_publicacion);
CREATE INDEX ix_com_padre       ON COMENTARIO(id_comentario_padre);

-- ============================================
-- VOTO  (sobre PUBLICACION)
-- Un agente vota a lo sumo una vez la misma publicación (UNIQUE).
-- ============================================
CREATE TABLE VOTO (
    id_voto         NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente       NUMBER NOT NULL,
    id_publicacion  NUMBER NOT NULL,
    tipo            VARCHAR2(10) NOT NULL,
    fecha_hora      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_voto PRIMARY KEY (id_voto),
    CONSTRAINT fk_voto_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_voto_publicacion FOREIGN KEY (id_publicacion)
        REFERENCES PUBLICACION(id_contenido) ON DELETE CASCADE,
    CONSTRAINT chk_voto_tipo CHECK (tipo IN ('positivo', 'negativo')),
    CONSTRAINT uk_voto_agente_pub UNIQUE (id_agente, id_publicacion)
);

CREATE INDEX ix_voto_publicacion ON VOTO(id_publicacion);

-- ============================================
-- MODERACION  (sobre CONTENIDO: publicación o comentario)
-- Depende del agente moderador, del contenido y de la comunidad.
-- ============================================
CREATE TABLE MODERACION (
    id_moderacion   NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente       NUMBER NOT NULL,
    id_contenido    NUMBER NOT NULL,
    id_comunidad    NUMBER NOT NULL,
    tipo_accion     VARCHAR2(20) NOT NULL,
    fecha_hora      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_moderacion PRIMARY KEY (id_moderacion),
    CONSTRAINT fk_mod_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente),
    CONSTRAINT fk_mod_contenido FOREIGN KEY (id_contenido)
        REFERENCES CONTENIDO(id_contenido) ON DELETE CASCADE,
    CONSTRAINT fk_mod_comunidad FOREIGN KEY (id_comunidad)
        REFERENCES COMUNIDAD(id_comunidad),
    CONSTRAINT chk_mod_accion CHECK (tipo_accion IN ('ocultar', 'cerrar', 'eliminar'))
);

CREATE INDEX ix_mod_contenido ON MODERACION(id_contenido);
CREATE INDEX ix_mod_comunidad ON MODERACION(id_comunidad);
CREATE INDEX ix_mod_agente    ON MODERACION(id_agente);
