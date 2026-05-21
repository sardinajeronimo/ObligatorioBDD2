-- ============================================
-- TABLAS: PUBLICACION, COMENTARIO, VOTO, MODERACION
-- Responsable: Renzo
-- ============================================
-- Convenciones del equipo (ver scripts/ddl/01 y feature/jero):
--   * IDENTITY columns para PKs autoincrementales.
--   * CURRENT_TIMESTAMP para defaults temporales.
--   * ON DELETE CASCADE en FKs que dependen del padre.
--
-- Supuestos:
--   * Voto solo aplica a publicaciones (el enunciado nunca menciona
--     votos sobre comentarios).
--   * Un agente puede votar a lo sumo UNA vez la misma publicación
--     (UNIQUE (id_agente, id_publicacion)).
--   * MODERACION usa dos FKs nullables exclusivas (id_publicacion XOR
--     id_comentario), preservando integridad referencial declarativa.
--   * Publicaciones eliminadas conservan el registro con estado
--     'Eliminada' (enunciado: "no se borran del sistema").
-- ============================================

-- ============================================
-- PUBLICACION
-- ============================================
CREATE TABLE PUBLICACION (
    id_publicacion          NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente               NUMBER NOT NULL,
    id_comunidad            NUMBER NOT NULL,
    titulo                  VARCHAR2(500) NOT NULL,
    contenido               CLOB NOT NULL,
    fecha_creacion          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    puntaje_total           NUMBER DEFAULT 0 NOT NULL,
    estado                  VARCHAR2(20) DEFAULT 'Activa' NOT NULL,
    id_publicacion_citada   NUMBER,
    fecha_cita              TIMESTAMP,

    CONSTRAINT pk_publicacion PRIMARY KEY (id_publicacion),
    CONSTRAINT fk_publicacion_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_publicacion_comunidad FOREIGN KEY (id_comunidad)
        REFERENCES COMUNIDAD(id_comunidad) ON DELETE CASCADE,
    CONSTRAINT fk_publicacion_citada FOREIGN KEY (id_publicacion_citada)
        REFERENCES PUBLICACION(id_publicacion),
    CONSTRAINT chk_publicacion_estado CHECK (estado IN ('Activa', 'Cerrada', 'Eliminada')),
    CONSTRAINT chk_publicacion_titulo_nv CHECK (LENGTH(TRIM(titulo)) > 0),
    CONSTRAINT chk_publicacion_cuerpo_nv CHECK (DBMS_LOB.GETLENGTH(contenido) > 0),
    CONSTRAINT chk_publicacion_cita CHECK (
        (id_publicacion_citada IS NULL     AND fecha_cita IS NULL)
        OR (id_publicacion_citada IS NOT NULL AND fecha_cita IS NOT NULL)
    ),
    CONSTRAINT chk_publicacion_autocita CHECK (id_publicacion_citada <> id_publicacion)
);

CREATE INDEX ix_publicacion_comunidad ON PUBLICACION(id_comunidad);
CREATE INDEX ix_publicacion_estado    ON PUBLICACION(estado);
CREATE INDEX ix_publicacion_fecha     ON PUBLICACION(fecha_creacion);

-- ============================================
-- COMENTARIO
-- Responde a una publicación o a otro comentario (jerarquía).
-- ============================================
CREATE TABLE COMENTARIO (
    id_comentario           NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente               NUMBER NOT NULL,
    id_publicacion          NUMBER NOT NULL,
    id_comentario_padre     NUMBER,
    contenido               CLOB NOT NULL,
    fecha_creacion          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_comentario PRIMARY KEY (id_comentario),
    CONSTRAINT fk_comentario_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_comentario_publicacion FOREIGN KEY (id_publicacion)
        REFERENCES PUBLICACION(id_publicacion) ON DELETE CASCADE,
    CONSTRAINT fk_comentario_padre FOREIGN KEY (id_comentario_padre)
        REFERENCES COMENTARIO(id_comentario),
    CONSTRAINT chk_comentario_cuerpo_nv CHECK (DBMS_LOB.GETLENGTH(contenido) > 0),
    CONSTRAINT chk_comentario_no_self   CHECK (id_comentario_padre <> id_comentario)
);

CREATE INDEX ix_comentario_publicacion ON COMENTARIO(id_publicacion);
CREATE INDEX ix_comentario_padre       ON COMENTARIO(id_comentario_padre);
CREATE INDEX ix_comentario_agente      ON COMENTARIO(id_agente);

-- ============================================
-- VOTO
-- Un agente vota a lo sumo una vez la misma publicación (UNIQUE).
-- ============================================
CREATE TABLE VOTO (
    id_voto                 NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente               NUMBER NOT NULL,
    id_publicacion          NUMBER NOT NULL,
    tipo_voto               VARCHAR2(20) NOT NULL,
    fecha_voto              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_voto PRIMARY KEY (id_voto),
    CONSTRAINT fk_voto_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_voto_publicacion FOREIGN KEY (id_publicacion)
        REFERENCES PUBLICACION(id_publicacion) ON DELETE CASCADE,
    CONSTRAINT uk_voto_agente_pub UNIQUE (id_agente, id_publicacion),
    CONSTRAINT chk_tipo_voto CHECK (tipo_voto IN ('Positivo', 'Negativo'))
);

CREATE INDEX ix_voto_publicacion ON VOTO(id_publicacion);
CREATE INDEX ix_voto_fecha       ON VOTO(fecha_voto);

-- ============================================
-- MODERACION
-- Acción de moderación sobre PUBLICACION o COMENTARIO.
-- Exclusividad declarativa (XOR) entre id_publicacion e id_comentario.
-- ============================================
CREATE TABLE MODERACION (
    id_moderacion           NUMBER GENERATED ALWAYS AS IDENTITY,
    id_agente               NUMBER NOT NULL,
    id_comunidad            NUMBER NOT NULL,
    id_publicacion          NUMBER,
    id_comentario           NUMBER,
    tipo_accion             VARCHAR2(20) NOT NULL,
    fecha_accion            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_moderacion PRIMARY KEY (id_moderacion),
    CONSTRAINT fk_moderacion_agente FOREIGN KEY (id_agente)
        REFERENCES AGENTE(id_agente) ON DELETE CASCADE,
    CONSTRAINT fk_moderacion_comunidad FOREIGN KEY (id_comunidad)
        REFERENCES COMUNIDAD(id_comunidad) ON DELETE CASCADE,
    CONSTRAINT fk_moderacion_publicacion FOREIGN KEY (id_publicacion)
        REFERENCES PUBLICACION(id_publicacion) ON DELETE CASCADE,
    CONSTRAINT fk_moderacion_comentario FOREIGN KEY (id_comentario)
        REFERENCES COMENTARIO(id_comentario) ON DELETE CASCADE,
    CONSTRAINT chk_moderacion_accion CHECK (tipo_accion IN ('Ocultar','Cerrar','Eliminar')),
    CONSTRAINT chk_moderacion_exclusivo CHECK (
        (id_publicacion IS NOT NULL AND id_comentario IS NULL)
        OR (id_publicacion IS NULL AND id_comentario IS NOT NULL)
    )
);

CREATE INDEX ix_moderacion_publicacion ON MODERACION(id_publicacion);
CREATE INDEX ix_moderacion_comentario  ON MODERACION(id_comentario);
CREATE INDEX ix_moderacion_comunidad   ON MODERACION(id_comunidad);
CREATE INDEX ix_moderacion_agente      ON MODERACION(id_agente);

-- ============================================
-- Restricciones NO estructurales pendientes (triggers/SPs Parte 2):
--   * Solo agentes 'Generador' pueden crear publicaciones/comentarios.
--   * Solo agentes 'Moderador' miembros de la comunidad pueden moderar
--     contenido de esa comunidad.
--   * Agente 'Observador' SOLO puede votar.
--   * Comunidad archivada → no admite nuevas publicaciones.
--   * Publicación con estado != 'Activa' → no admite nuevos comentarios.
--   * Agente que publica/comenta debe ser miembro activo de la comunidad.
--   * Trigger sobre VOTO mantiene PUBLICACION.puntaje_total.
-- ============================================
