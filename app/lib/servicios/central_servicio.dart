import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../modelos.dart';

/// Modo demo: `flutter run --dart-define=DEMO=true`.
/// Muestra datos de ejemplo sin Firebase (para ver el diseño o presentar).
const modoDemo = bool.fromEnvironment('DEMO');

/// Lectura y escritura de la Realtime Database de Firebase.
///
/// Estructura:
///   estado/armado        (bool)  lo escribe la app, lo lee la Placa de desarrollo ESP32
///   estado/alerta        (bool)  lo pone en true la ESP32, la app lo apaga al reconocer
///   estado/ultimoLatido  (ms)    la ESP32 lo actualiza cada 30 s
///   historial/{id}       {sensor, fecha}
abstract class CentralServicio {
  static final CentralServicio instancia =
      modoDemo ? _CentralDemo() : _CentralFirebase();

  void iniciar();
  DateTime get horaServidor;
  Stream<EstadoCentral> get estado;

  /// Últimas alertas, la más reciente primero.
  Stream<List<RegistroAlerta>> historial({int limite = 100});

  Future<void> cambiarArmado(bool armar);
  Future<void> reconocerAlerta();
  Future<void> borrarHistorial();

  /// Solo en modo demo: simula que llega una alerta de la bodega.
  void simularAlerta() {}
}

/// URL de la Realtime Database del proyecto acceso-remoto-5777.
const urlBaseDatos = 'https://acceso-remoto-5777-default-rtdb.firebaseio.com';

class _CentralFirebase extends CentralServicio {
  final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: urlBaseDatos,
  );
  DatabaseReference get _estado => _db.ref('estado');

  // Diferencia entre el reloj del celular y el de Firebase, para que
  // "en línea / sin conexión" no dependa de la hora del celular.
  int _desfaseServidor = 0;

  @override
  void iniciar() {
    _db.ref('.info/serverTimeOffset').onValue.listen((evento) {
      _desfaseServidor = (evento.snapshot.value as num?)?.toInt() ?? 0;
    });
  }

  @override
  DateTime get horaServidor =>
      DateTime.now().add(Duration(milliseconds: _desfaseServidor));

  @override
  Stream<EstadoCentral> get estado => _estado.onValue.map(
        (evento) => EstadoCentral.desdeMapa(evento.snapshot.value as Map?),
      );

  @override
  Stream<List<RegistroAlerta>> historial({int limite = 100}) => _db
          .ref('historial')
          .orderByChild('fecha')
          .limitToLast(limite)
          .onValue
          .map((evento) {
        final lista = <RegistroAlerta>[];
        for (final hijo in evento.snapshot.children) {
          if (hijo.value is Map) {
            lista.add(RegistroAlerta.desdeMapa(hijo.key!, hijo.value as Map));
          }
        }
        lista.sort((a, b) => b.fecha.compareTo(a.fecha));
        return lista;
      });

  @override
  Future<void> cambiarArmado(bool armar) => _estado.update({'armado': armar});

  @override
  Future<void> reconocerAlerta() => _estado.update({'alerta': false});

  @override
  Future<void> borrarHistorial() => _db.ref('historial').remove();
}

/// Central de mentira que vive en memoria (modo demo).
class _CentralDemo extends CentralServicio {
  bool _armado = true;
  bool _alerta = false;
  late final List<RegistroAlerta> _historial;
  final _cambios = StreamController<void>.broadcast();
  Timer? _latido;

  @override
  void iniciar() {
    final ahora = DateTime.now();
    final ayer = ahora.subtract(const Duration(days: 1));
    _historial = [
      RegistroAlerta(id: '1', sensor: 'BODEGA', fecha: ahora.subtract(const Duration(minutes: 47))),
      RegistroAlerta(id: '2', sensor: 'BODEGA', fecha: DateTime(ayer.year, ayer.month, ayer.day, 2, 14)),
      RegistroAlerta(id: '3', sensor: 'BODEGA', fecha: DateTime(ayer.year, ayer.month, ayer.day, 23, 41)),
      RegistroAlerta(id: '4', sensor: 'BODEGA', fecha: ahora.subtract(const Duration(days: 3, hours: 2))),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));
    // La central "manda latidos" para aparecer en línea
    _latido = Timer.periodic(const Duration(seconds: 30), (_) => _avisar());
  }

  void _avisar() => _cambios.add(null);

  EstadoCentral get _ahora => EstadoCentral(
        armado: _armado,
        alerta: _alerta,
        ultimoLatido: DateTime.now(),
      );

  @override
  DateTime get horaServidor => DateTime.now();

  @override
  Stream<EstadoCentral> get estado async* {
    yield _ahora;
    yield* _cambios.stream.map((_) => _ahora);
  }

  @override
  Stream<List<RegistroAlerta>> historial({int limite = 100}) async* {
    yield _historial.take(limite).toList();
    yield* _cambios.stream.map((_) => _historial.take(limite).toList());
  }

  @override
  Future<void> cambiarArmado(bool armar) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _armado = armar;
    _avisar();
  }

  @override
  Future<void> reconocerAlerta() async {
    _alerta = false;
    _avisar();
  }

  @override
  Future<void> borrarHistorial() async {
    _historial.clear();
    _avisar();
  }

  @override
  void simularAlerta() {
    if (!_armado) return;
    _historial.insert(
      0,
      RegistroAlerta(id: '${DateTime.now().millisecondsSinceEpoch}', sensor: 'BODEGA', fecha: DateTime.now()),
    );
    _alerta = true;
    _avisar();
  }

  void cerrar() => _latido?.cancel();
}
