// Sesión de mentira para el modo demo: acepta cualquier correo y contraseña.
import 'dart:async';

import '../../modelos/usuario.dart';
import '../../nucleo/errores.dart';
import '../auth_repositorio.dart';

class AuthDemo implements AuthRepositorio {
  Usuario? _actual;
  final _cambios = StreamController<Usuario?>.broadcast();

  @override
  Stream<Usuario?> get cambios async* {
    yield _actual;
    yield* _cambios.stream;
  }

  @override
  Usuario? get actual => _actual;

  void _entrar(String nombre, String correo) {
    _actual = Usuario(
      uid: 'demo',
      correo: correo.trim(),
      nombre: nombre,
      correoVerificado: true,
    );
    _cambios.add(_actual);
  }

  void _validar(String correo, String contrasena) {
    if (!correo.contains('@')) {
      throw const ErrorTiGuard('El correo no tiene un formato válido.');
    }
    if (contrasena.length < AuthRepositorio.largoMinimoContrasena) {
      throw const ErrorTiGuard('Correo o contraseña incorrectos.');
    }
  }

  @override
  Future<void> iniciarSesion(String correo, String contrasena) async {
    await Future.delayed(const Duration(milliseconds: 700));
    _validar(correo, contrasena);
    _entrar('Tiba', correo);
  }

  @override
  Future<void> registrar(String nombre, String correo, String contrasena) async {
    await Future.delayed(const Duration(milliseconds: 900));
    _validar(correo, contrasena);
    _entrar(nombre.trim(), correo);
  }

  @override
  Future<void> recuperarContrasena(String correo) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> reenviarVerificacion() async {}

  @override
  Future<Usuario?> recargar() async => _actual;

  @override
  Future<void> cerrarSesion() async {
    _actual = null;
    _cambios.add(null);
  }
}
