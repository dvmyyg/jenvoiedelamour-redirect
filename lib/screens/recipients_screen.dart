// 📄 lib/screens/recipients_screen.dart

import 'package:flutter/material.dart';
import '../services/recipient_service.dart';
import '../models/recipient.dart';
import 'add_recipient_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes destinataires"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecipientScreen(
                    deviceId: widget.deviceId,
                    deviceLang: widget.deviceLang,
                  ),
                ),
              );
              _loadRecipients();
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: _recipients.length,
        itemBuilder: (context, index) {
          final r = _recipients[index];
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
            onTap: () {
              // À adapter selon les fonctionnalités à venir (fiche de profil)
            },
          );
        },
      ),
    );
  }
}
