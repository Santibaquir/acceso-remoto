# TiGuard — App Android

App de **TiGuard Secure** en Flutter. Lee y controla las centrales TiGuard en
tiempo real desde Firebase.

> La arquitectura completa (capas, contrato de datos, seguridad) está en
> [`docs/ARQUITECTURA.md`](../docs/ARQUITECTURA.md). Léela antes de cambiar código.

## Funciones

- Cuenta con correo y contraseña: la misma cuenta en varios celulares.
- Vincular una o varias centrales con su ID y código de vinculación.
- Armar / desarmar, alerta de movimiento con sirena y notificación push.
- Nodos de vigilancia: agregar, renombrar, activar / desactivar, eliminar.
- Horario de vigilancia configurable (o las 24 horas).
- Historial por nodo, miembros de la central, botón para abrir la cámara.

## Carpetas de `lib/`

| Carpeta | Qué contiene |
|---------|--------------|
| `nucleo/` | Marca, colores, formatos de fecha, errores |
| `modelos/` | Clases de datos (estado, nodo, horario, historial...) |
| `datos/` | Repositorios de Firebase y demo. Único lugar con rutas |
| `estado/` | Sesión: usuario, centrales y central elegida |
| `servicios/` | Notificaciones, sirena, cámara |
| `pantallas/` | Una carpeta por pantalla |
| `widgets/` | Piezas visuales reutilizables |

## Configurar Firebase (una sola vez)

1. **Authentication → Método de acceso → Correo electrónico/contraseña → Habilitar**
   (o `firebase deploy --only auth` desde `firebase/`).
2. Publicar las reglas: desde la carpeta `firebase/`, `firebase deploy --only database`.
3. `app/android/app/google-services.json` debe ser el del proyecto (`acceso-remoto-5777`).
4. Preparar la central: `node firebase/herramientas/generar_identidad.js` y grabar
   `firmware/central`. Para probar sin hardware: `node firebase/herramientas/simular_central.js preparar`.

## Compilar

```bash
flutter pub get
flutter analyze
flutter test
flutter run                                  # con Firebase
flutter run --dart-define=DEMO=true          # modo demo, sin Firebase
flutter build apk --release                  # build/app/outputs/flutter-apk/app-release.apk
```

En modo demo cualquier correo con una contraseña de 8 caracteres entra; la
central de ejemplo es `DEMO7K2M9Q` / `TIGUARD1`. Mantener presionado el logo
del panel simula una alerta de movimiento.
