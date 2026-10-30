// Historial de alertas de movimiento, agrupado por día y filtrable por nodo.
import 'package:flutter/material.dart';

import '../../datos/repositorios.dart';
import '../../estado/sesion.dart';
import '../../modelos/nodo.dart';
import '../../modelos/registro_alerta.dart';
import '../../nucleo/formato.dart';
import '../../nucleo/tema.dart';
import '../../widgets/comunes.dart';
import '../../widgets/fila_alerta.dart';

class PantallaHistorial extends StatefulWidget {
  final String central;

  /// Si viene, abre el historial filtrado por ese nodo.
  final String? nodoInicial;
  const PantallaHistorial({super.key, required this.central, this.nodoInicial});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  final _repo = Repositorios.central;
  late String? _nodo = widget.nodoInicial;
  late final _nodos = _repo.nodos(widget.central);
  late Stream<List<RegistroAlerta>> _historial = _consultar();

  Stream<List<RegistroAlerta>> _consultar() =>
      _repo.historial(widget.central, nodo: _nodo);

  void _filtrar(String? nodo) => setState(() {
        _nodo = nodo;
        _historial = _consultar();
      });

  Future<void> _borrar() async {
    final ok = await confirmar(
      context,
      titulo: '¿Borrar el historial?',
      mensaje: 'Se eliminarán todas las alertas registradas de esta central, '
          'para todos sus miembros.',
      accion: 'Borrar',
      peligro: true,
    );
    if (!ok || !mounted) return;
    await intentar(context, () => _repo.borrarHistorial(widget.central),
        exito: 'Historial borrado');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de alertas'),
        actions: [
          if (Sesion.instancia.esPropietario)
            IconButton(
              tooltip: 'Borrar historial',
              onPressed: _borrar,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtro por nodo
          StreamBuilder<List<Nodo>>(
            stream: _nodos,
            builder: (context, snapshot) {
              final nodos = snapshot.data ?? const [];
              if (nodos.length < 2 && _nodo == null) return const SizedBox.shrink();
              return SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _Filtro(
                      texto: 'Todos',
                      elegido: _nodo == null,
                      onTap: () => _filtrar(null),
                    ),
                    for (final n in nodos)
                      _Filtro(
                        texto: n.nombre,
                        elegido: _nodo == n.id,
                        onTap: () => _filtrar(n.id),
                      ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<RegistroAlerta>>(
              stream: _historial,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudo leer el historial',
                        style: TextStyle(color: Colores.textoSuave)),
                  );
                }
                if (!snapshot.hasData) return const Cargando();
                final lista = snapshot.data!;
                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Sin alertas registradas',
                        style: TextStyle(color: Colores.textoSuave)),
                  );
                }

                final ahora = _repo.horaServidor;
                // Un título cada vez que cambia el día
                final elementos = <Widget>[];
                String? diaAnterior;
                for (final r in lista) {
                  final dia = tituloDia(r.fecha, ahora);
                  if (dia != diaAnterior) {
                    elementos.add(Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 4),
                      child: Text(
                        dia.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
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
          ),
        ],
      ),
    );
  }
}

class _Filtro extends StatelessWidget {
  final String texto;
  final bool elegido;
  final VoidCallback onTap;
  const _Filtro({required this.texto, required this.elegido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: elegido,
        onSelected: (_) => onTap(),
        selectedColor: Colores.marca.withValues(alpha: 0.2),
        backgroundColor: Colores.superficie,
        side: const BorderSide(color: Colores.borde),
        showCheckmark: false,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
