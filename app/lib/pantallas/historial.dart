import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modelos.dart';
import '../servicios/central_servicio.dart';
import '../tema.dart';
import '../widgets/fila_alerta.dart';

/// Historial completo de alertas, agrupado por día.
class PantallaHistorial extends StatelessWidget {
  const PantallaHistorial({super.key});

  String _tituloDia(DateTime dia, DateTime hoy) {
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final soloDia = DateTime(dia.year, dia.month, dia.day);
    final diferencia = soloHoy.difference(soloDia).inDays;
    if (diferencia == 0) return 'Hoy';
    if (diferencia == 1) return 'Ayer';
    final texto = DateFormat("EEEE d 'de' MMMM", 'es').format(dia);
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Future<void> _confirmarBorrado(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar el historial?'),
        content: const Text('Se eliminarán todas las alertas registradas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colores.rojo),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmado == true) await CentralServicio.instancia.borrarHistorial();
  }

  @override
  Widget build(BuildContext context) {
    final central = CentralServicio.instancia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de alertas'),
        actions: [
          IconButton(
            tooltip: 'Borrar historial',
            onPressed: () => _confirmarBorrado(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<RegistroAlerta>>(
        stream: central.historial(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colores.verde),
            );
          }
          final lista = snapshot.data!;
          if (lista.isEmpty) {
            return const Center(
              child: Text(
                'Sin alertas registradas',
                style: TextStyle(color: Colores.textoSuave),
              ),
            );
          }

          final ahora = central.horaServidor;

          // Construir la lista con un título cada vez que cambia el día
          final elementos = <Widget>[];
          String? diaAnterior;
          for (final r in lista) {
            final dia = _tituloDia(r.fecha, ahora);
            if (dia != diaAnterior) {
              elementos.add(Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 6),
                child: Text(
                  dia,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colores.textoSuave,
                  ),
                ),
              ));
              diaAnterior = dia;
            }
            elementos.add(FilaAlerta(registro: r, ahora: ahora));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: elementos,
          );
        },
      ),
    );
  }
}
