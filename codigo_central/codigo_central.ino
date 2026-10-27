#include <SPI.h>
#include <RF24.h>
#include <Wire.h>
#include <RTClib.h>
#include <LiquidCrystal_I2C.h>

// ---------- Firebase (librería FirebaseClient de Mobizt) ----------
#define ENABLE_SERVICE_AUTH
#define ENABLE_DATABASE
#define ENABLE_MESSAGING
#include <FirebaseClient.h>
#include <ExampleFunctions.h>  // WiFi, WiFiClientSecure y funciones de apoyo de la librería
#include "secretos.h"          // Wi-Fi y claves de Firebase (copia secretos_ejemplo.h)

// ---------- Pines ----------
const int PIN_RELE = 25;
const int PIN_ZUMBADOR = 27;
const int PIN_PULSADOR = 26;

// ---------- Objetos ----------
RF24 radio(4, 5);  // CE, CSN
RTC_DS3231 rtc;
LiquidCrystal_I2C *lcd = nullptr;
const byte direccion[6] = "BODEG";

ServiceAuth autenticacion(FIREBASE_CLIENT_EMAIL, FIREBASE_PROJECT_ID, PRIVATE_KEY, 3000);
FirebaseApp appFirebase;
WiFiClientSecure clienteSeguro;
AsyncClientClass clienteFirebase(clienteSeguro);
RealtimeDatabase baseDatos;
Messaging mensajeria;

// ---------- Ajustes ----------
const int RELE_ON = LOW;
const int RELE_OFF = HIGH;
const int ZUMBADOR_ON = HIGH;
const int ZUMBADOR_OFF = LOW;

// true = la alarma suena a cualquier hora (para probar). false = solo de 10 PM a 6 AM.
const bool MODO_PRUEBA = true;
const int HORA_INICIO = 22;  // 10:00 PM
const int HORA_FIN = 6;      // 6:00 AM

const unsigned long DURACION_ALARMA = 10000;   // la alarma suena 10 segundos
const unsigned long SILENCIO_PULSADOR = 5000;  // tras apagar con el pulsador se ignoran alertas 5 s
const unsigned long DURACION_AVISO = 3000;     // los avisos se quedan 3 s en la pantalla

const unsigned long CADA_LATIDO = 30000;       // avisa a la app que la central está en línea
const unsigned long CADA_LECTURA_ARMADO = 3000; // revisa si la app armó o desarmó

// ---------- Estado ----------
bool alarmaActiva = false;
unsigned long inicioAlarma = 0;
bool enSilencio = false;
unsigned long inicioSilencio = 0;
unsigned long ultimaPantalla = 0;
unsigned long finAviso = 0;

// Armado / desarmado desde la app. Arranca armado para que la central
// proteja aunque no haya Wi-Fi.
bool sistemaArmado = true;
bool firebaseIniciado = false;
unsigned long ultimoLatido = 0;
unsigned long ultimaLecturaArmado = 0;

// Hora en que se activó la última alarma (-1 = todavía no hubo ninguna)
int horaActivacion = -1;
int minutoActivacion = -1;

// ---------- Pantalla ----------
byte buscarPantalla() {
  byte candidatas[] = {0x27, 0x3F};
  for (byte i = 0; i < 2; i++) {
    Wire.beginTransmission(candidatas[i]);
    if (Wire.endTransmission() == 0) return candidatas[i];
  }
  return 0;
}

void mostrarLinea(int fila, const char *texto) {
  if (!lcd) return;
  char linea[17];
  snprintf(linea, sizeof(linea), "%-16s", texto);  // rellena con espacios
  lcd->setCursor(0, fila);
  lcd->print(linea);
}

// Muestra un aviso en la pantalla durante unos segundos
void aviso(const char *l0, const char *l1) {
  mostrarLinea(0, l0);
  mostrarLinea(1, l1);
  finAviso = millis() + DURACION_AVISO;
}

bool hayAviso() {
  return (long)(finAviso - millis()) > 0;
}

bool esHorarioNocturno(int hora) {
  return (hora >= HORA_INICIO || hora < HORA_FIN);
}

// Pantalla normal: hora actual y Wi-Fi arriba, estado abajo
void actualizarPantalla() {
  if (!lcd || hayAviso()) return;
  DateTime ahora = rtc.now();
  char l0[17], l1[17];

  snprintf(l0, sizeof(l0), "%02d:%02d %-6s %s", ahora.hour(), ahora.minute(),
           MODO_PRUEBA ? "PRUEBA" : (esHorarioNocturno(ahora.hour()) ? "NOCHE" : "DIA"),
           WiFi.status() == WL_CONNECTED ? "W" : "-");

  if (alarmaActiva) {
    snprintf(l1, sizeof(l1), "ALERTA %02d:%02d", horaActivacion, minutoActivacion);
  } else if (!sistemaArmado) {
    snprintf(l1, sizeof(l1), "Desarmado");
  } else if (enSilencio) {
    snprintf(l1, sizeof(l1), "Silenciada");
  } else if (horaActivacion >= 0) {
    snprintf(l1, sizeof(l1), "Ultima %02d:%02d", horaActivacion, minutoActivacion);
  } else {
    snprintf(l1, sizeof(l1), "Vigilando...");
  }

  mostrarLinea(0, l0);
  mostrarLinea(1, l1);
}

// ---------- Firebase ----------

// Respuesta de las tareas de Firebase (se llama sola cuando termina cada una)
void respuestaFirebase(AsyncResult &resultado) {
  if (resultado.isError()) {
    Serial.printf("Firebase error en %s: %s\n", resultado.uid().c_str(),
                  resultado.error().message().c_str());
    return;
  }
  if (!resultado.available()) return;

  // Lectura de estado/armado
  if (resultado.uid() == "leerArmado") {
    String valor = resultado.c_str();
    if (valor == "true" || valor == "false") {
      bool nuevo = (valor == "true");
      if (nuevo != sistemaArmado) {
        sistemaArmado = nuevo;
        Serial.println(sistemaArmado ? "App: sistema ARMADO" : "App: sistema DESARMADO");
        aviso("Desde la app:", sistemaArmado ? "ARMADO" : "DESARMADO");
        if (!sistemaArmado) apagarAlarma();
      }
    } else {
      // Todavía no existe en la base de datos: se crea con el valor actual
      baseDatos.set<bool>(clienteFirebase, "/estado/armado", sistemaArmado, respuestaFirebase, "crearArmado");
    }
  }
}

// Se llama en cada vuelta del loop. Inicia Firebase cuando haya Wi-Fi y hora.
void atenderFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  if (!firebaseIniciado) {
    // La autenticación necesita la hora real (NTP). Se espera sin bloquear.
    if (time(nullptr) < FIREBASE_DEFAULT_TS) return;
    appFirebase.setTime(time(nullptr));
    initializeApp(clienteFirebase, appFirebase, getAuth(autenticacion), auth_debug_print, "auth");
    appFirebase.getApp<RealtimeDatabase>(baseDatos);
    baseDatos.url(DATABASE_URL);
    appFirebase.getApp<Messaging>(mensajeria);
    firebaseIniciado = true;
    Serial.println("Firebase iniciando...");
  }

  appFirebase.loop();
  if (!appFirebase.ready()) return;

  // No se encolan más tareas si las anteriores no han terminado
  if (clienteFirebase.taskCount() > 2) return;

  // Latido: la app muestra "en línea" mientras llegue cada 30 s
  if (ultimoLatido == 0 || millis() - ultimoLatido >= CADA_LATIDO) {
    ultimoLatido = millis();
    baseDatos.set<object_t>(clienteFirebase, "/estado/ultimoLatido",
                            object_t("{\".sv\":\"timestamp\"}"), respuestaFirebase, "latido");
  }

  // Armado / desarmado que escribe la app
  if (millis() - ultimaLecturaArmado >= CADA_LECTURA_ARMADO) {
    ultimaLecturaArmado = millis();
    baseDatos.get(clienteFirebase, "/estado/armado", respuestaFirebase, false, "leerArmado");
  }
}

// Publica la alerta en Firebase y manda la notificación push al celular
void publicarAlerta(const char *sensor, int hora, int minuto) {
  if (!firebaseIniciado || !appFirebase.ready()) {
    Serial.println("Sin Wi-Fi/Firebase: la alerta no llegó a la app");
    return;  // Aquí irá el SMS con el Módulo GSM SIM800L
  }

  // 1. estado/alerta = true (la app la apaga al reconocerla)
  baseDatos.set<bool>(clienteFirebase, "/estado/alerta", true, respuestaFirebase, "alerta");

  // 2. Registro en el historial con la hora del servidor
  String registro = String("{\"sensor\":\"") + sensor + "\",\"fecha\":{\".sv\":\"timestamp\"}}";
  baseDatos.push<object_t>(clienteFirebase, "/historial", object_t(registro), respuestaFirebase, "historial");

  // 3. Notificación push (llega aunque la app esté cerrada)
  char titulo[64], cuerpo[48];
  snprintf(titulo, sizeof(titulo), "¡ALERTA CRÍTICA: %s!", sensor);
  snprintf(cuerpo, sizeof(cuerpo), "Movimiento detectado a las %02d:%02d", hora, minuto);

  Messages::Notification notificacion;
  notificacion.title(titulo).body(cuerpo);

  Messages::AndroidNotification notificacionAndroid;
  notificacionAndroid.channel_id("alertas_criticas").sound("sirena");
  notificacionAndroid.notification_priority(Messages::NotificationPriority::PRIORITY_MAX);

  Messages::AndroidConfig configAndroid;
  configAndroid.priority(Messages::AndroidMessagePriority::_HIGH);
  configAndroid.notification(notificacionAndroid);

  Messages::Message mensaje;
  mensaje.topic("alertas");
  mensaje.notification(notificacion);
  mensaje.android(configAndroid);

  mensajeria.send(clienteFirebase, Messages::Parent(FIREBASE_PROJECT_ID), mensaje, respuestaFirebase, "push");
}

// ---------- Alarma ----------
void enviarAlerta(const char *sensor, int hora, int minuto) {
  Serial.println(">>> ALERTA: movimiento en la BODEGA <<<");
  publicarAlerta(sensor, hora, minuto);
}

void activarAlarma() {
  digitalWrite(PIN_RELE, RELE_ON);
  digitalWrite(PIN_ZUMBADOR, ZUMBADOR_ON);
  inicioAlarma = millis();
  alarmaActiva = true;
}

void apagarAlarma() {
  digitalWrite(PIN_RELE, RELE_OFF);
  digitalWrite(PIN_ZUMBADOR, ZUMBADOR_OFF);
  alarmaActiva = false;
}

// ---------- Radio ----------
bool configurarRadio() {
  if (!radio.begin()) return false;
  radio.setPALevel(RF24_PA_LOW);
  radio.setDataRate(RF24_250KBPS);
  radio.setChannel(108);
  radio.openReadingPipe(1, direccion);
  radio.startListening();
  return true;
}

// ---------- Setup ----------
void setup() {
  Serial.begin(115200);

  // Salidas apagadas desde el arranque
  digitalWrite(PIN_RELE, RELE_OFF);
  digitalWrite(PIN_ZUMBADOR, ZUMBADOR_OFF);
  pinMode(PIN_RELE, OUTPUT);
  pinMode(PIN_ZUMBADOR, OUTPUT);
  pinMode(PIN_PULSADOR, INPUT_PULLUP);

  Wire.begin(21, 22);  // SDA, SCL

  // Pantalla (si no se encuentra, el sistema sigue funcionando sin ella)
  byte dirLcd = buscarPantalla();
  if (dirLcd != 0) {
    lcd = new LiquidCrystal_I2C(dirLcd, 16, 2);
    lcd->init();
    lcd->backlight();
    lcd->clear();
    mostrarLinea(0, "Acceso Remoto");
    mostrarLinea(1, "Iniciando...");
    Serial.print("Pantalla encontrada en 0x");
    Serial.println(dirLcd, HEX);
  } else {
    Serial.println("Pantalla LCD no encontrada: se continua sin ella");
  }

  if (!rtc.begin()) {
    Serial.println("RTC DS3231 no detectado");
    mostrarLinea(0, "Error:");
    mostrarLinea(1, "RTC no detectado");
    while (1);
  }

  SPI.begin(18, 19, 23, 5);  // SCK, MISO, MOSI, SS
  if (!configurarRadio()) {
    Serial.println("NRF24L01 no detectado");
    mostrarLinea(0, "Error:");
    mostrarLinea(1, "NRF24L01 no det.");
    while (1);
  }

  // Wi-Fi sin bloquear: la alarma funciona aunque no haya conexión
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  configTime(0, 0, "pool.ntp.org", "time.google.com");  // hora UTC para Firebase
  clienteSeguro.setInsecure();

  Serial.println("Central escuchando...");
  aviso("Central", "escuchando...");
}

// ---------- Loop ----------
void loop() {
  // 1. Recepción de alertas por radio
  if (radio.available()) {
    char texto[32] = "";
    radio.read(&texto, sizeof(texto));
    DateTime ahora = rtc.now();
    Serial.printf("Alerta recibida de: %s a las %02d:%02d\n", texto, ahora.hour(), ahora.minute());

    char l1[17];
    snprintf(l1, sizeof(l1), "%s %02d:%02d", texto, ahora.hour(), ahora.minute());

    if (!sistemaArmado) {
      Serial.println("Sistema desarmado desde la app: se ignora");
      aviso("Desarmado", "Alerta ignorada");
    } else if (enSilencio) {
      Serial.println("Alerta ignorada: alarma silenciada con el pulsador");
      aviso("Alerta ignorada", "Silenciada");
    } else if (MODO_PRUEBA || esHorarioNocturno(ahora.hour())) {
      if (!alarmaActiva) {
        horaActivacion = ahora.hour();
        minutoActivacion = ahora.minute();
        activarAlarma();
        enviarAlerta(texto, ahora.hour(), ahora.minute());
        aviso("ALERTA RECIBIDA", l1);
      }
    } else {
      Serial.println("Horario diurno: se ignora");
      aviso("Horario diurno", "Alerta ignorada");
    }
  }

  // 2. Pulsador: apaga la alarma
  if (alarmaActiva && digitalRead(PIN_PULSADOR) == LOW) {
    apagarAlarma();
    if (SILENCIO_PULSADOR > 0) {
      enSilencio = true;
      inicioSilencio = millis();
    }
    Serial.println("Alarma apagada con el pulsador");
    aviso("Alarma apagada", "con el pulsador");
    delay(300);  // evita rebotes
  }

  // 3. Apagado automático de la alarma
  if (alarmaActiva && millis() - inicioAlarma >= DURACION_ALARMA) {
    apagarAlarma();
    Serial.println("Alarma apagada automaticamente");
    aviso("Alarma apagada", "automaticamente");
  }

  // 4. Fin del periodo de silencio
  if (enSilencio && millis() - inicioSilencio >= SILENCIO_PULSADOR) {
    enSilencio = false;
  }

  // 5. Si el módulo de radio se colgó, se reconfigura
  static unsigned long ultimaRevisionRadio = 0;
  if (millis() - ultimaRevisionRadio >= 2000) {
    ultimaRevisionRadio = millis();
    if (!radio.isChipConnected() || radio.getChannel() != 108) {
      Serial.println("Radio colgado: reconfigurando...");
      aviso("Radio colgado", "Reconfigurando");
      configurarRadio();
    }
  }

  // 6. Wi-Fi y Firebase (latido, armado/desarmado, tareas pendientes)
  atenderFirebase();

  // 7. Actualizar pantalla cada segundo
  if (millis() - ultimaPantalla >= 1000) {
    ultimaPantalla = millis();
    actualizarPantalla();
  }
}
