# Pendientes para dejar TiGuard al 100 %

Lista en orden. Marca cada casilla cuando la termines (`[ ]` → `[x]`).

## 1. Hoy: poner a andar la versión 2.0

- [x] **Apagar la sesión anónima en Firebase** (2 min).
      Consola de Firebase → Authentication → Método de acceso → Anónimo → Deshabilitar.
- [ ] **Instalar la app nueva** en el celular: `entregas/TiGuard-2.0.0.apk`.
      Se instala encima de la vieja (misma firma). La app vieja ya no funciona con Firebase.
- [ ] **Crear tu cuenta** en la app (nombre, correo, contraseña) y abrir el
      correo de verificación que te llega.
- [x] **Revisar el Wi-Fi en `firmware/central/secretos.h`**: `WIFI_SSID` y
      `WIFI_PASSWORD` deben ser los de tu red de 2.4 GHz.
- [ ] **Grabar la central** (`firmware/central/central.ino`) en la Placa de
      desarrollo ESP32. La librería ArduinoJson ya quedó instalada.
- [ ] **Grabar el nodo** (`firmware/nodo/nodo.ino`) en la Placa Arduino Nano.
      Ya tiene `NODO_ID = "N01"`. Para otro nodo, cambia a `"N02"`, `"N03"`...
- [ ] **Vincular la central** en la app: el ID y el código salen en la
      pantalla LCD al encenderla (o al tocar el pulsador sin alarma).
- [ ] **Ponerle nombre al nodo** en la app: Nodos → N01 → Cambiar nombre → "Bodega".
- [x] **Borrar los datos viejos** de Acceso Remoto en Firebase:
      `node firebase/herramientas/simular_central.js limpiar-viejo`

## 2. Pruebas (anota lo que falle)

- [ ] La central aparece **En línea** en la app.
- [ ] Pasar la mano por el Sensor de movimiento PIR HC-SR501 → suena la
      sirena, llega la **notificación con la app cerrada** y aparece en el historial.
- [ ] **Reconocer** la alerta desde la app.
- [ ] Apagar la alarma con el **pulsador** → llega el aviso "Alarma desactivada".
- [ ] **Desarmar** desde la app → el movimiento ya no dispara la alarma.
- [ ] **Horario**: poner uno que no incluya la hora actual → no hay alerta.
      Activar "24 horas" → vuelve a alertar.
- [ ] **Desactivar el nodo** en la app → la central lo ignora.
- [ ] Iniciar sesión con la **misma cuenta en otro celular** → ve lo mismo y recibe alertas.
- [ ] **Otra cuenta** se vincula con el código → aparece como Miembro y no
      puede cambiar el horario ni los nodos.
- [ ] Desconectar el Wi-Fi de la central → la sirena **sigue sonando** con el movimiento.
- [ ] Reiniciar la central sin internet → **recuerda** el armado y el horario.

## 3. Hardware (siguiente etapa del proyecto)

- [ ] Etapa 3: zumbador/sirena y Módulo relé en la central.
- [ ] Pantalla LCD montada en la central.
- [ ] Montaje profesional sin protoboard (placa de expansión con borneras).
- [ ] Más nodos (N02, N03...) si los vas a usar.

## 4. Ya hecho por Claude (30 oct 2026)

- [x] Logo aplicado en la app, ícono del celular, pantalla de arranque y color verde de marca.
- [x] Mockups de las 9 pantallas en `docs/mockups/`.
- [x] APK final `entregas/TiGuard-2.0.0.apk`.
- [x] Reglas de Firebase publicadas e inicio de sesión con correo activado.
- [x] Commit de la reforma 2.0 en la rama `reforma-tiguard-2` (falta unirla a `main`).

## 5. Guardar el trabajo

- [ ] Revisar el commit y unir la rama `reforma-tiguard-2` a `main`
      (pídeselo a Claude: "une la rama a main").

## 6. Al final (cuando todo funcione)

- [ ] Módulo GSM SIM800L con regulador LM2596: SMS cuando no haya Wi-Fi.
- [ ] Certificado raíz en la central (quitar `setInsecure`, ver `docs/ARQUITECTURA.md` §8).
- [ ] Cambiar el código de vinculación desde la app.
- [ ] `applicationId` de Android con la marca TiGuard.
- [ ] Documentos de teoría nuevos en `docs/teoria/` y la presentación final.
