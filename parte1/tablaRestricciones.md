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

> Modelo de **generalización**: `CONTENIDO` es supertipo de `PUBLICACION` y
> `COMENTARIO` (consigna pág. 5). Los subtipos comparten la PK con el supertipo
> (`id_contenido`). El autor y la fecha de creación viven en `CONTENIDO`.
> "Contenido no vacío" se garantiza con `NOT NULL`: un `CHECK` con
> `DBMS_LOB.GETLENGTH` no es válido en Oracle (funciones de paquete prohibidas
> en constraints); enforcement estricto requeriría un trigger.

| Restricción | Tabla | Tipo | Implementación | Comentarios |
|-------------|-------|------|----------------|-------------|
| pk_contenido | CONTENIDO | Entidad | Estructural | Primary key autoincremental (IDENTITY) del supertipo |
| fk_contenido_agente | CONTENIDO | Referencial | Estructural | Autor del contenido existe en AGENTE |
| pk_publicacion | PUBLICACION | Entidad | Estructural | PK = id_contenido (compartida con CONTENIDO) |
| fk_pub_contenido | PUBLICACION | Referencial | Estructural | Subtipo: id_contenido referencia a CONTENIDO |
| fk_pub_comunidad | PUBLICACION | Referencial | Estructural | Publicación pertenece a una comunidad existente |
| fk_pub_citada | PUBLICACION | Referencial | Estructural | Cita opcional a otra publicación (auto-referencia) |
| chk_pub_estado | PUBLICACION | Semántica | No estructural | Solo 'Activa', 'Cerrada' o 'Eliminada' |
| chk_pub_titulo_nv | PUBLICACION | Dominio | No estructural | Título no vacío (LENGTH(TRIM(titulo)) > 0) |
| chk_pub_cita | PUBLICACION | Semántica | No estructural | id_publicacion_citada y fecha_cita van juntas (ambas nulas o ambas no nulas) |
| chk_pub_autocita | PUBLICACION | Semántica | No estructural | Una publicación no puede citarse a sí misma |
| pk_comentario | COMENTARIO | Entidad | Estructural | PK = id_contenido (compartida con CONTENIDO) |
| fk_com_contenido | COMENTARIO | Referencial | Estructural | Subtipo: id_contenido referencia a CONTENIDO |
| fk_com_publicacion | COMENTARIO | Referencial | Estructural | Comentario pertenece a una publicación existente |
| fk_com_padre | COMENTARIO | Referencial | Estructural | Comentario padre opcional (auto-referencia, jerarquía) |
| chk_com_no_self | COMENTARIO | Semántica | No estructural | Un comentario no puede ser su propio padre |
| pk_voto | VOTO | Entidad | Estructural | Primary key autoincremental (IDENTITY) |
| fk_voto_agente | VOTO | Referencial | Estructural | Voto emitido por un agente existente |
| fk_voto_publicacion | VOTO | Referencial | Estructural | Voto recae sobre una publicación (PUBLICACION.id_contenido) |
| uk_voto_agente_pub | VOTO | Dominio | Estructural | Un agente vota a lo sumo una vez la misma publicación |
| chk_voto_tipo | VOTO | Semántica | No estructural | Solo 'positivo' o 'negativo' |
| pk_moderacion | MODERACION | Entidad | Estructural | Primary key autoincremental (IDENTITY) |
| fk_mod_agente | MODERACION | Referencial | Estructural | Moderador existe en AGENTE |
| fk_mod_contenido | MODERACION | Referencial | Estructural | Modera un CONTENIDO (publicación o comentario) |
| fk_mod_comunidad | MODERACION | Referencial | Estructural | Moderación ocurre dentro de una comunidad existente |
| chk_mod_accion | MODERACION | Semántica | No estructural | Solo 'ocultar', 'cerrar' o 'eliminar' |
