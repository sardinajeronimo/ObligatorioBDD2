# Rúbrica de evaluación — Obligatorio Bases de Datos 2 (Moltbook)

> Construida a partir de la consigna oficial (`docs/consigna.pdf`, 27/04/2026).
> **Puntaje máximo:** 35 · **Mínimo para aprobar:** 15 · **Defensa oral obligatoria y eliminatoria.**

Todos los puntajes son acumulativos. Cada ítem es independiente: se otorgan según la calidad de la entrega, no como "todo o nada" salvo donde se indica explícitamente.

---

## Parte 1 — Modelo Relacional (8 ptos)

| Criterio | Pts | Cumple completamente | Cumple parcialmente | No cumple |
|---|:--:|---|---|---|
| 1.1 Análisis y supuestos documentados | 1.5 | Discute decisiones de modelado, supuestos explícitos sobre cardinalidades y reglas de negocio | Supuestos parciales o muy genéricos | No hay sección de análisis |
| 1.2 Tabla de restricciones de integridad | 1.5 | Todas las restricciones identificadas, clasificadas (entidad / referencial / dominio / semántica) y por implementación (estructural / no estructural) | Falta clasificar > 20% o columnas vacías | No hay tabla |
| 1.3 DDL completo y ejecutable | 3.0 | Crea todas las entidades del enunciado (Usuario, Agente, Configuración Histórica, Transferencia, Comunidad, Participación, Publicación, Comentario, Voto, Moderación) con FKs y checks estructurales. Ejecuta sin errores en Oracle | Faltan ≤ 2 entidades o fallas menores | Faltan > 2 entidades, o el script no corre |
| 1.4 Datos de prueba coherentes | 2.0 | Datos cubren las validaciones más complejas: comunidad archivada, publicación cerrada/eliminada, comentarios anidados, votos +/-, agente suspendido, configuraciones múltiples | Datos cubren casos básicos pero no los límites | Datos triviales o inexistentes |

**Cobertura mínima esperada de entidades:** USUARIO (+ teléfonos), AGENTE, CONFIGURACION_HISTORICA, TRANSFERENCIA_AGENTE, COMUNIDAD, PARTICIPACION, PUBLICACION, COMENTARIO, VOTO, MODERACION.

---

## Parte 2 — Servicios Relacionales (9 ptos)

> **Obligatorios** (sin estos no se aprueba el obligatorio): 2.1, 2.2, 2.3, 2.6, 2.8.
> **Opcionales** (suman pero no son requisito): 2.4, 2.5, 2.7.

| Req | Pts | Descripción | Criterio |
|---|:--:|---|---|
| 2.1 | 1.5 | Registrar agente de IA | Crea agente, lo asocia al usuario administrador, registra tipo y configuración inicial, **genera primer registro en CONFIGURACION_HISTORICA** con versión inicial |
| 2.2 | 1.5 | Transferir agente entre usuarios | Cambia el administrador, **conserva historial de transferencias** (no sobrescribe) |
| 2.3 | 1.5 | Crear publicación | Valida que el agente sea **miembro activo de la comunidad**, registra título, fecha, contenido (no vacío) y comunidad |
| 2.4 | 0.5 | Emitir voto | Inserta el voto y **actualiza puntaje total de la publicación** atómicamente. Rechaza voto duplicado del mismo agente |
| 2.5 | 0.5 | Generar comentario | Vincula a publicación O a otro comentario (jerarquía). Rechaza si la publicación está cerrada |
| 2.6 | 1.5 | Acción de moderación | Solo agentes Moderadores **que pertenezcan a la comunidad** pueden ejecutar la acción sobre contenido de esa comunidad. Registra tipo de acción, fecha y vínculos |
| 2.7 | 0.5 | Actualizar configuración | Agrega nueva versión a CONFIGURACION_HISTORICA, modifica config activa del agente |
| 2.8 | 1.5 | Ranking top 10 publicaciones | Filtra activas, **últimos 30 días**, comunidad específica, mayor puntaje positivo. Filtro opcional por usuario administrador. Devuelve puntaje, título, fecha, agente, admin |

**Penalización:** -0.5 pts por cada validación obligatoria omitida (rol del agente, pertenencia, estado de la publicación/comunidad, etc).

---

## Parte 3 — Consulta SQL + Plan de Ejecución (4 ptos)

| Criterio | Pts |
|---|:--:|
| Consulta involucra al menos 4 tablas | 0.5 |
| Consulta responde una **necesidad concreta del usuario / negocio** (no es ejercicio sintético) | 1.0 |
| Plan de ejecución obtenido y adjuntado | 0.5 |
| Identificación correcta de operaciones (nested loops, hash join, index range scan, etc.) | 1.0 |
| Relación con algoritmos vistos en clase + reflexión sobre eficiencia y mejoras concretas (índices, reescritura) | 1.0 |

---

## Parte 4 — MongoDB: diseño e integración (6 ptos)

| Criterio | Pts |
|---|:--:|
| 4.1 Análisis y supuestos del modelado Mongo | 1.0 |
| 4.2 Diseño en **máximo 2 colecciones**, con campos predefinidos + variaciones (estructuras anidadas, listas, opcionales). Aplicación de patrones del material de referencia (polymorphic, subset, bucket, etc.) | 1.5 |
| 4.3 Schema validators (`$jsonSchema`) para cada colección | 1.0 |
| 4.4 Datos de prueba coherentes en volumen con la BD relacional ("si en BD relacional hay 1.000 → equivalentemente en Mongo") | 1.0 |
| 4.5 Proceso de integración Oracle → MongoDB documentado y ejecutable. Resulta en eventos generados a partir de las acciones detectadas | 1.5 |

---

## Parte 5 — Consultas MongoDB (4 ptos)

| Req | Pts | Verificación |
|---|:--:|---|
| 5.1 Eventos "decisión" de un agente en rango de fechas, cronológico, incluyendo **contexto operacional y parámetros de entrada** | 1.5 | Aggregation o find con proyección, soporta rango de fechas, devuelve campos pedidos |
| 5.2 Top 5 agentes con eventos criticidad "alta" en última semana, **cantidad total + proporción del agente en ese período** | 1.5 | Pipeline `$match` → `$group` → `$lookup`/segundo `$group` para proporción → `$sort` → `$limit 5` |
| 5.3 Eventos "interacción con usuario" de un agente, agrupados por hora dentro de franja horaria, **cantidad por hora** | 1.0 | Pipeline con `$hour` + `$group` + `$sort` |

---

## Parte 6 — Reflexión MongoDB (2 ptos)

| Pregunta | Pts |
|---|:--:|
| ¿Cómo aplicaron los conceptos del material en el modelado? (ejemplos específicos) | 0.7 |
| ¿Su modelado puede ser mejorado? (propuestas concretas) | 0.7 |
| Ventajas/desventajas de MongoDB en este subsistema + otro caso de uso del obligatorio candidato a Mongo | 0.6 |

---

## Aspectos generales y entrega (2 ptos)

| Criterio | Pts |
|---|:--:|
| Estructura de entrega: carpeta **Documentación** + scripts de estructura + scripts de datos + guía de pasaje Oracle→Mongo, todo dentro de un único zip/rar ≤ 40 MB | 0.5 |
| Claridad y prolijidad del informe | 0.5 |
| Capturas de evidencia para servicios que retornan colecciones | 0.5 |
| Citación correcta del uso de IA (herramienta utilizada + contexto de uso) | 0.5 |

---

## Defensa (eliminatoria, no suma puntos)

- Cada integrante debe poder **defender cualquier parte** del trabajo.
- Si no se presenta a la defensa: **se pierde la totalidad de los puntos** del obligatorio.

---

## Resumen de pesos

| Sección | Pts |
|---|:--:|
| Parte 1 — Modelo Relacional | 8 |
| Parte 2 — Servicios Relacionales | 9 |
| Parte 3 — SQL + Plan de Ejecución | 4 |
| Parte 4 — MongoDB diseño + integración | 6 |
| Parte 5 — Consultas MongoDB | 4 |
| Parte 6 — Reflexión MongoDB | 2 |
| Entrega y aspectos generales | 2 |
| **TOTAL** | **35** |

Aprueba con ≥ 15 ptos **y** defensa exitosa.
