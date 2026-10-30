// Configurar a qué horas vigila la central (o las 24 horas).
import 'package:flutter/material.dart';

import '../../datos/repositorios.dart';
import '../../estado/sesion.dart';
import '../../modelos/horario.dart';
import '../../nucleo/formato.dart';
import '../../nucleo/tema.dart';
import '../../widgets/barra_horario.dart';
import '../../widgets/comunes.dart';

class PantallaHorario extends StatefulWidget {
  final String central;
  const PantallaHorario({super.key, required this.central});

  @override
  State<PantallaHorario> createState() => _PantallaHorarioState();
}

class _PantallaHorarioState extends State<PantallaHorario> {
  final _repo = Repositorios.central;

  /// Lo que hay en Firebase y lo que el usuario está editando.
  Horario? _guardado;
  Horario? _borrador;
  bool _guardando = false;

  bool get _propietario => Sesion.instancia.esPropietario;
  bool get _hayCambios => _borrador != null && _borrador != _guardado;

  static const _atajos = [
    ('Noche', Horario(siempre: false, inicio: 22 * 60, fin: 6 * 60)),
    ('Fuera de oficina', Horario(siempre: false, inicio: 18 * 60, fin: 8 * 60)),
    ('Madrugada', Horario(siempre: false, inicio: 0, fin: 5 * 60)),
    ('24 horas', Horario(siempre: true, inicio: 0, fin: 0)),
  ];

  @override
  void initState() {
    super.initState();
    _repo.horario(widget.central).first.then((h) {
      if (mounted) setState(() => _guardado = _borrador = h);
    });
  }

  Future<void> _elegirHora(bool inicio) async {
    final actual = inicio ? _borrador!.inicio : _borrador!.fin;
    final elegida = await showTimePicker(
      context: context,
      helpText: inicio ? 'EMPIEZA A VIGILAR' : 'DEJA DE VIGILAR',
      initialTime: TimeOfDay(hour: actual ~/ 60, minute: actual % 60),
    );
    if (elegida == null) return;
    final minutos = elegida.hour * 60 + elegida.minute;
    setState(() => _borrador = inicio
        ? _borrador!.copiar(inicio: minutos)
        : _borrador!.copiar(fin: minutos));
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final ok = await intentar(
      context,
      () => _repo.guardarHorario(widget.central, _borrador!),
      exito: 'Horario guardado. La central lo aplica en unos segundos.',
    );
    if (!mounted) return;
    setState(() {
      _guardando = false;
      if (ok) _guardado = _borrador;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = _borrador;
    final ahora = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Horario de vigilancia')),
      body: h == null
          ? const Cargando()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: [
                Text(
                  _propietario
                      ? 'La central solo da la alerta de movimiento dentro de este '
                          'horario. Usa la hora del Módulo de reloj RTC DS3231.'
                      : 'Solo el propietario de la central puede cambiar el horario.',
                  style: const TextStyle(color: Colores.textoSuave, height: 1.4),
                ),
                const SizedBox(height: 18),
                Panel(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.siempre
                            ? 'Vigila las 24 horas'
                            : 'Vigila ${formatoDuracion(h.duracion)} al día',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h.vigilaAhora(ahora)
                            ? 'Ahora mismo está dentro del horario'
                            : 'Ahora mismo está fuera del horario',
                        style: TextStyle(
                          color: h.vigilaAhora(ahora) ? Colores.verde : Colores.ambar,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      BarraHorario(horario: h, ahora: ahora),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Panel(
                  child: SwitchListTile(
                    value: h.siempre,
                    onChanged: _propietario
                        ? (v) => setState(() => _borrador = h.copiar(siempre: v))
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: const IconoCuadro(Icons.all_inclusive_rounded),
                    title: const Text('Vigilar las 24 horas',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Ignora el horario de abajo',
                        style: TextStyle(color: Colores.textoSuave, fontSize: 13)),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: h.siempre ? 0.4 : 1,
                  child: IgnorePointer(
                    ignoring: h.siempre || !_propietario,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Row(
                        children: [
                          _CajaHora(
                            titulo: 'Empieza',
                            icono: Icons.nightlight_round,
                            minutos: h.inicio,
                            onTap: () => _elegirHora(true),
                          ),
                          const SizedBox(width: 12),
                          _CajaHora(
                            titulo: 'Termina',
                            icono: Icons.wb_sunny_outlined,
                            minutos: h.fin,
                            onTap: () => _elegirHora(false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_propietario) ...[
                  const TituloSeccion('Atajos'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (nombre, atajo) in _atajos)
                        ChoiceChip(
                          label: Text(nombre),
                          selected: atajo.siempre ? h.siempre : h == atajo,
                          // "24 horas" conserva las horas elegidas por si se apaga después
                          onSelected: (_) => setState(() => _borrador =
                              atajo.siempre ? h.copiar(siempre: true) : atajo),
                          selectedColor: Colores.marca.withValues(alpha: 0.2),
                          backgroundColor: Colores.superficie,
                          side: const BorderSide(color: Colores.borde),
                          showCheckmark: false,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ],
            ),
      bottomNavigationBar: _propietario && _hayCambios
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colores.sobreMarca),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Guardar horario'),
                ),
              ),
            )
          : null,
    );
  }
}

class _CajaHora extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final int minutos;
  final VoidCallback onTap;

  const _CajaHora({
    required this.titulo,
    required this.icono,
    required this.minutos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Radios.tarjeta),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radios.tarjeta),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radios.tarjeta),
              border: Border.all(color: Colores.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icono, size: 18, color: Colores.textoSuave),
                    const SizedBox(width: 6),
                    Text(titulo, style: const TextStyle(color: Colores.textoSuave)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatoMinutos(minutos),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
