// Aplicación TiGuard y la "puerta" que decide qué pantalla se ve según la sesión.
import 'package:flutter/material.dart';

import 'estado/sesion.dart';
import 'nucleo/marca.dart';
import 'nucleo/tema.dart';
import 'pantallas/acceso/pantalla_acceso.dart';
import 'pantallas/panel/pantalla_panel.dart';
import 'pantallas/vincular/pantalla_vincular.dart';
import 'widgets/logo_tiguard.dart';

class TiGuardApp extends StatelessWidget {
  const TiGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Marca.app,
      debugShowCheckedModeBanner: false,
      theme: crearTema(),
      home: const PuertaSesion(),
    );
  }
}

/// Sin sesión → Acceso · sin centrales → Vincular · con centrales → Panel.
/// docs/ARQUITECTURA.md §3.2
class PuertaSesion extends StatelessWidget {
  const PuertaSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = Sesion.instancia;
    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) {
        final Widget pantalla;
        if (sesion.cargando) {
          pantalla = const _Arranque();
        } else if (sesion.usuario == null) {
          pantalla = const PantallaAcceso();
        } else if (sesion.centralActual == null) {
          pantalla = const PantallaVincular(primeraVez: true);
        } else {
          // La key fuerza un panel nuevo al cambiar de central
          pantalla = PantallaPanel(
            key: ValueKey(sesion.centralActual),
            central: sesion.centralActual!,
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: KeyedSubtree(
            key: ValueKey(pantalla.runtimeType),
            child: pantalla,
          ),
        );
      },
    );
  }
}

class _Arranque extends StatelessWidget {
  const _Arranque();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IsotipoTiGuard(tamano: 72),
            SizedBox(height: 20),
            LogotipoTiGuard(tamano: 30),
            SizedBox(height: 28),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
