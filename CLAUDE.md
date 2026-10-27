# Acceso Remoto — App móvil

Proyecto universitario de microcontroladores (Universidad de Manizales). Este repositorio es la **app móvil** de una central de monitoreo inalámbrica. El usuario se llama Tiba. Responde siempre en español.

## Qué es el sistema

Central de monitoreo que detecta movimiento con sensores infrarrojos y avisa al celular de inmediato, para abrir a tiempo la cámara comercial y verificar la intrusión.

Valor agregado: radiofrecuencia independiente del Wi-Fi, vigilancia por horarios nocturnos, montaje profesional sin protoboards y comunicación híbrida anti-sabotaje.

### Hardware (dos bloques unidos por radio a 2.4 GHz)

- **Nodo Remoto (la Bodega):** Placa Arduino Nano + Sensor de movimiento PIR HC-SR501 + Módulo transceptor NRF24L01. Envía la alerta "BODEGA" a la central.
- **Estación Central (cuarto del Patrón):** Placa de desarrollo ESP32-S DevKit (USB Tipo C) sobre placa de expansión con borneras. Incluye Módulo transceptor NRF24L01 receptor, Módulo de reloj RTC DS3231 (vigilancia solo de 10:00 PM a 6:00 AM, configurable), Módulo relé y zumbador/sirena. Pantalla LCD comprada, se usará en la central.
- **Respaldo GSM:** Módulo GSM SIM800L (con regulador LM2596) enviando SMS si cae el Wi-Fi. Aún no adquirido, va al final.

### Lógica de alertas

1. Vía principal: la Placa de desarrollo ESP32 se conecta al Wi-Fi y publica el estado de los sensores en **Firebase**.
2. Vía de respaldo: si falla el Wi-Fi, envía SMS por el Módulo GSM SIM800L.

## La app

Se reemplaza la versión planeada en MIT App Inventor por una app en **código**, con diseño cuidado y bonito. Lee Firebase en tiempo real.

Funciones requeridas:

- Estado del sistema: **ARMADO** / **DESARMADO**, bien visible.
- Alerta crítica: sirena sonora + pantalla/texto rojo **"¡ALERTA CRÍTICA: BODEGA!"**, incluso con la app en segundo plano (notificación push).
- Botones para **armar / desarmar** remotamente (escriben en Firebase, la Placa de desarrollo ESP32 los lee).
- Botón **"Ver Cámara"**: abre la app comercial de la cámara Wi-Fi mediante intent / deep link.
- Estado de conexión de la central (en línea / sin conexión, última vez visto).
- Historial de alertas con fecha y hora.

## Decisiones técnicas (a confirmar con Tiba si cambian)

- Stack: **Flutter** (Android primero, carpeta `app/`) + **Firebase Realtime Database** + sesión anónima. Estructura: `estado/armado`, `estado/alerta`, `estado/ultimoLatido`, `historial/{id}` (detalle en `app/README.md`).
- Push: la Placa de desarrollo ESP32 lo envía directo por FCM (librería FirebaseClient, cuenta de servicio, plan Spark gratis) al tema `alertas`, canal `alertas_criticas` con sonido `sirena`.
- Claves del firmware en `codigo_central/secretos.h` (no se sube; plantilla en `secretos_ejemplo.h`).
- Herramientas en el PC: Flutter en `C:\Users\santi\dev\flutter`, Android Studio con SDK, arduino-cli del Arduino IDE.
- Diseño: tema oscuro tipo centro de seguridad, rojo reservado para alertas, verde para sistema armado/normal, tipografía grande y legible, animaciones sutiles. Debe verse profesional, no como prototipo.

## Estado actual (octubre 2026)

- Fase de protoboard. Etapa 1 (enlace NRF24L01) y etapa 2 (RTC DS3231 en la Placa de desarrollo ESP32) probadas. Sigue etapa 3 (zumbador y relé).
- El nodo remoto vuelve a usar Placa Arduino Nano (la Uno daba falsos contactos).
- El firmware puede vivir en este repo, en `firmware/central` y `firmware/nodo`.

## Preferencias de Tiba

- Nombrar los componentes con su **nombre completo** ("Sensor de movimiento PIR HC-SR501", "Placa de desarrollo ESP32"), nunca abreviados.
- Correcciones breves y directas: aplicarlas de inmediato, sin explicaciones largas.
- Es estudiante: código claro y comentado, explicar lo justo.
