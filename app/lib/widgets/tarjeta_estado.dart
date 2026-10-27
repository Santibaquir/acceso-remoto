import 'package:flutter/material.dart';

import '../tema.dart';

/// Tarjeta grande con el estado ARMADO / DESARMADO y el botón para cambiarlo.
class TarjetaEstado extends StatefulWidget {
  final bool armado;
  final bool cambiando;
  final VoidCallback onCambiar;

  const TarjetaEstado({
    super.key,
    required this.armado,
    required this.cambiando,
    required this.onCambiar,
  });

  @override
  State<TarjetaEstado> createState() => _TarjetaEstadoState();
}

class _TarjetaEstadoState extends State<TarjetaEstado>
    with SingleTickerProviderStateMixin {
  // Pulso suave del escudo cuando el sistema está armado
  late final _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final armado = widget.armado;
    final color = armado ? Colores.verde : Colores.textoSuave;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: armado ? Colores.verde.withValues(alpha: 0.35) : Colores.borde,
        ),
        gradient: armado
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colores.verde.withValues(alpha: 0.10),
                  Colores.superficie,
                ],
              )
            : null,
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulso,
            builder: (context, child) {
              final brillo = armado ? 0.15 + _pulso.value * 0.25 : 0.0;
              return Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: brillo),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                armado ? Icons.shield_rounded : Icons.shield_outlined,
                key: ValueKey(armado),
                size: 56,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ESTADO DEL SISTEMA',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: Colores.textoSuave,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              armado ? 'ARMADO' : 'DESARMADO',
              key: ValueKey(armado),
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: armado ? Colores.verde : Colores.texto,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            armado
                ? 'Los sensores están vigilando la bodega'
                : 'El movimiento no activará la sirena',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colores.textoSuave),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: widget.cambiando ? null : widget.onCambiar,
              style: FilledButton.styleFrom(
                backgroundColor:
                    armado ? Colores.superficieAlta : Colores.verde,
                foregroundColor: armado ? Colores.texto : Colors.black,
                disabledBackgroundColor: Colores.superficieAlta,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: armado
                      ? const BorderSide(color: Colores.borde)
                      : BorderSide.none,
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: widget.cambiando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(armado ? Icons.lock_open_rounded : Icons.lock_rounded),
              label: Text(armado ? 'Desarmar sistema' : 'Armar sistema'),
            ),
          ),
        ],
      ),
    );
  }
}
