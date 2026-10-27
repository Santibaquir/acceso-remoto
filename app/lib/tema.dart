import 'package:flutter/material.dart';

/// Paleta de la app: fondo oscuro tipo centro de seguridad.
/// El rojo se reserva SOLO para alertas.
class Colores {
  static const fondo = Color(0xFF0A0E13);
  static const superficie = Color(0xFF131921);
  static const superficieAlta = Color(0xFF1B232E);
  static const borde = Color(0xFF253041);
  static const texto = Color(0xFFE8EDF3);
  static const textoSuave = Color(0xFF8593A6);
  static const verde = Color(0xFF22C55E); // sistema armado / normal
  static const rojo = Color(0xFFEF4444); // alertas
  static const ambar = Color(0xFFF5A524); // central sin conexión
  static const azul = Color(0xFF4C8DFF); // acciones neutras
}

ThemeData crearTema() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colores.fondo,
    colorScheme: const ColorScheme.dark(
      surface: Colores.superficie,
      primary: Colores.verde,
      secondary: Colores.azul,
      error: Colores.rojo,
      onSurface: Colores.texto,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Colores.texto,
      displayColor: Colores.texto,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.fondo,
      foregroundColor: Colores.texto,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colores.texto,
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colores.superficieAlta),
    dividerTheme: const DividerThemeData(color: Colores.borde, thickness: 1),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colores.superficieAlta,
      contentTextStyle: TextStyle(color: Colores.texto),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
