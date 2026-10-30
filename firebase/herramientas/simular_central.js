// Simula la central TiGuard (Placa de desarrollo ESP32) para probar la app sin hardware.
// Usa las mismas claves que la central (firmware/central/secretos.h) y las
// rutas de docs/ARQUITECTURA.md (sección 4).
//
//   node simular_central.js preparar         -> publica el código de vinculación y el estado inicial
//   node simular_central.js latido           -> la central aparece "en línea"
//   node simular_central.js alerta [N01]     -> alerta de movimiento + historial + push
//   node simular_central.js nodo [N02]       -> latido de un nodo (si es nuevo, se registra solo)
//   node simular_central.js pulsador         -> alguien apaga la alarma con el pulsador
//   node simular_central.js estado           -> muestra la central completa
//   node simular_central.js limpiar-viejo    -> borra las rutas de la versión Acceso Remoto
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ---------- Claves de secretos.h ----------
const secretos = fs.readFileSync(path.join(__dirname, '..', '..', 'firmware', 'central', 'secretos.h'), 'utf8');
const leer = (nombre) => {
  const r = secretos.match(new RegExp(`#define ${nombre} "([^"]*)"`));
  if (!r) throw new Error(`Falta #define ${nombre} en secretos.h (mira secretos_ejemplo.h)`);
  return r[1];
};
const URL_BD = leer('DATABASE_URL');
const PROYECTO = leer('FIREBASE_PROJECT_ID');
const CORREO = leer('FIREBASE_CLIENT_EMAIL');
const CENTRAL = leer('CENTRAL_ID');
const CODIGO = leer('CODIGO_VINCULACION');
const CLAVE = secretos.match(/PRIVATE_KEY\[\] PROGMEM = "([^"]*)"/)[1].replace(/\\n/g, '\n');

const BASE = `centrales/${CENTRAL}`;
const AHORA = { '.sv': 'timestamp' };

// Token de acceso de Google (OAuth con la cuenta de servicio), igual que hace la ESP32
async function token() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const ahora = Math.floor(Date.now() / 1000);
  const cuerpo = b64({ alg: 'RS256', typ: 'JWT' }) + '.' + b64({
    iss: CORREO,
    scope: 'https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: ahora,
    exp: ahora + 3600,
  });
  const firma = crypto.sign('RSA-SHA256', Buffer.from(cuerpo), CLAVE).toString('base64url');
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${cuerpo}.${firma}`,
  });
  const j = await r.json();
  if (!j.access_token) throw new Error('No se obtuvo token: ' + JSON.stringify(j));
  return j.access_token;
}

async function bd(t, metodo, ruta, datos) {
  const r = await fetch(`${URL_BD}/${ruta}.json`, {
    method: metodo,
    headers: { Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' },
    body: datos === undefined ? undefined : JSON.stringify(datos),
  });
  const texto = await r.text();
  if (!r.ok) throw new Error(`${metodo} ${ruta}: ${r.status} ${texto}`);
  return JSON.parse(texto);
}

// Igual que enviarPush() de la central
async function push(t, tema, canal, sonido, titulo, cuerpo) {
  const notificacion = { channel_id: canal, notification_priority: 'PRIORITY_MAX' };
  if (sonido) notificacion.sound = sonido;
  const r = await fetch(`https://fcm.googleapis.com/v1/projects/${PROYECTO}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        topic: tema,
        notification: { title: titulo, body: cuerpo },
        android: { priority: 'HIGH', notification: notificacion },
      },
    }),
  });
  console.log(`Push a "${tema}":`, r.status);
}

const tema = (sufijo) => `tg_${CENTRAL}_${sufijo}`;
const horaActual = () =>
  new Date().toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: false });

// Si el nodo no existe, se registra solo (igual que la central)
async function asegurarNodo(t, nodo) {
  const actual = await bd(t, 'GET', `${BASE}/nodos/${nodo}`);
  if (actual) return actual.nombre;
  await bd(t, 'PUT', `${BASE}/nodos/${nodo}`, {
    nombre: nodo, tipo: 'pir', activo: true, creado: AHORA, descubierto: true,
  });
  console.log(`Nodo ${nodo} descubierto y registrado`);
  return nodo;
}

async function main() {
  const accion = process.argv[2] || 'latido';
  const nodo = (process.argv[3] || 'N01').toUpperCase();
  const t = await token();

  if (accion === 'preparar') {
    await bd(t, 'PUT', `codigosVinculacion/${CENTRAL}`, CODIGO);
    await bd(t, 'PATCH', `${BASE}/estado`, { armado: true, alerta: false, ultimoLatido: AHORA });
    const horario = await bd(t, 'GET', `${BASE}/config/horario`);
    if (!horario) await bd(t, 'PUT', `${BASE}/config/horario`, { siempre: false, inicio: 22 * 60, fin: 6 * 60 });
    console.log(`Central ${CENTRAL} lista. Código de vinculación: ${CODIGO}`);
  } else if (accion === 'latido') {
    await bd(t, 'PATCH', `${BASE}/estado`, { ultimoLatido: AHORA });
    console.log('Latido enviado');
  } else if (accion === 'alerta') {
    const nombre = await asegurarNodo(t, nodo);
    await bd(t, 'PATCH', `${BASE}/estado`, { alerta: true, alertaNodo: nodo, ultimoLatido: AHORA });
    await bd(t, 'POST', `${BASE}/historial`, { nodo, nombre, tipo: 'movimiento', fecha: AHORA });
    await bd(t, 'PATCH', `${BASE}/nodos/${nodo}`, { ultimoContacto: AHORA });
    const titulo = 'Movimiento detectado';
    const cuerpo = `${nombre} · ${horaActual()}`;
    await push(t, tema('sirena'), 'movimiento_sirena', 'sirena', titulo, cuerpo);
    await push(t, tema('normal'), 'movimiento_normal', 'default', titulo, cuerpo);
    await push(t, tema('silencio'), 'movimiento_silencio', null, titulo, cuerpo);
    console.log(`Alerta de movimiento en ${nombre}`);
  } else if (accion === 'nodo') {
    await asegurarNodo(t, nodo);
    await bd(t, 'PATCH', `${BASE}/nodos/${nodo}`, { ultimoContacto: AHORA });
    console.log(`Latido del nodo ${nodo}`);
  } else if (accion === 'pulsador') {
    await bd(t, 'PATCH', `${BASE}/estado`, { alerta: false, desactivacion: { origen: 'pulsador', fecha: AHORA } });
    await push(t, tema('avisos'), 'avisos_central', 'default', 'Alarma desactivada',
      `Se apagó con el pulsador de la central a las ${horaActual()}`);
    console.log('Alarma apagada con el pulsador');
  } else if (accion === 'estado') {
    console.log(JSON.stringify(await bd(t, 'GET', BASE), null, 2));
  } else if (accion === 'limpiar-viejo') {
    await bd(t, 'DELETE', 'estado');
    await bd(t, 'DELETE', 'historial');
    console.log('Rutas de Acceso Remoto (estado/, historial/) borradas');
  } else {
    console.log('Acción desconocida. Mira el comentario al inicio del archivo.');
  }
}

main().catch((e) => { console.error('ERROR:', e.message); process.exit(1); });
