import 'dart:async';

import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicios/camara.dart';
import '../servicios/central_servicio.dart';
import '../servicios/sirena.dart';
import '../tema.dart';
import '../widgets/chip_conexion.dart';
import '../widgets/fila_alerta.dart';
import '../widgets/tarjeta_alerta.dart';
import '../widgets/tarjeta_estado.dart';
import 'ajustes.dart';
import 'historial.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final _central = CentralServicio.instancia;
  final List<StreamSubscription> _suscripciones = [];
  Timer? _reloj;

  EstadoCentral? _estado;
  List<RegistroAlerta> _recientes = [];
  String? _error;
  bool _cambiando = false;

  @override
  void initState() {
    super.initState();

    _suscripciones.add(_central.estado.listen(
      (nuevo) {
        // La sirena suena cuando la alerta pasa de apagada a encendida
        if (nuevo.alerta && _estado?.alerta != true) Sirena.sonar();
        if (!nuevo.alerta) Sirena.callar();
        setState(() {
          _estado = nuevo;
          _error = null;
        });
      },
      onError: (e) => setState(() => _error = 'No se pudo leer Firebase: $e'),
    ));

    _suscripciones.add(_central.historial(limite: 5).listen(
      (lista) => setState(() => _recientes = lista),
    ));

    // Redibuja cada 10 s para refrescar "en línea" y "hace X min"
    _reloj = Timer.periodic(
      const Duration(seconds: 10),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    for (final s in _suscripciones) {
      s.cancel();
    }
    _reloj?.cancel();
    Sirena.callar();
    super.dispose();
  }

  // ---------- Acciones ----------

  Future<void> _cambiarArmado() async {
    final armar = !(_estado?.armado ?? false);

    if (!armar) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Desarmar el sistema?'),
          content: const Text(
            'El Sensor de movimiento PIR HC-SR501 seguirá funcionando, '
            'pero la central no activará la sirena.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desarmar'),
            ),
          ],
        ),
      );
      if (confirmado != true) return;
    }

    setState(() => _cambiando = true);
    try {
      await _central.cambiarArmado(armar);
    } catch (e) {
      _mensaje('No se pudo cambiar el estado: $e');
    } finally {
      if (mounted) setState(() => _cambiando = false);
    }
  }

  Future<void> _verCamara() async {
    Sirena.callar();
    setState(() {});
    final abierta = await Camara.abrir();
    if (!abierta && mounted) {
      _mensaje('Primero elige la app de tu cámara en Ajustes');
      _abrirAjustes();
    }
  }

  Future<void> _reconocer() async {
    await Sirena.callar();
    await _central.reconocerAlerta();
  }

  void _abrirAjustes() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaAjustes()),
      );

  void _abrirHistorial() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaHistorial()),
      );

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // ---------- Interfaz ----------

  @override
  Widget build(BuildContext context) {
    final estado = _estado;
    final ahora = _central.horaServidor;

    return Scaffold(
      body: SafeArea(
        child: estado == null
            ? _Cargando(error: _error)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _Encabezado(
                    onAjustes: _abrirAjustes,
                    onSimularAlerta: _central.simularAlerta,
                  ),
                  const SizedBox(height: 18),
                  ChipConexion(
                    enLinea: estado.enLinea(ahora),
                    ultimoLatido: estado.ultimoLatido,
                    ahora: ahora,
                  ),
                  const SizedBox(height: 18),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: estado.alerta
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: TarjetaAlerta(
                              sensor: _recientes.isNotEmpty
                                  ? _recientes.first.sensor
                                  : 'BODEGA',
                              hora: _recientes.isNotEmpty
                                  ? formatoHora(_recientes.first.fecha)
                                  : null,
                              sirenaSonando: Sirena.sonando,
                              onVerCamara: _verCamara,
                              onReconocer: _reconocer,
                              onSilenciar: () async {
                                await Sirena.callar();
                                setState(() {});
                              },
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  TarjetaEstado(
                    armado: estado.armado,
                    cambiando: _cambiando,
                    onCambiar: _cambiarArmado,
                  ),
                  const SizedBox(height: 14),
                  _BotonCamara(onPressed: _verCamara),
                  const SizedBox(height: 28),
                  _TituloSeccion(
                    titulo: 'Últimas alertas',
                    accion: 'Ver todo',
                    onAccion: _abrirHistorial,
                  ),
                  const SizedBox(height: 8),
                  _Panel(
                    child: _recientes.isEmpty
                        ? const _SinAlertas()
                        : Column(
                            children: [
                              for (final r in _recientes)
                                FilaAlerta(registro: r, ahora: ahora),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final VoidCallback onAjustes;
  final VoidCallback onSimularAlerta;
  const _Encabezado({required this.onAjustes, required this.onSimularAlerta});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // En modo demo, mantener presionado el escudo simula una alerta
        GestureDetector(
          onLongPress: modoDemo ? onSimularAlerta : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colores.superficieAlta,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colores.borde),
            ),
            child: const Icon(Icons.security_rounded, color: Colores.verde),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acceso Remoto',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                modoDemo
                    ? 'Modo demo · datos de ejemplo'
                    : 'Central de monitoreo · Bodega',
                style: TextStyle(fontSize: 13, color: Colores.textoSuave),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onAjustes,
          tooltip: 'Ajustes',
          icon: const Icon(Icons.tune_rounded, color: Colores.textoSuave),
        ),
      ],
    );
  }
}

class _BotonCamara extends StatelessWidget {
  final VoidCallback onPressed;
  const _BotonCamara({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colores.superficie,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colores.borde),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colores.azul.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.videocam_rounded, color: Colores.azul),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ver cámara',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Abre la app de la cámara Wi-Fi',
                      style:
                          TextStyle(fontSize: 13, color: Colores.textoSuave),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded,
                  color: Colores.textoSuave, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String titulo;
  final String accion;
  final VoidCallback onAccion;

  const _TituloSeccion({
    required this.titulo,
    required this.accion,
    required this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(onPressed: onAccion, child: Text(accion)),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colores.borde),
      ),
      child: child,
    );
  }
}

class _SinAlertas extends StatelessWidget {
  const _SinAlertas();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: Colores.textoSuave, size: 20),
          SizedBox(width: 8),
          Text(
            'Sin alertas registradas',
            style: TextStyle(color: Colores.textoSuave),
          ),
        ],
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  final String? error;
  const _Cargando({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error == null)
              const CircularProgressIndicator(color: Colores.verde)
            else
              const Icon(Icons.cloud_off_rounded,
                  color: Colores.ambar, size: 48),
            const SizedBox(height: 18),
            Text(
              error ?? 'Conectando con la central...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colores.textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}
