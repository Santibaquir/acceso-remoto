// Logo oficial de TiGuard (marca/logo_app.jpg → assets/marca/isotipo.png).
import 'package:flutter/material.dart';

import '../nucleo/marca.dart';
import '../nucleo/tema.dart';

/// Isotipo: escudo con la "T" y el radar, sobre el cuadro oscuro.
class IsotipoTiGuard extends StatelessWidget {
  final double tamano;
  const IsotipoTiGuard({super.key, this.tamano = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamano * 0.2),
        // Resplandor verde suave, como en el logo
        boxShadow: [
          BoxShadow(
            color: Colores.marca.withValues(alpha: 0.28),
            blurRadius: tamano * 0.45,
          ),
        ],
      ),
      child: Image.asset(
        'assets/marca/isotipo.png',
        width: tamano,
        height: tamano,
        filterQuality: FilterQuality.medium,
        semanticLabel: Marca.app,
      ),
    );
  }
}

/// Logotipo de texto: "TiGuard" en blanco, como en marca/logo_horizontal.jpg.
class LogotipoTiGuard extends StatelessWidget {
  final double tamano;
  const LogotipoTiGuard({super.key, this.tamano = 22});

  @override
  Widget build(BuildContext context) {
    return Text(
      Marca.app,
      style: TextStyle(
        fontSize: tamano,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.1,
        color: Colores.texto,
      ),
    );
  }
}
