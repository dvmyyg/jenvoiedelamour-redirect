// 📄 lib/screens/recipient_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipient.dart';
import 'edit_recipient_screen.dart';

class RecipientDetailsScreen extends StatelessWidget {
  final String deviceId;
  final Recipient recipient;

  const RecipientDetailsScreen({
    super.key,
    required this.deviceId,
    required this.recipient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("📄 Fiche destinataire"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow("Nom affiché", recipient.displayName),
            _buildRow("Relation", recipient.relation),
            _buildRow("Icône", recipient.icon),
            _buildRow("Appairé", recipient.paired ? "Oui" : "Non"),
            const SizedBox(height: 20),
            const Text("Packs autorisés :", style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: recipient.allowedPacks.map((pack) {
                return Chip(
                  label: Text(pack),
                  backgroundColor: Colors.pink,
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditRecipientScreen(
                        deviceId: deviceId,
                        recipient: recipient,
                      ),
                    ),
                  );

                  if (updated == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Modifications enregistrées")),
                    );
                    Navigator.pop(context); // revient à la liste
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text("Modifier"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _confirmDelete(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete),
                label: const Text("Supprimer ce destinataire"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            "$label : ",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("❌ Confirmation"),
        content: const Text("Supprimer ce destinataire ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRecipient(context);
    }
  }

  Future<void> _deleteRecipient(BuildContext context) async {
    final docRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .collection('recipients')
        .doc(recipient.id);

    await docRef.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Destinataire supprimé ✅")),
    );

    Navigator.pop(context);
  }
}
