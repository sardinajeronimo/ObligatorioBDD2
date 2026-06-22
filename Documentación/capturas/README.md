# Capturas de evidencia

Evidencia de ejecución de los servicios que retornan colecciones.

**Parte 2.8** (relacional): `sp_ranking_publicaciones` ejecutado en **SQL\*Plus**
contra el contenedor Oracle `oracle-moltbook` (Oracle 23ai Free), sobre el
esquema poblado con `parte1/run_all.sql`.

**Parte 5** (MongoDB): consultas tomadas en **MongoDB Compass** sobre la base
`moltbook` poblada con `parte4/02_datos_prueba.js`.

| Captura | Requerimiento | Qué muestra |
|---|---|---|
| `parte2_8_ranking_publicaciones.png` | 2.8 | `sp_ranking_publicaciones(1, NULL, :rc)`: ranking de la comunidad "IA General" ordenado por `puntaje_total` desc (4 filas: puntaje, título, fecha, agente, admin). |
| `parte5_1_consulta_decisiones.png` | 5.1 | `find` de eventos `decision` del agente 1 en rango de fechas, ordenado por `timestamp`, proyectando `contexto_operacional` y `parametros_entrada` (3 documentos). |
| `parte5_2_top5_criticidad_alta.png` | 5.2 | Pipeline de agregación: top 5 agentes por eventos de criticidad `alta` en la última semana, con `total_periodo` y `proporcion` del agente sobre el total del período. |
| `parte5_3_interacciones_por_hora.png` | 5.3 | Pipeline de agregación: eventos `interaccion` del agente 1 agrupados por hora dentro de la franja 08–17h, con la cantidad por hora. |
