import 'package:flutter/material.dart';

import '../modelos.dart';
import '../tema.dart';

/// Una fila del historial de alertas.
class FilaAlerta extends StatelessWidget {
  final RegistroAlerta registro;
  final DateTime ahora;

  const FilaAlerta({super.key, required this.registro, required this.ahora});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colores.rojo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sensors_rounded,
                color: Colores.rojo, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Movimiento en ${registro.sensor}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatoHora(registro.fecha),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colores.textoSuave,
                  ),
                ),
              ],
            ),
          ),
          Text(
            haceCuanto(registro.fecha, ahora),
            style: const TextStyle(fontSize: 12, color: Colores.textoSuave),
          ),
        ],
      ),
    );
  }
}
