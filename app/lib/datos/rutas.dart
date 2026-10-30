// Todas las rutas de la Realtime Database. Es el reflejo exacto de
// docs/ARQUITECTURA.md §4: si cambia una, cambian las dos.

/// URL de la Realtime Database del proyecto (el ID no se puede renombrar).
const urlBaseDatos = 'https://acceso-remoto-5777-default-rtdb.firebaseio.com';

class Rutas {
  static String usuario(String uid) => 'usuarios/$uid';
  static String perfil(String uid) => 'usuarios/$uid/perfil';
  static String centralesDe(String uid) => 'usuarios/$uid/centrales';
  static String indiceCentral(String uid, String c) => 'usuarios/$uid/centrales/$c';

  static String central(String c) => 'centrales/$c';
  static String info(String c) => 'centrales/$c/info';
  static String miembros(String c) => 'centrales/$c/miembros';
  static String miembro(String c, String uid) => 'centrales/$c/miembros/$uid';
  static String estado(String c) => 'centrales/$c/estado';
  static String horario(String c) => 'centrales/$c/config/horario';
  static String nodos(String c) => 'centrales/$c/nodos';
  static String nodo(String c, String n) => 'centrales/$c/nodos/$n';
  static String historial(String c) => 'centrales/$c/historial';

  /// Temas de Firebase Cloud Messaging de una central (§7).
  static String tema(String c, String sufijo) => 'tg_${c}_$sufijo';
}
