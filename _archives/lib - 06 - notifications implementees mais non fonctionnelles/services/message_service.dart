// -------------------------------------------------------------
// 📄 FICHIER : lib/services/message_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Gère l'envoi et la réception de messages entre deux utilisateurs (identifiés par UID)
// ✅ Interagit avec la sous-collection 'messages' sous le chemin users/{userId}/recipients/{otherUserId}
// ✅ Écrit le message dans les collections miroir des deux utilisateurs pour un affichage bidirectionnel
// ✅ Fournit un stream temps réel des messages d'une conversation
// ✅ Intégration avec FirebaseFirestore
// ✅ Logs internes via DebugLog
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V003 - Remplacement des identifiants deviceId/recipientId par les UID Firebase des deux utilisateurs. Adaptation des chemins Firestore (users/{userId}/recipients/{otherUserId}/messages). - 2025/05/29
// V002 - correction récupération messages : affichage pour A et B - 2025/05/28 15h12
// V001 - ajout du stream temps réel pour les messages - 2025/05/26 18h34
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart'; // Utilise le modèle Message refactorisé (avec UID)
import '../utils/debug_log.dart';


class MessageService {
  // L'identifiant de l'utilisateur actuel (son UID Firebase)
  final String currentUserId;
  // L'identifiant de l'autre utilisateur (le destinataire, son UID Firebase)
  final String recipientUserId; // Renommé de recipientId pour plus de clarté

  // Le service est initialisé avec les UID des deux utilisateurs impliqués
  MessageService({required this.currentUserId, required this.recipientUserId});

  // Référence à la collection de messages pour CET utilisateur (chemin basé sur UID)
  CollectionReference get _messageRef => FirebaseFirestore.instance
      .collection('users') // Collection de premier niveau basée sur l'UID
      .doc(currentUserId) // Document de l'utilisateur actuel (UID)
      .collection('recipients') // Sous-collection des destinataires
      .doc(recipientUserId) // Document du destinataire (son UID)
      .collection('messages'); // Sous-collection des messages de cette conversation

  // Référence à la collection de messages pour l'AUTRE utilisateur (chemin basé sur UID)
  CollectionReference get _mirrorMessageRef => FirebaseFirestore.instance
      .collection('users') // Collection de premier niveau basée sur l'UID
      .doc(recipientUserId) // Document du destinataire (son UID)
      .collection('recipients') // Sous-collection des destinataires
      .doc(currentUserId) // Document de l'utilisateur actuel (son UID)
      .collection('messages'); // Sous-collection des messages de cette conversation

  // ✅ Stream temps réel de tous les messages de cette conversation
  Stream<List<Message>> streamMessages() {
    debugLog("🔄 Ouverture du flux de messages entre UID $currentUserId et $recipientUserId");
    // La requête reste la même, mais opère sur la nouvelle référence de collection
    return _messageRef
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
    // Utilise le factory Message.fromMap (qui attend l'ID du doc et un Map avec des UID)
        .map((doc) => Message.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // ✅ Ajout d'un nouveau message (écrit dans les collections miroir des 2 utilisateurs)
  Future<void> sendMessage(Message message) async {
    // Le message doit déjà avoir les UID corrects dans message.from et message.to
    debugLog("📤 Envoi d'un message de type '${message.type}' de UID ${message.from} vers UID ${message.to}");
    final data = message.toMap(); // Utilise toMap() du modèle Message (qui écrit les UID)

    // Écrit le message dans la conversation de l'utilisateur actuel
    await _messageRef.doc(message.id).set(data);
    debugLog(
      "✅ Message ${message.id} écrit pour l'expéditeur ${message.from} dans ${_messageRef.path}",
    );

    // Écrit le message dans la conversation miroir chez le destinataire
    await _mirrorMessageRef.doc(message.id).set(data);
    debugLog(
      "✅ Message ${message.id} écrit pour le destinataire ${message.to} dans ${_mirrorMessageRef.path}",
    );
  }
}

// 📄 FIN de lib/services/message_service.dart
