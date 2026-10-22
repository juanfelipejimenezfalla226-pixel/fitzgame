import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final ageVerified = prefs.getBool('ageVerified') ?? false;
  final permissionsDone = prefs.getBool('permissionsDone') ?? false;

  Widget home = const AgeScreen();
  if (ageVerified && permissionsDone) {
    home = const HomeScreen();
  } else if (ageVerified) {
    home = const PermissionsScreen();
  }

  runApp(FitzGameApp(home: home));
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayContent(),
    ),
  );
}

class FitzGameApp extends StatelessWidget {
  final Widget home;

  const FitzGameApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitzGame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF1744),
          brightness: Brightness.dark,
        ),
      ),
      home: home,
    );
  }
}

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  final dateController = TextEditingController();
  bool accepted = false;

  Future<void> verify() async {
    final parts = dateController.text.split('/');
    if (parts.length != 3) {
      show('Escribe tu fecha así: DD/MM/AAAA');
      return;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      show('Fecha inválida');
      return;
    }

    final birth = DateTime(year, month, day);
    final age = DateTime.now().difference(birth).inDays ~/ 365;

    if (age < 13) {
      show('Debes tener al menos 13 años');
      return;
    }

    if (!accepted) {
      show('Debes aceptar los términos');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ageVerified', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PermissionsScreen()),
    );
  }

  void show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🦂', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 10),
            const Text(
              'FitzGame',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF1744),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Verificación de edad'),
            const SizedBox(height: 24),
            TextField(
              controller: dateController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Fecha de nacimiento (DD/MM/AAAA)',
                border: OutlineInputBorder(),
              ),
            ),
            CheckboxListTile(
              value: accepted,
              onChanged: (value) {
                setState(() {
                  accepted = value ?? false;
                });
              },
              title: const Text('Acepto los términos y la privacidad'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: verify,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF1744),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Verificar edad'),
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool mic = false;
  bool overlay = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    final micStatus = await Permission.microphone.status;
    final overlayStatus = await FlutterOverlayWindow.isPermissionGranted();

    setState(() {
      mic = micStatus.isGranted;
      overlay = overlayStatus;
    });
  }

  Future<void> askMic() async {
    await Permission.microphone.request();
    await check();
  }

  Future<void> askOverlay() async {
    await FlutterOverlayWindow.requestPermission();
    await check();
  }

  Future<void> continueApp() async {
    if (!mic || !overlay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa los dos permisos')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissionsDone', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  mic ? Icons.check_circle : Icons.mic_off,
                  color: mic ? Colors.green : Colors.red,
                ),
                title: const Text('Micrófono'),
                subtitle: const Text('Para hablar con Fitz más adelante'),
                trailing: FilledButton(
                  onPressed: askMic,
                  child: const Text('Activar'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(
                  overlay ? Icons.check_circle : Icons.layers_clear,
                  color: overlay ? Colors.green : Colors.red,
                ),
                title: const Text('Mostrar sobre otras apps'),
                subtitle: const Text('Para que Fitz aparezca mientras juegas'),
                trailing: FilledButton(
                  onPressed: askOverlay,
                  child: const Text('Activar'),
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: continueApp,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF1744),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> openOverlay() async {
    if (await FlutterOverlayWindow.isActive()) return;

    await FlutterOverlayWindow.showOverlay(
      height: 420,
      width: 320,
      alignment: OverlayAlignment.topRight,
      flag: OverlayFlag.defaultFlag,
      positionGravity: PositionGravity.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FitzGame')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🦂', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 12),
            const Text(
              'Fitz está listo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activa la burbuja flotante antes de entrar a tu juego.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: openOverlay,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Activar Fitz flotante'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF1744),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverlayContent extends StatefulWidget {
  const OverlayContent({super.key});

  @override
  State<OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<OverlayContent> {
  final controller = TextEditingController();
  String advice = '';

  void getAdvice() {
    final text = controller.text.toLowerCase();

    if (text.contains('persiguen') || text.contains('persiguiendo')) {
      advice =
          'Busca cobertura, rompe la línea de visión y usa una granada para obligarlos a moverse. Revisa el minimapa y sal por un flanco.';
    } else if (text.contains('atacar')) {
      advice =
          'Antes de atacar, revisa tu vida, munición y posición. Pelea desde cobertura y no avances sin protección.';
    } else if (text.contains('escapar') || text.contains('huir')) {
      advice =
          'Rompe el contacto, usa cobertura, cambia de ruta y cura si es necesario. No corras en línea recta.';
    } else if (text.contains('perdido')) {
      advice =
          'Revisa el minimapa, identifica la zona segura y muévete por los bordes del mapa.';
    } else {
      advice =
          'Mantén cobertura, revisa el minimapa y no avances sin información. Describe tu situación con más detalle.';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xE60B0B0F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF1744)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Text('🦂', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text(
                  'Fitz — Asistente Gamer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Ej: Me están persiguiendo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: getAdvice,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF1744),
              ),
              child: const Text('Pedir consejo'),
            ),
            const SizedBox(height: 10),
            if (advice.isNotEmpty)
              Text(
                advice,
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}