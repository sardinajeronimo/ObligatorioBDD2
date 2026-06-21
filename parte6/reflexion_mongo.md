# Parte 6 — Reflexión sobre el modelado en MongoDB

> Subsistema de analítica de comportamiento y trazabilidad de agentes (Parte 4).
> Responde las tres preguntas de la consigna a partir del diseño efectivamente
> implementado en `parte4/` y las consultas de `parte5/`.

---

## 1. ¿Cómo aplicaron los conceptos del material de estudio en su modelado?

El diseño no eligió MongoDB por defecto, sino porque el subsistema tiene tres
propiedades que el material de referencia (*NoSQL Data Modeling Techniques* de
highlyscalable y la serie *Building with Patterns* de MongoDB) asocia
directamente al modelo documental: **heterogeneidad estructural**, **dinamismo**
(aparecerán tipos de evento no previstos) y **volumen alto con acceso
analítico**. Sobre esa base aplicamos patrones concretos:

### Polymorphic Pattern — colección `eventos`
Es el patrón central. Una única colección almacena documentos con estructuras
distintas, discriminados por el campo `tipo_evento`. Los **cinco campos
predefinidos** (`agente_id`, `tipo_agente`, `tipo_evento`, `criticidad`,
`timestamp`) están en todos los documentos; la **parte variable** depende del
tipo de evento.

Ejemplo específico — el sub-documento `detalle` cambia de forma según el tipo:

```jsonc
// tipo_evento: "decision"
"detalle": {
  "alternativas_evaluadas": [ {"opcion":"A","score":0.81}, {"opcion":"B","score":0.64} ],
  "opcion_elegida": "A",
  "modelo": { "nombre": "moltgpt-2", "temperatura": 0.7 }
}

// tipo_evento: "error"
"detalle": { "codigo": "TIMEOUT", "mensaje": "El modelo no respondio a tiempo" }
```

Ambos conviven en la misma colección sin que ninguno tenga columnas vacías. En
un modelo relacional esto obligaría a una tabla con decenas de columnas
opcionales nulas o a un esquema EAV (entidad-atributo-valor) difícil de
consultar.

### Embedding ("data that is accessed together, stored together")
La regla madre del modelado documental: lo que se lee junto, se guarda junto.
Los sub-documentos `contexto_operacional`, `parametros_entrada`, `metricas` y
`detalle` se **anidan dentro del propio evento** porque nunca se consultan por
separado del evento que los origina. Esto elimina *joins* en la lectura
analítica. Se ve en el requerimiento **5.1**, que devuelve cada evento junto a su
`contexto_operacional` y sus `parametros_entrada` con un solo `find` y una
proyección, sin ningún `$lookup`.

También aplicamos **listas embebidas** donde la cardinalidad es acotada:
`detalle.alternativas_evaluadas` y `detalle.etiquetas`.

### Subset / Extended Reference Pattern — colección `agentes`
En lugar de volver a Oracle (o de duplicar el agente entero) en cada dashboard,
`agentes` guarda un **subconjunto estable y de solo lectura** de cada agente:
nombre, identificador, tipo, estado y un sub-objeto `usuario_admin` con el
administrador. Deja afuera deliberadamente los CLOB pesados de Oracle (`prompt`,
`descripcion`) que la analítica no necesita. Además reusa el `id_agente` de
Oracle como `_id`, que funciona como clave de correlación entre ambas bases.

### Schema-on-read y diseño de índices guiado por las consultas
- El validador `$jsonSchema` es **estricto en los cinco campos fijos** pero deja
  `tipo_evento` como conjunto abierto (string) y **no restringe
  `additionalProperties`**. Eso materializa el *schema-on-read*: nuevos tipos de
  evento y nuevos campos entran sin migrar el esquema.
- Los índices se diseñaron **a partir del patrón de acceso** (no de las
  entidades): `{ agente_id, tipo_evento, timestamp }` soporta 5.1 y 5.3, y
  `{ timestamp, criticidad }` soporta 5.2.

---

## 2. ¿Consideran que su modelado puede ser mejorado?

Sí. El diseño priorizó simplicidad y el límite de **máximo 2 colecciones** que
fija la consigna; eso dejó mejoras concretas sobre la mesa:

1. **Bucket Pattern (tercera colección de agregados horarios).** Hoy las
   consultas 5.2 y 5.3 recorren la colección `eventos` completa para contar. Una
   colección `eventos_horarios` que pre-agrupe conteos por agente y por hora
   (un documento por ventana temporal) reduciría drásticamente el trabajo de
   esas agregaciones. Se descartó únicamente para respetar el tope de 2
   colecciones; queda como la mejora más rentable.

2. **Computed Pattern.** Calcular y persistir métricas derivadas en el momento de
   la escritura (por ejemplo, totales por agente o la proporción de criticidad
   "alta") en vez de recomputarlas en cada agregación de lectura. Conviene cuando
   la relación lectura/escritura es alta, como en un panel analítico.

3. **Schema Versioning Pattern.** Agregar un campo `schema_version` a cada evento
   permitiría evolucionar la forma de la parte polimórfica de manera explícita y
   coexistir versiones viejas y nuevas sin ambigüedad para la aplicación que lee.

4. **Validación condicional por tipo de evento.** Actualmente `detalle` se valida
   solo como `object` libre. Se podría reforzar la integridad sin perder
   dinamismo usando `$jsonSchema` condicional (`oneOf` / `if-then`) que exija
   ciertos campos en `detalle` según el `tipo_evento` (por ejemplo, `codigo` y
   `mensaje` obligatorios cuando `tipo_evento = "error"`).

5. **Índice TTL.** Si la bitácora tuviera una política de retención (por ejemplo,
   conservar eventos un año), un índice TTL sobre `timestamp` purgaría los
   documentos viejos automáticamente, controlando el crecimiento.

---

## 3. Ventajas y desventajas de MongoDB en este subsistema

### Ventajas
- **Esquema flexible para datos heterogéneos y dinámicos.** Nuevos tipos de
  evento entran sin migración (schema-on-read). El relacional exigiría columnas
  opcionales nulas o EAV.
- **Lecturas sin joins.** El embedding hace que cada evento traiga ya su contexto,
  métricas y detalle; la analítica de la Parte 5 se resuelve sobre una sola
  colección.
- **Escritura de alto volumen.** El subsistema es *append-only* (bitácora de
  auditoría); el modelo documental y el sharding por `timestamp` / `agente_id`
  escalan bien ese patrón de inserción masiva.
- **Aggregation Framework.** Cubre directamente los requerimientos analíticos
  (rankings, conteos por hora, proporciones por criticidad) de la Parte 5.

### Desventajas
- **Sin integridad referencial entre bases.** No hay FK Oracle↔Mongo; la
  correlación por `agente_id` queda como responsabilidad del proceso de
  integración (Parte 4.5), no del motor.
- **Sin el modelo transaccional ACID multi-tabla del relacional.** En este
  subsistema no duele porque es append-only, pero sería una limitación en un
  módulo con escrituras coordinadas (como los servicios transaccionales de la
  Parte 2).
- **Riesgo de datos desactualizados por denormalización.** El snapshot `agentes`
  (subset) debe re-sincronizarse cuando cambian los datos en Oracle; si no, queda
  *stale*.
- **Menor garantía de integridad por la flexibilidad.** Dejar la parte variable
  libre facilita el dinamismo pero traslada parte de la validación a la
  aplicación.

### ¿Otro subsistema del obligatorio candidato a este modelo?

Sí: el módulo de **contenido social — PUBLICACION + COMENTARIO + VOTO**.

- Los **comentarios son jerárquicos** (un comentario responde a una publicación o
  a otro comentario). En el modelo relacional esto se resuelve con una FK
  recursiva y consultas recursivas (CTEs); en documento se modela de forma
  natural con un **árbol de comentarios embebido** dentro de la publicación
  (patrón *Tree / Nested Set* + embedding).
- La publicación, su hilo de comentarios y el contador de votos **se leen
  juntos** (al abrir un post se muestra todo), lo que cumple la regla "lo que se
  accede junto se guarda junto".
- El **conteo de votos** encaja con el *Computed Pattern* (mantener el puntaje
  agregado en el propio documento de la publicación).

Un segundo candidato menor es **CONFIGURACION_HISTORICA**: el historial de
versiones de configuración de un agente se modela bien como un *array versionado
embebido* dentro del documento del agente (afín al Schema Versioning / historial
embebido), ya que se consulta casi siempre junto al agente.
