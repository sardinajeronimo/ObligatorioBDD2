// ============================================================
// PARTE 4.4 - Datos de prueba (portable, NO requiere Oracle)
// Base de datos: moltbook
// Ejecutar DESPUES de 01_colecciones_validators.js:
//   mongosh --file parte4/02_datos_prueba.js
// ============================================================
// Genera un volumen coherente con la BD relacional de la parte 1:
//   * 9 agentes (los mismos ids/tipos que el seed Oracle)
//   * eventos derivados de acciones (creacion/comentario/voto/moderacion)
//   * eventos internos de runtime (decision/interaccion/error) de los
//     ultimos 14 dias, para alimentar las consultas 5.1, 5.2 y 5.3.
// Si se dispone de Oracle, usar en su lugar 03_integracion_oracle_mongo.js,
// que produce exactamente los mismos documentos a partir de datos reales.
// ============================================================

const db = db.getSiblingDB("moltbook");
db.eventos.deleteMany({});
db.agentes.deleteMany({});

// --- AGENTES (subset). Ids y tipos identicos al seed relacional. ---
const AGENTES = [
  { _id: 1, ident: "genbot-alpha",  nombre: "GenBot Alpha", tipo: "GENERADOR",  estado: "Activo",      admin: { id: 1, alias: "ana_gomez",  nombre: "Ana Gomez"  } },
  { _id: 2, ident: "genbot-beta",   nombre: "GenBot Beta",  tipo: "GENERADOR",  estado: "Activo",      admin: { id: 2, alias: "carlos_d",   nombre: "Carlos Diaz"} },
  { _id: 3, ident: "genbot-gamma",  nombre: "GenBot Gamma", tipo: "GENERADOR",  estado: "Suspendido",  admin: { id: 3, alias: "lu_vega",    nombre: "Lucia Vega" } },
  { _id: 4, ident: "modbot-prime",  nombre: "ModBot Prime", tipo: "MODERADOR",  estado: "Activo",      admin: { id: 4, alias: "martin_rey", nombre: "Martin Rey" } },
  { _id: 5, ident: "modbot-etico",  nombre: "ModBot Etico", tipo: "MODERADOR",  estado: "Activo",      admin: { id: 5, alias: "sofia_luna", nombre: "Sofia Luna" } },
  { _id: 6, ident: "observabot-1",  nombre: "ObservaBot",   tipo: "OBSERVADOR", estado: "Activo",      admin: { id: 2, alias: "carlos_d",   nombre: "Carlos Diaz"} },
  { _id: 7, ident: "observabot-2",  nombre: "ObservaBot 2", tipo: "OBSERVADOR", estado: "Activo",      admin: { id: 4, alias: "martin_rey", nombre: "Martin Rey" } },
  { _id: 8, ident: "observabot-3",  nombre: "ObservaBot 3", tipo: "OBSERVADOR", estado: "Activo",      admin: { id: 5, alias: "sofia_luna", nombre: "Sofia Luna" } },
  { _id: 9, ident: "observabot-4",  nombre: "ObservaBot 4", tipo: "OBSERVADOR", estado: "Activo",      admin: { id: 1, alias: "ana_gomez",  nombre: "Ana Gomez"  } },
];
db.agentes.insertMany(AGENTES.map(a => ({
  _id: a._id, nombre: a.nombre, identificador: a.ident, tipo: a.tipo,
  estado: a.estado, usuario_admin: a.admin, fecha_creacion: new Date("2026-04-01T12:00:00Z"),
})));

// --- Politica de criticidad (misma que el ETL) ---
function criticidadDe(t) {
  return ({ error:"alta", moderacion:"alta", decision:"media", comentario:"media",
            creacion:"baja", voto:"baja", interaccion:"baja" })[t] || "media";
}
function base(a, tipo, ts, extra) {
  return Object.assign({ agente_id: a._id, tipo_agente: a.tipo, tipo_evento: tipo,
                         criticidad: criticidadDe(tipo), timestamp: ts }, extra);
}
const rnd = n => Math.floor(Math.random() * n);
const DIA = 864e5, AHORA = Date.now();
function tsHace(dias, hora) { const d = new Date(AHORA - dias*DIA); d.setHours(hora, rnd(60), 0, 0); return d; }

const docs = [];
const byId = Object.fromEntries(AGENTES.map(a => [a._id, a]));

// --- Eventos derivados de ACCIONES (muestra representativa) ---
docs.push(base(byId[1], "creacion", new Date("2026-05-20T10:00:00Z"),
  { contexto_operacional: { comunidad_id: 1, comunidad_nombre: "IA General", origen: "oracle" },
    detalle: { contenido_id: 1, titulo: "GPT-5 y el futuro de los LLMs" } }));
docs.push(base(byId[2], "comentario", new Date("2026-05-21T11:30:00Z"),
  { contexto_operacional: { comunidad_id: 1, comunidad_nombre: "IA General", origen: "oracle" },
    detalle: { comentario_id: 11, publicacion_id: 1 } }));
docs.push(base(byId[6], "voto", new Date("2026-05-22T09:15:00Z"),
  { detalle: { publicacion_id: 1, tipo_voto: "positivo" } }));
docs.push(base(byId[5], "moderacion", new Date("2026-05-25T16:45:00Z"),
  { contexto_operacional: { comunidad_id: 3, comunidad_nombre: "Etica en IA", origen: "oracle" },
    detalle: { contenido_id: 7, accion: "ocultar" } }));

// --- Eventos INTERNOS de runtime por agente ---
for (const a of AGENTES) {
  for (let i = 0; i < 3; i++) {
    docs.push(base(a, "decision", tsHace(rnd(10), 9 + rnd(8)), {
      contexto_operacional: { sesion_id: `s-${a._id}-${i}`, origen: "runtime" },
      parametros_entrada: { prompt_tokens: 100 + rnd(400), temperatura: 0.7 },
      detalle: { alternativas_evaluadas: [ { opcion: "A", score: +Math.random().toFixed(2) },
                                            { opcion: "B", score: +Math.random().toFixed(2) } ],
                 opcion_elegida: "A", modelo: { nombre: "moltgpt-2", temperatura: 0.7 } },
      metricas: { tiempo_respuesta_ms: 200 + rnd(800), tokens_procesados: 300 + rnd(700), uso_memoria_mb: 50 + rnd(150) },
    }));
  }
  for (let i = 0; i < 4; i++) {
    docs.push(base(a, "interaccion", tsHace(rnd(7), 8 + rnd(10)), {
      contexto_operacional: { sesion_id: `s-${a._id}-i${i}`, origen: "runtime" },
      parametros_entrada: { canal: "chat" },
      detalle: { usuario_alias: a.admin.alias, canal: "chat", mensaje_resumen: `consulta #${i}` },
      metricas: { tiempo_respuesta_ms: 150 + rnd(500), tokens_procesados: 80 + rnd(300) },
    }));
  }
  for (let i = 0, n = rnd(3); i < n; i++) {
    docs.push(base(a, "error", tsHace(rnd(7), rnd(24)), {
      detalle: { codigo: ["TIMEOUT","RATE_LIMIT","PARSE_ERROR"][rnd(3)], mensaje: "fallo en ejecucion" },
      anomalia: { detectada: true, patron: "latencia_alta", score: +(0.7 + Math.random()*0.3).toFixed(2) },
    }));
  }
}

db.eventos.insertMany(docs);
print(`agentes: ${db.agentes.countDocuments()}  |  eventos: ${db.eventos.countDocuments()}`);
printjson(db.eventos.aggregate([ { $group: { _id: "$tipo_evento", n: { $sum: 1 } } }, { $sort: { n: -1 } } ]).toArray());
