// lib/models/message.dart

// Historique du fichier
// V003 - Remplacement des champs 'from' et 'to' par l'UID Firebase de l'expéditeur et du destinataire. - 2025/05/29
// V002 - ajout de la méthode statique quick() pour messages rapides - 2025/05/26 20h12
// V001 - création du modèle de message structuré avec formes multiples - 2025/05/26 19h18

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id; // L'identifiant unique du message (souvent l'ID du document Firestore)
  final String from; // UID Firebase de l'expéditeur
  final String to; // UID Firebase du destinataire
  final String type;
  final String content;
  final Timestamp sentAt;
  final Timestamp? receivedAt;
  final Timestamp? seenAt;

  Message({
    required this.id,
    required this.from, // <-- Expects Firebase UID
    required this.to,   // <-- Expects Firebase UID
    required this.type,
    required this.content,
    required this.sentAt,
    this.receivedAt,
    this.seenAt,
  });

  // ✅ Factory pour générer un message rapide (❤️)
  // Reçoit maintenant les UID Firebase pour 'from' et 'to'
  static Message quick({required String from, required String to}) {
    // L'ID peut être généré ici ou par Firestore lors de l'ajout
    // Utiliser un ID généré par Firestore est souvent plus sûr pour garantir l'unicité
    // Pour l'instant, on garde la génération locale basée sur l'horodatage pour la compatibilité
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return Message(
      id: id,
      from: from, // UID de l'expéditeur
      to: to, // UID du destinataire
      type: 'heart',
      content: '❤️',
      sentAt: Timestamp.now(),
    );
  }

  // ✅ Transformation Firestore → objet
  // Lit les UID Firebase depuis les champs 'from' et 'to'
  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id, // ID du document Firestore
      from: data['from'] as String, // Assure que c'est bien lu comme String (UID)
      to: data['to'] as String,     // Assure que c'est bien lu comme String (UID)
      type: data['type'] as String,
      content: data['content'] as String,
      sentAt: data['sentAt'] as Timestamp,
      receivedAt: data['receivedAt'] as Timestamp?,
      seenAt: data['seenAt'] as Timestamp?,
    );
  }

  // ✅ Transformation objet → Firestore
  // Écrit les UID Firebase dans les champs 'from' et 'to'
  Map<String, dynamic> toMap() {
    return {
      'from': from, // UID de l'expéditeur
      'to': to, // UID du destinataire
      'type': type,
      'content': content,
      'sentAt': sentAt,
      if (receivedAt != null) 'receivedAt': receivedAt,
      if (seenAt != null) 'seenAt': seenAt,
    };
  }
}
