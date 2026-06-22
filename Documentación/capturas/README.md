# Capturas de evidencia

Evidencia de ejecución de los servicios que retornan colecciones, tomadas en
**MongoDB Compass** sobre la base `moltbook` poblada con
`parte4/02_datos_prueba.js`.

| Captura | Requerimiento | Qué muestra |
|---|---|---|
| `parte5_1_consulta_decisiones.png` | 5.1 | `find` de eventos `decision` del agente 1 en rango de fechas, ordenado por `timestamp`, proyectando `contexto_operacional` y `parametros_entrada` (3 documentos). |
| `parte5_2_top5_criticidad_alta.png` | 5.2 | Pipeline de agregación: top 5 agentes por eventos de criticidad `alta` en la última semana, con `total_periodo` y `proporcion` del agente sobre el total del período. |
| `parte5_3_interacciones_por_hora.png` | 5.3 | Pipeline de agregación: eventos `interaccion` del agente 1 agrupados por hora dentro de la franja 08–17h, con la cantidad por hora. |

> **Pendiente:** la captura del ranking de la Parte 2.8 (`sp_ranking_publicaciones`,
> retorna `SYS_REFCURSOR`) requiere la instancia Oracle levantada; se agrega
> ejecutándolo desde SQL*Plus / SQL Developer.
