import 'package:flutter/material.dart';

import '../../servicios/camara.dart';
import '../../nucleo/tema.dart';

/// Elegir la app de la cámara Wi-Fi que abre el botón "Ver cámara".
class PantallaCamara extends StatefulWidget {
  const PantallaCamara({super.key});

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

class _PantallaCamaraState extends State<PantallaCamara> {
  final _controladorPaquete = TextEditingController();
  String? _paquete;

  @override
  void initState() {
    super.initState();
    Camara.paqueteGuardado().then((p) {
      setState(() {
        _paquete = p;
        // Si es un paquete escrito a mano, se muestra en el campo de texto
        if (p != null && !Camara.apps.containsValue(p)) {
          _controladorPaquete.text = p;
        }
      });
    });
  }

  @override
  void dispose() {
    _controladorPaquete.dispose();
    super.dispose();
  }

  Future<void> _elegir(String paquete) async {
    await Camara.guardarPaquete(paquete);
    setState(() => _paquete = paquete.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App de la cámara')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const Text(
            'El botón "Ver cámara" abre esta app.',
            style: TextStyle(color: Colores.textoSuave),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colores.superficie,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colores.borde),
            ),
            child: RadioGroup<String>(
              groupValue: _paquete,
              onChanged: (valor) {
                if (valor != null) _elegir(valor);
              },
              child: Column(
                children: [
                  for (final app in Camara.apps.entries)
                    RadioListTile<String>(
                      value: app.value,
                      activeColor: Colores.verde,
                      title: Text(app.key),
                      subtitle: Text(
                        app.value,
                        style: const TextStyle(
                          color: Colores.textoSuave,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controladorPaquete,
            decoration: InputDecoration(
              labelText: 'Otra app (nombre del paquete)',
              hintText: 'com.ejemplo.camara',
              helperText: 'Está en el enlace de Play Store, después de "id="',
              filled: true,
              fillColor: Colores.superficie,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: () {
                  final texto = _controladorPaquete.text.trim();
                  if (texto.isEmpty) return;
                  _elegir(texto);
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cámara guardada: $texto')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
