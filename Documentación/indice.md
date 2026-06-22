# Documentación - Obligatorio BDD2 (Moltbook)

Índice maestro de la entrega. Mapea cada parte de la rúbrica (`docs/rubrica.md`)
a los archivos del repositorio.

> **Informe completo:** además de los documentos enlazados aquí, el informe
> integral está en Google Docs (link en el `README.md` de la raíz). Las
> **capturas de evidencia** de los servicios que retornan colecciones están en
> [`Documentación/capturas/`](capturas/).

---

## Parte 1 - Modelo Relacional

| Criterio | Archivo |
|---|---|
| 1.1 Análisis y supuestos | [`parte1/analisis_supuestos.md`](../parte1/analisis_supuestos.md) |
| 1.2 Tabla de restricciones | [`parte1/tablaRestricciones.md`](../parte1/tablaRestricciones.md) |
| 1.3 DDL ejecutable | [`parte1/00_usuario_agente.sql`](../parte1/00_usuario_agente.sql), [`01_comunidad.sql`](../parte1/01_comunidad.sql), [`02_contenido.sql`](../parte1/02_contenido.sql), [`03_transferencia_agente.sql`](../parte1/03_transferencia_agente.sql) |
| 1.4 Datos de prueba | [`parte1/datos_prueba.sql`](../parte1/datos_prueba.sql) |
| Runner | [`parte1/run_all.sql`](../parte1/run_all.sql) · [`drop_all.sql`](../parte1/drop_all.sql) |

## Parte 2 - Servicios Relacionales

| Criterio | Archivo |
|---|---|
| 2.1 Registrar agente | [`parte2/sp_registrar_agente.sql`](../parte2/sp_registrar_agente.sql) |
| 2.2 Transferir administración | [`parte2/sp_transferir_administracion.sql`](../parte2/sp_transferir_administracion.sql) |
| 2.3 Crear publicación | [`parte2/sp_publicar.sql`](../parte2/sp_publicar.sql) |
| 2.4 Emitir voto | [`parte2/sp_emitir_voto.sql`](../parte2/sp_emitir_voto.sql) |
| 2.5 Comentar | [`parte2/sp_comentar.sql`](../parte2/sp_comentar.sql) |
| 2.6 Moderar contenido | [`parte2/sp_moderar_contenido.sql`](../parte2/sp_moderar_contenido.sql) |
| 2.7 Actualizar configuración | [`parte2/sp_actualizar_config_agente.sql`](../parte2/sp_actualizar_config_agente.sql) |
| 2.8 Ranking top 10 (retorna colección) | [`parte2/sp_ranking_publicaciones.sql`](../parte2/sp_ranking_publicaciones.sql) |
| Triggers (validaciones no estructurales) | [`parte2/trg_*.sql`](../parte2/) |
| Runner | [`parte2/00_ejecutar_todos.sql`](../parte2/00_ejecutar_todos.sql) |

## Parte 3 - Consulta SQL + Plan de Ejecución

| Criterio | Archivo |
|---|---|
| Consulta (4+ tablas) | [`parte3/ConsultaParte3.sql`](../parte3/ConsultaParte3.sql) |
| Plan + análisis | [`parte3/plan_explicado.txt`](../parte3/plan_explicado.txt) |

## Parte 4 - MongoDB: diseño e integración

| Criterio | Archivo |
|---|---|
| 4.1 / 4.2 Análisis y diseño de colecciones | [`parte4/analisis_modelo.md`](../parte4/analisis_modelo.md) |
| 4.3 Validators (`$jsonSchema`) + índices | [`parte4/01_colecciones_validators.js`](../parte4/01_colecciones_validators.js) |
| 4.4 Datos de prueba | [`parte4/02_datos_prueba.js`](../parte4/02_datos_prueba.js) |
| 4.5 Integración Oracle → Mongo (ETL) | [`parte4/03_integracion_oracle_mongo.js`](../parte4/03_integracion_oracle_mongo.js) |
| Guía de pasaje Oracle → Mongo | [`parte4/guia_pasaje_oracle_mongo.md`](../parte4/guia_pasaje_oracle_mongo.md) |

## Parte 5 - Consultas MongoDB (retornan colecciones)

| Criterio | Archivo |
|---|---|
| 5.1 / 5.2 / 5.3 | [`parte5/consultas_parte5.js`](../parte5/consultas_parte5.js) |
| Capturas de evidencia | [`Documentación/capturas/`](capturas/) |

## Parte 6 - Reflexión MongoDB

| Criterio | Archivo |
|---|---|
| Reflexión (3 preguntas) | [`parte6/reflexion_mongo.md`](../parte6/reflexion_mongo.md) |

---

## Aspectos generales y entrega

- **Estructura del repo:** ver `README.md` en la raíz.
- **Scripts de estructura:** `parte1/*.sql` (relacional), `parte4/01_colecciones_validators.js` (Mongo).
- **Scripts de datos:** `parte1/datos_prueba.sql`, `parte4/02_datos_prueba.js`.
- **Guía de pasaje Oracle → Mongo:** `parte4/guia_pasaje_oracle_mongo.md`.
- **Capturas de evidencia:** `Documentación/capturas/`.
- **Citación del uso de IA:** `Documentación/uso_de_IA.md`.
