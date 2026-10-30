// Lectura y escritura de las centrales en la Realtime Database de Firebase.
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../modelos/central.dart';
import '../modelos/estado_central.dart';
import '../modelos/horario.dart';
import '../modelos/nodo.dart';
import '../modelos/registro_alerta.dart';
import '../modelos/usuario.dart';
import '../nucleo/errores.dart';
import 'rutas.dart';

/// Todo lo que la app puede hacer con una central. Las pantallas solo
/// conocen esta clase; nunca una ruta de Firebase.
abstract class CentralRepositorio {
  void iniciar();

  /// Hora de Firebase (no la del celular), para "en línea / sin conexión".
  DateTime get horaServidor;

  // ---------- Centrales del usuario ----------
  Stream<List<String>> centralesDe(String uid);

  /// Emite error si el usuario ya no es miembro (lo expulsaron).
  Stream<InfoCentral> info(String central);
  Future<void> vincular(Usuario usuario, String central, String codigo);
  Future<void> desvincular(String uid, String central);
  Future<void> renombrarCentral(String central, String nombre);
  Stream<List<Miembro>> miembros(String central);
  Future<void> expulsar(String central, String uid);

  // ---------- Estado ----------
  Stream<EstadoCentral> estado(String central);
  Future<void> cambiarArmado(String central, bool armar);
  Future<void> reconocerAlerta(String central, String uid);

  // ---------- Horario ----------
  Stream<Horario> horario(String central);
  Future<void> guardarHorario(String central, Horario horario);

  // ---------- Nodos ----------
  Stream<List<Nodo>> nodos(String central);
  Future<void> agregarNodo(String central, String id, String nombre);
  Future<void> renombrarNodo(String central, String id, String nombre);
  Future<void> activarNodo(String central, String id, bool activo);
  Future<void> eliminarNodo(String central, String id);

  // ---------- Historial ----------
  /// Últimas alertas, la más reciente primero. Con [nodo], solo las de ese nodo.
  Stream<List<RegistroAlerta>> historial(String central,
      {int limite = 100, String? nodo});
  Future<void> borrarHistorial(String central);

  // ---------- Solo modo demo ----------
  void simularAlerta(String central) {}
  void simularPulsador(String central) {}
}

class CentralFirebase extends CentralRepositorio {
  final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: urlBaseDatos,
  );

  DatabaseReference _ref([String? ruta]) => _db.ref(ruta);

  // Diferencia entre el reloj del celular y el de Firebase
  int _desfaseServidor = 0;

  @override
  void iniciar() {
    _ref('.info/serverTimeOffset').onValue.listen((evento) {
      _desfaseServidor = (evento.snapshot.value as num?)?.toInt() ?? 0;
    });
  }

  @override
  DateTime get horaServidor =>
      DateTime.now().add(Duration(milliseconds: _desfaseServidor));

  // ---------- Centrales del usuario ----------

  @override
  Stream<List<String>> centralesDe(String uid) =>
      _ref(Rutas.centralesDe(uid)).onValue.map((e) {
        final mapa = e.snapshot.value;
        if (mapa is! Map) return <String>[];
        return mapa.keys.map((k) => k.toString()).toList()..sort();
      });

  @override
  Stream<InfoCentral> info(String central) => _ref(Rutas.info(central))
      .onValue
      .map((e) => InfoCentral.desdeMapa(central, e.snapshot.value as Map?));

  @override
  Future<void> vincular(Usuario usuario, String central, String codigo) async {
    final id = InfoCentral.normalizar(central);
    final cod = InfoCentral.normalizar(codigo);
    if (!InfoCentral.formatoId.hasMatch(id)) {
      throw const ErrorTiGuard('El ID de la central tiene 10 letras y números.');
    }
    if (cod.length < 6) {
      throw const ErrorTiGuard('Escribe el código que muestra la central.');
    }

    try {
      // Una sola operación: o se guardan las dos cosas, o ninguna.
      // Las reglas comparan el código con codigosVinculacion/{id}.
      await _ref().update({
        Rutas.miembro(id, usuario.uid): {
          'correo': usuario.correo,
          'codigo': cod,
          'unido': ServerValue.timestamp,
        },
        Rutas.indiceCentral(usuario.uid, id): true,
      });
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') throw _error(e);
      // ¿Ya era miembro? Entonces sí puede leer la central.
      if (!await _puedeLeer(id)) {
        throw const ErrorTiGuard(
            'ID o código incorrectos. Revísalos en la pantalla de la central.');
      }
      await _ref(Rutas.indiceCentral(usuario.uid, id)).set(true);
    }

    // El primer usuario que se vincula queda como propietario
    final info = await _ref(Rutas.info(id)).get();
    final datos = info.value is Map ? info.value as Map : const {};
    if (datos['propietario'] == null) {
      await _intentar(
          () => _ref('${Rutas.info(id)}/propietario').set(usuario.uid));
      if (datos['nombre'] == null) {
        await _intentar(
            () => _ref('${Rutas.info(id)}/nombre').set('Mi central'));
      }
    }
  }

  Future<bool> _puedeLeer(String central) async {
    try {
      await _ref(Rutas.info(central)).get();
      return true;
    } on FirebaseException {
      return false;
    }
  }

  @override
  Future<void> desvincular(String uid, String central) => _intentar(
        () => _ref().update({
          Rutas.miembro(central, uid): null,
          Rutas.indiceCentral(uid, central): null,
        }),
        sinPermiso: 'El propietario no puede salir de su propia central.',
      );

  @override
  Future<void> renombrarCentral(String central, String nombre) => _intentar(
        () => _ref('${Rutas.info(central)}/nombre').set(nombre.trim()),
      );

  @override
  Stream<List<Miembro>> miembros(String central) =>
      _ref(Rutas.miembros(central)).onValue.map((e) {
        final lista = <Miembro>[];
        for (final hijo in e.snapshot.children) {
          if (hijo.value is Map) {
            lista.add(Miembro.desdeMapa(hijo.key!, hijo.value as Map));
          }
        }
        return lista;
      });

  @override
  Future<void> expulsar(String central, String uid) =>
      _intentar(() => _ref(Rutas.miembro(central, uid)).remove());

  // ---------- Estado ----------

  @override
  Stream<EstadoCentral> estado(String central) => _ref(Rutas.estado(central))
      .onValue
      .map((e) => EstadoCentral.desdeMapa(e.snapshot.value as Map?));

  @override
  Future<void> cambiarArmado(String central, bool armar) =>
      _intentar(() => _ref(Rutas.estado(central)).update({'armado': armar}));

  @override
  Future<void> reconocerAlerta(String central, String uid) => _intentar(
        () => _ref(Rutas.estado(central)).update({
          'alerta': false,
          'desactivacion': {
            'origen': 'app',
            'uid': uid,
            'fecha': ServerValue.timestamp,
          },
        }),
      );

  // ---------- Horario ----------

  @override
  Stream<Horario> horario(String central) => _ref(Rutas.horario(central))
      .onValue
      .map((e) => Horario.desdeMapa(e.snapshot.value as Map?));

  @override
  Future<void> guardarHorario(String central, Horario horario) =>
      _intentar(() => _ref(Rutas.horario(central)).set(horario.aMapa()));

  // ---------- Nodos ----------

  @override
  Stream<List<Nodo>> nodos(String central) =>
      _ref(Rutas.nodos(central)).onValue.map((e) {
        final lista = <Nodo>[];
        for (final hijo in e.snapshot.children) {
          if (hijo.value is Map) {
            lista.add(Nodo.desdeMapa(hijo.key!, hijo.value as Map));
          }
        }
        lista.sort((a, b) => a.id.compareTo(b.id));
        return lista;
      });

  @override
  Future<void> agregarNodo(String central, String id, String nombre) async {
    final nodoId = InfoCentral.normalizar(id);
    if (!Nodo.formatoId.hasMatch(nodoId)) {
      throw const ErrorTiGuard('El ID del nodo tiene de 2 a 8 letras o números.');
    }
    final existente = await _ref(Rutas.nodo(central, nodoId)).get();
    if (existente.exists) {
      throw ErrorTiGuard('Ya hay un nodo con el ID $nodoId.');
    }
    await _intentar(() => _ref(Rutas.nodo(central, nodoId)).set({
          'nombre': nombre.trim(),
          'tipo': 'pir',
          'activo': true,
          'descubierto': false,
          'creado': ServerValue.timestamp,
        }));
  }

  @override
  Future<void> renombrarNodo(String central, String id, String nombre) =>
      _intentar(() =>
          _ref(Rutas.nodo(central, id)).update({'nombre': nombre.trim()}));

  @override
  Future<void> activarNodo(String central, String id, bool activo) =>
      _intentar(() => _ref(Rutas.nodo(central, id)).update({'activo': activo}));

  @override
  Future<void> eliminarNodo(String central, String id) =>
      _intentar(() => _ref(Rutas.nodo(central, id)).remove());

  // ---------- Historial ----------

  @override
  Stream<List<RegistroAlerta>> historial(String central,
      {int limite = 100, String? nodo}) {
    final base = _ref(Rutas.historial(central));
    final consulta = nodo == null
        ? base.orderByChild('fecha').limitToLast(limite)
        : base.orderByChild('nodo').equalTo(nodo).limitToLast(limite);
    return consulta.onValue.map((e) {
      final lista = <RegistroAlerta>[];
      for (final hijo in e.snapshot.children) {
        if (hijo.value is Map) {
          lista.add(RegistroAlerta.desdeMapa(hijo.key!, hijo.value as Map));
        }
      }
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  @override
  Future<void> borrarHistorial(String central) =>
      _intentar(() => _ref(Rutas.historial(central)).remove());

  // ---------- Errores ----------

  Future<void> _intentar(Future<void> Function() accion,
      {String? sinPermiso}) async {
    try {
      await accion();
    } on FirebaseException catch (e) {
      throw _error(e, sinPermiso: sinPermiso);
    }
  }

  ErrorTiGuard _error(FirebaseException e, {String? sinPermiso}) =>
      ErrorTiGuard(switch (e.code) {
        'permission-denied' => sinPermiso ??
            'No tienes permiso para esto. Solo el propietario de la central puede hacerlo.',
        'network-error' || 'disconnected' => 'Sin conexión a internet.',
        _ => 'No se pudo guardar (${e.code}).',
      });
}
