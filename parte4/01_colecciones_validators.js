
const db = db.getSiblingDB("moltbook");

db.eventos.drop();
db.agentes.drop();

db.createCollection("eventos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      title: "Validador de eventos de comportamiento de agentes",
      required: ["agente_id", "tipo_agente", "tipo_evento", "criticidad", "timestamp"],
      properties: {
        agente_id: {
          bsonType: "int",
          description: "Id del agente en Oracle (AGENTE.id_agente). Requerido."
        },
        tipo_agente: {
          enum: ["GENERADOR", "MODERADOR", "OBSERVADOR"],
          description: "Tipo del agente que genera el evento. Requerido."
        },
        tipo_evento: {
          bsonType: "string",
          minLength: 1,
          description: "Conjunto ABIERTO (decision, interaccion, creacion, voto, moderacion, comentario, error, acceso, ...). Requerido."
        },
        criticidad: {
          enum: ["alta", "media", "baja"],
          description: "Nivel de criticidad. Requerido."
        },
        timestamp: {
          bsonType: "date",
          description: "Momento del evento (ISODate). Requerido."
        },
        contexto_operacional: { bsonType: "object" },
        parametros_entrada:   { bsonType: "object" },
        metricas: {
          bsonType: "object",
          properties: {
            tiempo_respuesta_ms: { bsonType: ["int", "double"] },
            tokens_procesados:   { bsonType: ["int", "double"] },
            uso_memoria_mb:      { bsonType: ["int", "double"] }
          }
        },
        detalle:  { bsonType: "object" },
        anomalia: {
          bsonType: "object",
          properties: {
            detectada: { bsonType: "bool" },
            patron:    { bsonType: "string" },
            score:     { bsonType: ["int", "double"] }
          }
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

db.eventos.createIndex({ agente_id: 1, tipo_evento: 1, timestamp: 1 },
                       { name: "ix_agente_tipo_ts" });
db.eventos.createIndex({ timestamp: 1, criticidad: 1 },
                       { name: "ix_ts_criticidad" });

db.createCollection("agentes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      title: "Validador de snapshot de agentes",
      required: ["_id", "nombre", "identificador", "tipo", "estado", "fecha_creacion"],
      properties: {
        _id:           { bsonType: "int", description: "= AGENTE.id_agente" },
        nombre:        { bsonType: "string" },
        identificador: { bsonType: "string" },
        tipo:          { enum: ["GENERADOR", "MODERADOR", "OBSERVADOR"] },
        estado:        { enum: ["Activo", "Suspendido"] },
        usuario_admin: {
          bsonType: "object",
          required: ["id", "alias"],
          properties: {
            id:     { bsonType: "int" },
            alias:  { bsonType: "string" },
            nombre: { bsonType: "string" }
          }
        },
        fecha_creacion: { bsonType: "date" }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

db.agentes.createIndex({ tipo: 1 }, { name: "ix_tipo" });

print(">> Colecciones 'eventos' y 'agentes' creadas con validators e indices.");
