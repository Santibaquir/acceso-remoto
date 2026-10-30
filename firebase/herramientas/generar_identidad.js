// Le da a la central su identidad TiGuard: CENTRAL_ID y CODIGO_VINCULACION.
// Los agrega a firmware/central/secretos.h si todavía no existen.
// Uso: node generar_identidad.js
//
// - CENTRAL_ID (10 caracteres): identifica la central en Firebase y en los
//   temas de notificación. No cambia nunca.
// - CODIGO_VINCULACION (8 caracteres): lo pide la app para unirse. Para
//   cambiarlo, bórralo de secretos.h, vuelve a ejecutar esto y graba la central.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Sin 0/O ni 1/I para que no se confundan al leerlos en la pantalla LCD
const ALFABETO = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const aleatorio = (n) =>
  Array.from(crypto.randomBytes(n), (b) => ALFABETO[b % ALFABETO.length]).join('');

const archivo = path.join(__dirname, '..', '..', 'firmware', 'central', 'secretos.h');
let texto = fs.readFileSync(archivo, 'utf8');

for (const [nombre, largo] of [['CENTRAL_ID', 10], ['CODIGO_VINCULACION', 8]]) {
  if (new RegExp(`#define ${nombre} "`).test(texto)) {
    console.log(`${nombre} ya existe: no se cambia`);
    continue;
  }
  const valor = aleatorio(largo);
  texto += `\n#define ${nombre} "${valor}"\n`;
  console.log(`${nombre} = ${valor}`);
}

fs.writeFileSync(archivo, texto);
