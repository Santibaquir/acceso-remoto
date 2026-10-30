// =====================================================================
//  TiGuard — Central (Placa de desarrollo ESP32)          TiGuard Secure
//  Recibe los nodos por radio, decide si hay alerta de movimiento y la
//  publica en Firebase. Contrato de datos y protocolo de radio:
//  docs/ARQUITECTURA.md (secciones 4 y 5). No cambiar rutas ni el
//  mensaje de radio sin actualizar ese documento.
// =====================================================================
#include <SPI.h>
#include <RF24.h>
#include <Wire.h>
#include <RTClib.h>
#include <LiquidCrystal_I2C.h>
#include <Preferences.h>   // memoria interna (NVS): armado y horario sin internet
#include <ArduinoJson.h>   // leer y escribir JSON de Firebase de forma segura

//  Firebase (librería FirebaseClient de Mobizt)
#define ENABLE_SERVICE_AUTH
#define ENABLE_DATABASE
#define ENABLE_MESSAGING
#include <FirebaseClient.h>
#include <ExampleFunctions.h>  // WiFi, WiFiClientSecure y funciones de apoyo de la librería
#include "secretos.h"          // Wi-Fi, claves de Firebase, CENTRAL_ID y CODIGO_VINCULACION

// ---------- Pines ----------
const int PIN_RELE = 25;
const int PIN_ZUMBADOR = 27;
const int PIN_PULSADOR = 26;

// ---------- Protocolo de radio (igual en firmware/nodo/nodo.ino) ----------
const uint8_t PROTOCOLO_VERSION = 1;
const uint8_t EVENTO_MOVIMIENTO = 1;
const uint8_t EVENTO_LATIDO = 2;

struct __attribute__((packed)) MensajeNodo {
  uint8_t version;  // PROTOCOLO_VERSION
  char nodo[9];     // ID del nodo, ej. "N01"
  uint8_t evento;   // EVENTO_MOVIMIENTO o EVENTO_LATIDO
};

const byte DIRECCION_RED[6] = "TGNET";
const uint8_t CANAL_RADIO = 108;

// ---------- Rutas de Firebase (docs/ARQUITECTURA.md §4) ----------
#define RUTA_CENTRAL "/centrales/" CENTRAL_ID
const char RUTA_ESTADO[] = RUTA_CENTRAL "/estado";
const char RUTA_HORARIO[] = RUTA_CENTRAL "/config/horario";
const char RUTA_NODOS[] = RUTA_CENTRAL "/nodos";
const char RUTA_HISTORIAL[] = RUTA_CENTRAL "/historial";
const char RUTA_CODIGO[] = "/codigosVinculacion/" CENTRAL_ID;

// Temas de notificación de esta central (§7)
const char TEMA_SIRENA[] = "tg_" CENTRAL_ID "_sirena";
const char TEMA_NORMAL[] = "tg_" CENTRAL_ID "_normal";
const char TEMA_SILENCIO[] = "tg_" CENTRAL_ID "_silencio";
const char TEMA_AVISOS[] = "tg_" CENTRAL_ID "_avisos";

// ---------- Objetos ----------
RF24 radio(4, 5);  // CE, CSN
RTC_DS3231 rtc;
LiquidCrystal_I2C *lcd = nullptr;
Preferences memoria;

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

const unsigned long DURACION_ALARMA = 10000;     // la alarma suena 10 segundos
const unsigned long SILENCIO_PULSADOR = 5000;    // tras apagar con el pulsador se ignoran alertas 5 s
const unsigned long DURACION_AVISO = 3000;       // los avisos se quedan 3 s en la pantalla
const unsigned long DURACION_IDENTIDAD = 10000;  // ID y código en pantalla al encender

const unsigned long CADA_LATIDO = 30000;          // avisa a la app que la central está en línea
const unsigned long CADA_LECTURA_ESTADO = 3000;   // armado / desarmado / alerta reconocida
const unsigned long CADA_LECTURA_CONFIG = 20000;  // horario y nodos
const unsigned long CADA_CONTACTO_NODO = 60000;   // máx. una escritura de ultimoContacto por nodo y minuto

// ---------- Horario de vigilancia (minutos desde la medianoche) ----------
// Se guarda en la memoria interna para seguir funcionando sin internet.
bool horarioSiempre = false;
int horarioInicio = 22 * 60;  // 10:00 PM
int horarioFin = 6 * 60;      // 6:00 AM

// ---------- Nodos conocidos ----------
const int MAX_NODOS = 16;
struct NodoConocido {
  char id[9];
  char nombre[31];
  bool activo;
  unsigned long ultimoReporte;  // millis() de la última escritura de ultimoContacto
};
NodoConocido nodos[MAX_NODOS];
int cantidadNodos = 0;
bool nodosCargados = false;  // true cuando ya se leyó la lista de Firebase

// ---------- Estado ----------
bool alarmaActiva = false;
unsigned long inicioAlarma = 0;
bool enSilencio = false;
unsigned long inicioSilencio = 0;
unsigned long ultimaPantalla = 0;
unsigned long finAviso = 0;

// Armado / desarmado desde la app. Se recuerda en la memoria interna.
bool sistemaArmado = true;
bool firebaseIniciado = false;
bool codigoPublicado = false;
unsigned long ultimoLatido = 0;
unsigned long ultimaLecturaEstado = 0;
unsigned long ultimaLecturaConfig = 0;
bool tocaLeerNodos = false;  // alterna horario / nodos en cada lectura de config

// true mientras la app muestra la alerta (estado/alerta). El pulsador la
// apaga también en la app aunque la sirena física ya se haya callado sola.
bool alertaEnApp = false;

// Última alarma: hora y nombre del nodo (para la pantalla)
int horaActivacion = -1;
int minutoActivacion = -1;
char nodoActivacion[31] = "";

// =====================================================================
//  Pantalla LCD
// =====================================================================
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

// Muestra un aviso en la pantalla durante unos milisegundos
void aviso(const char *l0, const char *l1, unsigned long duracion = DURACION_AVISO) {
  mostrarLinea(0, l0);
  mostrarLinea(1, l1);
  finAviso = millis() + duracion;
}

bool hayAviso() {
  return (long)(finAviso - millis()) > 0;
}

// ID y código de vinculación: los pide la app para vincular la central
void mostrarIdentidad() {
  char l0[17], l1[17];
  const char *cod = CODIGO_VINCULACION;
  snprintf(l0, sizeof(l0), "ID  %s", CENTRAL_ID);
  snprintf(l1, sizeof(l1), "COD %.4s-%.4s", cod, cod + 4);
  aviso(l0, l1, DURACION_IDENTIDAD);
}

// =====================================================================
//  Horario
// =====================================================================

// Misma regla que Horario.vigilaEn() de la app (app/lib/modelos/horario.dart)
bool dentroDeHorario(int minuto) {
  if (horarioSiempre || horarioInicio == horarioFin) return true;
  if (horarioInicio < horarioFin) return minuto >= horarioInicio && minuto < horarioFin;
  return minuto >= horarioInicio || minuto < horarioFin;  // cruza la medianoche
}

bool vigilandoAhora() {
  DateTime ahora = rtc.now();
  return dentroDeHorario(ahora.hour() * 60 + ahora.minute());
}

void cargarMemoria() {
  memoria.begin("tiguard", true);
  sistemaArmado = memoria.getBool("armado", true);
  horarioSiempre = memoria.getBool("siempre", false);
  horarioInicio = memoria.getInt("inicio", 22 * 60);
  horarioFin = memoria.getInt("fin", 6 * 60);
  memoria.end();
}

void guardarArmado() {
  memoria.begin("tiguard", false);
  memoria.putBool("armado", sistemaArmado);
  memoria.end();
}

void guardarHorario() {
  memoria.begin("tiguard", false);
  memoria.putBool("siempre", horarioSiempre);
  memoria.putInt("inicio", horarioInicio);
  memoria.putInt("fin", horarioFin);
  memoria.end();
}

// Pantalla normal: hora, vigilancia y Wi-Fi arriba; estado abajo
void actualizarPantalla() {
  if (!lcd || hayAviso()) return;
  DateTime ahora = rtc.now();
  char l0[17], l1[17];

  snprintf(l0, sizeof(l0), "%02d:%02d %-7s %s", ahora.hour(), ahora.minute(),
           vigilandoAhora() ? "VIGILA" : "PAUSA",
           WiFi.status() == WL_CONNECTED ? "W" : "-");

  if (alarmaActiva) {
    snprintf(l1, sizeof(l1), "!%.9s %02d:%02d", nodoActivacion, horaActivacion, minutoActivacion);
  } else if (!sistemaArmado) {
    snprintf(l1, sizeof(l1), "Desarmado");
  } else if (enSilencio) {
    snprintf(l1, sizeof(l1), "Silenciada");
  } else if (horaActivacion >= 0) {
    snprintf(l1, sizeof(l1), "Ultima %02d:%02d", horaActivacion, minutoActivacion);
  } else {
    snprintf(l1, sizeof(l1), "%d nodo%s", cantidadNodos, cantidadNodos == 1 ? "" : "s");
  }

  mostrarLinea(0, l0);
  mostrarLinea(1, l1);
}

// =====================================================================
//  Nodos
// =====================================================================
NodoConocido *buscarNodo(const char *id) {
  for (int i = 0; i < cantidadNodos; i++) {
    if (strcmp(nodos[i].id, id) == 0) return &nodos[i];
  }
  return nullptr;
}

// Solo letras mayúsculas y números, de 2 a 8 (igual que las reglas de Firebase)
bool idValido(const char *id) {
  size_t largo = strlen(id);
  if (largo < 2 || largo > 8) return false;
  for (size_t i = 0; i < largo; i++) {
    if (!isupper(id[i]) && !isdigit(id[i])) return false;
  }
  return true;
}

NodoConocido *agregarNodoLocal(const char *id, const char *nombre, bool activo) {
  if (cantidadNodos >= MAX_NODOS) return nullptr;
  NodoConocido &n = nodos[cantidadNodos++];
  strlcpy(n.id, id, sizeof(n.id));
  strlcpy(n.nombre, nombre, sizeof(n.nombre));
  n.activo = activo;
  n.ultimoReporte = 0;
  return &n;
}

// =====================================================================
//  Firebase
// =====================================================================
void respuestaFirebase(AsyncResult &resultado);

// Convierte un documento JSON en texto para mandarlo a Firebase
String aTexto(JsonDocument &doc) {
  String texto;
  serializeJson(doc, texto);
  return texto;
}

void procesarEstado(const String &valor) {
  JsonDocument doc;
  if (deserializeJson(doc, valor)) return;

  if (doc["alerta"].is<bool>()) alertaEnApp = doc["alerta"].as<bool>();

  if (doc["armado"].is<bool>()) {
    bool nuevo = doc["armado"].as<bool>();
    if (nuevo != sistemaArmado) {
      sistemaArmado = nuevo;
      guardarArmado();
      Serial.println(sistemaArmado ? "App: sistema ARMADO" : "App: sistema DESARMADO");
      aviso("Desde la app:", sistemaArmado ? "ARMADO" : "DESARMADO");
      if (!sistemaArmado) apagarAlarma();
    }
  } else {
    // Todavía no existe en la base de datos: se crea con el valor actual
    baseDatos.set<bool>(clienteFirebase, String(RUTA_ESTADO) + "/armado", sistemaArmado,
                        respuestaFirebase, "crearArmado");
  }
}

void procesarHorario(const String &valor) {
  JsonDocument doc;
  if (deserializeJson(doc, valor) || !doc.is<JsonObject>()) {
    // No hay horario en Firebase: se publica el que tiene la central
    JsonDocument nuevo;
    nuevo["siempre"] = horarioSiempre;
    nuevo["inicio"] = horarioInicio;
    nuevo["fin"] = horarioFin;
    baseDatos.set<object_t>(clienteFirebase, RUTA_HORARIO, object_t(aTexto(nuevo)),
                            respuestaFirebase, "crearHorario");
    return;
  }

  bool siempre = doc["siempre"] | false;
  int inicio = constrain((int)(doc["inicio"] | 22 * 60), 0, 1439);
  int fin = constrain((int)(doc["fin"] | 6 * 60), 0, 1439);

  if (siempre != horarioSiempre || inicio != horarioInicio || fin != horarioFin) {
    horarioSiempre = siempre;
    horarioInicio = inicio;
    horarioFin = fin;
    guardarHorario();
    char l1[17];
    if (siempre) snprintf(l1, sizeof(l1), "24 horas");
    else snprintf(l1, sizeof(l1), "%02d:%02d a %02d:%02d", inicio / 60, inicio % 60, fin / 60, fin % 60);
    Serial.printf("Horario nuevo: %s\n", l1);
    aviso("Horario nuevo", l1);
  }
}

// Reconstruye la tabla de nodos con lo que hay en Firebase (nombres y activo)
void procesarNodos(const String &valor) {
  JsonDocument doc;
  if (deserializeJson(doc, valor)) return;

  NodoConocido anteriores[MAX_NODOS];
  int cantidadAnterior = cantidadNodos;
  memcpy(anteriores, nodos, sizeof(nodos));
  cantidadNodos = 0;

  if (doc.is<JsonObject>()) {
    for (JsonPair par : doc.as<JsonObject>()) {
      JsonObject n = par.value().as<JsonObject>();
      NodoConocido *nuevo = agregarNodoLocal(par.key().c_str(), n["nombre"] | par.key().c_str(),
                                             n["activo"] | true);
      if (!nuevo) break;
      // Conservar cuándo se reportó por última vez
      for (int i = 0; i < cantidadAnterior; i++) {
        if (strcmp(anteriores[i].id, nuevo->id) == 0) nuevo->ultimoReporte = anteriores[i].ultimoReporte;
      }
    }
  }
  nodosCargados = true;
}

// Respuesta de las tareas de Firebase (se llama sola cuando termina cada una)
void respuestaFirebase(AsyncResult &resultado) {
  if (resultado.isError()) {
    Serial.printf("Firebase error en %s: %s\n", resultado.uid().c_str(),
                  resultado.error().message().c_str());
    return;
  }
  if (!resultado.available()) return;

  String uid = resultado.uid();
  if (uid == "leerEstado") procesarEstado(resultado.c_str());
  else if (uid == "leerHorario") procesarHorario(resultado.c_str());
  else if (uid == "leerNodos") procesarNodos(resultado.c_str());
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

  // El código de vinculación se publica una vez por encendido: así, si se
  // cambia en secretos.h, la app usa el nuevo en cuanto se graba la central.
  if (!codigoPublicado) {
    codigoPublicado = true;
    baseDatos.set<String>(clienteFirebase, RUTA_CODIGO, String(CODIGO_VINCULACION),
                          respuestaFirebase, "codigo");
  }

  // No se encolan más tareas si las anteriores no han terminado
  if (clienteFirebase.taskCount() > 2) return;

  // Latido: la app muestra "en línea" mientras llegue cada 30 s
  if (ultimoLatido == 0 || millis() - ultimoLatido >= CADA_LATIDO) {
    ultimoLatido = millis();
    baseDatos.set<object_t>(clienteFirebase, String(RUTA_ESTADO) + "/ultimoLatido",
                            object_t("{\".sv\":\"timestamp\"}"), respuestaFirebase, "latido");
    return;
  }

  // Armado / desarmado y alerta reconocida, que escribe la app
  if (millis() - ultimaLecturaEstado >= CADA_LECTURA_ESTADO) {
    ultimaLecturaEstado = millis();
    baseDatos.get(clienteFirebase, RUTA_ESTADO, respuestaFirebase, false, "leerEstado");
    return;
  }

  // Horario y nodos (se alternan para no saturar la conexión)
  if (ultimaLecturaConfig == 0 || millis() - ultimaLecturaConfig >= CADA_LECTURA_CONFIG / 2) {
    ultimaLecturaConfig = millis();
    if (tocaLeerNodos) baseDatos.get(clienteFirebase, RUTA_NODOS, respuestaFirebase, false, "leerNodos");
    else baseDatos.get(clienteFirebase, RUTA_HORARIO, respuestaFirebase, false, "leerHorario");
    tocaLeerNodos = !tocaLeerNodos;
  }
}

bool firebaseListo() {
  return firebaseIniciado && appFirebase.ready();
}

// Un nodo que la central nunca había escuchado: se registra solo en Firebase
void registrarNodo(const char *id) {
  if (!firebaseListo()) return;
  JsonDocument doc;
  doc["nombre"] = id;
  doc["tipo"] = "pir";
  doc["activo"] = true;
  doc["descubierto"] = true;
  doc["creado"][".sv"] = "timestamp";
  baseDatos.set<object_t>(clienteFirebase, String(RUTA_NODOS) + "/" + id,
                          object_t(aTexto(doc)), respuestaFirebase, "registrarNodo");
  Serial.printf("Nodo nuevo registrado: %s\n", id);
}

// "El nodo sigue vivo": como máximo una escritura por minuto por nodo
void reportarContacto(NodoConocido *nodo) {
  if (!firebaseListo() || !nodo) return;
  if (nodo->ultimoReporte != 0 && millis() - nodo->ultimoReporte < CADA_CONTACTO_NODO) return;
  nodo->ultimoReporte = millis();
  baseDatos.set<object_t>(clienteFirebase, String(RUTA_NODOS) + "/" + nodo->id + "/ultimoContacto",
                          object_t("{\".sv\":\"timestamp\"}"), respuestaFirebase, "contacto");
}

// Manda un push a un tema de Firebase Cloud Messaging.
// canal: canal de Android que crea la app (define sonido y vibración).
void enviarPush(const char *tema, const char *canal, const char *sonido,
                const char *titulo, const char *cuerpo, bool urgente) {
  Messages::Notification notificacion;
  notificacion.title(titulo).body(cuerpo);

  Messages::AndroidNotification notificacionAndroid;
  notificacionAndroid.channel_id(canal);
  if (sonido) notificacionAndroid.sound(sonido);
  notificacionAndroid.notification_priority(urgente ? Messages::NotificationPriority::PRIORITY_MAX
                                                    : Messages::NotificationPriority::PRIORITY_HIGH);

  Messages::AndroidConfig configAndroid;
  configAndroid.priority(Messages::AndroidMessagePriority::_HIGH);
  configAndroid.notification(notificacionAndroid);

  Messages::Message mensaje;
  mensaje.topic(tema);
  mensaje.notification(notificacion);
  mensaje.android(configAndroid);

  mensajeria.send(clienteFirebase, Messages::Parent(FIREBASE_PROJECT_ID), mensaje, respuestaFirebase, "push");
}

// Publica la alerta de movimiento en Firebase y manda la notificación push
void publicarAlerta(NodoConocido *nodo, int hora, int minuto) {
  if (!firebaseListo()) {
    Serial.println("Sin Wi-Fi/Firebase: la alerta no llegó a la app");
    return;  // Aquí irá el SMS con el Módulo GSM SIM800L
  }

  // 1. estado/alerta = true y qué nodo la disparó (la app la apaga al reconocerla)
  JsonDocument estado;
  estado["alerta"] = true;
  estado["alertaNodo"] = nodo->id;
  baseDatos.update<object_t>(clienteFirebase, RUTA_ESTADO, object_t(aTexto(estado)),
                             respuestaFirebase, "alerta");

  // 2. Registro en el historial con la hora del servidor y una copia del nombre
  JsonDocument registro;
  registro["nodo"] = nodo->id;
  registro["nombre"] = nodo->nombre;
  registro["tipo"] = "movimiento";
  registro["fecha"][".sv"] = "timestamp";
  baseDatos.push<object_t>(clienteFirebase, RUTA_HISTORIAL, object_t(aTexto(registro)),
                           respuestaFirebase, "historial");

  alertaEnApp = true;

  // 3. Notificación push (llega aunque la app esté cerrada). Cada celular
  //    está suscrito solo al tema del modo que eligió en Ajustes.
  char cuerpo[64];
  snprintf(cuerpo, sizeof(cuerpo), "%s · %02d:%02d", nodo->nombre, hora, minuto);
  const char *titulo = "Movimiento detectado";

  enviarPush(TEMA_SIRENA, "movimiento_sirena", "sirena", titulo, cuerpo, true);
  enviarPush(TEMA_NORMAL, "movimiento_normal", "default", titulo, cuerpo, true);
  enviarPush(TEMA_SILENCIO, "movimiento_silencio", nullptr, titulo, cuerpo, true);
}

// El pulsador apagó la alarma: la app quita la alerta y muestra quién la apagó
void publicarDesactivacion(int hora, int minuto) {
  if (!firebaseListo()) {
    Serial.println("Sin Wi-Fi/Firebase: la app no supo que se apagó con el pulsador");
    return;
  }
  alertaEnApp = false;

  baseDatos.update<object_t>(clienteFirebase, RUTA_ESTADO,
                             object_t("{\"alerta\":false,\"desactivacion\":{\"origen\":\"pulsador\",\"fecha\":{\".sv\":\"timestamp\"}}}"),
                             respuestaFirebase, "desactivacion");

  char cuerpo[64];
  snprintf(cuerpo, sizeof(cuerpo), "Se apagó con el pulsador de la central a las %02d:%02d", hora, minuto);
  enviarPush(TEMA_AVISOS, "avisos_central", "default", "Alarma desactivada", cuerpo, false);
}

// =====================================================================
//  Alarma
// =====================================================================
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

// =====================================================================
//  Radio
// =====================================================================
bool configurarRadio() {
  if (!radio.begin()) return false;
  radio.setPALevel(RF24_PA_LOW);
  radio.setDataRate(RF24_250KBPS);
  radio.setChannel(CANAL_RADIO);
  radio.setPayloadSize(sizeof(MensajeNodo));
  radio.openReadingPipe(1, DIRECCION_RED);
  radio.startListening();
  return true;
}

// Decide qué hacer con un mensaje que llegó de un nodo
void atenderNodo(const MensajeNodo &msg) {
  char id[9];
  strlcpy(id, msg.nodo, sizeof(id));  // por si el nodo no mandó el '\0'

  if (msg.version != PROTOCOLO_VERSION || !idValido(id)) {
    Serial.printf("Mensaje de radio inválido (versión %d, nodo '%s')\n", msg.version, id);
    return;
  }

  // ¿Lo conocemos? Si no, se agrega (activo) y se registra en Firebase
  NodoConocido *nodo = buscarNodo(id);
  if (!nodo) {
    nodo = agregarNodoLocal(id, id, true);
    if (!nodo) {
      Serial.println("Tabla de nodos llena (MAX_NODOS)");
      return;
    }
    if (nodosCargados) registrarNodo(id);
    aviso("Nodo nuevo:", id);
  }
  reportarContacto(nodo);

  if (msg.evento == EVENTO_LATIDO) return;
  if (msg.evento != EVENTO_MOVIMIENTO) return;

  DateTime ahora = rtc.now();
  Serial.printf("Movimiento en %s (%s) a las %02d:%02d\n", nodo->nombre, id, ahora.hour(), ahora.minute());
  char l1[17];
  snprintf(l1, sizeof(l1), "%.10s %02d:%02d", nodo->nombre, ahora.hour(), ahora.minute());

  if (!nodo->activo) {
    Serial.println("Nodo desactivado desde la app: se ignora");
    aviso("Nodo desactivado", l1);
  } else if (!sistemaArmado) {
    Serial.println("Sistema desarmado desde la app: se ignora");
    aviso("Desarmado", "Alerta ignorada");
  } else if (enSilencio) {
    Serial.println("Alerta ignorada: alarma silenciada con el pulsador");
    aviso("Alerta ignorada", "Silenciada");
  } else if (!dentroDeHorario(ahora.hour() * 60 + ahora.minute())) {
    Serial.println("Fuera del horario de vigilancia: se ignora");
    aviso("Fuera de horario", "Alerta ignorada");
  } else if (!alarmaActiva) {
    horaActivacion = ahora.hour();
    minutoActivacion = ahora.minute();
    strlcpy(nodoActivacion, nodo->nombre, sizeof(nodoActivacion));
    activarAlarma();
    Serial.println(">>> ALERTA DE MOVIMIENTO <<<");
    publicarAlerta(nodo, ahora.hour(), ahora.minute());
    aviso("MOVIMIENTO", l1);
  }
}

// =====================================================================
//  Setup
// =====================================================================
void setup() {
  Serial.begin(115200);

  // Salidas apagadas desde el arranque
  digitalWrite(PIN_RELE, RELE_OFF);
  digitalWrite(PIN_ZUMBADOR, ZUMBADOR_OFF);
  pinMode(PIN_RELE, OUTPUT);
  pinMode(PIN_ZUMBADOR, OUTPUT);
  pinMode(PIN_PULSADOR, INPUT_PULLUP);

  cargarMemoria();
  Wire.begin(21, 22);  // SDA, SCL

  // Pantalla (si no se encuentra, el sistema sigue funcionando sin ella)
  byte dirLcd = buscarPantalla();
  if (dirLcd != 0) {
    lcd = new LiquidCrystal_I2C(dirLcd, 16, 2);
    lcd->init();
    lcd->backlight();
    lcd->clear();
    mostrarLinea(0, "TiGuard");
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
  clienteSeguro.setInsecure();  // Pendiente: certificado raíz (docs/ARQUITECTURA.md §8)

  Serial.printf("TiGuard central %s lista. Armado: %s. Horario: %s %d-%d\n", CENTRAL_ID,
                sistemaArmado ? "si" : "no", horarioSiempre ? "24h" : "", horarioInicio, horarioFin);
  mostrarIdentidad();
}

// =====================================================================
//  Loop
// =====================================================================
void loop() {
  // 1. Mensajes de los nodos por radio
  if (radio.available()) {
    MensajeNodo msg;
    memset(&msg, 0, sizeof(msg));
    radio.read(&msg, sizeof(msg));
    atenderNodo(msg);
  }

  // 2. Pulsador: apaga la alarma (y la alerta en la app, aunque la sirena ya
  //    se haya apagado sola). Sin alarma, muestra el ID y el código.
  if (digitalRead(PIN_PULSADOR) == LOW) {
    if (alarmaActiva || alertaEnApp) {
      apagarAlarma();
      if (SILENCIO_PULSADOR > 0) {
        enSilencio = true;
        inicioSilencio = millis();
      }
      DateTime ahora = rtc.now();
      publicarDesactivacion(ahora.hour(), ahora.minute());
      Serial.println("Alarma apagada con el pulsador");
      aviso("Alarma apagada", "con el pulsador");
    } else {
      mostrarIdentidad();
    }
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
    if (!radio.isChipConnected() || radio.getChannel() != CANAL_RADIO) {
      Serial.println("Radio colgado: reconfigurando...");
      aviso("Radio colgado", "Reconfigurando");
      configurarRadio();
    }
  }

  // 6. Wi-Fi y Firebase (latido, estado, horario, nodos, tareas pendientes)
  atenderFirebase();

  // 7. Actualizar pantalla cada segundo
  if (millis() - ultimaPantalla >= 1000) {
    ultimaPantalla = millis();
    actualizarPantalla();
  }
}
