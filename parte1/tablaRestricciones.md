# TABLA DE RESTRICCIONES - PARTE 1

## Responsable: Jero

| Restricción | Tabla | Tipo | Implementación | Comentarios |
|-------------|-------|------|----------------|-------------|
| pk_usuario | USUARIO | Entidad | Estructural | Primary key autoincremental |
| uk_usuario_email | USUARIO | Dominio | Estructural | Email debe ser único |
| uk_usuario_alias | USUARIO | Dominio | Estructural | Alias debe ser único |
| chk_usuario_estado | USUARIO | Semántica | No estructural | Solo permite 'Activo' o 'Suspendido' |
| pk_agente | AGENTE | Entidad | Estructural | Primary key autoincremental |
| uk_agente_identificador | AGENTE | Dominio | Estructural | Identificador único del agente |
| fk_agente_usuario | AGENTE | Referencial | Estructural | Agente pertenece a un usuario admin |
| chk_agente_config | AGENTE | Semántica | No estructural | Solo 'Simple' o 'Compuesta' |
| chk_agente_estado | AGENTE | Semántica | No estructural | Solo 'Activo' o 'Suspendido' |
| pk_config_historica | CONFIGURACION_HISTORICA | Entidad | Estructural | Primary key autoincremental |
| fk_config_agente | CONFIGURACION_HISTORICA | Referencial | Estructural | Config pertenece a un agente |
| uk_config_agente_version | CONFIGURACION_HISTORICA | Dominio | Estructural | Un agente no tiene 2 versiones iguales |
| chk_config_version | CONFIGURACION_HISTORICA | Semántica | No estructural | Versión debe ser mayor a 0 |

## Responsable: Renzo

| Restricción | Tabla | Tipo | Implementación | Comentarios |
|-------------|-------|------|----------------|-------------|
| pk_publicacion | PUBLICACION | Entidad | Estructural | Primary key autoincremental (IDENTITY) |
| fk_publicacion_agente | PUBLICACION | Referencial | Estructural | Autor pertenece a un agente existente |
| fk_publicacion_comunidad | PUBLICACION | Referencial | Estructural | Publicación pertenece a una comunidad existente |
| fk_publicacion_citada | PUBLICACION | Referencial | Estructural | Cita opcional a otra publicación (auto-referencia) |
| chk_publicacion_estado | PUBLICACION | Semántica | No estructural | Solo 'Activa', 'Cerrada' o 'Eliminada' |
| chk_publicacion_titulo_nv | PUBLICACION | Dominio | No estructural | Título no vacío |
| chk_publicacion_cuerpo_nv | PUBLICACION | Dominio | No estructural | Contenido no vacío (DBMS_LOB.GETLENGTH > 0) |
| chk_publicacion_cita | PUBLICACION | Semántica | No estructural | id_publicacion_citada y fecha_cita van juntas (ambas nulas o ambas no nulas) |
| chk_publicacion_autocita | PUBLICACION | Semántica | No estructural | Una publicación no puede citarse a sí misma |
| pk_comentario | COMENTARIO | Entidad | Estructural | Primary key autoincremental (IDENTITY) |
| fk_comentario_agente | COMENTARIO | Referencial | Estructural | Autor del comentario existe en AGENTE |
| fk_comentario_publicacion | COMENTARIO | Referencial | Estructural | Comentario pertenece a una publicación existente |
| fk_comentario_padre | COMENTARIO | Referencial | Estructural | Comentario padre opcional (auto-referencia) |
| chk_comentario_cuerpo_nv | COMENTARIO | Dominio | No estructural | Contenido no vacío |
| chk_comentario_no_self | COMENTARIO | Semántica | No estructural | Un comentario no puede ser su propio padre |
| pk_voto | VOTO | Entidad | Estructural | Primary key autoincremental (IDENTITY) |
| fk_voto_agente | VOTO | Referencial | Estructural | Voto emitido por un agente existente |
| fk_voto_publicacion | VOTO | Referencial | Estructural | Voto recae sobre una publicación existente |
| uk_voto_agente_pub | VOTO | Dominio | Estructural | Un agente vota a lo sumo una vez la misma publicación |
| chk_tipo_voto | VOTO | Semántica | No estructural | Solo 'Positivo' o 'Negativo' |
| pk_moderacion | MODERACION | Entidad | Estructural | Primary key autoincremental (IDENTITY) |
| fk_moderacion_agente | MODERACION | Referencial | Estructural | Moderador existe en AGENTE |
| fk_moderacion_comunidad | MODERACION | Referencial | Estructural | Moderación ocurre dentro de una comunidad existente |
| fk_moderacion_publicacion | MODERACION | Referencial | Estructural | FK opcional a la publicación moderada |
| fk_moderacion_comentario | MODERACION | Referencial | Estructural | FK opcional al comentario moderado |
| chk_moderacion_accion | MODERACION | Semántica | No estructural | Solo 'Ocultar', 'Cerrar' o 'Eliminar' |
| chk_moderacion_exclusivo | MODERACION | Semántica | No estructural | Una moderación apunta exactamente a una publicación XOR un comentario |
