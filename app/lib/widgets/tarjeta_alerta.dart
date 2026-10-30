// Tarjeta "Alerta de movimiento". Solo aparece cuando estado/alerta es true.
import 'package:flutter/material.dart';

import '../nucleo/tema.dart';

/// Diseño sobrio: fondo oscuro con tinte rojo, sin parpadeo agresivo.
class TarjetaAlerta extends StatefulWidget {
  final String nodo;
  final String? hora;
  final bool sirenaSonando;
  final VoidCallback onVerCamara;
  final VoidCallback onReconocer;
  final VoidCallback onSilenciar;

  const TarjetaAlerta({
    super.key,
    required this.nodo,
    required this.hora,
    required this.sirenaSonando,
    required this.onVerCamara,
    required this.onReconocer,
    required this.onSilenciar,
  });

  @override
  State<TarjetaAlerta> createState() => _TarjetaAlertaState();
}

class _TarjetaAlertaState extends State<TarjetaAlerta>
    with SingleTickerProviderStateMixin {
  // Pulso lento del punto rojo (llama la atención sin exagerar)
  late final _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radios.tarjeta + 4),
        border: Border.all(color: Colores.rojo.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colores.rojo.withValues(alpha: 0.20),
            Colores.superficie,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulso,
                builder: (context, _) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colores.rojo,
                    boxShadow: [
                      BoxShadow(
                        color: Colores.rojo.withValues(alpha: 0.3 + _pulso.value * 0.5),
                        blurRadius: 6 + _pulso.value * 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ALERTA DE MOVIMIENTO',
                  style: TextStyle(
                    color: Colores.rojo,
                    fontSize: 12,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: widget.sirenaSonando ? 'Silenciar' : 'Silenciada',
                onPressed: widget.sirenaSonando ? widget.onSilenciar : null,
                icon: Icon(
                  widget.sirenaSonando
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: widget.sirenaSonando ? Colores.texto : Colores.textoTenue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'Movimiento en ${widget.nodo}',
              style: const TextStyle(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (widget.hora != null) ...[
            const SizedBox(height: 4),
            Text(
              'Detectado a las ${widget.hora}',
              style: const TextStyle(color: Colores.textoSuave, fontSize: 15),
            ),
          ],
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onVerCamara,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colores.rojo,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.videocam_rounded),
                    label: const Text('Ver cámara'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReconocer,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Reconocer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
