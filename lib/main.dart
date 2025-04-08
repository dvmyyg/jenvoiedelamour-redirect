import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ajouté le 08/04/2025 pour la partie bidirectionnelle
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';


// Détermine le rôle de l'appareil
const bool isReceiver = false; // ← Xiaomi 2 = true, Xiaomi 1 = false

// ajouté le 08/04/2025 pour la partie bidirectionnelle
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deviceId = await getDeviceId();
  runApp(MyApp(deviceId: deviceId));
}

// ajouté le 08/04/2025 pour la partie bidirectionnelle
class MyApp extends StatelessWidget {
  final String deviceId;
  const MyApp({super.key, required this.deviceId});
// ajouté le 08/04/2025 pour la partie bidirectionnelle
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SenderScreen(deviceId: deviceId),
    );
  }
}


// ajouté le 08/04/2025 pour la partie bidirectionnelle
// === ÉMETTEUR === //
class SenderScreen extends StatelessWidget {
  final String deviceId;
  const SenderScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Émetteur')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenue dans Jela MVP'),
            Text('📱 Device ID : $deviceId'),
          ],
        ),
      ),
    );
  }
}

// === RÉCEPTEUR === //
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  bool showIcon = false;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('devices')
        .doc('xiaomi2')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data()?['showIcon'] == true) {
        print("📡 showIcon == true → on affiche !");
        setState(() {
          showIcon = true;
        });
      } else {
        setState(() {
          showIcon = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Téléphone B (Récepteur)')),
      body: Center(
        child: showIcon
            ? const Icon(Icons.star, color: Colors.amber, size: 100)
            : const Text("En attente du signal..."),
      ),
    );
  }
}


// ajouté le 08/04/2025 pour la partie bidirectionnelle
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('deviceId');

  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await prefs.setString('deviceId', deviceId);
    print('🆕 Nouveau deviceId généré : $deviceId');
  } else {
    print('📲 DeviceId existant : $deviceId');
  }

  return deviceId;
}