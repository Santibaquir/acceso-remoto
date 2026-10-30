// =====================================================================
//  TiGuard — Nodo de vigilancia (Placa Arduino Nano)       TiGuard Secure
//  Sensor de movimiento PIR HC-SR501 + Módulo transceptor NRF24L01.
//  Avisa a la central por radio. Protocolo: docs/ARQUITECTURA.md §5.
//
//  CADA NODO NECESITA SU PROPIO NODO_ID (N01, N02, N03...). La central lo
//  registra sola la primera vez; el nombre ("Bodega") se pone en la app.
// =====================================================================
#include <SPI.h>
#include <RF24.h>

// ---------- Identidad de este nodo ----------
const char NODO_ID[] = "N01";  // 2 a 8 letras mayúsculas o números

// ---------- Pines ----------
const int PIN_PIR = 2;
RF24 radio(9, 10);  // CE, CSN

// ---------- Protocolo de radio (igual en firmware/central/central.ino) ----------
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

// ---------- Tiempos ----------
const unsigned long CALENTAMIENTO_PIR = 30000;     // el sensor necesita 30 s al encender
const unsigned long ESPERA_ENTRE_ALERTAS = 3000;   // máx. una alerta cada 3 s
const unsigned long CADA_LATIDO = 300000;          // "sigo vivo" cada 5 minutos

unsigned long ultimoEnvio = 0;
unsigned long ultimoLatido = 0;

// Manda un evento a la central. Devuelve true si la central lo recibió (ACK).
bool enviar(uint8_t evento) {
  MensajeNodo msg;
  memset(&msg, 0, sizeof(msg));
  msg.version = PROTOCOLO_VERSION;
  strncpy(msg.nodo, NODO_ID, sizeof(msg.nodo) - 1);
  msg.evento = evento;
  return radio.write(&msg, sizeof(msg));
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_PIR, INPUT);
  pinMode(LED_BUILTIN, OUTPUT);

  if (!radio.begin()) {
    Serial.println("NRF24L01 no detectado");
    while (1);
  }
  radio.setPALevel(RF24_PA_LOW);
  radio.setDataRate(RF24_250KBPS);
  radio.setChannel(CANAL_RADIO);
  radio.setPayloadSize(sizeof(MensajeNodo));
  // Reintentos: si dos nodos hablan a la vez, uno vuelve a intentar
  radio.setRetries(5, 15);
  radio.openWritingPipe(DIRECCION_RED);
  radio.stopListening();

  Serial.print("Nodo TiGuard ");
  Serial.print(NODO_ID);
  Serial.println(" listo");
  Serial.println("Calentando el Sensor de movimiento PIR HC-SR501 (30 s)...");
  delay(CALENTAMIENTO_PIR);
  Serial.println("Sensor listo: vigilando");

  // Primer latido: la central registra el nodo aunque no haya movimiento
  Serial.println(enviar(EVENTO_LATIDO) ? "Central encontrada" : "Sin respuesta de la central");
  ultimoLatido = millis();
}

void loop() {
  // Movimiento
  if (digitalRead(PIN_PIR) == HIGH && millis() - ultimoEnvio >= ESPERA_ENTRE_ALERTAS) {
    ultimoEnvio = millis();
    Serial.println(enviar(EVENTO_MOVIMIENTO) ? "Alerta enviada" : "Sin respuesta de la central");

    // El LED de la placa parpadea cuando hay movimiento
    digitalWrite(LED_BUILTIN, HIGH);
    delay(200);
    digitalWrite(LED_BUILTIN, LOW);
  }

  // Latido periódico
  if (millis() - ultimoLatido >= CADA_LATIDO) {
    ultimoLatido = millis();
    Serial.println(enviar(EVENTO_LATIDO) ? "Latido enviado" : "Latido sin respuesta");
  }
}
