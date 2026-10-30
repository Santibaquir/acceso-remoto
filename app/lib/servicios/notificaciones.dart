// Notificaciones push: canales de Android y temas de Firebase Cloud Messaging por central.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../datos/rutas.dart';

/// Cómo avisa el celular cuando llega una alerta de movimiento.
enum ModoAviso { sirena, normal, silencio }

/// Cada modo tiene su canal de Android y su sufijo de tema. La central manda
/// la alerta a los tres temas y el celular solo está suscrito al del modo
/// elegido. Así funciona aunque la app esté cerrada (docs/ARQUITECTURA.md §7).
extension DatosModoAviso on ModoAviso {
  AndroidNotificationChannel get canal => switch (this) {
        ModoAviso.sirena => const AndroidNotificationChannel(
            'movimiento_sirena',
            'Movimiento · con sirena',
            description: 'Movimiento detectado: suena la sirena',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('sirena'),
            enableVibration: true,
          ),
        ModoAviso.normal => const AndroidNotificationChannel(
            'movimiento_normal',
            'Movimiento · sonido normal',
            description: 'Movimiento detectado: sonido de notificación',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        ModoAviso.silencio => const AndroidNotificationChannel(
            'movimiento_silencio',
            'Movimiento · en silencio',
            description: 'Movimiento detectado: solo la notificación',
            importance: Importance.high,
            playSound: false,
            enableVibration: false,
          ),
      };

  String get sufijoTema => name; // sirena, normal, silencio
}

/// Aviso de que la alarma se apagó con el pulsador de la central.
const canalAvisos = AndroidNotificationChannel(
  'avisos_central',
  'Avisos de la central',
  description: 'Alarma desactivada desde el pulsador',
  importance: Importance.high,
);
const sufijoAvisos = 'avisos';

class Notificaciones {
  static final _locales = FlutterLocalNotificationsPlugin();
  static const _claveModo = 'modo_aviso';
  static const _claveAvisoPulsador = 'aviso_pulsador';
  static const _claveTemas = 'temas_suscritos';
  static const _claveMigrado = 'notificaciones_v2';

  static ModoAviso _modo = ModoAviso.sirena;
  static bool _avisoPulsador = true;
  static bool _iniciado = false;
  static List<String> _centrales = [];

  static ModoAviso get modo => _modo;
  static bool get avisoPulsador => _avisoPulsador;

  /// Lee los ajustes guardados. Va antes de Firebase para que la app
  /// sepa si debe sonar la sirena aunque no haya conexión.
  static Future<void> cargarAjustes() async {
    final prefs = await SharedPreferences.getInstance();
    _modo = ModoAviso.values.asNameMap()[prefs.getString(_claveModo)] ??
        ModoAviso.sirena;
    _avisoPulsador = prefs.getBool(_claveAvisoPulsador) ?? true;
  }

  static Future<void> iniciar() async {
    await _locales.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _locales.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final m in ModoAviso.values) {
      await android?.createNotificationChannel(m.canal);
    }
    await android?.createNotificationChannel(canalAvisos);

    // Pedir permiso de notificaciones (Android 13 o superior)
    await FirebaseMessaging.instance.requestPermission();

    await _migrarVersionAnterior(android);
    _iniciado = true;
  }

  /// Una sola vez: quita los canales y temas de "Acceso Remoto", que eran
  /// globales (cualquier celular recibía las alertas de cualquier central).
  static Future<void> _migrarVersionAnterior(
      AndroidFlutterLocalNotificationsPlugin? android) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_claveMigrado) == true) return;
    for (final canal in ['alertas_criticas', 'alertas_normales', 'alertas_silenciosas', 'avisos']) {
      await android?.deleteNotificationChannel(channelId: canal);
    }
    for (final tema in ['alertas', 'alertas_normal', 'alertas_silencio', 'avisos']) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(tema);
    }
    await prefs.setBool(_claveMigrado, true);
  }

  /// Suscribe el celular a los temas de estas centrales (y se desuscribe de
  /// los que ya no correspondan). Con una lista vacía, se desuscribe de todo.
  static Future<void> sincronizar(List<String> centrales) async {
    _centrales = List.of(centrales);
    if (!_iniciado) return;

    final deseados = <String>{
      for (final c in _centrales) ...[
        Rutas.tema(c, _modo.sufijoTema),
        if (_avisoPulsador) Rutas.tema(c, sufijoAvisos),
      ],
    };

    final prefs = await SharedPreferences.getInstance();
    final actuales = (prefs.getStringList(_claveTemas) ?? []).toSet();
    final fcm = FirebaseMessaging.instance;

    for (final tema in actuales.difference(deseados)) {
      await fcm.unsubscribeFromTopic(tema);
    }
    for (final tema in deseados.difference(actuales)) {
      await fcm.subscribeToTopic(tema);
    }
    await prefs.setStringList(_claveTemas, deseados.toList());
  }

  static Future<void> cambiarModo(ModoAviso modo) async {
    _modo = modo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveModo, modo.name);
    await sincronizar(_centrales);
  }

  static Future<void> cambiarAvisoPulsador(bool activo) async {
    _avisoPulsador = activo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveAvisoPulsador, activo);
    await sincronizar(_centrales);
  }

  /// Muestra una notificación de ejemplo con el modo elegido.
  static Future<void> probar() async {
    final canal = _modo.canal;
    await _locales.show(
      id: 0,
      title: 'Movimiento detectado',
      body: 'Prueba · así se verá una alerta en este celular',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          canal.id,
          canal.name,
          channelDescription: canal.description,
          importance: canal.importance,
          priority: Priority.max,
          playSound: canal.playSound,
          sound: canal.sound,
          enableVibration: canal.enableVibration,
        ),
      ),
    );
  }
}
