import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Canal de Android para las alertas. La Placa de desarrollo ESP32 manda
/// el push con `channel_id: alertas_criticas`, así suena la sirena
/// (res/raw/sirena.wav) aunque la app esté cerrada.
const canalAlertas = AndroidNotificationChannel(
  'alertas_criticas',
  'Alertas críticas',
  description: 'Movimiento detectado por los sensores',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('sirena'),
  enableVibration: true,
);

/// Tema de Firebase Cloud Messaging al que la ESP32 envía las alertas.
const temaAlertas = 'alertas';

class Notificaciones {
  static final _locales = FlutterLocalNotificationsPlugin();

  static Future<void> iniciar() async {
    // Crear el canal con sonido de sirena
    await _locales
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canalAlertas);

    // Pedir permiso de notificaciones (Android 13 o superior)
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();

    // Recibir las alertas que manda la ESP32
    await fcm.subscribeToTopic(temaAlertas);
  }
}
