// Un registro del historial: centrales/{id}/historial/{pushId}.
import '../nucleo/formato.dart';

class RegistroAlerta {
  final String id;

  /// ID del nodo que detectó el movimiento.
  final String nodo;

  /// Nombre que tenía el nodo en ese momento (copia, no cambia al renombrar).
  final String nombre;
  final DateTime fecha;

  const RegistroAlerta({
    required this.id,
    required this.nodo,
    required this.nombre,
    required this.fecha,
  });

  factory RegistroAlerta.desdeMapa(String id, Map<dynamic, dynamic> mapa) {
    final nodo = (mapa['nodo'] ?? '').toString();
    // Registros de la versión Acceso Remoto traían "sensor" en vez de nodo/nombre
    final nombre = (mapa['nombre'] ?? mapa['sensor'] ?? nodo).toString();
    return RegistroAlerta(
      id: id,
      nodo: nodo,
      nombre: nombre,
      fecha: fechaDesde(mapa['fecha']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
