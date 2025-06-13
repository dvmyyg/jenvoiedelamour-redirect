// lib/models/message.dart

// Historique du fichier
// V002 - ajout de la méthode statique quick() pour messages rapides - 2025/05/26 20h12
// V001 - création du modèle de message structuré avec formes multiples - 2025/05/26 19h18

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String from;
  final String to;
  final String type;
  final String content;
  final Timestamp sentAt;
  final Timestamp? receivedAt;
  final Timestamp? seenAt;

  Message({
    required this.id,
    required this.from,
    required this.to,
    required this.type,
    required this.content,
    required this.sentAt,
    this.receivedAt,
    this.seenAt,
  });

  // ✅ Factory pour générer un message rapide (❤️)
  static Message quick({required String from, required String to}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return Message(
      id: id,
      from: from,
      to: to,
      type: 'heart',
      content: '❤️',
      sentAt: Timestamp.now(),
    );
  }

  // ✅ Transformation Firestore → objet
  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      from: data['from'],
      to: data['to'],
      type: data['type'],
      content: data['content'],
      sentAt: data['sentAt'],
      receivedAt: data['receivedAt'],
      seenAt: data['seenAt'],
    );
  }

  // ✅ Transformation objet → Firestore
  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'type': type,
      'content': content,
      'sentAt': sentAt,
      if (receivedAt != null) 'receivedAt': receivedAt,
      if (seenAt != null) 'seenAt': seenAt,
    };
  }
}
