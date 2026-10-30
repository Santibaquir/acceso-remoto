// Ajustes: cuenta, central y miembros, alertas en este celular, cámara y versión.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../datos/repositorios.dart';
import '../../estado/sesion.dart';
import '../../modelos/central.dart';
import '../../modelos/estado_central.dart';
import '../../nucleo/formato.dart';
import '../../nucleo/marca.dart';
import '../../nucleo/tema.dart';
import '../../servicios/camara.dart';
import '../../servicios/notificaciones.dart';
import '../../widgets/comunes.dart';
import '../../widgets/logo_tiguard.dart';
import '../vincular/pantalla_vincular.dart';
import 'pantalla_camara.dart';

class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({super.key});

  @override
  State<PantallaAjustes> createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  final _sesion = Sesion.instancia;
  final _repo = Repositorios.central;
  final _auth = Repositorios.auth;
  late final String _c = _sesion.centralActual!;
  late final _estado = _repo.estado(_c);

  ModoAviso _modo = Notificaciones.modo;
  bool _avisoPulsador = Notificaciones.avisoPulsador;
  String? _nombreCamara;
  String? _version;

  @override
  void initState() {
    super.initState();
    _leerCamara();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  Future<void> _leerCamara() async {
    final paquete = await Camara.paqueteGuardado();
    final conocida = Camara.apps.entries
        .where((app) => app.value == paquete)
        .map((app) => app.key)
        .firstOrNull;
    if (mounted) setState(() => _nombreCamara = conocida ?? paquete);
  }

  // ---------- Cuenta ----------

  Future<void> _verificar() async {
    final usuario = await _auth.recargar();
    if (!mounted) return;
    if (usuario?.correoVerificado == true) {
      mostrarMensaje(context, 'Correo verificado');
      return;
    }
    await intentar(context, _auth.reenviarVerificacion,
        exito: 'Te enviamos de nuevo el correo de verificación');
  }

  Future<void> _cerrarSesion() async {
    final ok = await confirmar(
      context,
      titulo: '¿Cerrar sesión?',
      mensaje: 'Este celular dejará de recibir alertas de movimiento hasta que '
          'vuelvas a iniciar sesión.',
      accion: 'Cerrar sesión',
      peligro: true,
    );
    if (!ok || !mounted) return;
    Navigator.popUntil(context, (r) => r.isFirst);
    await _sesion.cerrarSesion();
  }

  // ---------- Central ----------

  Future<void> _renombrarCentral(InfoCentral info) async {
    final nombre = await pedirTexto(
      context,
      titulo: 'Nombre de la central',
      etiqueta: 'Ej. Casa, Bodega principal, Local 2',
      inicial: info.nombre,
      largoMaximo: 40,
    );
    if (nombre == null || !mounted) return;
    await intentar(context, () => _repo.renombrarCentral(_c, nombre));
  }

  void _copiarId() {
    Clipboard.setData(ClipboardData(text: _c));
    mostrarMensaje(context, 'ID copiado');
  }

  void _verMiembros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ListaMiembros(central: _c),
    );
  }

  Future<void> _salirDeCentral(InfoCentral info) async {
    final ok = await confirmar(
      context,
      titulo: '¿Salir de "${info.nombre}"?',
      mensaje: 'Dejarás de ver esta central y de recibir sus alertas. Para '
          'volver necesitarás su código de vinculación.',
      accion: 'Salir',
      peligro: true,
    );
    if (!ok || !mounted) return;
    final salio = await intentar(context, () => _sesion.salirDeCentral(_c));
    if (salio && mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  // ---------- Alertas ----------

  Future<void> _guardarAviso(Future<void> Function() accion) async {
    try {
      await accion();
    } catch (_) {
      if (mounted) {
        mostrarMensaje(context, modoDemo
            ? 'Modo demo: se guardó, pero no hay Firebase'
            : 'No se pudo guardar. Revisa la conexión a internet.');
      }
    }
  }

  // ---------- Interfaz ----------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sesion,
      builder: (context, _) {
        final usuario = _sesion.usuario;
        final info = _sesion.infoActual;
        final propietario = _sesion.esPropietario;
        if (usuario == null) return const Scaffold(body: Cargando());

        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              // ---------- Cuenta ----------
              const TituloSeccion('Cuenta', padding: EdgeInsets.only(top: 8, bottom: 10)),
              Panel(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: Colores.marca.withValues(alpha: 0.18),
                        foregroundColor: Colores.marca,
                        child: Text(
                          usuario.nombreVisible.characters.first.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      title: Text(usuario.nombreVisible,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(usuario.correo,
                          style: const TextStyle(color: Colores.textoSuave)),
                    ),
                    if (!usuario.correoVerificado) ...[
                      const Divider(height: 1),
                      ListTile(
                        onTap: _verificar,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: const IconoCuadro(Icons.mark_email_unread_outlined,
                            color: Colores.ambar),
                        title: const Text('Verifica tu correo'),
                        subtitle: const Text(
                          'Toca para comprobar o reenviar el enlace',
                          style: TextStyle(color: Colores.textoSuave, fontSize: 13),
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      onTap: _cerrarSesion,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const IconoCuadro(Icons.logout_rounded, color: Colores.rojo),
                      title: const Text('Cerrar sesión',
                          style: TextStyle(color: Colores.rojo)),
                    ),
                  ],
                ),
              ),

              // ---------- Central ----------
              TituloSeccion(
                'Central',
                detalle: propietario
                    ? 'Eres el propietario de esta central'
                    : 'Eres miembro de esta central',
              ),
              Panel(
                child: Column(
                  children: [
                    ListTile(
                      onTap: propietario && info != null ? () => _renombrarCentral(info) : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const IconoCuadro(Icons.router_rounded),
                      title: const Text('Nombre'),
                      subtitle: Text(info?.nombre ?? '...',
                          style: const TextStyle(color: Colores.textoSuave)),
                      trailing: propietario
                          ? const Icon(Icons.edit_rounded, size: 20, color: Colores.textoSuave)
                          : null,
                    ),
                    const Divider(height: 1, indent: 72),
                    ListTile(
                      onTap: _copiarId,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const IconoCuadro(Icons.tag_rounded),
                      title: const Text('ID de la central'),
                      subtitle: Text(_c,
                          style: const TextStyle(
                              color: Colores.textoSuave, fontFamily: 'monospace')),
                      trailing: const Icon(Icons.copy_rounded,
                          size: 20, color: Colores.textoSuave),
                    ),
                    const Divider(height: 1, indent: 72),
                    StreamBuilder<EstadoCentral>(
                      stream: _estado,
                      builder: (context, snapshot) {
                        final estado = snapshot.data;
                        final ahora = _repo.horaServidor;
                        final enLinea = estado?.enLinea(ahora) ?? false;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: IconoCuadro(
                            enLinea ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                            color: enLinea ? Colores.verde : Colores.ambar,
                          ),
                          title: Text(estado == null
                              ? 'Consultando...'
                              : enLinea
                                  ? 'En línea'
                                  : 'Sin conexión'),
                          subtitle: Text(
                            estado?.ultimoLatido == null
                                ? 'Nunca se ha conectado'
                                : 'Último latido ${haceCuanto(estado!.ultimoLatido!, ahora)}',
                            style: const TextStyle(color: Colores.textoSuave),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 72),
                    ListTile(
                      onTap: _verMiembros,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const IconoCuadro(Icons.group_outlined),
                      title: const Text('Miembros'),
                      subtitle: const Text('Quién más ve esta central',
                          style: TextStyle(color: Colores.textoSuave)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Colores.textoSuave),
                    ),
                    const Divider(height: 1, indent: 72),
                    ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaVincular()),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const IconoCuadro(Icons.add_link_rounded),
                      title: const Text('Vincular otra central'),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Colores.textoSuave),
                    ),
                    if (!propietario && info != null) ...[
                      const Divider(height: 1, indent: 72),
                      ListTile(
                        onTap: () => _salirDeCentral(info),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: const IconoCuadro(Icons.link_off_rounded, color: Colores.rojo),
                        title: const Text('Salir de esta central',
                            style: TextStyle(color: Colores.rojo)),
                      ),
                    ],
                  ],
                ),
              ),

              // ---------- Alertas ----------
              const TituloSeccion(
                'Alertas en este celular',
                detalle: 'Cómo avisa cuando un nodo detecta movimiento, '
                    'también con la app cerrada.',
              ),
              Panel(
                child: Column(
                  children: [
                    for (final modo in ModoAviso.values)
                      _OpcionModo(
                        modo: modo,
                        elegido: modo == _modo,
                        onTap: () {
                          setState(() => _modo = modo);
                          _guardarAviso(() => Notificaciones.cambiarModo(modo));
                        },
                      ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _avisoPulsador,
                      onChanged: (v) {
                        setState(() => _avisoPulsador = v);
                        _guardarAviso(() => Notificaciones.cambiarAvisoPulsador(v));
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      secondary: const IconoCuadro(Icons.radio_button_checked_rounded),
                      title: const Text('Alarma apagada con el pulsador'),
                      subtitle: const Text(
                        'Avisa cuando alguien la desactiva en la central',
                        style: TextStyle(color: Colores.textoSuave, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => intentar(context, Notificaciones.probar),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Enviar notificación de prueba'),
              ),

              // ---------- Cámara ----------
              const TituloSeccion('Cámara'),
              Panel(
                child: ListTile(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PantallaCamara()),
                    );
                    _leerCamara();
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const IconoCuadro(Icons.videocam_rounded),
                  title: const Text('App de la cámara'),
                  subtitle: Text(_nombreCamara ?? 'Sin elegir',
                      style: const TextStyle(color: Colores.textoSuave, fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colores.textoSuave),
                ),
              ),

              // ---------- Acerca de ----------
              const SizedBox(height: 36),
              const Center(child: IsotipoTiGuard(tamano: 40)),
              const SizedBox(height: 10),
              const Center(child: LogotipoTiGuard(tamano: 20)),
              const SizedBox(height: 4),
              Text(
                '${Marca.firma}\nVersión ${_version ?? '...'}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colores.textoTenue, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OpcionModo extends StatelessWidget {
  final ModoAviso modo;
  final bool elegido;
  final VoidCallback onTap;

  const _OpcionModo({required this.modo, required this.elegido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icono, titulo, detalle) = switch (modo) {
      ModoAviso.sirena => (
          Icons.campaign_rounded,
          'Sirena',
          'Sonido fuerte, ideal de noche',
        ),
      ModoAviso.normal => (
          Icons.notifications_rounded,
          'Sonido normal',
          'Sonido de notificación del celular y vibración',
        ),
      ModoAviso.silencio => (
          Icons.notifications_off_outlined,
          'Solo notificación',
          'Sin sonido ni vibración',
        ),
    };
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: IconoCuadro(icono, color: elegido ? Colores.verde : Colores.marca),
      title: Text(titulo, style: TextStyle(fontWeight: elegido ? FontWeight.w700 : null)),
      subtitle: Text(detalle,
          style: const TextStyle(color: Colores.textoSuave, fontSize: 13)),
      trailing: elegido
          ? const Icon(Icons.check_circle_rounded, color: Colores.verde)
          : const Icon(Icons.circle_outlined, color: Colores.borde),
    );
  }
}

/// Miembros de la central. El propietario puede quitar a los demás.
class _ListaMiembros extends StatelessWidget {
  final String central;
  const _ListaMiembros({required this.central});

  @override
  Widget build(BuildContext context) {
    final sesion = Sesion.instancia;
    final repo = Repositorios.central;
    final propietarioUid = sesion.infoActual?.propietario;

    return SafeArea(
      child: StreamBuilder<List<Miembro>>(
        stream: repo.miembros(central),
        builder: (context, snapshot) {
          final miembros = snapshot.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text('Miembros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Para invitar a alguien, dale el ID y el código que muestra la central.',
                  style: TextStyle(color: Colores.textoSuave),
                ),
              ),
              if (miembros == null)
                const Padding(padding: EdgeInsets.all(24), child: Cargando())
              else
                for (final m in miembros)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: const IconoCuadro(Icons.person_outline_rounded),
                    title: Text(m.correo.isEmpty ? m.uid : m.correo),
                    subtitle: Row(
                      children: [
                        if (m.uid == propietarioUid)
                          const Etiqueta('PROPIETARIO', color: Colores.verde)
                        else
                          const Etiqueta('MIEMBRO', color: Colores.textoSuave),
                        if (m.uid == sesion.usuario?.uid) ...[
                          const SizedBox(width: 6),
                          const Etiqueta('TÚ'),
                        ],
                      ],
                    ),
                    trailing: sesion.esPropietario && m.uid != propietarioUid
                        ? IconButton(
                            tooltip: 'Quitar acceso',
                            icon: const Icon(Icons.person_remove_outlined,
                                color: Colores.rojo),
                            onPressed: () async {
                              final ok = await confirmar(
                                context,
                                titulo: '¿Quitar a ${m.correo}?',
                                mensaje: 'Dejará de ver la central y de recibir sus '
                                    'alertas. Si conoce el código, podrá volver a '
                                    'vincularse.',
                                accion: 'Quitar',
                                peligro: true,
                              );
                              if (ok && context.mounted) {
                                await intentar(context, () => repo.expulsar(central, m.uid));
                              }
                            },
                          )
                        : null,
                  ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
