#include <SPI.h>
#include <RF24.h>

// ---------- Pines ----------
const int PIN_PIR = 2;  // OUT del Sensor de movimiento PIR HC-SR501

// ---------- Objetos ----------
RF24 radio(9, 10);  // CE, CSN
const byte direccion[6] = "BODEG";

// ---------- Ajustes ----------
const unsigned long CALENTAMIENTO_PIR = 30000;  // el sensor tarda 30 s en estabilizarse
const unsigned long ESPERA_ENTRE_ALERTAS = 3000;  // mínimo 3 s entre un envío y otro

unsigned long ultimoEnvio = 0;

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
  radio.setChannel(108);
  radio.openWritingPipe(direccion);
  radio.stopListening();

  Serial.println("Nodo remoto listo");
  Serial.println("Calentando el sensor PIR (30 s)...");
  delay(CALENTAMIENTO_PIR);
  Serial.println("Sensor PIR listo: vigilando");
}

void loop() {
  if (digitalRead(PIN_PIR) == HIGH && millis() - ultimoEnvio >= ESPERA_ENTRE_ALERTAS) {
    ultimoEnvio = millis();

    const char mensaje[] = "BODEGA";
    bool ok = radio.write(&mensaje, sizeof(mensaje));

    Serial.println(ok ? "Alerta enviada" : "Sin respuesta de la central");

    // El LED de la placa parpadea cuando hay movimiento
    digitalWrite(LED_BUILTIN, HIGH);
    delay(200);
    digitalWrite(LED_BUILTIN, LOW);
  }
}