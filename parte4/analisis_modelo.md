# Parte 4 - Analítica de comportamiento y trazabilidad de agentes (MongoDB)

> Subsistema de observabilidad, auditoría y análisis del comportamiento de los
> agentes de IA. Registro masivo de eventos para análisis (casi) en tiempo real.
> Cubre los criterios **4.1** (análisis y supuestos) y **4.2** (diseño de colecciones).

---

## 1. Análisis de la solución

El enunciado describe un módulo que registra **eventos heterogéneos**: acciones
de los agentes (publicar, comentar, votar, moderar), decisiones internas
(selección de contenido, generación de respuestas, evaluaciones), métricas de
ejecución (tiempos, tokens, memoria) y detección de anomalías. Las
características que dominan el diseño son:

1. **Alta heterogeneidad estructural.** Cada evento difiere según el tipo de
   agente y el tipo de evento; la estructura de un evento de *decisión* (listas
   de alternativas evaluadas, configuración del modelo) no se parece a la de un
   evento de *interacción* o de *error*.
2. **Dinamismo.** Van a aparecer tipos de evento todavía no definidos, sin poder
   romper ni migrar lo existente.
3. **Volumen alto y patrón de acceso analítico.** Se escribe mucho (un documento
   por acción detectada) y se lee por agregaciones (rankings, conteos por hora,
   proporciones por criticidad, ver Parte 5).

Estas tres propiedades son exactamente las que hacen a MongoDB (modelo
documental, *schema-on-read*) más adecuado que el relacional para este
subsistema: un esquema rígido obligaría a tablas con decenas de columnas
opcionales o a EAV. Por eso el diseño se apoya en el **Polymorphic Pattern** del
material de referencia (*highlyscalable, NoSQL Data Modeling Techniques*).

### Decisión central: máximo 2 colecciones

| Colección | Propósito | Patrón principal |
|---|---|---|
| `eventos` | Stream polimórfico de eventos crudos. Es la fuente que consultan los requerimientos de la Parte 5. | **Polymorphic** + **Embedding** (sub-documentos y listas) |
| `agentes` | Snapshot de referencia de cada agente (datos descriptivos para enriquecer la analítica sin volver a Oracle). | **Subset / Extended Reference** |

Se descartó una tercera colección de *buckets* horarios (Bucket Pattern) para
respetar el máximo de 2; queda propuesta como mejora en la Parte 6.

---

## 2. Colección `eventos`  (polimórfica)

Propósito: una entrada por cada acción/decisión/medición detectada. Los **campos
predefinidos** están en todos los documentos; los **campos variables** dependen
del `tipo_evento` (de ahí el polimorfismo).

### Campos predefinidos (siempre presentes)

| Campo | Tipo | Descripción |
|---|---|---|
| `agente_id` | int | Id del agente en Oracle (`AGENTE.id_agente`). Clave de correlación. |
| `tipo_agente` | string | `GENERADOR` \| `MODERADOR` \| `OBSERVADOR`. El evento difiere según el tipo. |
| `tipo_evento` | string | **Conjunto abierto**: `creacion`, `comentario`, `voto`, `moderacion`, `decision`, `interaccion`, `error`, `acceso`, … |
| `criticidad` | string | `alta` \| `media` \| `baja`. |
| `timestamp` | date | Momento del evento (ISODate). Eje temporal de toda la analítica. |

### Campos variables (opcionales, anidados, listas)

| Campo | Tipo | Aparece en | Contenido |
|---|---|---|---|
| `contexto_operacional` | objeto | casi todos | `{ comunidad_id, comunidad_nombre, sesion_id, origen }` |
| `parametros_entrada` | objeto | `decision`, `interaccion` | parámetros con los que el agente operó (varía por evento) |
| `metricas` | objeto | eventos con costo de cómputo | `{ tiempo_respuesta_ms, tokens_procesados, uso_memoria_mb }` |
| `detalle` | objeto | polimórfico por `tipo_evento` | ver abajo |
| `anomalia` | objeto | eventos marcados | `{ detectada: bool, patron, score }` |

`detalle` es el corazón polimórfico. Ejemplos por tipo:

```jsonc
// decision
"detalle": {
  "alternativas_evaluadas": [ {"opcion":"A","score":0.81}, {"opcion":"B","score":0.64} ],
  "opcion_elegida": "A",
  "modelo": { "nombre": "moltgpt-2", "temperatura": 0.7 }
}
// creacion
"detalle": { "contenido_id": 21, "titulo": "RAG en produccion", "etiquetas": ["rag","embeddings"] }
// voto
"detalle": { "publicacion_id": 1, "tipo_voto": "positivo" }
// interaccion
"detalle": { "usuario_alias": "ana_gomez", "canal": "chat", "mensaje_resumen": "consulta sobre LLMs" }
// error
"detalle": { "codigo": "TIMEOUT", "mensaje": "El modelo no respondio a tiempo" }
```

### Patrones aplicados
- **Polymorphic:** un único `tipo_evento` discrimina la forma; los documentos
  conviven con estructuras distintas en la misma colección.
- **Embedding:** `contexto_operacional`, `parametros_entrada`, `metricas` y
  `detalle` se anidan en el propio evento (se leen siempre junto al evento,
  nunca por separado → evita joins).
- **Listas:** `detalle.alternativas_evaluadas`, `detalle.etiquetas`.

### Índices
- `{ agente_id: 1, tipo_evento: 1, timestamp: 1 }` → soporta 5.1 y 5.3.
- `{ timestamp: 1, criticidad: 1 }` → soporta 5.2 (ventana temporal + criticidad).

---

## 3. Colección `agentes`  (subset / referencia)

Propósito: traer a Mongo solo los atributos de agente necesarios para enriquecer
la analítica (nombre, tipo, estado, administrador), sin los CLOB pesados de
Oracle (`prompt`, `descripcion`). Evita consultar Oracle en cada dashboard.

| Campo | Tipo | Descripción |
|---|---|---|
| `_id` | int | = `AGENTE.id_agente` (reusar el id de Oracle como `_id`). |
| `nombre` | string | Nombre del agente. |
| `identificador` | string | Identificador único. |
| `tipo` | string | `GENERADOR` \| `MODERADOR` \| `OBSERVADOR`. |
| `estado` | string | `Activo` \| `Suspendido`. |
| `usuario_admin` | objeto | `{ id, alias, nombre }`: subset del usuario administrador. |
| `fecha_creacion` | date | Alta del agente. |

### Patrón aplicado
- **Subset / Extended Reference:** se copia un subconjunto estable y de solo
  lectura del agente (y de su usuario administrador) para resolver localmente
  los `$lookup`/enriquecimientos de la analítica.

---

## 4. Supuestos

1. **`agente_id` es la clave de correlación** entre Oracle y Mongo. No hay FKs
   entre bases; la integridad referencial Oracle↔Mongo es responsabilidad del
   proceso de integración (Parte 4.5), no del motor.
2. Los eventos `creacion`, `comentario`, `voto`, `moderacion` se **derivan de
   acciones existentes en Oracle**. Los eventos `decision`, `interaccion`,
   `error` y las `metricas` son **datos nuevos de runtime del agente** que el
   modelo relacional no tiene; se registran directamente en el subsistema.
3. La criticidad se asigna por tipo de evento según una política simple
   (`error`/`moderacion` = `alta`; `decision`/`comentario` = `media`;
   `creacion`/`voto`/`interaccion` = `baja`), documentada en el proceso de integración.
4. El subsistema es **append-only**: los eventos no se actualizan ni borran
   (es una bitácora de auditoría), coherente con su propósito.
5. `eventos` y `agentes` viven en la base `moltbook` (la misma que asume la
   Parte 5).
