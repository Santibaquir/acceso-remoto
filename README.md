# TiGuard · by TiGuard Secure

Sistema de vigilancia por zonas: nodos con Sensor de movimiento PIR HC-SR501
avisan por radio a una central (Placa de desarrollo ESP32), que publica las
alertas de movimiento en Firebase y en la app **TiGuard**.

Antes de cambiar cualquier cosa, lee [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).
Lo que falta por hacer está en [`PENDIENTES.md`](PENDIENTES.md).

## Carpetas

| Carpeta | Qué contiene |
|---------|--------------|
| [`app/`](app/) | App TiGuard (Flutter, Android) |
| [`firmware/central/`](firmware/central/) | Central: Placa de desarrollo ESP32 (+ `secretos.h`, no se sube) |
| [`firmware/nodo/`](firmware/nodo/) | Nodo de vigilancia: Placa Arduino Nano |
| [`firebase/`](firebase/) | Reglas de la base de datos, configuración y scripts (`herramientas/`) |
| [`docs/`](docs/) | Arquitectura, mockups de la app, guías de trabajo y (más adelante) la teoría |
| [`marca/`](marca/) | Logos de TiGuard |
| `entregas/` | APKs compiladas (no se suben a GitHub) |
