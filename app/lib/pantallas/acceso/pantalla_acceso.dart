// Iniciar sesión, crear cuenta y recuperar contraseña con correo.
import 'package:flutter/material.dart';

import '../../datos/auth_repositorio.dart';
import '../../datos/repositorios.dart';
import '../../nucleo/marca.dart';
import '../../nucleo/tema.dart';
import '../../widgets/comunes.dart';
import '../../widgets/logo_tiguard.dart';

class PantallaAcceso extends StatefulWidget {
  const PantallaAcceso({super.key});

  @override
  State<PantallaAcceso> createState() => _PantallaAccesoState();
}

class _PantallaAccesoState extends State<PantallaAcceso> {
  final _auth = Repositorios.auth;
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();

  bool _registro = false;
  bool _ocultar = true;
  bool _enviando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  // ---------- Validaciones ----------

  String? _validarCorreo(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe tu correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
      return 'Correo no válido';
    }
    return null;
  }

  String? _validarContrasena(String? v) {
    if (v == null || v.isEmpty) return 'Escribe tu contraseña';
    if (_registro && v.length < AuthRepositorio.largoMinimoContrasena) {
      return 'Mínimo ${AuthRepositorio.largoMinimoContrasena} caracteres';
    }
    if (_registro && !RegExp(r'(?=.*[A-Za-z])(?=.*\d)').hasMatch(v)) {
      return 'Usa letras y números';
    }
    return null;
  }

  // ---------- Acciones ----------

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_formulario.currentState!.validate()) return;
    setState(() => _enviando = true);
    await intentar(
      context,
      () => _registro
          ? _auth.registrar(_nombre.text, _correo.text, _contrasena.text)
          : _auth.iniciarSesion(_correo.text, _contrasena.text),
    );
    // Si salió bien, la PuertaSesion cambia de pantalla sola
    if (mounted) setState(() => _enviando = false);
  }

  Future<void> _recuperar() async {
    final error = _validarCorreo(_correo.text);
    if (error != null) {
      mostrarMensaje(context, 'Escribe arriba el correo de tu cuenta');
      return;
    }
    await intentar(
      context,
      () => _auth.recuperarContrasena(_correo.text),
      exito: 'Te enviamos un correo para crear una nueva contraseña',
    );
  }

  void _cambiarModo(bool registro) {
    if (registro == _registro) return;
    _formulario.currentState?.reset();
    setState(() => _registro = registro);
  }

  // ---------- Interfaz ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Resplandor de marca detrás del logo
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: Container(
              height: 340,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colores.marca.withValues(alpha: 0.22),
                    Colores.fondo.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formulario,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: IsotipoTiGuard(tamano: 64)),
                        const SizedBox(height: 18),
                        const Center(child: LogotipoTiGuard(tamano: 32)),
                        const SizedBox(height: 8),
                        const Text(
                          Marca.lema,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colores.textoSuave, fontSize: 15),
                        ),
                        const SizedBox(height: 32),
                        _SelectorModo(registro: _registro, onCambiar: _cambiarModo),
                        const SizedBox(height: 22),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: _registro
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    controller: _nombre,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    maxLength: 40,
                                    decoration: const InputDecoration(
                                      labelText: 'Tu nombre',
                                      prefixIcon: Icon(Icons.person_outline_rounded),
                                      counterText: '',
                                    ),
                                    validator: (v) => (v?.trim().isEmpty ?? true)
                                        ? 'Escribe tu nombre'
                                        : null,
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        TextFormField(
                          controller: _correo,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: _validarCorreo,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _contrasena,
                          obscureText: _ocultar,
                          textInputAction:
                              _registro ? TextInputAction.next : TextInputAction.done,
                          autofillHints: [
                            _registro ? AutofillHints.newPassword : AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) => _registro ? null : _enviar(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            helperText: _registro
                                ? 'Mínimo ${AuthRepositorio.largoMinimoContrasena} caracteres, con letras y números'
                                : null,
                            helperStyle: const TextStyle(color: Colores.textoTenue),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                              onPressed: () => setState(() => _ocultar = !_ocultar),
                              icon: Icon(_ocultar
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: _validarContrasena,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: _registro
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: TextFormField(
                                    controller: _confirmacion,
                                    obscureText: _ocultar,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _enviar(),
                                    decoration: const InputDecoration(
                                      labelText: 'Repite la contraseña',
                                      prefixIcon: Icon(Icons.lock_outline_rounded),
                                    ),
                                    validator: (v) => v != _contrasena.text
                                        ? 'Las contraseñas no coinciden'
                                        : null,
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        if (!_registro)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _enviando ? null : _recuperar,
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          )
                        else
                          const SizedBox(height: 22),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _enviando ? null : _enviar,
                          child: _enviando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colores.sobreMarca,
                                  ),
                                )
                              : Text(_registro ? 'Crear cuenta' : 'Iniciar sesión'),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_outlined,
                                size: 16, color: Colores.textoTenue),
                            const SizedBox(width: 6),
                            Text(
                              modoDemo ? 'Modo demo · ${Marca.firma}' : Marca.firma,
                              style: const TextStyle(
                                  color: Colores.textoTenue, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interruptor "Iniciar sesión | Crear cuenta".
class _SelectorModo extends StatelessWidget {
  final bool registro;
  final ValueChanged<bool> onCambiar;
  const _SelectorModo({required this.registro, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    Widget opcion(String texto, bool valor) {
      final elegido = registro == valor;
      return Expanded(
        child: GestureDetector(
          onTap: () => onCambiar(valor),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: elegido ? Colores.superficieAlta : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: elegido ? Colores.borde : Colors.transparent,
              ),
            ),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: elegido ? Colores.texto : Colores.textoSuave,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Radios.boton),
        border: Border.all(color: Colores.borde),
      ),
      child: Row(
        children: [
          opcion('Iniciar sesión', false),
          opcion('Crear cuenta', true),
        ],
      ),
    );
  }
}
