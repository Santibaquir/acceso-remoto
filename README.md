# Acceso Remoto — Sistema inalámbrico de seguridad

Proyecto de Microcontroladores · Universidad de Manizales.

Un Sensor de movimiento PIR HC-SR501 en la bodega avisa por radio (Módulo transceptor NRF24L01, 2.4 GHz) a una central con Placa de desarrollo ESP32. La central hace sonar la sirena, publica la alerta en Firebase y el celular recibe una notificación con sirena para abrir la cámara a tiempo.

| Carpeta | Qué contiene |
| --- | --- |
| [`codigo_transmisor/`](codigo_transmisor) | Nodo remoto: Placa Arduino Nano + Sensor de movimiento PIR HC-SR501 + NRF24L01 |
| [`codigo_central/`](codigo_central) | Estación central: Placa de desarrollo ESP32 + NRF24L01 + RTC DS3231 + LCD + relé + Wi-Fi/Firebase |
| [`app/`](app) | App Android en Flutter: estado, armar/desarmar, alertas, historial, cámara |
| [`app/firebase/`](app/firebase) | Reglas de la base de datos y simulador de la central |

## Puesta en marcha

1. **Central:** copia `codigo_central/secretos_ejemplo.h` como `secretos.h`, llena tu Wi-Fi y las claves de Firebase, y carga `codigo_central.ino` (librería **FirebaseClient** de Mobizt).
2. **Nodo:** carga `codigo_transmisor.ino` en la Placa Arduino Nano (librería **RF24**).
3. **App:** ver [`app/README.md`](app/README.md).
