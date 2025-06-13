// lib/services/message_service.dart

// Historique du fichier
// V001 - ajout du stream temps réel pour les messages - 2025/05/26 18h34

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../utils/debug_log.dart';

class MessageService {
  final String deviceId;
  final String recipientId;

  MessageService({required this.deviceId, required this.recipientId});

  CollectionReference get _messageRef => FirebaseFirestore.instance
      .collection('devices')
      .doc(deviceId)
      .collection('recipients')
      .doc(recipientId)
      .collection('messages');

  // ✅ Stream temps réel de tous les messages
  Stream<List<Message>> streamMessages() {
    debugLog("🔄 Ouverture du flux de messages entre $deviceId et $recipientId");
    return _messageRef
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Message.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // ✅ Ajout d'un nouveau message
  Future<void> sendMessage(Message message) async {
    debugLog("📤 Envoi d'un message à $recipientId : ${message.type}");
    await _messageRef.doc(message.id).set(message.toMap());
  }
}
