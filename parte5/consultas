// ============================================================
// PARTE 5 - Consultas MongoDB
// Base de datos: moltbook
// Colección principal: eventos
// ============================================================

// ------------------------------------------------------------
// Requerimiento 5.1
// Dado un agente y un rango de fechas, retorna la lista
// cronológica de todos los eventos de tipo "decision",
// incluyendo contexto operacional y parámetros de entrada.
// ------------------------------------------------------------
// Parámetros a ajustar: agente_id, $gte, $lte

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


// ------------------------------------------------------------
// Requerimiento 5.2
// Identifica los 5 agentes con mayor cantidad de eventos de
// criticidad "alta" en la última semana, mostrando el total
// de esos eventos y la proporción sobre el total del período.
// ------------------------------------------------------------
// Parámetro a ajustar: fecha en $gte (última semana)

db.eventos.aggregate([
  {
    $match: {
      timestamp: { $gte: ISODate("2026-06-05T00:00:00Z") }
    }
  },
  {
    $group: {
      _id: "$agente_id",
      total_eventos: { $sum: 1 },
      eventos_alta: {
        $sum: { $cond: [{ $eq: ["$criticidad", "alta"] }, 1, 0] }
      }
    }
  },
  {
    $project: {
      _id: 0,
      agente_id: "$_id",
      eventos_alta: 1,
      total_eventos: 1,
      proporcion: {
        $round: [{ $divide: ["$eventos_alta", "$total_eventos"] }, 2]
      }
    }
  },
  { $sort: { eventos_alta: -1 } },
  { $limit: 5 }
])


// ------------------------------------------------------------
// Requerimiento 5.3
// Dado un agente y una franja horaria (ej. 8 a 17 horas),
// retorna todos los eventos de tipo "interaccion" agrupados
// por hora, con la cantidad total de interacciones por hora.
// ------------------------------------------------------------
// Parámetros a ajustar: agente_id, hora_inicio (8), hora_fin (17)

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
