// 📄 lib/screens/recipients_screen.dart

import 'package:flutter/material.dart';
import '../services/recipient_service.dart';
import '../models/recipient.dart';
import 'recipient_details_screen.dart';
import 'add_recipient_screen.dart';

class RecipientsScreen extends StatefulWidget {
  final String deviceId;
  const RecipientsScreen({super.key, required this.deviceId});

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
        title: const Text("👤 Mes destinataires"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
            trailing: Text(
              r.paired ? "[Appairé]" : "[Non appairé]",
              style: TextStyle(color: r.paired ? Colors.green : Colors.orange),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipientDetailsScreen(
                    deviceId: widget.deviceId,
                    recipient: r,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddRecipientScreen(deviceId: widget.deviceId),
            ),
          );
          _loadRecipients(); // recharge la liste après retour
        },
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
      ),
    );
  }
}

