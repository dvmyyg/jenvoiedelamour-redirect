//  lib/screens/recipients_screen.dart

// Historique du fichier
// V005 - ajout des paramètres obligatoires 'allowedPacks' et 'paired' dans Recipient - 2025/05/26 09h18
// V004 - ajout de la validation du champ de lien dans la boîte de dialogue - 2025/05/26 09h13
// V003 - connexion du lien collé à la méthode d’appairage - 2025/05/26 08h55
// V002 - ajout du bouton "Valider une invitation" avec champ de lien - 2025/05/26 08h52
// V001 - version initiale - 2025/05/21

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/recipient_service.dart';
import '../models/recipient.dart';
import 'recipient_details_screen.dart';
import '../services/i18n_service.dart';

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
        title: Text(
          getUILabel('delete_contact_title', widget.deviceLang),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          getUILabel('delete_contact_warning', widget.deviceLang),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              getUILabel('cancel_button', widget.deviceLang),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              getUILabel('delete_button', widget.deviceLang),
              style: const TextStyle(color: Colors.red),
            ),
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
    final inviteLink =
        "https://dvmyyg.github.io/jenvoiedelamour-redirect/?recipient=${widget.deviceId}";
    Share.share(inviteLink);
  }

  void _showPasteLinkDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          getUILabel('validate_invite_button', widget.deviceLang),
          style: const TextStyle(color: Colors.white),
        ),
        content: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: getUILabel('paste_invite_hint', widget.deviceLang),
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              getUILabel('cancel_button', widget.deviceLang),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              final input = controller.text.trim();
              final uri = Uri.tryParse(input);
              final recipientId = uri?.queryParameters['recipient'];
              if (recipientId != null && recipientId.isNotEmpty) {
                await _recipientService.addRecipient(Recipient(
                  id: recipientId,
                  displayName: '🎁 Nouveau lien',
                  icon: '💌',
                  relation: 'relation_partner',
                  deviceId: recipientId,
                  allowedPacks: [],
                  paired: true,
                ));
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadRecipients();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUILabel('pairing_success', widget.deviceLang)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(getUILabel('invalid_invite_link', widget.deviceLang)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              getUILabel('validate_button', widget.deviceLang),
              style: const TextStyle(color: Colors.pink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getUILabel('recipients_title', widget.deviceLang)),
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
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.add, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    getUILabel('invite_someone_button', widget.deviceLang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _showPasteLinkDialog,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.link, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    getUILabel('validate_invite_button', widget.deviceLang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                getUILabel(r.relation, widget.deviceLang),
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
