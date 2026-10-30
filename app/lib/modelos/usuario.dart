// Usuario con sesión iniciada (correo y contraseña).

class Usuario {
  final String uid;
  final String correo;
  final String nombre;
  final bool correoVerificado;

  const Usuario({
    required this.uid,
    required this.correo,
    required this.nombre,
    required this.correoVerificado,
  });

  /// Lo que se muestra cuando no hay nombre: la parte antes de la @.
  String get nombreVisible =>
      nombre.isNotEmpty ? nombre : correo.split('@').first;
}
