// Completa la configuración de Firebase usando la sesión de Firebase CLI:
//  1. Crea la Realtime Database principal (la primera no se puede crear con el CLI)
//  2. Crea la clave de la cuenta de servicio y escribe firmware/central/secretos.h
// Uso: node completar.js <id-del-proyecto>
// Después: node generar_identidad.js (ID y código de la central)
const fs = require('fs');
const path = require('path');
const lib = 'C:/Users/santi/AppData/Roaming/npm/node_modules/firebase-tools/lib/';
const { requireAuth } = require(lib + 'requireAuth');
const { Client } = require(lib + 'apiv2');
const { configstore } = require(lib + 'configstore');

const proyecto = process.argv[2];
const instancia = `${proyecto}-default-rtdb`;
const urlBaseDatos = `https://${instancia}.firebaseio.com`;

async function main() {
  // Sesión guardada por "firebase login"
  await requireAuth({ user: configstore.get('user'), tokens: configstore.get('tokens') });

  // 1. Realtime Database principal
  const rtdb = new Client({ urlPrefix: 'https://firebasedatabase.googleapis.com', apiVersion: 'v1beta' });
  try {
    await rtdb.request({
      method: 'POST',
      path: `/projects/${proyecto}/locations/us-central1/instances`,
      queryParams: { databaseId: instancia },
      body: { type: 'DEFAULT_DATABASE' },
    });
    console.log('Base de datos creada:', urlBaseDatos);
  } catch (e) {
    if (String(e.message).includes('already exists')) console.log('La base de datos ya existía');
    else throw e;
  }

  // 2. Clave de la cuenta de servicio de Firebase (la usa la Placa de desarrollo ESP32)
  const iam = new Client({ urlPrefix: 'https://iam.googleapis.com', apiVersion: 'v1' });
  const lista = await iam.request({ method: 'GET', path: `/projects/${proyecto}/serviceAccounts` });
  const cuenta = (lista.body.accounts || []).find((c) => c.email.startsWith('firebase-adminsdk'));
  if (!cuenta) throw new Error('No se encontró la cuenta firebase-adminsdk');

  const clave = await iam.request({
    method: 'POST',
    path: `/projects/${proyecto}/serviceAccounts/${cuenta.email}/keys`,
    body: {},
  });
  const json = JSON.parse(Buffer.from(clave.body.privateKeyData, 'base64').toString('utf8'));

  // La clave se escribe como texto C (los saltos de línea quedan como \n)
  const claveC = json.private_key.replace(/\n/g, '\\n');
  const destino = path.join(__dirname, '..', '..', 'firmware', 'central', 'secretos.h');
  fs.writeFileSync(destino, `// Claves de la central. NO subir a GitHub.

// Escribe aquí tu red Wi-Fi (debe ser de 2.4 GHz)
#define WIFI_SSID "NOMBRE_DE_TU_WIFI"
#define WIFI_PASSWORD "CLAVE_DE_TU_WIFI"

#define DATABASE_URL "${urlBaseDatos}"
#define FIREBASE_PROJECT_ID "${json.project_id}"
#define FIREBASE_CLIENT_EMAIL "${json.client_email}"
const char PRIVATE_KEY[] PROGMEM = "${claveC}";
`);
  console.log('secretos.h escrito con la cuenta', json.client_email);
}

main().then(
  () => console.log('COMPLETADO'),
  (e) => { console.error('ERROR:', e.message); process.exit(1); },
);
