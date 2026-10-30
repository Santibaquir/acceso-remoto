# TiGuard — de TiGuard Secure

Proyecto universitario de microcontroladores (Universidad de Manizales) que evolucionó a producto: **TiGuard**, la app de **TiGuard Secure** (antes "Acceso Remoto"; ese nombre ya no se usa en textos nuevos). El usuario se llama Tiba. Responde siempre en español.

## Regla número uno

**Antes de cambiar la app, el firmware o Firebase, lee [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) y síguelo.** Ahí están las carpetas, las capas de la app, el contrato de datos de Firebase, el protocolo de radio, la seguridad y la lista de verificación de cambios. Si algo nuevo no encaja, primero se actualiza ese documento.

## Grafo del proyecto (graphify) — consultar antes de explorar

El proyecto ya está mapeado en `graphify-out/` (944 nodos: app, firmware, Firebase, docs, mockups y logos). **No revises el proyecto desde cero:** primero pregunta al grafo y abre solo los archivos que señale.

- Panorama: leer [graphify-out/GRAPH_REPORT.md](graphify-out/GRAPH_REPORT.md) (comunidades, nodos clave, conexiones).
- Pregunta: `graphify query "<pregunta>" --budget 1500` (con `PYTHONIOENCODING=utf-8` en Windows).
- Un símbolo o concepto: `graphify explain "CentralRepositorio"`. Camino entre dos: `graphify path "atenderNodo()" "PantallaPanel"`.
- Después de cambiar código: `graphify update .` (sin costo, solo AST). Si cambian docs, imágenes o firmware `.ino` (graphify los lee como documentos), re-ejecutar la skill graphify con `--update`.
- La skill está en `C:\Users\santi\dev\graphify` (instalada con pip en Python 3.12).

## Qué es el sistema

Vigilancia por zonas: cada **nodo de vigilancia** (Placa Arduino Nano + Sensor de movimiento PIR HC-SR501 + Módulo transceptor NRF24L01) avisa por radio de 2.4 GHz a la **central** (Placa de desarrollo ESP32-S DevKit con Módulo de reloj RTC DS3231, Módulo relé, zumbador/sirena, pulsador y pantalla LCD). La central publica en **Firebase** y manda push. Respaldo futuro: Módulo GSM SIM800L (con regulador LM2596) por SMS.

Valor agregado: radiofrecuencia independiente del Wi-Fi, horario de vigilancia configurable desde la app, varios nodos con nombre, varias cuentas y celulares por central, montaje profesional sin protoboards.

## La app TiGuard (Flutter, `app/`)

- Inicio de sesión con correo y contraseña (misma cuenta en varios celulares).
- Vincular una central con su ID y código (se ven en la pantalla LCD de la central).
- Estado **ARMADO / DESARMADO**, armar y desarmar.
- **Alerta de movimiento** (no "alerta crítica"): tarjeta roja sobria + push con el nombre del nodo, también con la app cerrada.
- Nodos: agregar, renombrar, activar/desactivar, eliminar.
- Horario de vigilancia configurable (o todo el día).
- Ver cámara (abre la app comercial de la cámara Wi-Fi), conexión de la central, historial por nodo.

## Herramientas en el PC

Flutter en `C:\Users\santi\dev\flutter`, Android Studio con SDK, `arduino-cli` del Arduino IDE (`C:\Program Files\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe`), Firebase CLI con sesión iniciada.

## Diseño

Tema oscuro tipo centro de seguridad, profesional (no prototipo). Rojo solo para alertas de movimiento, verde para armado, ámbar para sin conexión, verde TiGuard (`Colores.marca`, del logo) para acciones y marca. Tipografía grande y legible, animaciones sutiles. Colores y textos de marca solo en `app/lib/nucleo/`. Logos oficiales en `marca/`; en la app, `assets/marca/isotipo.png` e íconos del launcher ya aplicados.

## Estado actual (octubre 2026)

- Fase de protoboard: enlace NRF24L01 y RTC DS3231 probados; sigue zumbador y relé.
- Reforma 2.0 (TiGuard) terminada en software: multiusuario, multinodo, horario desde la app, logo aplicado, reglas de Firebase publicadas. APK en `entregas/TiGuard-2.0.0.apk`.
- Lo que falta está en [PENDIENTES.md](PENDIENTES.md).

## Preferencias de Tiba

- Nombrar los componentes con su **nombre completo** ("Sensor de movimiento PIR HC-SR501", "Placa de desarrollo ESP32"), nunca abreviados.
- Correcciones breves y directas: aplicarlas de inmediato, sin explicaciones largas.
- Es estudiante: código claro y comentado, explicar lo justo.
- Trabajo profesional, escalable y seguro; no "proyecto simple".
