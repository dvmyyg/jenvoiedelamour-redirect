import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ajouté le 08/04/2025 pour la partie bidirectionnelle
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';


// Détermine le rôle de l'appareil
const bool isReceiver = true; // ← Xiaomi B = true, Xiaomi A = false

// ajouté le 08/04/2025 pour la partie bidirectionnelle
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deviceId = await getDeviceId();
  // ajouté le 08/04/2025 pour la sauvegarde dans Firebase du deviceId et de son rôle
  await Firebase.initializeApp(); // important si absent
  await registerDevice(deviceId, isReceiver);
  // fin ajout
  runApp(MyApp(deviceId: deviceId));
}

// mis à jour le 08/04/2025 pour afficher l’écran combiné
class MyApp extends StatelessWidget {
  final String deviceId;
  const MyApp({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoveScreen(
        deviceId: deviceId,
        isReceiver: isReceiver,
      ),
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


// ajouté le 08/04/2025 pour la sauvegarde dans Firebase du deviceId et de son rôle
Future<void> registerDevice(String deviceId, bool isReceiver) async {
  final deviceDoc = FirebaseFirestore.instance.collection('devices').doc(deviceId);
  await deviceDoc.set({
    'deviceId': deviceId,
    'isReceiver': isReceiver,
    'lastSeen': DateTime.now().toIso8601String(),
  });
  print('📡 Appareil enregistré : $deviceId (receiver: $isReceiver)');
}



// ajouté le 08/04/2025 pour l’écran combiné envoi + réception
class LoveScreen extends StatefulWidget {
  final String deviceId;
  final bool isReceiver;
  const LoveScreen({super.key, required this.deviceId, required this.isReceiver});

  @override
  State<LoveScreen> createState() => _LoveScreenState();
}

class _LoveScreenState extends State<LoveScreen> {
  bool showIcon = false;

  @override
  void initState() {
    super.initState();

    // On écoute notre propre doc Firebase pour afficher une animation si on reçoit un cœur
    FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .snapshots()
        .listen((doc) async {
      if (doc.exists && doc.data()?['showIcon'] == true) {
        print("🎯 Cœur reçu → animation");
        setState(() => showIcon = true);

        // ⏱️ Attente de 2 secondes
        await Future.delayed(const Duration(seconds: 2));

        // Réinitialisation de l’icône après affichage
        setState(() => showIcon = false);

        await FirebaseFirestore.instance
            .collection('devices')
            .doc(widget.deviceId)
            .update({'showIcon': false});
      }
    });
  }

  Future<void> sendLove() async {
    // On récupère tous les appareils sauf soi-même
    final devices = await FirebaseFirestore.instance.collection('devices').get();
    for (final doc in devices.docs) {
      if (doc.id != widget.deviceId) {
        await doc.reference.update({'showIcon': true});
      }
    }

    print('❤️ Cœur envoyé à tous les autres devices !');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("J'envoie de l'amour")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("📱 ID: ${widget.deviceId}"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: sendLove,
              icon: const Icon(Icons.favorite, color: Colors.red),
              label: const Text('Envoyer un cœur'),
            ),
            const SizedBox(height: 40),
            showIcon
                ? const Icon(Icons.star, color: Colors.amber, size: 100)
                : const Text("💤 En attente de l'amour..."),
          ],
        ),
      ),
    );
  }
}