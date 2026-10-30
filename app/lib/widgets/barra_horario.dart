// Barra de 24 horas que pinta el tramo vigilado y marca la hora actual.
import 'package:flutter/material.dart';

import '../modelos/horario.dart';
import '../nucleo/tema.dart';

class BarraHorario extends StatelessWidget {
  final Horario horario;
  final DateTime ahora;
  final double alto;

  const BarraHorario({
    super.key,
    required this.horario,
    required this.ahora,
    this.alto = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: alto + 8,
          width: double.infinity,
          child: CustomPaint(
            painter: _PintorHorario(horario, ahora.hour * 60 + ahora.minute, alto),
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Marca('12 a. m.'),
            _Marca('6 a. m.'),
            _Marca('12 p. m.'),
            _Marca('6 p. m.'),
            _Marca('12 a. m.'),
          ],
        ),
      ],
    );
  }
}

class _Marca extends StatelessWidget {
  final String texto;
  const _Marca(this.texto);

  @override
  Widget build(BuildContext context) => Text(
        texto,
        style: const TextStyle(fontSize: 11, color: Colores.textoTenue),
      );
}

class _PintorHorario extends CustomPainter {
  final Horario horario;
  final int minutoActual;
  final double alto;
  _PintorHorario(this.horario, this.minutoActual, this.alto);

  @override
  void paint(Canvas canvas, Size size) {
    final arriba = (size.height - alto) / 2;
    final radio = Radius.circular(alto / 2);
    final fondo = RRect.fromLTRBR(0, arriba, size.width, arriba + alto, radio);
    canvas.drawRRect(fondo, Paint()..color = Colores.superficieAlta);

    // Tramos vigilados (uno, o dos si cruza la medianoche)
    canvas.save();
    canvas.clipRRect(fondo);
    final pintura = Paint()..color = Colores.verde.withValues(alpha: 0.85);
    double x(int minuto) => size.width * minuto / Horario.minutosDia;
    void tramo(int desde, int hasta) => canvas.drawRect(
        Rect.fromLTRB(x(desde), arriba, x(hasta), arriba + alto), pintura);

    if (horario.siempre || horario.inicio == horario.fin) {
      tramo(0, Horario.minutosDia);
    } else if (horario.inicio < horario.fin) {
      tramo(horario.inicio, horario.fin);
    } else {
      tramo(horario.inicio, Horario.minutosDia);
      tramo(0, horario.fin);
    }
    canvas.restore();

    // Hora actual
    final xAhora = x(minutoActual);
    canvas.drawRRect(
      RRect.fromLTRBR(xAhora - 1.5, 0, xAhora + 1.5, size.height, const Radius.circular(2)),
      Paint()..color = Colores.texto,
    );
  }

  @override
  bool shouldRepaint(_PintorHorario viejo) =>
      viejo.horario != horario || viejo.minutoActual != minutoActual;
}
