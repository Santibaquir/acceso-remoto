import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'pantallas/inicio.dart';
import 'servicios/central_servicio.dart';
import 'servicios/notificaciones.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  if (!modoDemo) {
    // Lee la configuración de android/app/google-services.json
    await Firebase.initializeApp();

    // Sesión anónima: las reglas de la base de datos exigen usuario autenticado
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('No se pudo iniciar sesión en Firebase: $e');
    }

    try {
      await Notificaciones.iniciar();
    } catch (e) {
      debugPrint('No se pudieron configurar las notificaciones: $e');
    }
  }

  CentralServicio.instancia.iniciar();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colores.fondo,
  ));

  runApp(const AccesoRemotoApp());
}

class AccesoRemotoApp extends StatelessWidget {
  const AccesoRemotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acceso Remoto',
      debugShowCheckedModeBanner: false,
      theme: crearTema(),
      home: const PantallaInicio(),
    );
  }
}
