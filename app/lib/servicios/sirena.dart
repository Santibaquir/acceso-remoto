import 'package:audioplayers/audioplayers.dart';

/// Sirena dentro de la app (cuando está abierta).
/// Con la app cerrada, el sonido lo pone la notificación push.
class Sirena {
  static final _reproductor = AudioPlayer();
  static bool _sonando = false;

  static bool get sonando => _sonando;

  static Future<void> sonar() async {
    if (_sonando) return;
    _sonando = true;
    await _reproductor.setReleaseMode(ReleaseMode.loop);
    await _reproductor.play(AssetSource('sonidos/sirena.wav'), volume: 1);
  }

  static Future<void> callar() async {
    if (!_sonando) return;
    _sonando = false;
    await _reproductor.stop();
  }
}
