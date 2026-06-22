

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



db.eventos.aggregate([
  {
    $match: {
      timestamp: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
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
