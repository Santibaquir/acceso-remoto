// Estado global de la sesión: usuario, sus centrales y la central elegida.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../datos/repositorios.dart';
import '../modelos/central.dart';
import '../modelos/usuario.dart';
import '../servicios/notificaciones.dart';

/// Las pantallas escuchan esta clase para saber qué mostrar
/// (acceso, vincular o panel). Es la única fuente de "quién soy" y
/// "qué central estoy viendo".
class Sesion extends ChangeNotifier {
  Sesion._();
  static final instancia = Sesion._();

  static const _claveCentral = 'central_elegida';
  final _auth = Repositorios.auth;
  final _repo = Repositorios.central;

  Usuario? _usuario;
  bool _cargando = true;
  bool _primerEvento = true;
  List<String> _centrales = [];
  String? _centralActual;
  final Map<String, InfoCentral> _infos = {};

  StreamSubscription? _subAuth;
  StreamSubscription? _subCentrales;
  final Map<String, StreamSubscription> _subInfos = {};

  Usuario? get usuario => _usuario;

  /// true mientras se averigua si hay sesión y qué centrales tiene.
  bool get cargando => _cargando;
  List<String> get centrales => List.unmodifiable(_centrales);
  String? get centralActual => _centralActual;
  InfoCentral? get infoActual => _infos[_centralActual];
  InfoCentral? infoDe(String central) => _infos[central];

  /// ¿El usuario es el propietario de la central que está viendo?
  bool get esPropietario =>
      _usuario != null && (infoActual?.esPropietario(_usuario!.uid) ?? false);

  void iniciar() {
    _subAuth = _auth.cambios.listen(_alCambiarUsuario);
  }

  void _alCambiarUsuario(Usuario? usuario) {
    // El primer evento siempre cuenta (aunque sea "sin sesión")
    final cambioDeCuenta = _primerEvento || usuario?.uid != _usuario?.uid;
    _primerEvento = false;
    _usuario = usuario;
    if (!cambioDeCuenta) {
      notifyListeners(); // solo cambió el nombre o la verificación
      return;
    }

    _cancelarCentrales();
    if (usuario == null) {
      _cargando = false;
      Notificaciones.sincronizar([]);
      notifyListeners();
      return;
    }

    _cargando = true;
    notifyListeners();
    _subCentrales = _repo.centralesDe(usuario.uid).listen(
          _alCambiarCentrales,
          onError: (_) => _alCambiarCentrales([]),
        );
  }

  Future<void> _alCambiarCentrales(List<String> ids) async {
    _centrales = ids;

    // Escuchar el nombre y el propietario de cada central
    for (final id in _subInfos.keys.toList()) {
      if (!ids.contains(id)) {
        _subInfos.remove(id)?.cancel();
        _infos.remove(id);
      }
    }
    for (final id in ids) {
      _subInfos[id] ??= _repo.info(id).listen(
        (info) {
          _infos[id] = info;
          notifyListeners();
        },
        // Sin permiso = lo sacaron de la central: se quita de su lista
        onError: (_) => _repo.desvincular(_usuario!.uid, id).catchError((_) {}),
      );
    }

    // Recordar la última central elegida en este celular
    if (_centralActual == null || !ids.contains(_centralActual)) {
      final prefs = await SharedPreferences.getInstance();
      final guardada = prefs.getString(_claveCentral);
      _centralActual = ids.contains(guardada) ? guardada : ids.firstOrNull;
    }

    _cargando = false;
    Notificaciones.sincronizar(ids);
    notifyListeners();
  }

  Future<void> elegirCentral(String central) async {
    if (!_centrales.contains(central)) return;
    _centralActual = central;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveCentral, central);
  }

  Future<void> vincular(String central, String codigo) async {
    await _repo.vincular(_usuario!, central, codigo);
    await elegirCentral(InfoCentral.normalizar(central));
  }

  Future<void> salirDeCentral(String central) =>
      _repo.desvincular(_usuario!.uid, central);

  /// Cierra sesión y deja de recibir alertas en este celular.
  Future<void> cerrarSesion() async {
    await Notificaciones.sincronizar([]);
    _centralActual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveCentral);
    await _auth.cerrarSesion();
  }

  void _cancelarCentrales() {
    _subCentrales?.cancel();
    _subCentrales = null;
    for (final s in _subInfos.values) {
      s.cancel();
    }
    _subInfos.clear();
    _infos.clear();
    _centrales = [];
    _centralActual = null;
  }

  @override
  void dispose() {
    _subAuth?.cancel();
    _cancelarCentrales();
    super.dispose();
  }
}
