---
name: evaluar-obligatorio
description: Evalúa el estado actual del repo contra la rúbrica del Obligatorio de BDD2 (`docs/rubrica.md`). Recorre las seis partes verificando criterios concretos y devuelve un puntaje detallado, ítems faltantes y recomendaciones. Úsala cuando el usuario pida "evaluar", "ver cómo vamos", "revisar progreso", "auditar el obligatorio" o variantes.
---

# Evaluar Obligatorio BDD2

Esta skill audita el repo contra la rúbrica oficial del equipo (`docs/rubrica.md`).

## Procedimiento

### 1. Cargar la rúbrica
Leer `docs/rubrica.md`. Si no existe, **abortar** con un mensaje que diga "no encuentro la rúbrica en docs/rubrica.md".

### 2. Recorrer las partes

Para cada parte, verificar los criterios listados abajo. Por cada criterio: asignar puntos completos / parciales / cero. **Justificá la asignación citando archivos y líneas concretas.**

#### Parte 1 — Modelo Relacional (8 pts)
- **Análisis y supuestos** (1.5): Buscar en `parte1/` o `documentacion/` (o equivalentes) un documento de análisis. Verificar que documente supuestos explícitos.
- **Tabla de restricciones** (1.5): Verificar `parte1/tablaRestricciones.md`. Contar restricciones por integrante. Verificar columnas: Restricción / Tabla / Tipo / Implementación / Comentarios. Penalizar si > 20% de columnas vacías.
- **DDL completo** (3.0): Listar `scripts/ddl/*.sql`. Verificar que existan tablas para: USUARIO (+ teléfonos), AGENTE, CONFIGURACION_HISTORICA, TRANSFERENCIA_AGENTE, COMUNIDAD, PARTICIPACION, PUBLICACION, COMENTARIO, VOTO, MODERACION. Si Oracle está corriendo (`docker ps` muestra `oracle-moltbook`), ejecutar los scripts y reportar errores.
- **Datos de prueba** (2.0): Buscar scripts de INSERT. Verificar que cubran casos límite: comunidad archivada, publicación cerrada/eliminada, comentarios anidados, votos +/-, agente suspendido, varias versiones de configuración.

#### Parte 2 — Servicios Relacionales (9 pts)
Buscar procedimientos/funciones en `scripts/servicios/` o equivalentes. Para cada uno de los 8 requerimientos (2.1 a 2.8), verificar existencia y completitud según rúbrica. **Los obligatorios son 2.1, 2.2, 2.3, 2.6, 2.8** — si falta alguno, marcar como riesgo crítico de reprobación.

Para cada SP, leer y validar:
- Que aplique las validaciones de negocio listadas en la rúbrica
- Que use parámetros razonables (no hardcoded)
- Que maneje errores con `RAISE_APPLICATION_ERROR` apropiados

#### Parte 3 — SQL + Plan de Ejecución (4 pts)
Buscar archivo con la consulta SQL + análisis del plan (típicamente `parte3/` o `documentacion/parte_3_*.md`). Verificar:
- Consulta involucra ≥ 4 tablas
- Documentación del plan de ejecución (capturas o texto)
- Identificación de operaciones (nested loops, hash join, etc.)
- Reflexión sobre eficiencia

#### Parte 4 — MongoDB diseño e integración (6 pts)
- `mongodb/06_colecciones.js` o equivalente: ≤ 2 colecciones, schema validators presentes
- Script de integración Oracle → MongoDB (Python/JS): verificar existencia y que esté documentado
- Datos de prueba: verificar conteos (`mongosh --eval "db.eventos.countDocuments({})"` si Mongo está corriendo)
- Aplicación de patrones del material (polymorphic, subset, bucket): buscar comentarios o documentación que los mencione

#### Parte 5 — Consultas MongoDB (4 pts)
Buscar tres archivos (`08_consulta_5_1.js`, `5_2.js`, `5_3.js` o equivalentes). Para cada uno, validar que:
- 5.1 filtre por agente + rango fechas + tipo "decision" y devuelva contexto + parámetros
- 5.2 filtre criticidad "alta" última semana, agrupe por agente, devuelva total + proporción, top 5
- 5.3 use `$hour` con timezone, agrupe por hora dentro de franja

#### Parte 6 — Reflexión MongoDB (2 pts)
Buscar `documentacion/parte_6_*.md` o equivalente. Verificar que responda las 3 preguntas (aplicación de conceptos, mejoras, ventajas/desventajas + otro caso de uso).

#### Aspectos generales (2 pts)
- Estructura de carpetas clara
- README con instrucciones de ejecución
- Capturas de evidencia para SPs que retornan colecciones (si aplica)
- Sección documentando uso de IA

### 3. Generar reporte

Producir un reporte estructurado:

```markdown
# Evaluación Obligatorio BDD2 — <fecha>

## Resumen
- **Puntaje estimado:** X / 35
- **Estado:** APRUEBA / EN RIESGO / NO APRUEBA
- **Requerimientos obligatorios completos:** sí / no

## Detalle por parte

### Parte 1: X.X / 8
- ✅ Análisis y supuestos (1.5/1.5) — encontrado en `parte1/analisis.md:42`
- ⚠️ Tabla de restricciones (1.0/1.5) — falta clasificación de tipo en 8 filas
- ✅ DDL (3.0/3.0)
- ❌ Datos de prueba (0.5/2.0) — no encontré inserts para casos límite

[...repetir para cada parte...]

## Faltantes críticos
1. Servicio 2.X no implementado (OBLIGATORIO)
2. ...

## Recomendaciones priorizadas
1. ...
```

### 4. Reglas

- **Trust pero verifica:** si un archivo dice "implementado" pero el SP no compila o falta una validación, contalo como parcial.
- **Citá siempre archivo:línea** en cada hallazgo.
- **No inventes archivos:** si no existen, marcá como faltante (✅ ⚠️ ❌).
- **Si Oracle está corriendo** (`docker ps | grep oracle-moltbook`): correr los scripts DDL contra él para validar que no hay errores de sintaxis. Si no está, asumir validez sintáctica y marcarlo en el reporte.
- **Si Mongo está corriendo** (`mongosh --quiet --eval "db.runCommand({ping:1})"`): correr las consultas 5.x para verificar que devuelven resultados.
- Reportar siempre los **ítems pendientes de otros integrantes** (Jero, Feli) sin asignar culpa — útil para que el equipo sepa qué priorizar.
