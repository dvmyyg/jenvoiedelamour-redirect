// -------------------------------------------------------------
// 📄 FICHIER : lib/services/message_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Envoi de messages texte, sonores ou animés dans Firestore
// ✅ Récupération des messages liés à un destinataire
// ✅ Affichage de tous les messages échangés (envoyés ou reçus)
// ✅ Tri chronologique naturel (plus récent en bas)
// ✅ Intégration avec FirebaseFirestore
// ✅ Logs internes via DebugLog
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V002 - correction récupération messages : affichage pour A et B - 2025/05/28 15h12
// V001 - ajout du stream temps réel pour les messages - 2025/05/26 18h34
// -------------------------------------------------------------

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

  CollectionReference get _mirrorMessageRef => FirebaseFirestore.instance
      .collection('devices')
      .doc(recipientId)
      .collection('recipients')
      .doc(deviceId)
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

  // ✅ Ajout d'un nouveau message (écrit sur les 2 appareils)
  Future<void> sendMessage(Message message) async {
    debugLog("📤 Envoi d'un message à $recipientId : ${message.type}");
    final data = message.toMap();
    await _messageRef.doc(message.id).set(data);
    await _mirrorMessageRef.doc(message.id).set(data);
  }
}
