// Pruebas de los modelos. El horario debe dar lo mismo que dentroDeHorario() del firmware.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiguard/modelos/central.dart';
import 'package:tiguard/modelos/horario.dart';
import 'package:tiguard/modelos/nodo.dart';
import 'package:tiguard/modelos/registro_alerta.dart';

void main() {
  group('Horario', () {
    const noche = Horario(siempre: false, inicio: 22 * 60, fin: 6 * 60);
    const dia = Horario(siempre: false, inicio: 8 * 60, fin: 18 * 60);

    test('cruza la medianoche (22:00 → 06:00)', () {
      expect(noche.vigilaEn(23 * 60), isTrue);
      expect(noche.vigilaEn(0), isTrue);
      expect(noche.vigilaEn(5 * 60 + 59), isTrue);
      expect(noche.vigilaEn(6 * 60), isFalse); // el fin no se incluye
      expect(noche.vigilaEn(12 * 60), isFalse);
      expect(noche.vigilaEn(22 * 60), isTrue); // el inicio sí
      expect(noche.duracion, const Duration(hours: 8));
    });

    test('dentro del mismo día (08:00 → 18:00)', () {
      expect(dia.vigilaEn(7 * 60 + 59), isFalse);
      expect(dia.vigilaEn(8 * 60), isTrue);
      expect(dia.vigilaEn(17 * 60 + 59), isTrue);
      expect(dia.vigilaEn(18 * 60), isFalse);
      expect(dia.duracion, const Duration(hours: 10));
    });

    test('siempre o inicio == fin vigila las 24 horas', () {
      expect(noche.copiar(siempre: true).vigilaEn(12 * 60), isTrue);
      const igual = Horario(siempre: false, inicio: 300, fin: 300);
      expect(igual.vigilaEn(0), isTrue);
      expect(igual.duracion, const Duration(hours: 24));
    });

    test('desdeMapa limita valores fuera de rango y usa el de fábrica si no hay datos', () {
      expect(Horario.desdeMapa(null), Horario.porDefecto);
      final h = Horario.desdeMapa({'siempre': false, 'inicio': 5000, 'fin': -3});
      expect(h.inicio, 1439);
      expect(h.fin, 0);
    });
  });

  group('IDs', () {
    test('normalizar quita guiones y espacios', () {
      expect(InfoCentral.normalizar(' kg3d-u8ec 72 '), 'KG3DU8EC72');
    });

    test('formato del ID de nodo', () {
      expect(Nodo.formatoId.hasMatch('N01'), isTrue);
      expect(Nodo.formatoId.hasMatch('N'), isFalse);
      expect(Nodo.formatoId.hasMatch('n01'), isFalse);
      expect(Nodo.formatoId.hasMatch('NODO-1'), isFalse);
    });
  });

  test('registros viejos de Acceso Remoto (campo "sensor") siguen leyéndose', () {
    final r = RegistroAlerta.desdeMapa('x', {'sensor': 'BODEGA', 'fecha': 1000});
    expect(r.nombre, 'BODEGA');
    expect(r.nodo, '');
  });
}
