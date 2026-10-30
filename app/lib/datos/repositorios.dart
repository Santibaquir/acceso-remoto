// Punto único para obtener los repositorios (Firebase o demo).
import 'auth_repositorio.dart';
import 'central_repositorio.dart';
import 'demo/auth_demo.dart';
import 'demo/central_demo.dart';

/// Modo demo: `flutter run --dart-define=DEMO=true`.
/// Muestra datos de ejemplo sin Firebase (para ver el diseño o presentar).
const modoDemo = bool.fromEnvironment('DEMO');

class Repositorios {
  static final AuthRepositorio auth = modoDemo ? AuthDemo() : AuthFirebase();
  static final CentralRepositorio central =
      modoDemo ? CentralDemo() : CentralFirebase();
}
