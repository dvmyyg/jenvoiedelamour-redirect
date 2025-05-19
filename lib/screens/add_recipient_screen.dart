// 📄 lib/screens/add_recipient_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../utils/debug_log.dart';

class AddRecipientScreen extends StatelessWidget {
  final String deviceId;
  final String deviceLang;

  const AddRecipientScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
  });

  Future<void> _createAndShareLink(BuildContext context) async {
    final recipientId = const Uuid().v4();

    // 🔄 Création Firestore (placeholder)
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .collection('recipients')
        .doc(recipientId)
        .set({
      'id': recipientId,
      'deviceId': null, // 🟡 B complétera lors de l'appairage
      'paired': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final link =
        'https://dvmyyg.github.io/jenvoiedelamour-redirect/?recipient=$recipientId';

    debugLog("🔗 Lien d’invitation généré : $link");

    await Share.share(
      "💌 Clique ici pour te connecter à moi dans l’app Jela :\n\n$link",
      subject: "Invitation à se connecter sur Jela",
    );

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("➕ Ajouter un contact"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Partage ce lien avec la personne que tu veux inviter.\n"
                  "Elle devra avoir l’application installée pour accepter.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _createAndShareLink(context),
              icon: const Icon(Icons.link),
              label: const Text("Partager mon lien d’invitation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
