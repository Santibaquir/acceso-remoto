import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abre la app comercial de la cámara Wi-Fi por su nombre de paquete.
class Camara {
  static const _clave = 'paquete_camara';

  /// Apps de cámara más comunes. Si la tuya no está, se escribe el
  /// paquete a mano en Ajustes (se ve en la URL de Play Store: ?id=...).
  static const apps = {
    'Tapo (TP-Link)': 'com.tplink.iot',
    'EZVIZ': 'com.ezviz',
    'Imou Life': 'com.mm.android.smartlifeiot',
    'V380 Pro': 'com.macrovideo.v380pro',
    'Yoosee': 'com.yoosee',
    'iCSee': 'com.xm.csee',
    'Xiaomi Home': 'com.xiaomi.smarthome',
  };

  static Future<String?> paqueteGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clave);
  }

  static Future<void> guardarPaquete(String paquete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, paquete.trim());
  }

  /// Devuelve false si todavía no se ha elegido la app de la cámara.
  static Future<bool> abrir() async {
    final paquete = await paqueteGuardado();
    if (paquete == null || paquete.isEmpty) return false;
    // Si la app no está instalada, abre su página en Play Store
    await LaunchApp.openApp(androidPackageName: paquete, openStore: true);
    return true;
  }
}
