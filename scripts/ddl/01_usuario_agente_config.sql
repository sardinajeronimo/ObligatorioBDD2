-- Usuarios
INSERT INTO USUARIO (email, alias, nombre_completo, pais_residencia) 
VALUES ('jero@mail.com', 'jero_dev', 'Jeronimo Rodriguez', 'Uruguay');

INSERT INTO USUARIO (email, alias, nombre_completo, pais_residencia) 
VALUES ('feli@mail.com', 'feli_tech', 'Felipe Martinez', 'Uruguay');

INSERT INTO USUARIO (email, alias, nombre_completo, pais_residencia) 
VALUES ('renzo@mail.com', 'renzo_code', 'Renzo Silva', 'Uruguay');

COMMIT;

-- Agentes
INSERT INTO AGENTE (nombre, identificador, descripcion, prompt, id_usuario_admin)
VALUES ('ContentBot', 'AGENT001', 'Generador de contenido', 
        'Eres un agente que crea publicaciones interesantes sobre tecnología', 1);

INSERT INTO AGENTE (nombre, identificador, descripcion, prompt, configuracion, id_usuario_admin)
VALUES ('ModeratorAI', 'AGENT002', 'Moderador de comunidades',
        'Supervisas contenido y mantienes las comunidades sanas', 'Compuesta', 2);

INSERT INTO AGENTE (nombre, identificador, descripcion, prompt, id_usuario_admin)
VALUES ('ObserverBot', 'AGENT003', 'Observador analítico',
        'Analizas patrones y votas contenido relevante', 3);

COMMIT;

-- Config histórica
INSERT INTO CONFIGURACION_HISTORICA (id_agente, version, descripcion_cambio, prompt_historico)
VALUES (1, 1, 'Configuración inicial', 'Eres un agente que crea publicaciones interesantes sobre tecnología');

INSERT INTO CONFIGURACION_HISTORICA (id_agente, version, descripcion_cambio, prompt_historico)
VALUES (2, 1, 'Configuración inicial', 'Supervisas contenido y mantienes las comunidades sanas');

COMMIT;

-- Ver datos
SELECT * FROM USUARIO;
SELECT * FROM AGENTE;
SELECT * FROM CONFIGURACION_HISTORICA;