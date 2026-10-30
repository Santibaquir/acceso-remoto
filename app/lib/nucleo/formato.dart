// Formatos de fecha y hora en español usados en toda la app.
import 'package:intl/intl.dart';

/// "hace 2 min", "hace 3 h", o la fecha si fue hace mucho.
String haceCuanto(DateTime momento, DateTime ahora) {
  final d = ahora.difference(momento);
  if (d.inSeconds < 60) return 'hace un momento';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  return DateFormat("d MMM, h:mm a", 'es').format(momento);
}

/// 11:42:05 p. m.
String formatoHora(DateTime momento) =>
    DateFormat('h:mm:ss a', 'es').format(momento);

/// Minutos desde la medianoche → "10:00 p. m."
String formatoMinutos(int minutos) {
  final hora = DateTime(2000, 1, 1, minutos ~/ 60, minutos % 60);
  return DateFormat('h:mm a', 'es').format(hora);
}

/// Duración legible: "8 h", "7 h 30 min".
String formatoDuracion(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}

/// "Hoy", "Ayer" o "Lunes 27 de octubre".
String tituloDia(DateTime dia, DateTime hoy) {
  final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
  final soloDia = DateTime(dia.year, dia.month, dia.day);
  final diferencia = soloHoy.difference(soloDia).inDays;
  if (diferencia == 0) return 'Hoy';
  if (diferencia == 1) return 'Ayer';
  final texto = DateFormat("EEEE d 'de' MMMM", 'es').format(dia);
  return texto[0].toUpperCase() + texto.substring(1);
}

/// Convierte un número de Firebase (ms) en fecha; null si no hay dato.
DateTime? fechaDesde(Object? valor) => valor is num
    ? DateTime.fromMillisecondsSinceEpoch(valor.toInt())
    : null;
