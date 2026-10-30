# TiGuard — Arquitectura del sistema

> **TiGuard** es la app de **TiGuard Secure**. Este documento es la referencia
> obligatoria antes de tocar la app, el firmware o Firebase. Si un cambio no
> encaja aquí, primero se actualiza este documento y después el código.

Versión del documento: 2.0 (octubre 2026) · Reemplaza al diseño de "Acceso Remoto".

---

## 1. Qué es TiGuard

Un sistema de vigilancia por zonas. Cada zona tiene un **nodo de vigilancia**
(Sensor de movimiento PIR HC-SR501 + Placa Arduino Nano + Módulo transceptor
NRF24L01) que avisa por radio a una **central** (Placa de desarrollo ESP32). La
central decide si la alerta vale (sistema armado, dentro del horario, nodo
activo), hace sonar la sirena local y publica la alerta en Firebase. La app
**TiGuard** muestra todo en tiempo real y recibe notificaciones push.

Principios:

1. **La central es la autoridad física.** Funciona sin internet: guarda en su
   memoria el último estado de armado y el horario, y la sirena suena igual.
2. **Firebase es la fuente de verdad remota.** La app nunca habla con la
   central directamente; las dos leen y escriben en Firebase.
3. **Multiusuario y multicentral desde el diseño.** Un usuario puede tener
   varias centrales; una central puede tener varios usuarios y muchos nodos.
4. **Seguro por defecto.** Las reglas de Firebase niegan todo lo que no se
   permite de forma explícita.

```
 Nodo N01 ─┐                                      ┌─ App TiGuard (celular 1)
 Nodo N02 ─┼─ radio 2.4 GHz ─► Central ESP32 ─► Firebase ─┼─ App TiGuard (celular 2)
 Nodo N0x ─┘   (NRF24L01)      (RTC, sirena)   (RTDB+FCM) └─ ...
                                   │
                                   └─ (futuro) SMS por Módulo GSM SIM800L
```

---

## 2. Estructura del repositorio

```
/
├── README.md                  Portada del repositorio y mapa de carpetas
├── PENDIENTES.md              Lista de lo que falta, en orden
├── CLAUDE.md                  Reglas cortas para el asistente (apunta aquí)
├── docs/
│   ├── ARQUITECTURA.md        ESTE documento
│   ├── mockups/               Capturas de cada pantalla de la app
│   ├── guias/                 Guías de trabajo (skills de Claude Code...)
│   └── teoria/                Documentos académicos (se escriben al final)
├── marca/                     Logos de TiGuard (logo_app, logo_horizontal)
├── entregas/                  APKs compiladas (no se suben a GitHub)
├── app/                       App TiGuard (Flutter, Android primero)
├── firmware/
│   ├── central/central.ino    Placa de desarrollo ESP32 (+ secretos.h, no se sube)
│   └── nodo/nodo.ino          Placa Arduino Nano de cada nodo
├── firebase/
│   ├── firebase.json          Despliegue (reglas + proveedores de inicio de sesión)
│   ├── reglas_database.json   Reglas de seguridad de la Realtime Database
│   └── herramientas/          Scripts Node.js (crear proyecto, simular central)
```

Regla: **cada bloque vive en su carpeta** y solo se comunica con los demás a
través del contrato de datos de la sección 4 (Firebase) o del protocolo de
radio de la sección 5.

---

## 3. La app (`app/`)

### 3.1 Capas

```
lib/
├── main.dart              Arranque: Firebase, fechas, notificaciones, runApp
├── app.dart               MaterialApp + PuertaSesion (decide qué pantalla ver)
├── nucleo/                Sin dependencias de Firebase ni de pantallas
│   ├── marca.dart         Nombres de la marca y textos fijos
│   ├── tema.dart          Colores (tokens) y ThemeData
│   └── formato.dart       Fechas, horas, "hace X min"
├── modelos/               Clases de datos puras (desdeMapa / aMapa)
├── datos/                 Acceso a Firebase. ÚNICO lugar que conoce rutas
│   ├── rutas.dart         Todas las rutas de la base de datos
│   ├── auth_repositorio.dart
│   ├── central_repositorio.dart
│   └── demo/              Implementaciones en memoria (modo demo)
├── estado/
│   └── sesion.dart        Usuario actual, sus centrales y la central elegida
├── servicios/             Plataforma: notificaciones, sirena, cámara
├── pantallas/             Una carpeta por función (acceso, vincular, panel...)
└── widgets/               Piezas visuales reutilizables
```

Dependencias permitidas (de arriba hacia abajo, nunca al revés):

```
pantallas / widgets  →  estado  →  datos  →  modelos  →  nucleo
                    ↘  servicios ↗
```

- Una pantalla **nunca** usa `FirebaseDatabase` ni escribe una ruta: llama a un
  repositorio.
- Los repositorios son **abstractos** con dos implementaciones: Firebase y
  demo (`flutter run --dart-define=DEMO=true`). Así la app se puede presentar
  sin hardware y el día de mañana se pueden escribir pruebas.
- Los modelos no importan Flutter (solo Dart puro + `intl`).

### 3.2 Flujo de pantallas

```
Arranque ─► ¿sesión? ─no─► Acceso (iniciar sesión / crear cuenta / recuperar)
               │
               sí
               ▼
        ¿tiene centrales? ─no─► Vincular central (ID + código)
               │
               sí
               ▼
             Panel ──► Nodos (agregar, renombrar, activar, eliminar)
               ├────► Horario de vigilancia
               ├────► Historial (filtro por nodo)
               └────► Ajustes (cuenta, central, miembros, alertas, cámara)
```

### 3.3 Convenciones de código

- Todo en **español**: clases, variables, comentarios y textos.
- Componentes físicos con su **nombre completo** en textos y comentarios.
- Colores solo desde `Colores` (`nucleo/tema.dart`); nunca un `Color(0x...)`
  suelto en una pantalla. **Rojo = alerta de movimiento, verde = armado,
  ámbar = sin conexión, marca (verde TiGuard) = acciones principales.**
- Textos de la marca solo desde `Marca` (`nucleo/marca.dart`).
- Cada archivo empieza con un comentario de una línea que dice para qué es.
- Manejo de errores: los repositorios lanzan `ErrorTiGuard` con un mensaje ya
  listo para el usuario; las pantallas lo muestran en un `SnackBar`.
- Versión en `pubspec.yaml`: subir **siempre** el número de compilación.

---

## 4. Contrato de datos — Firebase Realtime Database

Proyecto: `acceso-remoto-5777` (el ID de un proyecto de Firebase no se puede
renombrar; el nombre visible es "TiGuard").

```
usuarios/{uid}/
  perfil        { nombre: string, correo: string, creado: ms }
  centrales/{centralId}: true            índice de las centrales del usuario

codigosVinculacion/{centralId}: string   SOLO la central lo escribe. Nadie lo lee.

centrales/{centralId}/
  info          { nombre: string, propietario: uid }
  miembros/{uid}  { correo: string, codigo: string, unido: ms }
  estado        {
                  armado: bool,                 app y central
                  alerta: bool,                 central → true, app → false
                  alertaNodo: nodoId,           central (qué nodo disparó)
                  ultimoLatido: ms,             central cada 30 s
                  desactivacion: { origen: "app"|"pulsador", fecha: ms, uid? }
                }
  config/
    horario     { siempre: bool, inicio: 0..1439, fin: 0..1439 }  (minutos del día)
  nodos/{nodoId}  {
                  nombre: string (1–30),        lo cambia el propietario
                  tipo: "pir",
                  activo: bool,                 false = la central lo ignora
                  creado: ms,
                  descubierto: bool,            true = lo registró la central sola
                  ultimoContacto: ms            SOLO la central
                }
  historial/{pushId} { nodo: nodoId, nombre: string, tipo: "movimiento", fecha: ms }
```

Reglas del contrato:

- Las fechas siempre las pone el servidor (`{".sv":"timestamp"}`).
- `nodoId` = 2 a 8 caracteres `A-Z 0-9` (ej. `N01`). Es el mismo que tiene
  grabado el nodo en su firmware. El **nombre** es solo para mostrar y se
  puede cambiar cuando sea.
- `centralId` = 10 caracteres `A-Z 0-9`, aleatorio, grabado en
  `firmware/central/secretos.h`. Funciona también como parte del secreto de
  los temas de notificación.
- El historial guarda una **copia del nombre** del nodo en ese momento, para
  que renombrar un nodo no cambie alertas viejas.
- Cualquier ruta nueva se agrega **primero aquí**, luego en
  `firebase/reglas_database.json`, `app/lib/datos/rutas.dart`,
  `firmware/central/central.ino` y `firebase/herramientas/simular_central.js`.

### 4.1 Permisos (resumen de las reglas)

| Ruta | Leer | Escribir |
|------|------|----------|
| `usuarios/{uid}` | el mismo usuario | el mismo usuario |
| `codigosVinculacion` | nadie | nadie (solo la central con cuenta de servicio) |
| `centrales/{c}` | miembros | según hijo ↓ |
| `info/propietario` | — | una sola vez, un miembro con código válido |
| `info/nombre` | — | propietario |
| `miembros/{uid}` | — | unirse con código válido · salir uno mismo · el propietario expulsa |
| `estado/armado` | — | miembros (bool) |
| `estado/alerta` | — | miembros, **solo `false`** (reconocer) |
| `estado/desactivacion` | — | miembros, `origen: "app"` y su propio uid |
| `estado/ultimoLatido`, `alertaNodo` | — | solo la central |
| `config/horario` | — | propietario (con validación de rangos) |
| `nodos/{n}` | — | propietario (`ultimoContacto` no se puede tocar) |
| `historial` | — | propietario, **solo borrar** |

La central usa una **cuenta de servicio** (acceso de administrador): las
reglas no la limitan, por eso su clave nunca sale de `secretos.h`.

### 4.2 Roles

- **Propietario**: el primer usuario que vincula la central. Cambia nombre,
  horario, nodos, borra historial y expulsa miembros.
- **Miembro**: cualquier otro usuario vinculado con el código. Ve todo, arma,
  desarma y reconoce alertas.

---

## 5. Protocolo de radio (nodo → central)

Módulo transceptor NRF24L01: canal 108, 250 kbps, dirección `TGNET`, auto-ACK.
Todos los nodos escriben en la misma dirección; la central los distingue por
el contenido del mensaje.

```c
struct __attribute__((packed)) MensajeNodo {
  uint8_t version;   // PROTOCOLO_VERSION = 1
  char    nodo[9];   // "N01" + '\0'
  uint8_t evento;    // 1 = movimiento, 2 = latido
};                   // 11 bytes, igual en Placa Arduino Nano y ESP32
```

- **Movimiento**: el Sensor de movimiento PIR HC-SR501 se activó (máx. uno cada 3 s).
- **Latido**: cada 5 minutos, para que la app muestre si el nodo sigue vivo.
- Si llega un `nodo` que la central no conoce, lo **registra sola** en
  `nodos/{id}` con `descubierto: true` y nombre igual al ID; el propietario
  solo tiene que ponerle nombre en la app.
- La definición del `struct` está copiada en `firmware/central/central.ino` y
  `firmware/nodo/nodo.ino`. **Si cambia, se cambia en los dos y se sube
  `version`.**

---

## 6. Flujos principales

### 6.1 Vincular una central

1. La central, al encender (o al tocar el pulsador sin alarma), muestra en
   la pantalla LCD su **ID** y su **código de vinculación**, y publica el
   código en `codigosVinculacion/{ID}`.
2. En la app: *Vincular central* → ID + código.
3. La app escribe en una sola operación `miembros/{uid}` (con el código) y
   `usuarios/{uid}/centrales/{ID}`. Las reglas comparan el código con
   `codigosVinculacion/{ID}`; si no coincide, se rechaza.
4. Si la central no tiene propietario, la app escribe `info/propietario = uid`.

### 6.2 Alerta de movimiento

1. Nodo → radio → central (`evento = 1`).
2. La central revisa: nodo activo, sistema armado, dentro del horario, no
   silenciado. Si todo se cumple:
3. Sirena local + `estado/alerta = true` + `estado/alertaNodo` + registro en
   `historial`.
4. Push FCM a los temas `tg_{centralId}_sirena`, `_normal` y `_silencio`
   (cada celular está suscrito solo al modo que eligió) con el título
   **"Movimiento detectado"** y el nombre del nodo.
5. La app muestra la tarjeta **"Alerta de movimiento"**. *Reconocer* →
   `alerta = false` + `desactivacion`.

### 6.3 Horario de vigilancia

- La app escribe `config/horario`. La central lo lee cada 20 s y lo guarda en
  su memoria interna (NVS) para seguir funcionando si pierde internet.
- `inicio > fin` significa que cruza la medianoche (22:00 → 06:00).
- `siempre = true` vigila las 24 horas.
- La hora la da el Módulo de reloj RTC DS3231 de la central (hora local).

---

## 7. Notificaciones push

| Tema | Canal Android | Sonido |
|------|---------------|--------|
| `tg_{c}_sirena` | `movimiento_sirena` | `sirena` |
| `tg_{c}_normal` | `movimiento_normal` | por defecto |
| `tg_{c}_silencio` | `movimiento_silencio` | ninguno |
| `tg_{c}_avisos` | `avisos_central` | por defecto |

- El celular se suscribe a los temas de **todas** sus centrales al iniciar
  sesión y se desuscribe de todas al **cerrar sesión** (para no recibir
  alertas de una cuenta que ya no está en ese celular).
- Limitación conocida: FCM no protege los temas con reglas; la seguridad se
  apoya en que el `centralId` es aleatorio y solo lo conocen los miembros.
  Mejora futura: tokens por dispositivo en `centrales/{c}/dispositivos`.

---

## 8. Seguridad

- Inicio de sesión con **correo y contraseña** (Firebase Authentication),
  contraseña de mínimo 8 caracteres, recuperación por correo y verificación
  de correo enviada al registrarse.
- Las reglas de la base de datos **niegan por defecto** y validan tipo y
  rango de cada dato.
- Secretos fuera del repositorio: `firmware/central/secretos.h`,
  `app/android/key.properties`, la llave `.jks`.
  `google-services.json` no es secreto (lo protege el paquete + las reglas).
- La central se autentica con cuenta de servicio sobre TLS.
- Vincularse exige **presencia física** (leer el código en la central).
- Pendiente: `clienteSeguro.setInsecure()` en la central omite verificar el
  certificado de Google; se debe cargar el certificado raíz antes de producción.

---

## 9. Escalabilidad

- Nuevos nodos: solo se graba otro `NODO_ID` en un Placa Arduino Nano. La
  central lo descubre sola; la app no cambia.
- Nuevos tipos de sensor: `tipo` en `nodos/{n}` y nuevos valores de `evento`
  en el protocolo (puerta, humo…). La app muestra el ícono según `tipo`.
- Nuevos clientes: cada cliente tiene su propia central (`centralId`) y sus
  propios usuarios; las reglas aíslan los datos de cada central.
- Límite de la central: `MAX_NODOS = 16` en memoria (ajustable).
- Respaldo GSM: el punto de enganche es `publicarAlerta()` en la central
  cuando no hay Firebase.

---

## 10. Antes de cambiar algo (lista de verificación)

- [ ] ¿Toca una ruta de Firebase? Actualizar sección 4, reglas, `rutas.dart`,
      firmware y simulador **en el mismo cambio**.
- [ ] ¿Toca el mensaje de radio? Actualizar sección 5 y los **dos** firmwares.
- [ ] ¿Toca textos de la marca o colores? Solo en `nucleo/`.
- [ ] ¿Pantalla nueva? Carpeta propia en `pantallas/`, datos por repositorio,
      que funcione en modo demo.
- [ ] Subir la versión en `pubspec.yaml`.
- [ ] `flutter analyze` sin errores y compilar el firmware con `arduino-cli`.
- [ ] Publicar las reglas (`firebase deploy --only database`) si cambiaron.

---

## 11. Decisiones tomadas

| Decisión | Alternativa descartada | Por qué |
|----------|------------------------|---------|
| Realtime Database | Firestore | Latencia baja, la librería FirebaseClient de la ESP32 la soporta bien, plan gratis suficiente. |
| Correo y contraseña | Sesión anónima | Misma cuenta en varios celulares. |
| Código de vinculación validado en reglas | Cloud Functions | Funciona en el plan Spark gratuito, sin servidor. |
| Temas FCM por central | Tokens por dispositivo | La ESP32 manda 3 mensajes fijos sin leer listas; simple y suficiente hoy. |
| Nodos descubiertos por la central | Solo alta manual | Agregar un nodo = encenderlo y ponerle nombre. |
| Repositorios abstractos + modo demo | Firebase directo en pantallas | Presentar sin hardware y poder probar. |
| Sin paquete de gestión de estado | Provider / Riverpod / Bloc | `ChangeNotifier` basta para el tamaño actual; si crece, se migra `estado/`. |

## 12. Pendientes conocidos

- Cambiar el `applicationId` de Android a uno de la marca (exige registrar la
  app de nuevo en Firebase y un nuevo `google-services.json`).
- Certificado raíz en la central (quitar `setInsecure`).
- Respaldo GSM con el Módulo GSM SIM800L.
- Cambiar el código de vinculación desde la app (hoy se cambia en
  `secretos.h` y se graba la central). Un miembro expulsado que conozca el
  código puede volver a vincularse hasta que se cambie.
- Sin internet al encender, la central trata a todos los nodos como activos
  y con su ID como nombre hasta que lee la lista de Firebase.
