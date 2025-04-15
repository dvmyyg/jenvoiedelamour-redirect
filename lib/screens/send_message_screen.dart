// 📄 lib/screens/send_message_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/recipient.dart';
import '../services/i18n_service.dart';

class SendMessageScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;
  final Recipient recipient;

  const SendMessageScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
    required this.recipient,
  });

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  @override
  Widget build(BuildContext context) {
    final allowedMessages = widget.recipient.allowedPacks;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("💌 ${widget.recipient.displayName}"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        itemCount: allowedMessages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final messageType = allowedMessages[index];
          final previewText = getPreviewText(messageType, widget.deviceLang);

          return GestureDetector(
            onTap: () => sendLove(messageType),
            child: Container(
              height: 90,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  previewText,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> sendLove(String type) async {
    final otherDeviceId = widget.recipient.deviceId;
    if (otherDeviceId == null || !widget.recipient.paired) return;

    HapticFeedback.mediumImpact(); // retour haptique

    await FirebaseFirestore.instance
        .collection('devices')
        .doc(otherDeviceId)
        .update({
      'messageType': type,
      'senderName': widget.recipient.displayName,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(getUILabel('message_sent', widget.deviceLang))),
    );

    Navigator.pop(context);
  }
}
