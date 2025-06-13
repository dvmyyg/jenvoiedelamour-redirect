// -------------------------------------------------------------
// 📄 FICHIER : lib/models/message.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Modèle de données pour représenter un message dans l'application.
// ✅ Contient les informations essentielles d'un message (expéditeur, destinataire, type, contenu, horodatages).
// ✅ Utilise les UID Firebase pour identifier l'expéditeur et le destinataire.
// ✅ Fournit des méthodes de conversion pour/depuis les Map (format Firestore).
// ✅ Inclut une factory pour créer facilement des messages rapides prédéfinis.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V003 - Remplacement des champs 'from' et 'to' par l'UID Firebase de l'expéditeur et du destinataire. - 2025/05/29
// V002 - ajout de la méthode statique quick() pour messages rapides - 2025/05/26 20h12
// V001 - création du modèle de message structuré avec formes multiples - 2025/05/26 19h18
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/30 // Mise à jour de la date au 30/05

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Ajout de l'import pour générer des UUID

class Message {
  final String id; // L'identifiant unique du message (souvent l'ID du document Firestore si généré là)
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
  static Message quick({required String from, required String to, required String content}) { // Ajout du paramètre 'content'
    // Utilisation de Uuid().v4() pour générer un ID unique, plus fiable que l'horodatage
    final id = const Uuid().v4();
    return Message(
      id: id,
      from: from, // UID de l'expéditeur
      to: to, // UID du destinataire
      type: 'quick', // Peut-être un type générique 'quick' au lieu de 'heart' si content varie? Ou 'heart' si c'est juste pour le cœur
      content: content, // Le contenu est maintenant passé en paramètre
      sentAt: Timestamp.now(),
      // receivedAt et seenAt sont null par défaut
    );
  }

  // ✅ Transformation Firestore → objet
  // Lit les UID Firebase depuis les champs 'from' et 'to'
  factory Message.fromMap(String id, Map<String, dynamic> data) {
    // Ajout de vérifications ou de valeurs par défaut au cas où des champs manqueraient (robustesse)
    return Message(
      id: id, // ID du document Firestore
      from: (data['from'] as String?) ?? '', // Utilise ?? '' pour éviter null si le champ est manquant
      to: (data['to'] as String?) ?? '',     // Utilise ?? '' pour éviter null si le champ est manquant
      type: (data['type'] as String?) ?? 'text', // Valeur par défaut si type est manquant
      content: (data['content'] as String?) ?? '', // Valeur par défaut si content est manquant
      sentAt: (data['sentAt'] as Timestamp?) ?? Timestamp.now(), // Valeur par défaut si sentAt est manquant
      receivedAt: data['receivedAt'] as Timestamp?, // Peut être null
      seenAt: data['seenAt'] as Timestamp?,         // Peut être null
    );
  }

  // ✅ Transformation objet → Firestore
  // Écrit les UID Firebase dans les champs 'from' et 'to'
  Map<String, dynamic> toMap() {
    // S'assure que les champs obligatoires ne sont pas null avant de créer la map
    // Bien que le constructeur l'exige déjà, c'est une sécurité supplémentaire
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

// Optionnel: Ajouter une méthode copyWith pour faciliter la modification d'instances
// Message copyWith({
//   String? id,
//   String? from,
//   String? to,
//   String? type,
//   String? content,
//   Timestamp? sentAt,
//   Timestamp? receivedAt,
//   Timestamp? seenAt,
// }) {
//   return Message(
//     id: id ?? this.id,
//     from: from ?? this.from,
//     to: to ?? this.to,
//     type: type ?? this.type,
//     content: content ?? this.content,
//     sentAt: sentAt ?? this.sentAt,
//     receivedAt: receivedAt ?? this.receivedAt,
//     seenAt: seenAt ?? this.seenAt,
//   );
// }
}
// 📄 FIN de lib/models/message.dart
