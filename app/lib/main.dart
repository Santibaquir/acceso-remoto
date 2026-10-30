// Arranque de TiGuard: fechas, Firebase, notificaciones y sesión.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'datos/repositorios.dart';
import 'estado/sesion.dart';
import 'nucleo/tema.dart';
import 'servicios/notificaciones.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await Notificaciones.cargarAjustes();

  if (!modoDemo) {
    // Lee la configuración de android/app/google-services.json
    await Firebase.initializeApp();
    try {
      await Notificaciones.iniciar();
    } catch (e) {
      debugPrint('No se pudieron configurar las notificaciones: $e');
    }
  }

  Repositorios.central.iniciar();
  Sesion.instancia.iniciar();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colores.fondo,
  ));

  runApp(const TiGuardApp());
}
