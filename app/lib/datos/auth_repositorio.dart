// Inicio de sesión con correo y contraseña (Firebase Authentication).
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../modelos/usuario.dart';
import '../nucleo/errores.dart';
import 'rutas.dart';

abstract class AuthRepositorio {
  /// Emite el usuario al iniciar sesión y null al cerrarla.
  Stream<Usuario?> get cambios;
  Usuario? get actual;

  Future<void> iniciarSesion(String correo, String contrasena);
  Future<void> registrar(String nombre, String correo, String contrasena);
  Future<void> recuperarContrasena(String correo);
  Future<void> reenviarVerificacion();

  /// Vuelve a leer el usuario (para saber si ya verificó el correo).
  Future<Usuario?> recargar();
  Future<void> cerrarSesion();

  static const largoMinimoContrasena = 8;
}

class AuthFirebase implements AuthRepositorio {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: urlBaseDatos,
  );

  Usuario? _convertir(User? u) {
    // Las sesiones anónimas de la versión Acceso Remoto ya no sirven
    if (u == null || u.isAnonymous) return null;
    return Usuario(
      uid: u.uid,
      correo: u.email ?? '',
      nombre: u.displayName ?? '',
      correoVerificado: u.emailVerified,
    );
  }

  @override
  Stream<Usuario?> get cambios async* {
    // Si quedó una sesión anónima vieja, se cierra para pedir correo y contraseña
    if (_auth.currentUser?.isAnonymous == true) await _auth.signOut();
    yield* _auth.userChanges().map(_convertir);
  }

  @override
  Usuario? get actual => _convertir(_auth.currentUser);

  @override
  Future<void> iniciarSesion(String correo, String contrasena) => _intentar(
        () => _auth.signInWithEmailAndPassword(
          email: correo.trim(),
          password: contrasena,
        ),
      );

  @override
  Future<void> registrar(String nombre, String correo, String contrasena) =>
      _intentar(() async {
        final credencial = await _auth.createUserWithEmailAndPassword(
          email: correo.trim(),
          password: contrasena,
        );
        final u = credencial.user!;
        await u.updateDisplayName(nombre.trim());
        await _db.ref(Rutas.perfil(u.uid)).set({
          'nombre': nombre.trim(),
          'correo': u.email,
          'creado': ServerValue.timestamp,
        });
        // La verificación no bloquea el uso, pero protege la recuperación de cuenta
        await u.sendEmailVerification();
        await u.reload();
      });

  @override
  Future<void> recuperarContrasena(String correo) =>
      _intentar(() => _auth.sendPasswordResetEmail(email: correo.trim()));

  @override
  Future<void> reenviarVerificacion() =>
      _intentar(() async => _auth.currentUser?.sendEmailVerification());

  @override
  Future<Usuario?> recargar() async {
    await _auth.currentUser?.reload();
    return actual;
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  /// Traduce los códigos de Firebase a mensajes claros en español.
  Future<void> _intentar(Future<void> Function() accion) async {
    try {
      await accion();
    } on FirebaseAuthException catch (e) {
      throw ErrorTiGuard(switch (e.code) {
        'invalid-email' => 'El correo no tiene un formato válido.',
        'user-disabled' => 'Esta cuenta fue deshabilitada.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Correo o contraseña incorrectos.',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
        'weak-password' => 'La contraseña es muy débil.',
        'too-many-requests' =>
          'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
        'network-request-failed' => 'Sin conexión a internet.',
        'operation-not-allowed' =>
          'El inicio de sesión con correo no está habilitado en Firebase.',
        _ => 'No se pudo completar (${e.code}).',
      });
    }
  }
}
