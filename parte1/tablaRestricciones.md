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
