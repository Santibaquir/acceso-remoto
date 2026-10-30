// Fila de un nodo de vigilancia: nombre, ID y si está en línea o activo.
import 'package:flutter/material.dart';

import '../modelos/nodo.dart';
import '../nucleo/formato.dart';
import '../nucleo/tema.dart';
import 'comunes.dart';

class FilaNodo extends StatelessWidget {
  final Nodo nodo;
  final DateTime ahora;

  /// true = el nodo disparó la alerta que está activa.
  final bool enAlerta;
  final Widget? accion;
  final VoidCallback? onTap;

  const FilaNodo({
    super.key,
    required this.nodo,
    required this.ahora,
    this.enAlerta = false,
    this.accion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enLinea = nodo.enLinea(ahora);
    final Color color;
    final String estado;
    if (enAlerta) {
      color = Colores.rojo;
      estado = 'Movimiento detectado';
    } else if (!nodo.activo) {
      color = Colores.textoTenue;
      estado = 'Desactivado';
    } else if (enLinea) {
      color = Colores.verde;
      estado = 'En línea';
    } else if (nodo.ultimoContacto == null) {
      color = Colores.textoSuave;
      estado = 'Esperando primera señal';
    } else {
      color = Colores.ambar;
      estado = 'Sin señal · ${haceCuanto(nodo.ultimoContacto!, ahora)}';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconoCuadro(
              Icons.sensors_rounded,
              color: nodo.activo ? (enAlerta ? Colores.rojo : Colores.marca) : Colores.textoTenue,
              tamano: 42,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nodo.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: nodo.activo ? Colores.texto : Colores.textoSuave,
                          ),
                        ),
                      ),
                      if (nodo.sinNombre) ...[
                        const SizedBox(width: 8),
                        const Etiqueta('NUEVO'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      PuntoEstado(color, tamano: 7),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          '$estado · ${nodo.id}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colores.textoSuave),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ?accion,
          ],
        ),
      ),
    );
  }
}
