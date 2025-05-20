// 📄 lib/screens/recipients_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/recipient_service.dart';
import '../models/recipient.dart';
import 'recipient_details_screen.dart';

class RecipientsScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;

  const RecipientsScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
  });

  @override
  State<RecipientsScreen> createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends State<RecipientsScreen> {
  late RecipientService _recipientService;
  List<Recipient> _recipients = [];

  @override
  void initState() {
    super.initState();
    _recipientService = RecipientService(widget.deviceId);
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    final recipients = await _recipientService.fetchRecipients();
    setState(() => _recipients = recipients);
  }

  Future<void> _confirmDeleteRecipient(String recipientId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Supprimer ce contact ?", style: TextStyle(color: Colors.white)),
        content: const Text("Cette action est irréversible.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _recipientService.deleteRecipient(recipientId);
      _loadRecipients();
    }
  }

  void _shareInviteLink() {
    final inviteLink = "https://dvmyyg.github.io/jenvoiedelamour-redirect/?recipient=${widget.deviceId}";
    Share.share(inviteLink);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Destinataires"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        children: [
          GestureDetector(
            onTap: _shareInviteLink,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: const [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.add, size: 20, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Inviter quelqu’un",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          ..._recipients.map((r) {
            return ListTile(
              leading: Text(r.icon, style: const TextStyle(fontSize: 24)),
              title: Text(
                r.displayName,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                r.relation,
                style: TextStyle(color: Colors.grey[400]),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: () => _confirmDeleteRecipient(r.id),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipientDetailsScreen(
                      deviceId: widget.deviceId,
                      deviceLang: widget.deviceLang,
                      recipient: r,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
