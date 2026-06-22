# Parte 1 - Análisis y Supuestos del Modelo Relacional (Moltbook)

> Cubre el criterio **1.1** de la rúbrica: decisiones de modelado, supuestos
> explícitos sobre cardinalidades y reglas de negocio.
> Complementa la `tablaRestricciones.md` (1.2) y el DDL de esta carpeta (1.3).

---

## 1. Visión general

Moltbook es una red social operada por **agentes de IA** que pertenecen a
**usuarios humanos**. Los agentes participan en **comunidades** temáticas donde
generan **contenido** (publicaciones y comentarios), lo **votan** y lo
**moderan**. El modelo relacional captura tres ejes:

1. **Identidad y administración**: quién es dueño de qué agente y cómo
   evoluciona su configuración (USUARIO, TELEFONO_USUARIO, AGENTE,
   CONFIGURACION_HISTORICA, TRANSFERENCIA_AGENTE).
2. **Pertenencia**: qué agente participa en qué comunidad y en qué rol
   (COMUNIDAD, AGENTE_COMUNIDAD).
3. **Contenido e interacción**: la generalización CONTENIDO y sus subtipos,
   más los votos y las acciones de moderación (CONTENIDO, PUBLICACION,
   COMENTARIO, VOTO, MODERACION).

---

## 2. Decisiones de modelado

### 2.1. Generalización CONTENIDO → PUBLICACION / COMENTARIO
La consigna (pág. 5) define *contenido* como "toda unidad de información
generada por los agentes", clasificada en publicaciones y comentarios que
"comparten características comunes". Se modeló como **supertipo/subtipo**:

- `CONTENIDO` concentra lo común: identificador único, autor (`id_agente`) y
  `fecha_hora_creacion`.
- `PUBLICACION` y `COMENTARIO` **comparten la PK** con el supertipo
  (`id_contenido` es a la vez PK y FK hacia CONTENIDO).

**Por qué así y no alternativas:**
- *Tabla única con discriminador*: descartada porque publicación y comentario
  tienen atributos disjuntos (título/comunidad/puntaje vs. publicación-padre/
  comentario-padre) → muchos NULL y CHECKs condicionales frágiles.
- *Dos tablas independientes sin supertipo*: descartada porque VOTO y MODERACION
  necesitan referenciar "contenido" de forma uniforme. Con el supertipo,
  MODERACION apunta a `CONTENIDO` y modera indistintamente publicaciones o
  comentarios con una sola FK.

### 2.2. Versionado de configuración (CONFIGURACION_HISTORICA)
La configuración del agente cambia en el tiempo y el negocio exige conservar el
historial. Se separó la **config activa** (campos `prompt`, `configuracion` en
AGENTE) del **historial** (CONFIGURACION_HISTORICA, una fila por versión). La
unicidad `(id_agente, version)` impide versiones duplicadas y `version > 0`
evita numeraciones inválidas. Esto soporta directamente los servicios 2.1
(primer registro de versión) y 2.7 (alta de nueva versión) de la Parte 2.

### 2.3. Transferencia de administración como bitácora inmutable
TRANSFERENCIA_AGENTE registra `(agente, usuario_anterior, usuario_nuevo, fecha)`
y **nunca se actualiza ni se borra**: es una tabla de auditoría. El "dueño
actual" vive en `AGENTE.id_usuario_admin`; el historial vive aquí. Las FKs a
USUARIO **sin `ON DELETE`** garantizan que no se pueda borrar un usuario que
figure en el historial, preservando la trazabilidad (criterio 2.2).

### 2.4. Teléfonos como entidad débil multivaluada
La consigna habla de "los teléfonos" del usuario → atributo multivaluado. Se
modeló como TELEFONO_USUARIO (1:N) con `ON DELETE CASCADE` y unicidad
`(id_usuario, telefono)` para que un usuario no repita el mismo número.

### 2.5. Puntaje desnormalizado en PUBLICACION
`PUBLICACION.puntaje_total` es una **desnormalización deliberada**: en vez de
recalcular `SUM` sobre VOTO en cada lectura, el servicio de voto (2.4) lo
mantiene atómicamente. Justificación: el ranking top-10 (2.8) se consulta mucho
más de lo que se vota, y mantener el agregado evita un GROUP BY costoso en cada
ranking. El trade-off (riesgo de divergencia) se acota concentrando toda
escritura del puntaje en el SP de voto.

### 2.6. Borrado lógico de publicaciones
Las publicaciones eliminadas **no se borran físicamente**: pasan a
`estado = 'Eliminada'`. Permite que comentarios y moderaciones asociadas
conserven su contexto y que el ranking las filtre por estado.

---

## 3. Supuestos sobre cardinalidades

| Relación | Cardinalidad | Supuesto |
|---|---|---|
| USUARIO - TELEFONO_USUARIO | 1 : N | Un usuario tiene 0..N teléfonos; cada teléfono es de un solo usuario. |
| USUARIO - AGENTE (admin) | 1 : N | Un usuario administra 0..N agentes; un agente tiene **exactamente un** administrador a la vez. |
| AGENTE - CONFIGURACION_HISTORICA | 1 : N | Un agente tiene 1..N versiones (al menos la inicial creada en 2.1). |
| AGENTE - TRANSFERENCIA_AGENTE | 1 : N | Un agente puede transferirse 0..N veces. |
| AGENTE - COMUNIDAD | N : M | Resuelta con AGENTE_COMUNIDAD; un agente participa **una sola vez** por comunidad (UNIQUE), como `seguidor` o `miembro`. |
| AGENTE - CONTENIDO | 1 : N | Un agente autor genera 0..N contenidos; cada contenido tiene un único autor. |
| COMUNIDAD - PUBLICACION | 1 : N | Cada publicación pertenece a exactamente una comunidad. |
| PUBLICACION - COMENTARIO | 1 : N | Cada comentario pertenece a exactamente una publicación. |
| COMENTARIO - COMENTARIO (padre) | 1 : N | Jerarquía de hilos: un comentario responde a 0..1 comentario padre. |
| PUBLICACION - PUBLICACION (cita) | 1 : N | Una publicación cita opcionalmente a 0..1 publicación. |
| AGENTE - PUBLICACION (voto) | N : M | Resuelta con VOTO; un agente vota **a lo sumo una vez** la misma publicación. |
| AGENTE - CONTENIDO (moderación) | N : M | Resuelta con MODERACION; incluye la comunidad donde ocurre. |

---

## 4. Reglas de negocio y su implementación

| Regla de negocio | Dónde se garantiza |
|---|---|
| Estados de usuario/agente acotados (Activo/Suspendido) | CHECK de dominio (`chk_*_estado`). |
| Tipo de agente acotado (GENERADOR/MODERADOR/OBSERVADOR) | CHECK `chk_agente_tipo`. |
| Comunidad archivada ⇔ tiene fecha de archivado | CHECK `chk_comunidad_archivado` (coherencia estado/fecha). |
| Comunidad archivada no admite nuevas publicaciones | Estructural en DDL (estado) + validado en SP de publicar (Parte 2). |
| Título de publicación no vacío | CHECK `chk_pub_titulo_nv`. |
| Contenido (CLOB) no vacío | `NOT NULL`. **Supuesto:** el "no vacío" estricto sobre CLOB requeriría trigger (`DBMS_LOB.GETLENGTH` no es válido en CHECK); se asume suficiente NOT NULL a nivel DDL y validación en el SP. |
| Una publicación no se cita a sí misma | CHECK `chk_pub_autocita`. |
| Cita: par (publicación citada, fecha) todo-o-nada | CHECK `chk_pub_cita`. |
| Un comentario no es su propio padre | CHECK `chk_com_no_self`. |
| Voto único por agente/publicación | UNIQUE `uk_voto_agente_pub`. |
| Voto solo sobre publicaciones (no comentarios) | FK de VOTO apunta a PUBLICACION. **Supuesto:** la consigna nunca menciona votos sobre comentarios. |
| Solo agentes moderadores miembros de la comunidad moderan | Estructural (FK a comunidad) + validación de rol/pertenencia en el SP de moderación (Parte 2). |

> **Decisión sobre dónde validar:** las restricciones de **dominio/estructura**
> (tipos, unicidad, referencias) se resuelven en el DDL. Las reglas que dependen
> del **estado en el momento de la operación** (pertenencia activa, comunidad no
> archivada, publicación no cerrada) se validan en los procedimientos de la
> Parte 2, porque no son expresables como constraints declarativas estáticas.

---

## 5. Supuestos adicionales explícitos

1. **IDs subrogados** (`GENERATED ALWAYS AS IDENTITY`) en todas las entidades
   fuertes; las FK en datos de prueba se resuelven por claves naturales
   (email, alias, identificador, nombre) para que el script sea reejecutable.
2. **Un agente suspendido** no puede generar contenido ni votar; se asume que el
   estado se evalúa al ejecutar el servicio (Parte 2), no por constraint.
3. **`AGENTE_COMUNIDAD.tipo_participacion`**: `seguidor` solo visualiza;
   `miembro` participa (publica/comenta/modera). La distinción habilita las
   validaciones de pertenencia de la Parte 2.
4. **Moderación auditable**: MODERACION conserva `tipo_accion`, fecha y los
   vínculos a agente/contenido/comunidad; no se borra al revertir una acción.
5. **Borrado en cascada selectivo**: se usa `ON DELETE CASCADE` hacia
   dependientes "hijos" (teléfonos, contenido, votos, comentarios) pero **no**
   en las FK de auditoría (transferencias, administrador), que deben bloquear
   el borrado para no perder historia.
