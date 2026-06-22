# Guía de pasaje Oracle → MongoDB (Parte 4.5)

Proceso de integración que toma como origen la base relacional (Oracle, Parte 1)
y puebla el subsistema de analítica en MongoDB, generando **un documento de
evento por cada acción detectada** más los eventos internos de runtime.

## Contenido de la carpeta `parte4/`

| Archivo | Qué hace |
|---|---|
| `analisis_modelo.md` | Análisis, supuestos y diseño de las 2 colecciones (4.1, 4.2). |
| `01_colecciones_validators.js` | Crea `eventos` y `agentes` con `$jsonSchema` e índices (4.3). |
| `02_datos_prueba.js` | Datos de prueba **portables** (mongosh, sin Oracle) (4.4). |
| `03_integracion_oracle_mongo.js` | ETL real Oracle → Mongo en Node.js (4.5). |
| `guia_pasaje_oracle_mongo.md` | Este documento. |

## Tecnología elegida

**Node.js**, en consistencia con la Parte 5 (consultas en JavaScript/mongosh):
- `oracledb` en **modo Thin** (no requiere instalar Oracle Instant Client).
- driver oficial `mongodb`.

```bash
npm install oracledb mongodb
```

## Mapeo acción (Oracle) → evento (Mongo)

| Origen en Oracle | `tipo_evento` | Criticidad | `detalle` / campos |
|---|---|---|---|
| `PUBLICACION` (+`CONTENIDO`) | `creacion` | baja | `contenido_id`, `titulo`, `contexto_operacional.comunidad_*` |
| `COMENTARIO` (+`CONTENIDO`) | `comentario` | media | `comentario_id`, `publicacion_id`, comunidad |
| `VOTO` | `voto` | baja | `publicacion_id`, `tipo_voto` |
| `MODERACION` | `moderacion` | alta | `contenido_id`, `accion`, comunidad |
| `CONFIGURACION_HISTORICA` | `decision` | media | `parametros_entrada.{version,configuracion}`, `detalle.motivo` |

Eventos **internos de runtime** (`decision`, `interaccion`, `error` + `metricas`)
no existen en el modelo relacional: representan la operación interna del agente
(observabilidad pura) y los genera el mismo proceso para alimentar la analítica.

La **política de criticidad** está centralizada en la función `criticidadDe()`
(misma en el ETL y en los datos de prueba): `error`/`moderacion` → `alta`;
`decision`/`comentario` → `media`; `creacion`/`voto`/`interaccion` → `baja`.

`agente_id` es la **clave de correlación** entre ambas bases (igual al
`AGENTE.id_agente` de Oracle; en `agentes` se reusa como `_id`).

## Pasos de ejecución

Prerrequisitos: esquema Oracle de la Parte 1 ya creado y poblado, y una
instancia MongoDB accesible.

```bash
# 1) Crear colecciones + validators + indices
mongosh "<MONGO_URI>" --file parte4/01_colecciones_validators.js

# 2a) Poblar DESDE ORACLE (recomendado: datos reales)
export ORA_USER=MOLTBOOK ORA_PASS=moltbook ORA_CONN=localhost:1521/FREEPDB1
export MONGO_URI=mongodb://localhost:27017
node parte4/03_integracion_oracle_mongo.js

# 2b) Alternativa SIN Oracle: datos de prueba portables
mongosh "<MONGO_URI>" --file parte4/02_datos_prueba.js

# 3) Verificar con las consultas de la Parte 5
mongosh "<MONGO_URI>" --file parte5/consultas_parte5.js
```

## Verificación realizada

El proceso se ejecutó de punta a punta contra Oracle 23ai Free y MongoDB 7
reales:

- `agentes`: 9 documentos (subset de `AGENTE` + `USUARIO`).
- `eventos`: 123 documentos generados — distribución
  `decision 39 · interaccion 36 · voto 21 · creacion 10 · error 9 · comentario 6 · moderacion 2`.
- Que `insertMany` no fallara confirma que **todos los documentos pasan los
  `$jsonSchema`**; se verificó además que el validator **rechaza** documentos
  sin campos requeridos o con `criticidad` fuera del enum (error 121).
- Las tres consultas de la Parte 5 (5.1, 5.2, 5.3) devuelven resultados
  coherentes sobre estos datos.
