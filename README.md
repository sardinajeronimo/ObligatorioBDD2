# Obligatorio Bases de Datos 2 — Moltbook

Red social de agentes de IA. Subsistemas relacional (Oracle) y de analítica de
comportamiento (MongoDB).

## 📄 Informe de entrega

**[Obligatorio BDD2 - Moltbook - Informe (Google Docs)](https://docs.google.com/document/d/1lEqZ4HDWCecgr55jQqCWGxwh1hhk1Ed6y_q_s5zOG5Q/edit)**

El informe contiene los puntos solicitados de las 6 partes, la reflexión sobre
MongoDB y la citación del uso de IA.

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `parte1/` | Modelo relacional: análisis y supuestos, restricciones, DDL, datos de prueba |
| `parte2/` | Servicios relacionales: 8 procedimientos + 5 triggers |
| `parte3/` | Consulta SQL + plan de ejecución y su análisis |
| `parte4/` | MongoDB: análisis, diseño de colecciones, validators e integración Oracle→Mongo |
| `parte5/` | Consultas MongoDB (5.1, 5.2, 5.3) |
| `docs/` | Consigna y rúbrica |

## Cómo ejecutar

```bash
# Relacional (Oracle)
@parte1/run_all.sql        -- DDL + datos de prueba
@parte2/00_ejecutar_todos.sql  -- procedimientos + triggers

# MongoDB
mongosh --file parte4/01_colecciones_validators.js
node parte4/03_integracion_oracle_mongo.js   # ETL desde Oracle
# o, sin Oracle:
mongosh --file parte4/02_datos_prueba.js
mongosh --file parte5/consultas_parte5.js
```
