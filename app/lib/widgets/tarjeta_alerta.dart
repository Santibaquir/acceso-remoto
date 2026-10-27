import 'package:flutter/material.dart';

import '../tema.dart';

/// Banner rojo de alerta crítica. Solo aparece cuando `estado/alerta` es true.
class TarjetaAlerta extends StatefulWidget {
  final String sensor;
  final String? hora;
  final bool sirenaSonando;
  final VoidCallback onVerCamara;
  final VoidCallback onReconocer;
  final VoidCallback onSilenciar;

  const TarjetaAlerta({
    super.key,
    required this.sensor,
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
  // Parpadeo del resplandor rojo
  late final _parpadeo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _parpadeo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _parpadeo,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colores.rojo.withValues(alpha: 0.25 + _parpadeo.value * 0.35),
              blurRadius: 36,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDC2626), Color(0xFF7F1D1D)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 30),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'MOVIMIENTO DETECTADO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
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
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '¡ALERTA CRÍTICA: ${widget.sensor}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (widget.hora != null) ...[
              const SizedBox(height: 6),
              Text(
                'Detectado a las ${widget.hora}',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onVerCamara,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB91C1C),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
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
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Reconocer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
