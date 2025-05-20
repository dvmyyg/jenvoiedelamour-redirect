// 📄 lib/screens/recipient_details_screen.dart

import 'package:flutter/material.dart';
import '../models/recipient.dart';
import '../services/recipient_service.dart';
import '../utils/debug_log.dart';
import '../screens/send_message_screen.dart';

class RecipientDetailsScreen extends StatelessWidget {
  final String deviceId;
  final String deviceLang;
  final Recipient recipient;

  const RecipientDetailsScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
    required this.recipient,
  });

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Supprimer ce contact", style: TextStyle(color: Colors.white)),
        content: const Text("Cette action est irréversible. Supprimer ce contact ?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecipientService(deviceId).deleteRecipient(recipient.id);
      debugLog("🗑️ Contact supprimé : ${recipient.displayName}");
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(recipient.displayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text("Supprimer ce contact"),
              ),
              // Autres actions futures ici
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.pink,
              child: Text(
                recipient.icon,
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              recipient.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              recipient.relation,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SendMessageScreen(
                      deviceId: deviceId,
                      deviceLang: deviceLang,
                      recipient: recipient,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.favorite),
              label: const Text("Accéder aux messages"),
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
