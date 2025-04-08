import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Détermine le rôle de l'appareil
const bool isReceiver = false; // ← Xiaomi 2 = true, Xiaomi 1 = false

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: isReceiver ? 'Récepteur' : 'Émetteur',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: isReceiver ? const ReceiverScreen() : const SenderScreen(),
    );
  }
}

// === ÉMETTEUR === //
class SenderScreen extends StatelessWidget {
  const SenderScreen({super.key});

  void sendMessageToXiaomi2() async {
    await FirebaseFirestore.instance
        .collection('devices')
        .doc('xiaomi2')
        .set({'showIcon': true});
    print("✅ showIcon: true envoyé à Xiaomi 2");

    // Réinitialise après 2 secondes
    await Future.delayed(const Duration(seconds: 2));
    await FirebaseFirestore.instance
        .collection('devices')
        .doc('xiaomi2')
        .set({'showIcon': false});
    print("🔁 showIcon: false envoyé à Xiaomi 2");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Téléphone A (Émetteur)')),
      body: const Center(
        child: Text("Clique sur le bouton pour déclencher l’icône sur Xiaomi 2."),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: sendMessageToXiaomi2,
        tooltip: 'Envoyer',
        child: const Icon(Icons.send),
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