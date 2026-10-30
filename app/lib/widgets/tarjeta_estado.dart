// Tarjeta grande con el estado ARMADO / DESARMADO y el botón para cambiarlo.
import 'package:flutter/material.dart';

import '../nucleo/tema.dart';

class TarjetaEstado extends StatefulWidget {
  final bool armado;

  /// false = armado, pero fuera del horario de vigilancia.
  final bool vigilandoAhora;

  /// Texto bajo el estado, ej. "Vigila desde las 10:00 p. m.".
  final String detalle;
  final bool cambiando;
  final VoidCallback onCambiar;

  const TarjetaEstado({
    super.key,
    required this.armado,
    required this.vigilandoAhora,
    required this.detalle,
    required this.cambiando,
    required this.onCambiar,
  });

  @override
  State<TarjetaEstado> createState() => _TarjetaEstadoState();
}

class _TarjetaEstadoState extends State<TarjetaEstado>
    with SingleTickerProviderStateMixin {
  // Pulso suave del escudo cuando el sistema está vigilando
  late final _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final armado = widget.armado;
    final activo = armado && widget.vigilandoAhora;
    final color = !armado
        ? Colores.textoSuave
        : activo
            ? Colores.verde
            : Colores.ambar;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Radios.tarjeta + 6),
        border: Border.all(
          color: armado ? color.withValues(alpha: 0.35) : Colores.borde,
        ),
        gradient: armado
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.10), Colores.superficie],
              )
            : null,
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulso,
            builder: (context, child) {
              final brillo = activo ? 0.15 + _pulso.value * 0.25 : 0.0;
              return Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
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
                !armado
                    ? Icons.shield_outlined
                    : activo
                        ? Icons.shield_rounded
                        : Icons.nightlight_round,
                key: ValueKey('$armado$activo'),
                size: 52,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
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
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: armado ? color : Colores.texto,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.detalle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colores.textoSuave),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.cambiando ? null : widget.onCambiar,
              style: FilledButton.styleFrom(
                backgroundColor: armado ? Colores.superficieAlta : Colores.verde,
                foregroundColor: armado ? Colores.texto : Colors.black,
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: armado
                      ? const BorderSide(color: Colores.borde)
                      : BorderSide.none,
                ),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
