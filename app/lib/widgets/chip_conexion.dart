import 'package:flutter/material.dart';

import '../modelos.dart';
import '../tema.dart';

/// Indicador "Central en línea" / "Central sin conexión · visto hace...".
class ChipConexion extends StatelessWidget {
  final bool enLinea;
  final DateTime? ultimoLatido;
  final DateTime ahora;

  const ChipConexion({
    super.key,
    required this.enLinea,
    required this.ultimoLatido,
    required this.ahora,
  });

  @override
  Widget build(BuildContext context) {
    final color = enLinea ? Colores.verde : Colores.ambar;
    final String detalle;
    if (enLinea) {
      detalle = 'Central en línea';
    } else if (ultimoLatido == null) {
      detalle = 'Central sin conexión · nunca vista';
    } else {
      detalle = 'Central sin conexión · vista ${haceCuanto(ultimoLatido!, ahora)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detalle,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            enLinea ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }
}
