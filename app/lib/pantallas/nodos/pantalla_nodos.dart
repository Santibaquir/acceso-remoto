// Gestión de los nodos de vigilancia: agregar, renombrar, activar y eliminar.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../datos/repositorios.dart';
import '../../estado/sesion.dart';
import '../../modelos/estado_central.dart';
import '../../modelos/nodo.dart';
import '../../nucleo/formato.dart';
import '../../nucleo/tema.dart';
import '../../widgets/comunes.dart';
import '../../widgets/fila_nodo.dart';
import '../historial/pantalla_historial.dart';

class PantallaNodos extends StatefulWidget {
  final String central;
  const PantallaNodos({super.key, required this.central});

  @override
  State<PantallaNodos> createState() => _PantallaNodosState();
}

class _PantallaNodosState extends State<PantallaNodos> {
  final _repo = Repositorios.central;
  Timer? _reloj;

  // Se crean una sola vez: el reloj redibuja, pero no vuelve a suscribirse
  late final _estado = _repo.estado(_c);
  late final _nodos = _repo.nodos(_c);

  String get _c => widget.central;
  bool get _propietario => Sesion.instancia.esPropietario;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _agregar() async {
    final datos = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FormularioNodo(),
    );
    if (datos == null || !mounted) return;
    await intentar(
      context,
      () => _repo.agregarNodo(_c, datos.$1, datos.$2),
      exito: 'Nodo "${datos.$2}" agregado',
    );
  }

  void _opciones(Nodo nodo) {
    showModalBottomSheet(
      context: context,
      builder: (contexto) => _OpcionesNodo(
        nodo: nodo,
        propietario: _propietario,
        onRenombrar: () async {
          Navigator.pop(contexto);
          final nombre = await pedirTexto(
            context,
            titulo: 'Nombre del nodo',
            etiqueta: 'Ej. Bodega, Garaje, Oficina',
            inicial: nodo.sinNombre ? '' : nodo.nombre,
            largoMaximo: Nodo.largoMaximoNombre,
          );
          if (nombre == null || !mounted) return;
          await intentar(context, () => _repo.renombrarNodo(_c, nodo.id, nombre));
        },
        onHistorial: () {
          Navigator.pop(contexto);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaHistorial(central: _c, nodoInicial: nodo.id),
            ),
          );
        },
        onEliminar: () async {
          Navigator.pop(contexto);
          final ok = await confirmar(
            context,
            titulo: '¿Eliminar "${nodo.nombre}"?',
            mensaje: 'Se quitará de la app. Si el nodo sigue encendido, la '
                'central lo volverá a registrar como nuevo. Para retirarlo del '
                'todo, desconéctalo.',
            accion: 'Eliminar',
            peligro: true,
          );
          if (!ok || !mounted) return;
          await intentar(context, () => _repo.eliminarNodo(_c, nodo.id),
              exito: 'Nodo eliminado');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ahora = _repo.horaServidor;
    return Scaffold(
      appBar: AppBar(title: const Text('Nodos de vigilancia')),
      floatingActionButton: _propietario
          ? FloatingActionButton.extended(
              onPressed: _agregar,
              backgroundColor: Colores.marca,
              foregroundColor: Colores.sobreMarca,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar nodo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: StreamBuilder<EstadoCentral>(
        stream: _estado,
        builder: (context, estado) => StreamBuilder<List<Nodo>>(
          stream: _nodos,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Cargando();
            final nodos = snapshot.data!;
            final alerta = estado.data;
            final enLinea = nodos.where((n) => n.activo && n.enLinea(ahora)).length;
            final activos = nodos.where((n) => n.activo).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              children: [
                Text(
                  _propietario
                      ? 'Cada nodo es un Sensor de movimiento PIR HC-SR501 con su '
                          'Placa Arduino Nano. Ponles el nombre del lugar que vigilan.'
                      : 'Solo el propietario de la central puede cambiar los nodos.',
                  style: const TextStyle(color: Colores.textoSuave, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Resumen(valor: '${nodos.length}', texto: 'Nodos'),
                    const SizedBox(width: 10),
                    _Resumen(valor: '$activos', texto: 'Activos', color: Colores.marca),
                    const SizedBox(width: 10),
                    _Resumen(valor: '$enLinea', texto: 'En línea', color: Colores.verde),
                  ],
                ),
                const SizedBox(height: 16),
                if (nodos.isEmpty)
                  const Panel(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(Icons.sensors_off_rounded, size: 40, color: Colores.textoSuave),
                        SizedBox(height: 12),
                        Text(
                          'Aún no hay nodos.\nEnciende un nodo cerca de la central y '
                          'aparecerá aquí solo, o agrégalo con su ID.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colores.textoSuave, height: 1.4),
                        ),
                      ],
                    ),
                  )
                else
                  Panel(
                    child: Column(
                      children: [
                        for (final (i, n) in nodos.indexed) ...[
                          if (i > 0) const Divider(height: 1, indent: 72),
                          FilaNodo(
                            nodo: n,
                            ahora: ahora,
                            enAlerta: alerta?.alerta == true && alerta?.alertaNodo == n.id,
                            onTap: () => _opciones(n),
                            accion: Switch(
                              value: n.activo,
                              onChanged: _propietario
                                  ? (v) => intentar(context, () => _repo.activarNodo(_c, n.id, v))
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final String valor;
  final String texto;
  final Color color;
  const _Resumen({required this.valor, required this.texto, this.color = Colores.texto});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Panel(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valor,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            Text(texto, style: const TextStyle(fontSize: 13, color: Colores.textoSuave)),
          ],
        ),
      ),
    );
  }
}

/// Hoja para agregar un nodo: ID grabado en el firmware + nombre.
class _FormularioNodo extends StatefulWidget {
  const _FormularioNodo();

  @override
  State<_FormularioNodo> createState() => _FormularioNodoState();
}

class _FormularioNodoState extends State<_FormularioNodo> {
  final _formulario = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _nombre = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formulario.currentState!.validate()) return;
    Navigator.pop(context, (_id.text.trim().toUpperCase(), _nombre.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Agregar nodo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'El ID está grabado en el firmware del nodo (NODO_ID) y en su etiqueta.',
              style: TextStyle(color: Colores.textoSuave),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _id,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'ID del nodo',
                hintText: 'N02',
                prefixIcon: Icon(Icons.tag_rounded),
                counterText: '',
              ),
              validator: (v) => Nodo.formatoId.hasMatch(v?.trim().toUpperCase() ?? '')
                  ? null
                  : 'De 2 a 8 letras o números, sin espacios',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: Nodo.largoMaximoNombre,
              onFieldSubmitted: (_) => _guardar(),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Bodega, Garaje, Oficina...',
                prefixIcon: Icon(Icons.label_outline_rounded),
                counterText: '',
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _guardar, child: const Text('Agregar')),
          ],
        ),
      ),
    );
  }
}

/// Acciones de un nodo (hoja inferior).
class _OpcionesNodo extends StatelessWidget {
  final Nodo nodo;
  final bool propietario;
  final VoidCallback onRenombrar;
  final VoidCallback onHistorial;
  final VoidCallback onEliminar;

  const _OpcionesNodo({
    required this.nodo,
    required this.propietario,
    required this.onRenombrar,
    required this.onHistorial,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final ahora = Repositorios.central.horaServidor;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nodo.nombre,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'ID ${nodo.id} · Sensor de movimiento PIR HC-SR501'
                  '${nodo.ultimoContacto != null ? ' · última señal ${haceCuanto(nodo.ultimoContacto!, ahora)}' : ''}',
                  style: const TextStyle(color: Colores.textoSuave),
                ),
              ],
            ),
          ),
          if (propietario)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const IconoCuadro(Icons.edit_rounded),
              title: const Text('Cambiar nombre'),
              onTap: onRenombrar,
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const IconoCuadro(Icons.history_rounded),
            title: const Text('Ver sus alertas'),
            onTap: onHistorial,
          ),
          if (propietario)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const IconoCuadro(Icons.delete_outline_rounded, color: Colores.rojo),
              title: const Text('Eliminar nodo', style: TextStyle(color: Colores.rojo)),
              onTap: onEliminar,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
