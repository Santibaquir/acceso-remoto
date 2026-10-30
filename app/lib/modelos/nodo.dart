// Un nodo de vigilancia: centrales/{id}/nodos/{nodoId}.
import '../nucleo/formato.dart';

class Nodo {
  /// ID grabado en el firmware del nodo (ej. "N01"). No cambia.
  final String id;

  /// Nombre que ve el usuario (ej. "Bodega"). Se puede cambiar.
  final String nombre;
  final String tipo;

  /// false = la central ignora sus alertas.
  final bool activo;

  /// true = la central lo registró sola al escucharlo por primera vez.
  final bool descubierto;
  final DateTime? creado;
  final DateTime? ultimoContacto;

  const Nodo({
    required this.id,
    required this.nombre,
    this.tipo = 'pir',
    this.activo = true,
    this.descubierto = false,
    this.creado,
    this.ultimoContacto,
  });

  /// 2 a 8 letras mayúsculas o números (docs/ARQUITECTURA.md §4).
  static final formatoId = RegExp(r'^[A-Z0-9]{2,8}$');
  static const largoMaximoNombre = 30;

  /// El nodo manda un latido cada 5 min; con 12 min sin noticias se da por perdido.
  static const toleranciaLatido = Duration(minutes: 12);

  bool enLinea(DateTime ahora) =>
      ultimoContacto != null &&
      ahora.difference(ultimoContacto!) < toleranciaLatido;

  /// Recién descubierto y todavía sin nombre propio.
  bool get sinNombre => descubierto && nombre == id;

  factory Nodo.desdeMapa(String id, Map<dynamic, dynamic> mapa) => Nodo(
        id: id,
        nombre: (mapa['nombre'] ?? id).toString(),
        tipo: (mapa['tipo'] ?? 'pir').toString(),
        activo: mapa['activo'] != false,
        descubierto: mapa['descubierto'] == true,
        creado: fechaDesde(mapa['creado']),
        ultimoContacto: fechaDesde(mapa['ultimoContacto']),
      );
}
