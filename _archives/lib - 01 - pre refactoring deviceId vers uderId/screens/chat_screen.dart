// lib/screens/chat_screen.dart

// Historique du fichier
// V002 - affichage du flux de messages avec correction de l’appel à Message.quick() - 2025/05/26 20h16
// V001 - structure de base de l’écran de chat et affichage des messages - 2025/05/26 19h34

import 'package:flutter/material.dart';
import '../models/recipient.dart';
import '../models/message.dart';
import '../services/message_service.dart';

class ChatScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final messageService = MessageService(
      deviceId: deviceId,
      recipientId: recipient.deviceId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(recipient.displayName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: messageService.streamMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.from == deviceId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.pink : Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: TextStyle(
                                fontSize: 20,
                                color: isMe ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.sentAt.toDate().toString().substring(11, 16),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white38,
                              ),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final msg = Message.quick(from: deviceId, to: recipient.deviceId);
                  await messageService.sendMessage(msg);
                },
                icon: const Icon(Icons.favorite),
                label: const Text("Envoyer ❤️"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
