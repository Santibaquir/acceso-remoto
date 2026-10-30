# Graph Report - proyecto seguridad-Acceso Remoto  (2026-10-30)

## Corpus Check
- Corpus is ~22,800 words - fits in a single context window. You may not need a graph.

## Summary
- 944 nodes · 1241 edges · 68 communities (53 shown, 15 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 34 edges (avg confidence: 0.86)
- Token cost: 435,123 input · 0 output

## Community Hubs (Navigation)
- Central en modo demo
- Modelo de estado de la central
- Pantalla Panel
- Arranque y ajustes de la app
- Notificaciones y sirena
- Sesión y centrales del usuario
- Acceso y vinculación
- Marca y tema visual
- Herramientas de Firebase (JS)
- Repositorio de la central (Firebase)
- Widgets comunes
- Dependencias de la app
- Mockups de pantallas
- Pantalla Horario
- Autenticación (repositorio)
- Secciones privadas de pantallas
- Raíz de la app y logo
- Rutas de Firebase
- Pantalla Historial
- Formato de fechas y horas
- Protocolo de radio NRF24L01
- Autenticación demo
- Barra de horario
- Modelo Horario
- Modelo Nodo
- Modelo Central y miembros
- Pantalla LCD de la central
- Pantalla Cámara
- Contrato de datos Firebase
- Fila de nodo
- Estados de pantallas y tarjetas
- Tarjeta de alerta
- Tarjeta de estado
- Alarma, relé y memoria NVS
- Seguridad y pendientes
- Sincronización central-Firebase
- Alertas y push de la central
- Fila de alerta
- Chip de conexión
- Principios y permisos
- Modelo RegistroAlerta
- Pruebas de modelos
- Estado del proyecto y pendientes
- Reglas del analizador
- Isotipo TiGuard
- Errores TiGuard
- Visión general del sistema
- Hardware y firmware base
- Nodos y horario en firmware
- Documentación principal
- Logo horizontal
- Capas de la app
- Actividad Android
- Implementaciones de CentralRepositorio
- Proyecto Firebase
- Diseño y convenciones
- Guía de skills
- Estructura del repositorio
- Compilación
- Herramientas del PC
- Valor agregado
- Flujo de pantallas

## God Nodes (most connected - your core abstractions)
1. `atenderNodo()` - 13 edges
2. `dependencies` - 12 edges
3. `TiGuard mockups - todas las pantallas (v2.0)` - 11 edges
4. `loop() central` - 9 edges
5. `Contrato de datos — Firebase Realtime Database` - 9 edges
6. `atenderFirebase()` - 8 edges
7. `publicarAlerta()` - 8 edges
8. `main()` - 7 edges
9. `setup() central` - 7 edges
10. `Pendientes para dejar TiGuard al 100 %` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Capas de la app (pantallas → estado → datos → modelos → nucleo)` --references--> `CentralRepositorio`  [INFERRED]
  docs/ARQUITECTURA.md → app/lib/datos/central_repositorio.dart
- `Orden recomendado de skills` --semantically_similar_to--> `Regla número uno: leer ARQUITECTURA.md antes de cambiar`  [INFERRED] [semantically similar]
  docs/guias/skills_claude_code.md → CLAUDE.md
- `Diseño: tema oscuro tipo centro de seguridad` --semantically_similar_to--> `Convenciones de código (español, Colores, Marca, ErrorTiGuard)`  [INFERRED] [semantically similar]
  CLAUDE.md → docs/ARQUITECTURA.md
- `Al final: GSM, certificado raíz, código de vinculación, applicationId, teoría` --semantically_similar_to--> `Pendientes conocidos (applicationId, certificado, GSM, código de vinculación)`  [INFERRED] [semantically similar]
  PENDIENTES.md → docs/ARQUITECTURA.md
- `Mapa de carpetas del repositorio` --semantically_similar_to--> `Estructura del repositorio`  [INFERRED] [semantically similar]
  README.md → docs/ARQUITECTURA.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Flujo de alerta de movimiento: nodo PIR -> radio -> central -> sirena + Firebase + push** — firmware_nodo_nodo_enviar, firmware_central_central_atendernodo, firmware_central_central_activaralarma, firmware_central_central_publicaralerta, firmware_central_central_enviarpush, firmware_central_central_ruta_historial [EXTRACTED 1.00]
- **Sondeo y sincronizacion con Firebase (estado, horario, nodos)** — firmware_central_central_atenderfirebase, firmware_central_central_respuestafirebase, firmware_central_central_procesarestado, firmware_central_central_procesarhorario, firmware_central_central_procesarnodos [EXTRACTED 1.00]
- **Protocolo de radio compartido entre nodo y central** — firmware_central_central_protocolo_radio, firmware_central_central_mensajenodo, firmware_nodo_nodo_mensajenodo, firmware_central_central_configurarradio, firmware_nodo_nodo_setup [EXTRACTED 1.00]
- **Cadena de alerta: nodo → radio → central → Firebase → push** — docs_arquitectura_nodo_de_vigilancia, docs_arquitectura_protocolo_de_radio, docs_arquitectura_central, docs_arquitectura_estado_central, docs_arquitectura_notificaciones_push [EXTRACTED 1.00]
- **Una ruta nueva se actualiza a la vez en contrato, reglas, rutas.dart, firmware y simulador** — docs_arquitectura_contrato_de_datos, docs_arquitectura_permisos, docs_arquitectura_lista_de_verificacion, pendientes_simular_central_limpiar_viejo [INFERRED 0.75]
- **Principios de arquitectura TiGuard** — docs_arquitectura_central_autoridad_fisica, docs_arquitectura_firebase_fuente_de_verdad, docs_arquitectura_multiusuario_multicentral, docs_arquitectura_seguro_por_defecto [EXTRACTED 1.00]
- **Flujo de ingreso: iniciar sesión / crear cuenta -> vincular central -> panel** — docs_mockups_00_todas_las_pantallas_iniciar_sesion, docs_mockups_00_todas_las_pantallas_crear_cuenta, docs_mockups_00_todas_las_pantallas_vincular_central, docs_mockups_00_todas_las_pantallas_panel_principal [INFERRED 0.85]
- **Flujo de alerta: alerta de movimiento -> ver cámara -> historial** — docs_mockups_00_todas_las_pantallas_alerta_movimiento, docs_mockups_00_todas_las_pantallas_ver_camara, docs_mockups_00_todas_las_pantallas_historial [INFERRED 0.75]

## Communities (68 total, 15 thin omitted)

### Community 0 - "Central en modo demo"
Cohesion: 0.04
Nodes (38): activarNodo, agregarNodo, _alerta, _alertaNodo, _armado, _avisar, borrarHistorial, cambiarArmado (+30 more)

### Community 1 - "Modelo de estado de la central"
Cohesion: 0.05
Nodes (38): alerta, alertaNodo, armado, Desactivacion, desdeMapa, desdePulsador, enLinea, EstadoCentral (+30 more)

### Community 2 - "Pantalla Panel"
Cohesion: 0.05
Nodes (35): ahora, _avisarAlerta, build, _c, _cambiando, _cambiarArmado, central, createState (+27 more)

### Community 3 - "Arranque y ajustes de la app"
Cohesion: 0.05
Nodes (30): cargarAjustes, initializeDateFormatting, main, _auth, _avisoPulsador, build, _c, central (+22 more)

### Community 4 - "Notificaciones y sirena"
Cohesion: 0.05
Nodes (28): _avisoPulsador, cambiarAvisoPulsador, cambiarModo, canal, canalAvisos, cargarAjustes, _centrales, _claveAvisoPulsador (+20 more)

### Community 5 - "Sesión y centrales del usuario"
Cohesion: 0.05
Nodes (32): _alCambiarCentrales, _alCambiarUsuario, _auth, _cancelarCentrales, _cargando, _centralActual, _centrales, cerrarSesion (+24 more)

### Community 6 - "Acceso y vinculación"
Cohesion: 0.05
Nodes (34): _auth, build, _cambiarModo, _confirmacion, _contrasena, _correo, createState, dispose (+26 more)

### Community 7 - "Marca y tema visual"
Cohesion: 0.05
Nodes (32): app, empresa, firma, lema, Marca, ambar, base, borde (+24 more)

### Community 8 - "Herramientas de Firebase (JS)"
Cohesion: 0.07
Nodes (28): { Client }, { configstore }, fs, path, { requireAuth }, archivo, crypto, fs (+20 more)

### Community 9 - "Repositorio de la central (Firebase)"
Cohesion: 0.06
Nodes (29): activarNodo, agregarNodo, borrarHistorial, cambiarArmado, centralesDe, _db, _desfaseServidor, desvincular (+21 more)

### Community 10 - "Widgets comunes"
Cohesion: 0.07
Nodes (21): accion, build, child, color, colorBorde, confirmar, controlador, detalle (+13 more)

### Community 11 - "Dependencias de la app"
Cohesion: 0.07
Nodes (26): dependencies, audioplayers, external_app_launcher, firebase_auth, firebase_core, firebase_database, firebase_messaging, flutter (+18 more)

### Community 12 - "Mockups de pantallas"
Cohesion: 0.11
Nodes (22): TiGuard mockups - todas las pantallas (v2.0), Pantalla Ajustes, Pantalla Alerta de movimiento, Atajos de horario (Noche, Fuera de oficina, Madrugada, 24 horas) y Vigilar las 24 horas, Barra de horario 24 h (12 a.m.-12 a.m.) con marcador de hora actual, Indicador Central en línea, ID y código de vinculación mostrados en la pantalla LCD de la central, Pantalla Crear cuenta (+14 more)

### Community 13 - "Pantalla Horario"
Cohesion: 0.09
Nodes (20): _atajos, _borrador, build, _CajaHora, central, createState, _elegirHora, _guardado (+12 more)

### Community 14 - "Autenticación (repositorio)"
Cohesion: 0.10
Nodes (16): actual, _auth, AuthFirebase, AuthRepositorio, cambios, cerrarSesion, _convertir, _db (+8 more)

### Community 15 - "Secciones privadas de pantallas"
Cohesion: 0.11
Nodes (17): _ListaMiembros, _OpcionModo, _OpcionesNodo, _Resumen, _BotonCamara, _Encabezado, _ErrorConexion, _SelectorCentral (+9 more)

### Community 16 - "Raíz de la app y logo"
Cohesion: 0.12
Nodes (8): _Arranque, build, PuertaSesion, TiGuardApp, build, IsotipoTiGuard, LogotipoTiGuard, tamano

### Community 17 - "Rutas de Firebase"
Cohesion: 0.12
Nodes (16): central, centralesDe, estado, historial, horario, indiceCentral, info, miembro (+8 more)

### Community 18 - "Pantalla Historial"
Cohesion: 0.12
Nodes (15): _borrar, build, central, _consultar, createState, elegido, _filtrar, _Filtro (+7 more)

### Community 19 - "Formato de fechas y horas"
Cohesion: 0.12
Nodes (14): d, diferencia, fechaDesde, formatoDuracion, formatoHora, formatoMinutos, h, haceCuanto (+6 more)

### Community 20 - "Protocolo de radio NRF24L01"
Cohesion: 0.17
Nodes (15): configurarRadio(), EVENTO_LATIDO, EVENTO_MOVIMIENTO, idValido(), Latido de la central (estado/ultimoLatido cada 30 s), struct MensajeNodo (central), Modulo transceptor NRF24L01, Protocolo de radio TiGuard v1 (TGNET, canal 108, 250 kbps) (+7 more)

### Community 21 - "Autenticación demo"
Cohesion: 0.13
Nodes (10): _actual, _cambios, cerrarSesion, _entrar, iniciarSesion, recargar, recuperarContrasena, reenviarVerificacion (+2 more)

### Community 22 - "Barra de horario"
Cohesion: 0.13
Nodes (12): Horario, ahora, alto, BarraHorario, build, horario, _Marca, minutoActual (+4 more)

### Community 23 - "Modelo Horario"
Cohesion: 0.14
Nodes (12): aMapa, copiar, desdeMapa, fin, hashCode, inicio, minutosDia, operator (+4 more)

### Community 24 - "Modelo Nodo"
Cohesion: 0.14
Nodes (13): activo, creado, descubierto, desdeMapa, enLinea, formatoId, id, largoMaximoNombre (+5 more)

### Community 25 - "Modelo Central y miembros"
Cohesion: 0.15
Nodes (12): correo, desdeMapa, esPropietario, formatoId, id, InfoCentral, Miembro, nombre (+4 more)

### Community 26 - "Pantalla LCD de la central"
Cohesion: 0.22
Nodes (11): actualizarPantalla(), aviso(), buscarPantalla(), Pantalla LCD 16x2 I2C, loop() central, mostrarIdentidad(), mostrarLinea(), Pulsador de la central (+3 more)

### Community 27 - "Pantalla Cámara"
Cohesion: 0.18
Nodes (9): build, _controladorPaquete, createState, dispose, _elegir, initState, PantallaCamara, _PantallaCamaraState (+1 more)

### Community 28 - "Contrato de datos Firebase"
Cohesion: 0.21
Nodes (9): Alerta de movimiento (tarjeta roja + push), codigosVinculacion/{centralId}, Contrato de datos — Firebase Realtime Database, centrales/{c}/estado (armado, alerta, alertaNodo, ultimoLatido, desactivacion), Flujo: alerta de movimiento, Flujo: vincular una central, centrales/{c}/historial (copia del nombre del nodo), centrales/{c}/nodos/{nodoId} (+1 more)

### Community 29 - "Fila de nodo"
Cohesion: 0.18
Nodes (8): Nodo, accion, ahora, build, enAlerta, FilaNodo, nodo, onTap

### Community 30 - "Estados de pantallas y tarjetas"
Cohesion: 0.25
Nodes (8): PantallaHistorial, _PantallaHistorialState, PantallaPanel, _PantallaPanelState, TarjetaAlerta, _TarjetaAlertaState, TarjetaEstado, _TarjetaEstadoState

### Community 31 - "Tarjeta de alerta"
Cohesion: 0.18
Nodes (10): build, createState, dispose, hora, nodo, onReconocer, onSilenciar, onVerCamara (+2 more)

### Community 32 - "Tarjeta de estado"
Cohesion: 0.18
Nodes (9): armado, build, cambiando, createState, detalle, dispose, onCambiar, _pulso (+1 more)

### Community 33 - "Alarma, relé y memoria NVS"
Cohesion: 0.22
Nodes (10): activarAlarma(), apagarAlarma(), cargarMemoria(), guardarArmado(), guardarHorario(), Memoria interna NVS (Preferences 'tiguard'), Modulo rele, procesarEstado() (+2 more)

### Community 34 - "Seguridad y pendientes"
Cohesion: 0.25
Nodes (9): Módulo GSM SIM800L (respaldo SMS, regulador LM2596), Cuenta de servicio de la central, Escalabilidad (nuevos nodos, sensores, clientes, MAX_NODOS=16), Pendientes conocidos (applicationId, certificado, GSM, código de vinculación), publicarAlerta() (punto de enganche GSM), Seguridad (correo/contraseña, reglas, secretos, TLS, presencia física), clienteSeguro.setInsecure() pendiente (certificado raíz), Teoría (documentos académicos futuros) (+1 more)

### Community 35 - "Sincronización central-Firebase"
Cohesion: 0.31
Nodes (9): atenderFirebase(), aTexto(), procesarHorario(), procesarNodos(), registrarNodo(), respuestaFirebase(), /codigosVinculacion/{CENTRAL_ID}, /centrales/{CENTRAL_ID}/config/horario (+1 more)

### Community 36 - "Alertas y push de la central"
Cohesion: 0.25
Nodes (9): enviarPush(), Firebase Cloud Messaging (push por temas), firebaseListo(), Modulo GSM SIM800L (respaldo SMS futuro), publicarAlerta(), publicarDesactivacion(), reportarContacto(), /centrales/{CENTRAL_ID}/historial (+1 more)

### Community 37 - "Fila de alerta"
Cohesion: 0.25
Nodes (5): RegistroAlerta, ahora, build, FilaAlerta, registro

### Community 38 - "Chip de conexión"
Cohesion: 0.25
Nodes (5): ahora, build, ChipConexion, enLinea, ultimoLatido

### Community 39 - "Principios y permisos"
Cohesion: 0.29
Nodes (5): config/horario (siempre, inicio, fin), Flujo: horario de vigilancia (NVS, cruce de medianoche), Permisos (resumen de las reglas), Roles: Propietario y Miembro, Pruebas del sistema (en línea, alerta, horario, multicuenta, sin Wi-Fi)

### Community 40 - "Modelo RegistroAlerta"
Cohesion: 0.29
Nodes (5): desdeMapa, fecha, id, nodo, nombre

### Community 42 - "Estado del proyecto y pendientes"
Cohesion: 0.33
Nodes (7): Estado actual (octubre 2026): fase de protoboard, reforma 2.0 terminada, APK entregas/TiGuard-2.0.0.apk, Hardware: zumbador, Módulo relé, pantalla LCD, montaje sin protoboard, Pendientes para dejar TiGuard al 100 %, Poner a andar la versión 2.0, simular_central.js limpiar-viejo, Unir rama reforma-tiguard-2 a main

### Community 43 - "Reglas del analizador"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 44 - "Isotipo TiGuard"
Cohesion: 0.40
Nodes (6): Isotipo TiGuard (logo de la app), Escudo de seguridad, Formato de ícono de app con esquinas redondeadas, Monograma de dos T (TiGuard) estilo circuito, Radar / ondas concéntricas con aguja de barrido, Verde TiGuard neón sobre fondo oscuro

### Community 45 - "Errores TiGuard"
Cohesion: 0.33
Nodes (4): ErrorTiGuard, mensaje, mensajeDeError, toString

### Community 46 - "Visión general del sistema"
Cohesion: 0.40
Nodes (6): TiGuard (app de TiGuard Secure), Central (Placa de desarrollo ESP32, RTC, sirena), Lista de verificación antes de cambiar algo, struct MensajeNodo (11 bytes), Nodo de vigilancia (Placa Arduino Nano + Sensor PIR HC-SR501 + NRF24L01), Protocolo de radio NRF24L01 (canal 108, 250 kbps, TGNET)

### Community 47 - "Hardware y firmware base"
Cohesion: 0.33
Nodes (6): central.ino (Central ESP32), Placa de desarrollo ESP32-S DevKit, Firebase Realtime Database (FirebaseClient Mobizt, ServiceAuth), secretos.h (Wi-Fi, claves Firebase, CENTRAL_ID, CODIGO_VINCULACION), nodo.ino (Nodo de vigilancia Arduino Nano), Placa Arduino Nano

### Community 48 - "Nodos y horario en firmware"
Cohesion: 0.40
Nodes (6): agregarNodoLocal(), atenderNodo(), buscarNodo(), dentroDeHorario(), Horario de vigilancia (minutos desde medianoche, cruza medianoche), struct NodoConocido

### Community 49 - "Documentación principal"
Cohesion: 0.40
Nodes (3): TiGuard — App Android (README), TiGuard — Arquitectura del sistema, README: TiGuard by TiGuard Secure

### Community 50 - "Logo horizontal"
Cohesion: 0.60
Nodes (5): TiGuard Horizontal Logo, Brand palette: TiGuard green on near-black navy, Shield isotype with 'T' and radio-wave arcs, Geometric sans-serif typography (bold wordmark, regular tagline), Wordmark 'TiGuard' + tagline 'by TiGuard Secure'

### Community 53 - "Implementaciones de CentralRepositorio"
Cohesion: 0.67
Nodes (3): CentralFirebase, CentralRepositorio, CentralDemo

### Community 54 - "Proyecto Firebase"
Cohesion: 0.67
Nodes (3): Configurar Firebase (auth correo, reglas, google-services.json), Proyecto Firebase acceso-remoto-5777, ID de proyecto Firebase acceso-remoto-5777

### Community 56 - "Guía de skills"
Cohesion: 0.67
Nodes (3): Skill frontend-design, Skills de Claude Code para desarrollar una app, Skills de ingeniería (system-design, architecture, testing-strategy, code-review, tech-debt, documentation)

## Ambiguous Edges - Review These
- `Isotipo TiGuard (logo de la app)` → `Monograma de dos T (TiGuard) estilo circuito`  [AMBIGUOUS]
  app/assets/marca/isotipo.png · relation: references

## Knowledge Gaps
- **511 isolated node(s):** `build`, `cambios`, `actual`, `largoMinimoContrasena`, `_auth` (+506 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 625 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CentralRepositorio` connect `Implementaciones de CentralRepositorio` to `Repositorio de la central (Firebase)`, `Capas de la app`?**
  _High betweenness centrality (0.079) - this node is a cross-community bridge._
- **What connects `build`, `cambios`, `actual` to the rest of the system?**
  _511 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Central en modo demo` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Why does `Capas de la app (pantallas → estado → datos → modelos → nucleo)` connect `Capas de la app` to `Implementaciones de CentralRepositorio`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Should `Modelo de estado de la central` be split into smaller, more focused modules?**
  _Cohesion score 0.048625792811839326 - nodes in this community are weakly interconnected._
- **Why does `Repositorios abstractos (Firebase + demo)` connect `Capas de la app` to `Contrato de datos Firebase`?**
  _High betweenness centrality (0.075) - this node is a cross-community bridge._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Isotipo TiGuard (logo de la app)` and `Monograma de dos T (TiGuard) estilo circuito`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._