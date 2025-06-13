// lib/screens/chat_screen.dart

// Historique du fichier
// V001 - écran de conversation avec affichage des messages et envoi rapide - 2025/05/26 20h00

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/recipient.dart';
import '../services/message_service.dart';
import '../utils/debug_log.dart';
import '../services/i18n_service.dart';

class ChatScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;
  final Recipient recipient;

  const ChatScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
    required this.recipient,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late MessageService _messageService;

  @override
  void initState() {
    super.initState();
    _messageService = MessageService(
      deviceId: widget.deviceId,
      recipientId: widget.recipient.deviceId,
    );
  }

  void _sendQuickMessage() {
    final message = Message.quick(
      from: widget.deviceId,
      to: widget.recipient.deviceId,
      type: 'heart',
    );
    _messageService.sendMessage(message);
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
      body: StreamBuilder<List<Message>>(
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
              final isMe = msg.from == widget.deviceId;
              final time = TimeOfDay.fromDateTime(msg.sentAt.toDate()).format(context);

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.pink : Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${msg.content}  •  $time',
                    style: TextStyle(color: isMe ? Colors.white : Colors.white70),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendQuickMessage,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.favorite),
      ),
    );
  }
}
