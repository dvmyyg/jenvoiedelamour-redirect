// lib/screens/recipient_details_screen.dart

// Historique du fichier
// V006 - correction type Timestamp / DateTime + import firestore - 2025/05/26 22h00
// V005 - remplacement affichage par chat + messages - 2025/05/26 21h00
// V004 - intégration AppBar + bouton d’envoi - 2025/05/24 16h00
// V003 - suppression du bloc contact, refonte UI - 2025/05/23 18h20
// V002 - ajout navigation depuis RecipientScreen - 2025/05/22 12h30
// V001 - création écran fiche destinataire - 2025/05/21

import 'package:flutter/material.dart';
import '../models/recipient.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../utils/debug_log.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ pour Timestamp

class RecipientDetailsScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;
  final Recipient recipient;

  const RecipientDetailsScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
    required this.recipient,
  });

  @override
  State<RecipientDetailsScreen> createState() => _RecipientDetailsScreenState();
}

class _RecipientDetailsScreenState extends State<RecipientDetailsScreen> {
  late MessageService _messageService;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageService = MessageService(
      deviceId: widget.deviceId,
      recipientId: widget.recipient.deviceId,
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msg = Message(
      id: const Uuid().v4(),
      from: widget.deviceId,
      to: widget.recipient.deviceId,
      sentAt: Timestamp.fromDate(DateTime.now()), // ✅ conversion ici
      seenAt: null,
      type: 'text',
      content: text,
    );

    _messageService.sendMessage(msg);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipient.displayName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageService.streamMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg.from == widget.deviceId;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.pink : Colors.grey[700], // fond bulle reçue 800
                          borderRadius: BorderRadius.circular(10), // au lieu de 12
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: const TextStyle(color: Colors.white, fontSize: 15), // fontsize ajouté
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.Hm().format(msg.sentAt.toDate()), // ✅ conversion ici
                              style: TextStyle(color: Colors.white38, fontSize: 10), // fontsize date/heure
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[900], // ??
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
