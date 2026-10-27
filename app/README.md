# Acceso Remoto — App Android

App en Flutter que lee la central en tiempo real desde Firebase.

## Estructura de la base de datos (Realtime Database)

| Ruta                   | Tipo   | Quién escribe | Para qué |
|------------------------|--------|---------------|----------|
| `estado/armado`        | bool   | App           | La Placa de desarrollo ESP32 solo hace sonar la sirena si es `true` |
| `estado/alerta`        | bool   | ESP32 → `true`, App → `false` | Alerta activa hasta que se reconoce en la app |
| `estado/ultimoLatido`  | número (ms) | ESP32 cada 30 s | En línea / sin conexión (más de 90 s sin latido = sin conexión) |
| `historial/{id}`       | `{ sensor: "BODEGA", fecha: ms }` | ESP32 | Historial con fecha y hora |

Las fechas las pone el servidor de Firebase (`{".sv": "timestamp"}`), no el reloj del celular.

## Notificación push

La ESP32 envía el push por Firebase Cloud Messaging al tema **`alertas`**, con
`android.notification.channel_id = "alertas_criticas"` y `sound = "sirena"`.
La app se suscribe a ese tema al abrirse y crea el canal con el sonido de sirena.

## Configurar Firebase (una sola vez)

1. Entra a <https://console.firebase.google.com> → **Agregar proyecto** (plan Spark, gratis).
2. **Compilación → Realtime Database → Crear base de datos** (ubicación `us-central1`, modo bloqueado).
   En la pestaña **Reglas** pega el contenido de `firebase/reglas_database.json` y publica.
3. **Compilación → Authentication → Comenzar → Anónimo → Habilitar**.
4. **Configuración del proyecto → Tus apps → Android**:
   - Nombre del paquete: `co.edu.umanizales.acceso_remoto`
   - Descarga `google-services.json` y cópialo en `app/android/app/google-services.json`.
5. Para la ESP32: **Configuración del proyecto → Cuentas de servicio → Generar nueva clave privada**.
   Ese JSON lleva el correo y la clave que usa el firmware. **No lo subas a GitHub.**

## Compilar e instalar

```bash
flutter pub get
flutter run
```

Para generar el APK: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
