// Error con un mensaje ya listo para mostrarle al usuario.

/// Los repositorios convierten los errores de Firebase en [ErrorTiGuard]
/// para que las pantallas solo tengan que mostrar [mensaje].
class ErrorTiGuard implements Exception {
  final String mensaje;
  const ErrorTiGuard(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Texto para el usuario a partir de cualquier error.
String mensajeDeError(Object error) => error is ErrorTiGuard
    ? error.mensaje
    : 'Algo salió mal. Revisa la conexión a internet e inténtalo de nuevo.';
