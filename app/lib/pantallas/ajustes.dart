import 'package:flutter/material.dart';

import '../servicios/camara.dart';
import '../servicios/sirena.dart';
import '../tema.dart';

/// Ajustes: elegir la app de la cámara y probar la sirena.
class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({super.key});

  @override
  State<PantallaAjustes> createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  final _controladorPaquete = TextEditingController();
  String? _paquete;
  bool _probandoSirena = false;

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
    if (_probandoSirena) Sirena.callar();
    super.dispose();
  }

  Future<void> _elegir(String paquete) async {
    await Camara.guardarPaquete(paquete);
    setState(() => _paquete = paquete.trim());
  }

  Future<void> _alternarSirena() async {
    if (_probandoSirena) {
      await Sirena.callar();
    } else {
      await Sirena.sonar();
    }
    setState(() => _probandoSirena = !_probandoSirena);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const _Titulo('App de la cámara'),
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
          const SizedBox(height: 28),
          const _Titulo('Sirena'),
          const Text(
            'Comprueba que el volumen del celular esté alto.',
            style: TextStyle(color: Colores.textoSuave),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _alternarSirena,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _probandoSirena ? Colores.rojo : Colores.texto,
                side: BorderSide(
                  color: _probandoSirena ? Colores.rojo : Colores.borde,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(_probandoSirena
                  ? Icons.stop_rounded
                  : Icons.volume_up_rounded),
              label: Text(_probandoSirena ? 'Detener sirena' : 'Probar sirena'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}
