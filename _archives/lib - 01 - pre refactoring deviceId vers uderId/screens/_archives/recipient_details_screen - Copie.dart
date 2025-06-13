// lib/screens/recipient_details_screen.dart

import 'package:flutter/material.dart';
import '../models/recipient.dart';
import '../services/recipient_service.dart';
import '../utils/debug_log.dart';
import '../screens/send_message_screen.dart';
import '../services/i18n_service.dart';

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

  // modifié le 21/05/2025 — ajout des libellés dynamiques avec getUILabel
  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          getUILabel('delete_contact_title', deviceLang),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          getUILabel('delete_contact_warning', deviceLang),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: Text(getUILabel('cancel_button', deviceLang)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(
              getUILabel('delete_button', deviceLang),
              style: const TextStyle(color: Colors.red),
            ),
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
              PopupMenuItem(
                value: 'delete',
                child: Text(getUILabel('delete_contact_title', deviceLang)),
              ),
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
              getUILabel(recipient.relation, deviceLang),
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
              label: Text(getUILabel('access_messages_button', deviceLang)),
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
