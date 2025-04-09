import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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