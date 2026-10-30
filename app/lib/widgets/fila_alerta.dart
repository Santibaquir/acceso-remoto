// Una fila del historial de alertas de movimiento.
import 'package:flutter/material.dart';

import '../modelos/registro_alerta.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'comunes.dart';

class FilaAlerta extends StatelessWidget {
  final RegistroAlerta registro;
  final DateTime ahora;

  const FilaAlerta({super.key, required this.registro, required this.ahora});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const IconoCuadro(Icons.directions_walk_rounded,
              color: Colores.rojo, tamano: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Movimiento en ${registro.nombre}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  registro.nodo.isEmpty
                      ? formatoHora(registro.fecha)
                      : '${formatoHora(registro.fecha)} · ${registro.nodo}',
                  style: const TextStyle(fontSize: 13, color: Colores.textoSuave),
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
