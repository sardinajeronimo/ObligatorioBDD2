// Parte 5 — Consultas sobre el subsistema de analitica (coleccion `eventos`).
// Ejecutar contra la BD `moltbook` poblada por parte4/02_datos_prueba.js
// (o por parte4/03_integracion_oracle_mongo.js).

// =============================================================================
// 5.1 — Eventos "decision" de un agente en un rango de fechas, en orden
//        cronologico, incluyendo su contexto operacional y parametros de entrada.
// =============================================================================
db.eventos.find(
  {
    agente_id: 1,
    tipo_evento: "decision",
    timestamp: {
      $gte: ISODate("2026-01-01T00:00:00Z"),
      $lte: ISODate("2026-06-30T23:59:59Z")
    }
  },
  {
    _id: 0,
    agente_id: 1,
    tipo_evento: 1,
    criticidad: 1,
    timestamp: 1,
    contexto_operacional: 1,
    parametros_entrada: 1
  }
).sort({ timestamp: 1 })


// =============================================================================
// 5.2 — Top 5 agentes con mas eventos de criticidad "alta" en la ultima semana.
//        Para cada uno: cantidad total de eventos "alta" y su PROPORCION sobre
//        el total de eventos "alta" del periodo (la cuota del agente en la semana).
//        El segundo $group calcula el total del periodo, necesario para la
//        proporcion: un solo $group no puede ver las filas de los demas agentes.
// =============================================================================
db.eventos.aggregate([
  {
    $match: {
      criticidad: "alta",
      timestamp: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
    }
  },
  {
    $group: {
      _id: "$agente_id",
      eventos_alta: { $sum: 1 }
    }
  },
  {
    $group: {
      _id: null,
      total_periodo: { $sum: "$eventos_alta" },
      agentes: { $push: { agente_id: "$_id", eventos_alta: "$eventos_alta" } }
    }
  },
  { $unwind: "$agentes" },
  {
    $project: {
      _id: 0,
      agente_id: "$agentes.agente_id",
      eventos_alta: "$agentes.eventos_alta",
      total_periodo: 1,
      proporcion: {
        $round: [{ $divide: ["$agentes.eventos_alta", "$total_periodo"] }, 2]
      }
    }
  },
  { $sort: { eventos_alta: -1 } },
  { $limit: 5 }
])


// =============================================================================
// 5.3 — Eventos "interaccion con usuario" de un agente, dentro de una franja
//        horaria (08:00-17:00), agrupados por hora con la cantidad por hora.
// =============================================================================
db.eventos.aggregate([
  {
    $match: {
      agente_id: 1,
      tipo_evento: "interaccion",
      $expr: {
        $and: [
          { $gte: [{ $hour: "$timestamp" }, 8] },
          { $lte: [{ $hour: "$timestamp" }, 17] }
        ]
      }
    }
  },
  {
    $group: {
      _id: { hora: { $hour: "$timestamp" } },
      total_interacciones: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      hora: "$_id.hora",
      total_interacciones: 1
    }
  },
  { $sort: { hora: 1 } }
])
