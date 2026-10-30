// Lo que la central publica en centrales/{id}/estado.
import '../nucleo/formato.dart';

class EstadoCentral {
  final bool armado;
  final bool alerta;

  /// ID del nodo que disparó la alerta actual.
  final String? alertaNodo;
  final DateTime? ultimoLatido;
  final Desactivacion? desactivacion;

  const EstadoCentral({
    required this.armado,
    required this.alerta,
    this.alertaNodo,
    this.ultimoLatido,
    this.desactivacion,
  });

  factory EstadoCentral.desdeMapa(Map<dynamic, dynamic>? mapa) {
    mapa ??= {};
    final desactivacion = mapa['desactivacion'];
    return EstadoCentral(
      armado: mapa['armado'] == true,
      alerta: mapa['alerta'] == true,
      alertaNodo: mapa['alertaNodo']?.toString(),
      ultimoLatido: fechaDesde(mapa['ultimoLatido']),
      desactivacion:
          desactivacion is Map ? Desactivacion.desdeMapa(desactivacion) : null,
    );
  }

  /// La central manda un latido cada 30 s. Si pasan más de 90 s sin
  /// latido, se considera sin conexión.
  bool enLinea(DateTime ahora) =>
      ultimoLatido != null &&
      ahora.difference(ultimoLatido!) < const Duration(seconds: 90);
}

/// Quién apagó la última alerta. La central escribe `origen: pulsador`;
/// la app escribe `origen: app`.
class Desactivacion {
  final String origen;
  final DateTime fecha;

  const Desactivacion({required this.origen, required this.fecha});

  bool get desdePulsador => origen == 'pulsador';

  factory Desactivacion.desdeMapa(Map<dynamic, dynamic> mapa) => Desactivacion(
        origen: (mapa['origen'] ?? 'app').toString(),
        fecha: fechaDesde(mapa['fecha']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
