// Panel principal de una central: estado, alerta, horario, nodos, cámara e historial.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../datos/repositorios.dart';
import '../../estado/sesion.dart';
import '../../modelos/estado_central.dart';
import '../../modelos/horario.dart';
import '../../modelos/nodo.dart';
import '../../modelos/registro_alerta.dart';
import '../../nucleo/formato.dart';
import '../../nucleo/tema.dart';
import '../../servicios/camara.dart';
import '../../servicios/notificaciones.dart';
import '../../servicios/sirena.dart';
import '../../widgets/barra_horario.dart';
import '../../widgets/chip_conexion.dart';
import '../../widgets/comunes.dart';
import '../../widgets/fila_alerta.dart';
import '../../widgets/fila_nodo.dart';
import '../../widgets/logo_tiguard.dart';
import '../../widgets/tarjeta_alerta.dart';
import '../../widgets/tarjeta_estado.dart';
import '../ajustes/pantalla_ajustes.dart';
import '../historial/pantalla_historial.dart';
import '../horario/pantalla_horario.dart';
import '../nodos/pantalla_nodos.dart';
import '../vincular/pantalla_vincular.dart';

class PantallaPanel extends StatefulWidget {
  final String central;
  const PantallaPanel({super.key, required this.central});

  @override
  State<PantallaPanel> createState() => _PantallaPanelState();
}

class _PantallaPanelState extends State<PantallaPanel> {
  final _repo = Repositorios.central;
  final _sesion = Sesion.instancia;
  final List<StreamSubscription> _suscripciones = [];
  Timer? _reloj;

  EstadoCentral? _estado;
  Horario _horario = Horario.porDefecto;
  List<Nodo> _nodos = [];
  List<RegistroAlerta> _recientes = [];
  String? _error;
  bool _cambiando = false;

  String get _c => widget.central;

  @override
  void initState() {
    super.initState();

    _suscripciones.add(_repo.estado(_c).listen(
      (nuevo) {
        final anterior = _estado;
        // Avisa cuando la alerta pasa de apagada a encendida
        if (nuevo.alerta && anterior != null && !anterior.alerta) _avisarAlerta();
        if (nuevo.alerta && anterior == null) _avisarAlerta();
        if (!nuevo.alerta) Sirena.callar();
        // La alerta se apagó desde la central (pulsador físico)
        if (anterior?.alerta == true &&
            !nuevo.alerta &&
            nuevo.desactivacion?.desdePulsador == true) {
          if (mounted) mostrarMensaje(context, 'La alarma se apagó con el pulsador de la central');
        }
        setState(() {
          _estado = nuevo;
          _error = null;
        });
      },
      onError: (_) => setState(() => _error = 'No se pudo leer la central. Revisa la conexión.'),
    ));
    _suscripciones.add(_repo.horario(_c).listen((h) => setState(() => _horario = h)));
    _suscripciones.add(_repo.nodos(_c).listen((n) => setState(() => _nodos = n)));
    _suscripciones.add(
        _repo.historial(_c, limite: 5).listen((l) => setState(() => _recientes = l)));

    // Redibuja cada 10 s para refrescar "en línea" y "hace X min"
    _reloj = Timer.periodic(const Duration(seconds: 10), (_) => setState(() {}));
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

  /// Con la app abierta, el aviso depende del modo elegido en Ajustes.
  void _avisarAlerta() {
    switch (Notificaciones.modo) {
      case ModoAviso.sirena:
        Sirena.sonar();
      case ModoAviso.normal:
        HapticFeedback.vibrate();
      case ModoAviso.silencio:
        break;
    }
  }

  Future<void> _cambiarArmado() async {
    final armar = !(_estado?.armado ?? false);
    if (!armar) {
      final ok = await confirmar(
        context,
        titulo: '¿Desarmar el sistema?',
        mensaje: 'Los nodos seguirán detectando movimiento, pero la central '
            'no activará la sirena ni enviará alertas.',
        accion: 'Desarmar',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _cambiando = true);
    await intentar(context, () => _repo.cambiarArmado(_c, armar));
    if (mounted) setState(() => _cambiando = false);
  }

  Future<void> _verCamara() async {
    await Sirena.callar();
    setState(() {});
    final abierta = await Camara.abrir();
    if (!abierta && mounted) {
      mostrarMensaje(context, 'Primero elige la app de tu cámara en Ajustes');
      _abrir(const PantallaAjustes());
    }
  }

  Future<void> _reconocer() async {
    await Sirena.callar();
    if (!mounted) return;
    await intentar(context, () => _repo.reconocerAlerta(_c, _sesion.usuario!.uid));
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) setState(() {});
  }

  void _elegirCentral() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SelectorCentral(
        onVincular: () {
          Navigator.pop(context);
          _abrir(const PantallaVincular());
        },
      ),
    );
  }

  /// Nombre del nodo que disparó la alerta (o el del último registro).
  String _nombreNodoAlerta() {
    final id = _estado?.alertaNodo;
    final nodo = _nodos.where((n) => n.id == id).firstOrNull;
    if (nodo != null) return nodo.nombre;
    return _recientes.firstOrNull?.nombre ?? 'un nodo';
  }

  String _detalleEstado(DateTime ahora) {
    final estado = _estado!;
    if (!estado.armado) return 'El movimiento no activará la sirena';
    final activos = _nodos.where((n) => n.activo).length;
    if (!_horario.vigilaAhora(ahora)) {
      return 'Fuera de horario · vigila desde las ${formatoMinutos(_horario.inicio)}';
    }
    if (activos == 0) return 'Armado, pero no hay nodos activos';
    return activos == 1
        ? 'Vigilando con 1 nodo activo'
        : 'Vigilando con $activos nodos activos';
  }

  // ---------- Interfaz ----------

  @override
  Widget build(BuildContext context) {
    final estado = _estado;
    final ahora = _repo.horaServidor;
    final info = _sesion.infoActual;

    return Scaffold(
      body: SafeArea(
        child: estado == null
            ? _error == null
                ? const Cargando(texto: 'Conectando con la central...')
                : _ErrorConexion(texto: _error!)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _Encabezado(
                    nombreCentral: info?.nombre ?? 'Central',
                    variasCentrales: _sesion.centrales.length > 1,
                    onCentral: _elegirCentral,
                    onAjustes: () => _abrir(const PantallaAjustes()),
                    // Demo: mantener presionado el logo simula alerta / pulsador
                    onDemo: estado.alerta
                        ? () => _repo.simularPulsador(_c)
                        : () => _repo.simularAlerta(_c),
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
                              nodo: _nombreNodoAlerta(),
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
                  if (!estado.alerta &&
                      estado.desactivacion != null &&
                      ahora.difference(estado.desactivacion!.fecha) <
                          const Duration(minutes: 30))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _UltimaDesactivacion(
                        desactivacion: estado.desactivacion!,
                        ahora: ahora,
                      ),
                    ),
                  TarjetaEstado(
                    armado: estado.armado,
                    vigilandoAhora: _horario.vigilaAhora(ahora),
                    detalle: _detalleEstado(ahora),
                    cambiando: _cambiando,
                    onCambiar: _cambiarArmado,
                  ),
                  const SizedBox(height: 14),
                  _TarjetaHorario(
                    horario: _horario,
                    ahora: ahora,
                    onTap: () => _abrir(PantallaHorario(central: _c)),
                  ),
                  const SizedBox(height: 14),
                  _BotonCamara(onPressed: _verCamara),
                  TituloSeccion(
                    'Nodos de vigilancia',
                    accion: 'Gestionar',
                    onAccion: () => _abrir(PantallaNodos(central: _c)),
                  ),
                  Panel(
                    child: _nodos.isEmpty
                        ? const _Vacio(
                            icono: Icons.sensors_off_rounded,
                            texto: 'Aún no hay nodos. Enciende uno y aparecerá aquí.',
                          )
                        : Column(
                            children: [
                              for (final (i, n) in _nodos.take(4).indexed) ...[
                                if (i > 0) const Divider(height: 1, indent: 72),
                                FilaNodo(
                                  nodo: n,
                                  ahora: ahora,
                                  enAlerta: estado.alerta && estado.alertaNodo == n.id,
                                  onTap: () => _abrir(PantallaNodos(central: _c)),
                                ),
                              ],
                              if (_nodos.length > 4)
                                TextButton(
                                  onPressed: () => _abrir(PantallaNodos(central: _c)),
                                  child: Text('Ver los ${_nodos.length} nodos'),
                                ),
                            ],
                          ),
                  ),
                  TituloSeccion(
                    'Últimas alertas',
                    accion: 'Ver todo',
                    onAccion: () => _abrir(PantallaHistorial(central: _c)),
                  ),
                  Panel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _recientes.isEmpty
                        ? const _Vacio(
                            icono: Icons.check_circle_outline_rounded,
                            texto: 'Sin alertas registradas',
                          )
                        : Column(
                            children: [
                              for (final r in _recientes) FilaAlerta(registro: r, ahora: ahora),
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
  final String nombreCentral;
  final bool variasCentrales;
  final VoidCallback onCentral;
  final VoidCallback onAjustes;
  final VoidCallback onDemo;

  const _Encabezado({
    required this.nombreCentral,
    required this.variasCentrales,
    required this.onCentral,
    required this.onAjustes,
    required this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onLongPress: modoDemo ? onDemo : null,
          child: const IsotipoTiGuard(tamano: 44),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onCentral,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LogotipoTiGuard(tamano: 22),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        modoDemo ? '$nombreCentral · demo' : nombreCentral,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colores.textoSuave),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded,
                        size: 18, color: Colores.textoSuave),
                  ],
                ),
              ],
            ),
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

/// Lista de centrales del usuario para cambiar entre ellas.
class _SelectorCentral extends StatelessWidget {
  final VoidCallback onVincular;
  const _SelectorCentral({required this.onVincular});

  @override
  Widget build(BuildContext context) {
    final sesion = Sesion.instancia;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Tus centrales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          for (final c in sesion.centrales)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const IconoCuadro(Icons.router_rounded),
              title: Text(sesion.infoDe(c)?.nombre ?? c),
              subtitle: Text(c, style: const TextStyle(color: Colores.textoSuave)),
              trailing: c == sesion.centralActual
                  ? const Icon(Icons.check_circle_rounded, color: Colores.verde)
                  : null,
              onTap: () {
                sesion.elegirCentral(c);
                Navigator.pop(context);
              },
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const IconoCuadro(Icons.add_rounded, color: Colores.textoSuave),
            title: const Text('Vincular otra central'),
            onTap: onVincular,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Resumen del horario de vigilancia con su barra de 24 horas.
class _TarjetaHorario extends StatelessWidget {
  final Horario horario;
  final DateTime ahora;
  final VoidCallback onTap;

  const _TarjetaHorario({required this.horario, required this.ahora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vigila = horario.vigilaAhora(ahora);
    return Material(
      color: Colores.superficie,
      borderRadius: BorderRadius.circular(Radios.tarjeta),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radios.tarjeta),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radios.tarjeta),
            border: Border.all(color: Colores.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconoCuadro(Icons.schedule_rounded),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Horario de vigilancia',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(
                          horario.siempre
                              ? 'Las 24 horas'
                              : '${formatoMinutos(horario.inicio)} – ${formatoMinutos(horario.fin)}',
                          style: const TextStyle(fontSize: 13, color: Colores.textoSuave),
                        ),
                      ],
                    ),
                  ),
                  Etiqueta(
                    vigila ? 'VIGILANDO' : 'EN PAUSA',
                    color: vigila ? Colores.verde : Colores.ambar,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BarraHorario(horario: horario, ahora: ahora, alto: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Franja que confirma quién apagó la última alerta (30 min).
class _UltimaDesactivacion extends StatelessWidget {
  final Desactivacion desactivacion;
  final DateTime ahora;
  const _UltimaDesactivacion({required this.desactivacion, required this.ahora});

  @override
  Widget build(BuildContext context) {
    final pulsador = desactivacion.desdePulsador;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            pulsador ? Icons.radio_button_checked_rounded : Icons.phone_android_rounded,
            color: Colores.verde,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pulsador
                      ? 'Alarma desactivada con el pulsador'
                      : 'Alerta reconocida desde la app',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${formatoHora(desactivacion.fecha)} · ${haceCuanto(desactivacion.fecha, ahora)}',
                  style: const TextStyle(fontSize: 13, color: Colores.textoSuave),
                ),
              ],
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(Radios.tarjeta),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Radios.tarjeta),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radios.tarjeta),
            border: Border.all(color: Colores.borde),
          ),
          child: const Row(
            children: [
              IconoCuadro(Icons.videocam_rounded, tamano: 44),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ver cámara',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Abre la app de la cámara Wi-Fi',
                        style: TextStyle(fontSize: 13, color: Colores.textoSuave)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: Colores.textoSuave, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Vacio({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: Colores.textoSuave, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colores.textoSuave)),
          ),
        ],
      ),
    );
  }
}

class _ErrorConexion extends StatelessWidget {
  final String texto;
  const _ErrorConexion({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colores.ambar, size: 48),
            const SizedBox(height: 18),
            Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colores.textoSuave)),
          ],
        ),
      ),
    );
  }
}
