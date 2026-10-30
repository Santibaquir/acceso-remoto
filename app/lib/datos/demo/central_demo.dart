// Central de mentira que vive en memoria (modo demo). Imita las reglas de Firebase.
import 'dart:async';

import '../../modelos/central.dart';
import '../../modelos/estado_central.dart';
import '../../modelos/horario.dart';
import '../../modelos/nodo.dart';
import '../../modelos/registro_alerta.dart';
import '../../modelos/usuario.dart';
import '../../nucleo/errores.dart';
import '../central_repositorio.dart';

class CentralDemo extends CentralRepositorio {
  static const _id = 'DEMO7K2M9Q';
  static const _codigo = 'TIGUARD1';

  final _cambios = StreamController<void>.broadcast();
  final List<String> _mias = [];
  String _nombre = 'Casa principal';
  bool _armado = true;
  bool _alerta = false;
  String? _alertaNodo;
  Desactivacion? _desactivacion;
  Horario _horario = Horario.porDefecto;
  final Map<String, Nodo> _nodos = {};
  final List<RegistroAlerta> _historial = [];
  final Map<String, Miembro> _miembros = {};

  /// Emite el valor actual y luego uno nuevo con cada cambio.
  Stream<T> _vigilar<T>(T Function() leer) async* {
    yield leer();
    yield* _cambios.stream.map((_) => leer());
  }

  void _avisar() => _cambios.add(null);

  @override
  void iniciar() {
    final ahora = DateTime.now();
    final ayer = ahora.subtract(const Duration(days: 1));
    _mias.add(_id);
    _miembros['demo'] = Miembro(uid: 'demo', correo: 'tiba@tiguard.co', unido: ayer);
    _miembros['m2'] = Miembro(uid: 'm2', correo: 'familia@tiguard.co', unido: ayer);
    for (final n in [
      Nodo(id: 'N01', nombre: 'Bodega', ultimoContacto: ahora),
      Nodo(id: 'N02', nombre: 'Garaje', ultimoContacto: ahora),
      Nodo(id: 'N03', nombre: 'Oficina', activo: false,
          ultimoContacto: ahora.subtract(const Duration(hours: 2))),
      const Nodo(id: 'N04', nombre: 'N04', descubierto: true),
    ]) {
      _nodos[n.id] = n;
    }
    _historial.addAll([
      RegistroAlerta(id: '1', nodo: 'N01', nombre: 'Bodega', fecha: ahora.subtract(const Duration(minutes: 47))),
      RegistroAlerta(id: '2', nodo: 'N02', nombre: 'Garaje', fecha: DateTime(ayer.year, ayer.month, ayer.day, 2, 14)),
      RegistroAlerta(id: '3', nodo: 'N01', nombre: 'Bodega', fecha: DateTime(ayer.year, ayer.month, ayer.day, 23, 41)),
      RegistroAlerta(id: '4', nodo: 'N02', nombre: 'Garaje', fecha: ahora.subtract(const Duration(days: 3, hours: 2))),
    ]);
    _historial.sort((a, b) => b.fecha.compareTo(a.fecha));
    // La central "manda latidos" para aparecer en línea
    Timer.periodic(const Duration(seconds: 30), (_) => _avisar());
  }

  @override
  DateTime get horaServidor => DateTime.now();

  EstadoCentral get _estado => EstadoCentral(
        armado: _armado,
        alerta: _alerta,
        alertaNodo: _alertaNodo,
        ultimoLatido: DateTime.now(),
        desactivacion: _desactivacion,
      );

  // ---------- Centrales del usuario ----------

  @override
  Stream<List<String>> centralesDe(String uid) => _vigilar(() => List.of(_mias));

  @override
  Stream<InfoCentral> info(String central) => _vigilar(
      () => InfoCentral(id: central, nombre: _nombre, propietario: 'demo'));

  @override
  Future<void> vincular(Usuario usuario, String central, String codigo) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (InfoCentral.normalizar(central) != _id ||
        InfoCentral.normalizar(codigo) != _codigo) {
      throw const ErrorTiGuard(
          'ID o código incorrectos. En el modo demo: DEMO7K2M9Q / TIGUARD1');
    }
    if (!_mias.contains(_id)) _mias.add(_id);
    _avisar();
  }

  @override
  Future<void> desvincular(String uid, String central) async =>
      throw const ErrorTiGuard('El propietario no puede salir de su propia central.');

  @override
  Future<void> renombrarCentral(String central, String nombre) async {
    _nombre = nombre.trim();
    _avisar();
  }

  @override
  Stream<List<Miembro>> miembros(String central) =>
      _vigilar(() => _miembros.values.toList());

  @override
  Future<void> expulsar(String central, String uid) async {
    _miembros.remove(uid);
    _avisar();
  }

  // ---------- Estado ----------

  @override
  Stream<EstadoCentral> estado(String central) => _vigilar(() => _estado);

  @override
  Future<void> cambiarArmado(String central, bool armar) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _armado = armar;
    _avisar();
  }

  @override
  Future<void> reconocerAlerta(String central, String uid) async {
    _alerta = false;
    _desactivacion = Desactivacion(origen: 'app', fecha: DateTime.now());
    _avisar();
  }

  // ---------- Horario ----------

  @override
  Stream<Horario> horario(String central) => _vigilar(() => _horario);

  @override
  Future<void> guardarHorario(String central, Horario horario) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _horario = horario;
    _avisar();
  }

  // ---------- Nodos ----------

  @override
  Stream<List<Nodo>> nodos(String central) =>
      _vigilar(() => _nodos.values.toList()..sort((a, b) => a.id.compareTo(b.id)));

  @override
  Future<void> agregarNodo(String central, String id, String nombre) async {
    final nodoId = InfoCentral.normalizar(id);
    if (!Nodo.formatoId.hasMatch(nodoId)) {
      throw const ErrorTiGuard('El ID del nodo tiene de 2 a 8 letras o números.');
    }
    if (_nodos.containsKey(nodoId)) {
      throw ErrorTiGuard('Ya hay un nodo con el ID $nodoId.');
    }
    _nodos[nodoId] = Nodo(id: nodoId, nombre: nombre.trim(), creado: DateTime.now());
    _avisar();
  }

  Nodo _copiar(Nodo n, {String? nombre, bool? activo}) => Nodo(
        id: n.id,
        nombre: nombre ?? n.nombre,
        tipo: n.tipo,
        activo: activo ?? n.activo,
        descubierto: n.descubierto,
        creado: n.creado,
        ultimoContacto: n.ultimoContacto,
      );

  @override
  Future<void> renombrarNodo(String central, String id, String nombre) async {
    _nodos[id] = _copiar(_nodos[id]!, nombre: nombre.trim());
    _avisar();
  }

  @override
  Future<void> activarNodo(String central, String id, bool activo) async {
    _nodos[id] = _copiar(_nodos[id]!, activo: activo);
    _avisar();
  }

  @override
  Future<void> eliminarNodo(String central, String id) async {
    _nodos.remove(id);
    _avisar();
  }

  // ---------- Historial ----------

  @override
  Stream<List<RegistroAlerta>> historial(String central,
          {int limite = 100, String? nodo}) =>
      _vigilar(() => _historial
          .where((r) => nodo == null || r.nodo == nodo)
          .take(limite)
          .toList());

  @override
  Future<void> borrarHistorial(String central) async {
    _historial.clear();
    _avisar();
  }

  // ---------- Simulación ----------

  /// Simula una alerta del primer nodo activo (como haría la central).
  @override
  void simularAlerta(String central) {
    final ahora = DateTime.now();
    final nodo = _nodos.values.where((n) => n.activo).firstOrNull;
    if (!_armado || nodo == null || !_horario.vigilaAhora(ahora)) return;
    _historial.insert(0, RegistroAlerta(
      id: '${ahora.millisecondsSinceEpoch}',
      nodo: nodo.id,
      nombre: nodo.nombre,
      fecha: ahora,
    ));
    _alerta = true;
    _alertaNodo = nodo.id;
    _avisar();
  }

  @override
  void simularPulsador(String central) {
    if (!_alerta) return;
    _alerta = false;
    _desactivacion = Desactivacion(origen: 'pulsador', fecha: DateTime.now());
    _avisar();
  }
}
