// Colores (tokens) y tema visual de TiGuard. Ninguna pantalla define colores sueltos.
import 'package:flutter/material.dart';

/// Paleta: fondo oscuro tipo centro de seguridad.
/// Rojo = alerta de movimiento · verde = armado · ámbar = sin conexión ·
/// marca (verde TiGuard) = acciones principales y logo.
class Colores {
  static const fondo = Color(0xFF080B10);
  static const superficie = Color(0xFF11161D);
  static const superficieAlta = Color(0xFF19202A);
  static const borde = Color(0xFF232C39);
  static const texto = Color(0xFFE9EEF4);
  static const textoSuave = Color(0xFF8592A4);
  static const textoTenue = Color(0xFF5A6677);

  static const marca = Color(0xFF2FD08A); // verde TiGuard (del logo en marca/)
  static const sobreMarca = Color(0xFF06140E); // texto sobre botones de marca
  static const verde = Color(0xFF22C55E); // sistema armado / normal
  static const rojo = Color(0xFFEF4444); // alerta de movimiento
  static const ambar = Color(0xFFF5A524); // sin conexión / fuera de horario
}

/// Radios de las esquinas, para que todas las tarjetas se vean iguales.
class Radios {
  static const tarjeta = 22.0;
  static const boton = 16.0;
  static const icono = 12.0;
}

ThemeData crearTema() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colores.fondo,
    colorScheme: const ColorScheme.dark(
      surface: Colores.superficie,
      primary: Colores.marca,
      onPrimary: Colores.sobreMarca,
      secondary: Colores.verde,
      error: Colores.rojo,
      onSurface: Colores.texto,
    ),
  );

  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radios.boton),
    borderSide: const BorderSide(color: Colores.borde),
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.superficie,
      labelStyle: const TextStyle(color: Colores.textoSuave),
      hintStyle: const TextStyle(color: Colores.textoTenue),
      prefixIconColor: Colores.textoSuave,
      suffixIconColor: Colores.textoSuave,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
        borderSide: const BorderSide(color: Colores.marca, width: 1.6),
      ),
      errorBorder: bordeCampo.copyWith(
        borderSide: const BorderSide(color: Colores.rojo),
      ),
      focusedErrorBorder: bordeCampo.copyWith(
        borderSide: const BorderSide(color: Colores.rojo, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colores.marca,
        foregroundColor: Colores.sobreMarca,
        disabledBackgroundColor: Colores.superficieAlta,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radios.boton),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colores.texto,
        side: const BorderSide(color: Colores.borde),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radios.boton),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colores.marca),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : Colores.textoSuave,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colores.verde : Colores.superficieAlta,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colores.borde),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colores.superficieAlta),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colores.superficie,
      showDragHandle: true,
      dragHandleColor: Colores.borde,
    ),
    dividerTheme: const DividerThemeData(color: Colores.borde, thickness: 1),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colores.superficieAlta,
      contentTextStyle: TextStyle(color: Colores.texto),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Colores.marca),
  );
}
