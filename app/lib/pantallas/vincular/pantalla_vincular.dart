// Vincular una central TiGuard con su ID y su código de vinculación.
import 'package:flutter/material.dart';

import '../../datos/repositorios.dart';
import '../../estado/sesion.dart';
import '../../nucleo/tema.dart';
import '../../widgets/comunes.dart';
import '../../widgets/logo_tiguard.dart';

class PantallaVincular extends StatefulWidget {
  /// true = el usuario todavía no tiene ninguna central (no hay a dónde volver).
  final bool primeraVez;
  const PantallaVincular({super.key, this.primeraVez = false});

  @override
  State<PantallaVincular> createState() => _PantallaVincularState();
}

class _PantallaVincularState extends State<PantallaVincular> {
  final _sesion = Sesion.instancia;
  final _formulario = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _codigo = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _id.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _vincular() async {
    FocusScope.of(context).unfocus();
    if (!_formulario.currentState!.validate()) return;
    setState(() => _enviando = true);
    final ok = await intentar(
      context,
      () => _sesion.vincular(_id.text, _codigo.text),
      exito: 'Central vinculada',
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok && !widget.primeraVez) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _sesion.usuario?.nombreVisible ?? '';
    return Scaffold(
      appBar: widget.primeraVez
          ? null
          : AppBar(title: const Text('Vincular central')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.primeraVez) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: IsotipoTiGuard(tamano: 52),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Hola, $nombre',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                    ],
                    const Text(
                      'Vincula tu central TiGuard para empezar a vigilar. '
                      'El ID y el código aparecen en la pantalla de la central al encenderla.',
                      style: TextStyle(color: Colores.textoSuave, fontSize: 15, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    const _PantallaLcd(),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _id,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'ID de la central',
                        hintText: 'TG8K2M4P7Q',
                        prefixIcon: Icon(Icons.router_outlined),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Escribe el ID de la central'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _codigo,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      onFieldSubmitted: (_) => _vincular(),
                      decoration: const InputDecoration(
                        labelText: 'Código de vinculación',
                        hintText: '4F7K-9QXW',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Escribe el código de vinculación'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _enviando ? null : _vincular,
                      icon: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colores.sobreMarca),
                            )
                          : const Icon(Icons.link_rounded),
                      label: const Text('Vincular central'),
                    ),
                    if (modoDemo) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Modo demo: DEMO7K2M9Q / TIGUARD1',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colores.textoTenue),
                      ),
                    ],
                    if (widget.primeraVez) ...[
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: _sesion.cerrarSesion,
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibujo de la pantalla LCD de la central para mostrar dónde están los datos.
class _PantallaLcd extends StatelessWidget {
  const _PantallaLcd();

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      fontFamily: 'monospace',
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: Color(0xFFCFF5FF),
      height: 1.4,
    );
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0E3A5C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E5A86), width: 2),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID  TG8K2M4P7Q', style: estilo),
                  Text('COD 4F7K-9QXW', style: estilo),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Pantalla\nde la\ncentral',
            style: TextStyle(color: Colores.textoSuave, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}
