import 'package:intl/intl.dart';

/// Lo que la Placa de desarrollo ESP32 publica en `estado/` de Firebase.
class EstadoCentral {
  final bool armado;
  final bool alerta;
  final DateTime? ultimoLatido;

  const EstadoCentral({
    required this.armado,
    required this.alerta,
    this.ultimoLatido,
  });

  factory EstadoCentral.desdeMapa(Map<dynamic, dynamic>? mapa) {
    mapa ??= {};
    final latido = mapa['ultimoLatido'];
    return EstadoCentral(
      armado: mapa['armado'] == true,
      alerta: mapa['alerta'] == true,
      ultimoLatido: latido is num
          ? DateTime.fromMillisecondsSinceEpoch(latido.toInt())
          : null,
    );
  }

  /// La central manda un latido cada 30 s. Si pasan más de 90 s sin
  /// latido, se considera sin conexión.
  bool enLinea(DateTime ahora) =>
      ultimoLatido != null &&
      ahora.difference(ultimoLatido!) < const Duration(seconds: 90);
}

/// Un registro de `historial/{id}`.
class RegistroAlerta {
  final String id;
  final String sensor;
  final DateTime fecha;

  const RegistroAlerta({
    required this.id,
    required this.sensor,
    required this.fecha,
  });

  factory RegistroAlerta.desdeMapa(String id, Map<dynamic, dynamic> mapa) {
    final fecha = mapa['fecha'];
    return RegistroAlerta(
      id: id,
      sensor: (mapa['sensor'] ?? 'BODEGA').toString(),
      fecha: fecha is num
          ? DateTime.fromMillisecondsSinceEpoch(fecha.toInt())
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// "hace 2 min", "hace 3 h", o la fecha si fue hace mucho.
String haceCuanto(DateTime momento, DateTime ahora) {
  final d = ahora.difference(momento);
  if (d.inSeconds < 60) return 'hace un momento';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  return DateFormat("d MMM, h:mm a", 'es').format(momento);
}

String formatoHora(DateTime momento) =>
    DateFormat('h:mm:ss a', 'es').format(momento);
