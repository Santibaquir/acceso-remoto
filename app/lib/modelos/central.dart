// Datos generales de una central y de sus miembros: centrales/{id}/info y /miembros.
import '../nucleo/formato.dart';

class InfoCentral {
  final String id;
  final String nombre;
  final String? propietario;

  const InfoCentral({required this.id, required this.nombre, this.propietario});

  /// ID: 10 caracteres sin letras que se confundan (docs/ARQUITECTURA.md §4).
  static final formatoId = RegExp(r'^[A-Z0-9]{10}$');

  /// Quita espacios y guiones y pasa a mayúsculas lo que escribe el usuario.
  static String normalizar(String texto) =>
      texto.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  bool esPropietario(String uid) => propietario == uid;

  factory InfoCentral.desdeMapa(String id, Map<dynamic, dynamic>? mapa) {
    mapa ??= {};
    final nombre = (mapa['nombre'] ?? '').toString();
    return InfoCentral(
      id: id,
      nombre: nombre.isEmpty ? 'Central $id' : nombre,
      propietario: mapa['propietario']?.toString(),
    );
  }
}

class Miembro {
  final String uid;
  final String correo;
  final DateTime? unido;

  const Miembro({required this.uid, required this.correo, this.unido});

  factory Miembro.desdeMapa(String uid, Map<dynamic, dynamic> mapa) => Miembro(
        uid: uid,
        correo: (mapa['correo'] ?? '').toString(),
        unido: fechaDesde(mapa['unido']),
      );
}
