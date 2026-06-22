
const oracledb = require("oracledb");
const { MongoClient } = require("mongodb");

const ORA = {
  user:          process.env.ORA_USER || "MOLTBOOK",
  password:      process.env.ORA_PASS || "moltbook",
  connectString: process.env.ORA_CONN || "localhost:1521/FREEPDB1",
};
const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017";

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.fetchAsString = [oracledb.CLOB];

function criticidadDe(tipoEvento) {
  return ({ error: "alta", moderacion: "alta", decision: "media", comentario: "media",
            creacion: "baja", voto: "baja", interaccion: "baja" })[tipoEvento] || "media";
}

function eventoBase(agente, tipoEvento, ts, extra) {
  return Object.assign({
    agente_id:   agente.ID_AGENTE,
    tipo_agente: agente.TIPO,
    tipo_evento: tipoEvento,
    criticidad:  criticidadDe(tipoEvento),
    timestamp:   ts,
  }, extra);
}

async function main() {
  const ora = await oracledb.getConnection(ORA);
  const mongo = new MongoClient(MONGO_URI);
  await mongo.connect();
  const db = mongo.db("moltbook");
  const eventos = db.collection("eventos");
  const agentes = db.collection("agentes");

  const ags = (await ora.execute(`
    SELECT a.id_agente, a.nombre, a.identificador, a.tipo, a.estado,
           a.fecha_creacion,
           u.id_usuario AS admin_id, u.alias AS admin_alias, u.nombre_completo AS admin_nombre
      FROM AGENTE a JOIN USUARIO u ON u.id_usuario = a.id_usuario_admin`)).rows;

  await agentes.deleteMany({});
  await agentes.insertMany(ags.map(a => ({
    _id:           a.ID_AGENTE,
    nombre:        a.NOMBRE,
    identificador: a.IDENTIFICADOR,
    tipo:          a.TIPO,
    estado:        a.ESTADO,
    usuario_admin: { id: a.ADMIN_ID, alias: a.ADMIN_ALIAS, nombre: a.ADMIN_NOMBRE },
    fecha_creacion: a.FECHA_CREACION,
  })));
  console.log(`agentes: ${ags.length} documentos`);

  const agById = {};
  ags.forEach(a => { agById[a.ID_AGENTE] = { ID_AGENTE: a.ID_AGENTE, TIPO: a.TIPO }; });

  await eventos.deleteMany({});
  const docs = [];


  const pubs = (await ora.execute(`
    SELECT c.id_agente, c.fecha_hora_creacion AS ts, p.id_contenido, p.titulo,
           p.id_comunidad, com.nombre AS comunidad
      FROM PUBLICACION p
      JOIN CONTENIDO c   ON c.id_contenido = p.id_contenido
      JOIN COMUNIDAD com ON com.id_comunidad = p.id_comunidad`)).rows;
  for (const p of pubs) {
    docs.push(eventoBase(agById[p.ID_AGENTE], "creacion", p.TS, {
      contexto_operacional: { comunidad_id: p.ID_COMUNIDAD, comunidad_nombre: p.COMUNIDAD, origen: "oracle" },
      detalle: { contenido_id: p.ID_CONTENIDO, titulo: p.TITULO },
    }));
  }

  const coms = (await ora.execute(`
    SELECT c.id_agente, c.fecha_hora_creacion AS ts, cm.id_contenido,
           cm.id_publicacion, p.id_comunidad, com.nombre AS comunidad
      FROM COMENTARIO cm
      JOIN CONTENIDO c   ON c.id_contenido = cm.id_contenido
      JOIN PUBLICACION p ON p.id_contenido = cm.id_publicacion
      JOIN COMUNIDAD com ON com.id_comunidad = p.id_comunidad`)).rows;
  for (const c of coms) {
    docs.push(eventoBase(agById[c.ID_AGENTE], "comentario", c.TS, {
      contexto_operacional: { comunidad_id: c.ID_COMUNIDAD, comunidad_nombre: c.COMUNIDAD, origen: "oracle" },
      detalle: { comentario_id: c.ID_CONTENIDO, publicacion_id: c.ID_PUBLICACION },
    }));
  }

  const votos = (await ora.execute(`
    SELECT v.id_agente, v.fecha_hora AS ts, v.id_publicacion, v.tipo
      FROM VOTO v`)).rows;
  for (const v of votos) {
    docs.push(eventoBase(agById[v.ID_AGENTE], "voto", v.TS, {
      detalle: { publicacion_id: v.ID_PUBLICACION, tipo_voto: v.TIPO },
    }));
  }

  const mods = (await ora.execute(`
    SELECT m.id_agente, m.fecha_hora AS ts, m.id_contenido, m.id_comunidad,
           m.tipo_accion, com.nombre AS comunidad
      FROM MODERACION m JOIN COMUNIDAD com ON com.id_comunidad = m.id_comunidad`)).rows;
  for (const m of mods) {
    docs.push(eventoBase(agById[m.ID_AGENTE], "moderacion", m.TS, {
      contexto_operacional: { comunidad_id: m.ID_COMUNIDAD, comunidad_nombre: m.COMUNIDAD, origen: "oracle" },
      detalle: { contenido_id: m.ID_CONTENIDO, accion: m.TIPO_ACCION },
    }));
  }

  const cfgs = (await ora.execute(`
    SELECT ch.id_agente, ch.fecha_aplicacion AS ts, ch.version,
           ch.configuracion_historica AS config, ch.descripcion_cambio
      FROM CONFIGURACION_HISTORICA ch`)).rows;
  for (const ch of cfgs) {
    docs.push(eventoBase(agById[ch.ID_AGENTE], "decision", ch.TS, {
      parametros_entrada: { version: ch.VERSION, configuracion: ch.CONFIG },
      detalle: { motivo: ch.DESCRIPCION_CAMBIO, opcion_elegida: "aplicar_version_" + ch.VERSION },
    }));
  }

  const ahora = Date.now();
  const DIA = 24 * 60 * 60 * 1000;
  function tsHace(dias, hora) {
    const d = new Date(ahora - dias * DIA);
    d.setHours(hora, Math.floor(Math.random() * 60), 0, 0);
    return d;
  }
  const rnd = (n) => Math.floor(Math.random() * n);

  for (const a of ags) {
    const ag = { ID_AGENTE: a.ID_AGENTE, TIPO: a.TIPO };
    for (let i = 0; i < 3; i++) {
      docs.push(eventoBase(ag, "decision", tsHace(rnd(10), 9 + rnd(8)), {
        contexto_operacional: { sesion_id: "s-" + a.ID_AGENTE + "-" + i, origen: "runtime" },
        parametros_entrada: { prompt_tokens: 100 + rnd(400), temperatura: 0.7 },
        detalle: {
          alternativas_evaluadas: [
            { opcion: "A", score: Number((Math.random()).toFixed(2)) },
            { opcion: "B", score: Number((Math.random()).toFixed(2)) },
          ],
          opcion_elegida: "A",
          modelo: { nombre: "moltgpt-2", temperatura: 0.7 },
        },
        metricas: { tiempo_respuesta_ms: 200 + rnd(800), tokens_procesados: 300 + rnd(700), uso_memoria_mb: 50 + rnd(150) },
      }));
    }
    for (let i = 0; i < 4; i++) {
      docs.push(eventoBase(ag, "interaccion", tsHace(rnd(7), 8 + rnd(10)), {
        contexto_operacional: { sesion_id: "s-" + a.ID_AGENTE + "-i" + i, origen: "runtime" },
        parametros_entrada: { canal: "chat" },
        detalle: { usuario_alias: a.ADMIN_ALIAS, canal: "chat", mensaje_resumen: "consulta del usuario #" + i },
        metricas: { tiempo_respuesta_ms: 150 + rnd(500), tokens_procesados: 80 + rnd(300) },
      }));
    }
    const nErr = rnd(3);
    for (let i = 0; i < nErr; i++) {
      docs.push(eventoBase(ag, "error", tsHace(rnd(7), rnd(24)), {
        detalle: { codigo: ["TIMEOUT", "RATE_LIMIT", "PARSE_ERROR"][rnd(3)], mensaje: "fallo en ejecucion" },
        anomalia: { detectada: true, patron: "latencia_alta", score: Number((0.7 + Math.random() * 0.3).toFixed(2)) },
      }));
    }
  }

  const res = await eventos.insertMany(docs);
  console.log(`eventos: ${res.insertedCount} documentos insertados`);
  console.log("Distribucion por tipo_evento:");
  const dist = await eventos.aggregate([
    { $group: { _id: "$tipo_evento", n: { $sum: 1 } } },
    { $sort: { n: -1 } },
  ]).toArray();
  dist.forEach(d => console.log(`  ${d._id.padEnd(12)} ${d.n}`));

  await ora.close();
  await mongo.close();
  console.log("Integracion Oracle -> MongoDB completada.");
}

main().catch(err => { console.error(err); process.exit(1); });
