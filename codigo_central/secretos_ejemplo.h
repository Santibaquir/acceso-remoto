// Copia este archivo como "secretos.h" (en esta misma carpeta) y llena tus datos.
// secretos.h NO se debe subir a GitHub: tiene la clave privada de Firebase.

#define WIFI_SSID "NOMBRE_DE_TU_WIFI"
#define WIFI_PASSWORD "CLAVE_DE_TU_WIFI"

// Consola de Firebase -> Realtime Database (la URL de arriba, termina en .firebaseio.com o .firebasedatabase.app)
#define DATABASE_URL "https://TU-PROYECTO-default-rtdb.firebaseio.com"

// Consola de Firebase -> Configuración del proyecto -> Cuentas de servicio -> Generar nueva clave privada.
// Del JSON descargado copia "project_id", "client_email" y "private_key".
#define FIREBASE_PROJECT_ID "tu-proyecto"
#define FIREBASE_CLIENT_EMAIL "firebase-adminsdk-xxxxx@tu-proyecto.iam.gserviceaccount.com"
const char PRIVATE_KEY[] PROGMEM = "-----BEGIN PRIVATE KEY-----\nPEGA_AQUI_LA_CLAVE\n-----END PRIVATE KEY-----\n";
