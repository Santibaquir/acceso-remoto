// Simula la Placa de desarrollo ESP32 para probar la app sin hardware.
// Usa la misma clave que la central (codigo_central/secretos.h).
//
//   node simular_central.js iniciar  -> estado inicial: armado y sin alerta
//   node simular_central.js latido   -> la central aparece "en línea"
//   node simular_central.js alerta   -> alerta + historial + notificación push
//   node simular_central.js estado   -> muestra lo que hay en estado/
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Leer las claves de secretos.h
const secretos = fs.readFileSync(path.join(__dirname, '..', '..', 'codigo_central', 'secretos.h'), 'utf8');
const leer = (nombre) => secretos.match(new RegExp(`#define ${nombre} "([^"]*)"`))[1];
const URL_BD = leer('DATABASE_URL');
const PROYECTO = leer('FIREBASE_PROJECT_ID');
const CORREO = leer('FIREBASE_CLIENT_EMAIL');
const CLAVE = secretos.match(/PRIVATE_KEY\[\] PROGMEM = "([^"]*)"/)[1].replace(/\\n/g, '\n');

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
  return texto;
}

const AHORA = { '.sv': 'timestamp' };

async function main() {
  const accion = process.argv[2] || 'latido';
  const t = await token();

  if (accion === 'iniciar') {
    await bd(t, 'PATCH', 'estado', { armado: true, alerta: false, ultimoLatido: AHORA });
    console.log('Estado inicial: armado, sin alerta');
  } else if (accion === 'latido') {
    await bd(t, 'PATCH', 'estado', { ultimoLatido: AHORA });
    console.log('Latido enviado');
  } else if (accion === 'alerta') {
    await bd(t, 'PATCH', 'estado', { alerta: true, ultimoLatido: AHORA });
    await bd(t, 'POST', 'historial', { sensor: 'BODEGA', fecha: AHORA });
    const hora = new Date().toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: false });
    const r = await fetch(`https://fcm.googleapis.com/v1/projects/${PROYECTO}/messages:send`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: {
          topic: 'alertas',
          notification: { title: '¡ALERTA CRÍTICA: BODEGA!', body: `Movimiento detectado a las ${hora}` },
          android: {
            priority: 'HIGH',
            notification: { channel_id: 'alertas_criticas', sound: 'sirena', notification_priority: 'PRIORITY_MAX' },
          },
        },
      }),
    });
    console.log('Alerta enviada. Push:', r.status, await r.text());
  } else if (accion === 'estado') {
    console.log(await bd(t, 'GET', 'estado'));
  }
}

main().catch((e) => { console.error('ERROR:', e.message); process.exit(1); });
