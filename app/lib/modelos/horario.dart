// Horario de vigilancia: centrales/{id}/config/horario (minutos desde la medianoche).

class Horario {
  /// true = vigila las 24 horas.
  final bool siempre;
  final int inicio;
  final int fin;

  const Horario({required this.siempre, required this.inicio, required this.fin});

  /// El de fábrica: de 10:00 p. m. a 6:00 a. m.
  static const porDefecto = Horario(siempre: false, inicio: 22 * 60, fin: 6 * 60);
  static const minutosDia = 24 * 60;

  factory Horario.desdeMapa(Map<dynamic, dynamic>? mapa) {
    if (mapa == null) return porDefecto;
    int minutos(Object? v, int defecto) =>
        v is num ? v.toInt().clamp(0, minutosDia - 1) : defecto;
    return Horario(
      siempre: mapa['siempre'] == true,
      inicio: minutos(mapa['inicio'], porDefecto.inicio),
      fin: minutos(mapa['fin'], porDefecto.fin),
    );
  }

  Map<String, Object> aMapa() => {'siempre': siempre, 'inicio': inicio, 'fin': fin};

  Horario copiar({bool? siempre, int? inicio, int? fin}) => Horario(
        siempre: siempre ?? this.siempre,
        inicio: inicio ?? this.inicio,
        fin: fin ?? this.fin,
      );

  /// ¿Se vigila en este minuto del día? Si inicio > fin, cruza la medianoche.
  /// Es la misma regla que usa la central (firmware/central, dentroDeHorario).
  bool vigilaEn(int minuto) {
    if (siempre || inicio == fin) return true;
    if (inicio < fin) return minuto >= inicio && minuto < fin;
    return minuto >= inicio || minuto < fin;
  }

  bool vigilaAhora(DateTime ahora) => vigilaEn(ahora.hour * 60 + ahora.minute);

  Duration get duracion {
    if (siempre || inicio == fin) return const Duration(hours: 24);
    final minutos = (fin - inicio + minutosDia) % minutosDia;
    return Duration(minutes: minutos);
  }

  @override
  bool operator ==(Object other) =>
      other is Horario &&
      other.siempre == siempre &&
      other.inicio == inicio &&
      other.fin == fin;

  @override
  int get hashCode => Object.hash(siempre, inicio, fin);
}
