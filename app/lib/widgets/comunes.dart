// Piezas visuales pequeñas que comparten varias pantallas.
import 'package:flutter/material.dart';

import '../nucleo/errores.dart';
import '../nucleo/tema.dart';

/// Tarjeta oscura con borde: el contenedor base de la app.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? colorBorde;

  const Panel({super.key, required this.child, this.padding, this.colorBorde});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Radios.tarjeta),
        border: Border.all(color: colorBorde ?? Colores.borde),
      ),
      child: child,
    );
  }
}

/// Título de sección con texto de ayuda y una acción opcional a la derecha.
class TituloSeccion extends StatelessWidget {
  final String titulo;
  final String? detalle;
  final String? accion;
  final VoidCallback? onAccion;
  final EdgeInsetsGeometry padding;

  const TituloSeccion(
    this.titulo, {
    super.key,
    this.detalle,
    this.accion,
    this.onAccion,
    this.padding = const EdgeInsets.only(top: 26, bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (detalle != null) ...[
                  const SizedBox(height: 2),
                  Text(detalle!, style: const TextStyle(color: Colores.textoSuave)),
                ],
              ],
            ),
          ),
          if (accion != null)
            TextButton(onPressed: onAccion, child: Text(accion!)),
        ],
      ),
    );
  }
}

/// Ícono dentro de un cuadrado de color suave.
class IconoCuadro extends StatelessWidget {
  final IconData icono;
  final Color color;
  final double tamano;

  const IconoCuadro(this.icono,
      {super.key, this.color = Colores.marca, this.tamano = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radios.icono),
      ),
      child: Icon(icono, color: color, size: tamano * 0.55),
    );
  }
}

/// Punto de color con brillo (en línea, sin conexión...).
class PuntoEstado extends StatelessWidget {
  final Color color;
  final double tamano;
  const PuntoEstado(this.color, {super.key, this.tamano = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)],
      ),
    );
  }
}

/// Etiqueta pequeña tipo "Nuevo", "Inactivo", "Propietario".
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  const Etiqueta(this.texto, {super.key, this.color = Colores.marca});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Indicador de carga centrado, con un texto opcional.
class Cargando extends StatelessWidget {
  final String? texto;
  const Cargando({super.key, this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (texto != null) ...[
            const SizedBox(height: 18),
            Text(texto!, style: const TextStyle(color: Colores.textoSuave)),
          ],
        ],
      ),
    );
  }
}

/// Muestra un mensaje abajo de la pantalla.
void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Ejecuta una acción y, si falla, muestra el error al usuario.
/// Devuelve true si salió bien.
Future<bool> intentar(BuildContext context, Future<void> Function() accion,
    {String? exito}) async {
  try {
    await accion();
    if (exito != null && context.mounted) mostrarMensaje(context, exito);
    return true;
  } catch (e) {
    if (context.mounted) mostrarMensaje(context, mensajeDeError(e));
    return false;
  }
}

/// Diálogo de confirmación. [peligro] pinta el botón de rojo.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String accion,
  bool peligro = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: peligro ? Colores.rojo : Colores.marca,
            minimumSize: const Size(0, 44),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return r == true;
}

/// Diálogo con un campo de texto (renombrar). Devuelve null si se cancela.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String etiqueta,
  String inicial = '',
  int largoMaximo = 30,
  String accion = 'Guardar',
}) {
  final controlador = TextEditingController(text: inicial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: controlador,
        autofocus: true,
        maxLength: largoMaximo,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: etiqueta),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () {
            final v = controlador.text.trim();
            if (v.isNotEmpty) Navigator.pop(context, v);
          },
          child: Text(accion),
        ),
      ],
    ),
  );
}
