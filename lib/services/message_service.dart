// -------------------------------------------------------------
// 📄 FICHIER : lib/services/message_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Gère l'envoi et la réception de messages entre deux utilisateurs (identifiés par UID)
// ✅ Interagit avec la sous-collection 'messages' sous le chemin users/{userId}/recipients/{otherUserId}
// ✅ Utilise FirestoreService pour l'envoi atomique de messages dans les collections miroir des deux utilisateurs.
// ✅ Fournit un stream temps réel des messages d'une conversation.
// ✅ Dépend de FirestoreService pour l'envoi.
// ✅ Logs internes via DebugLog
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V005 - Suppression des blocs de code marqués ⛔️ À supprimer. - 2025/06/18 13h44
// V004 - Refactor de sendMessage pour utiliser FirestoreService (écriture atomique via batch). Ajout injection de dépendances FirestoreService. - 2025/06/18 13h40
// V003 - Remplacement des identifiants deviceId/recipientId par les UID Firebase des deux utilisateurs. Adaptation des chemins Firestore (users/{userId}/recipients/{otherUserId}/messages). - 2025/05/29
// V002 - correction récupération messages : affichage pour A et B - 2025/05/28 15h12
// V001 - ajout du stream temps réel pour les messages - 2025/05/26 18h34
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart'; // Utilise le modèle Message refactorisé (avec UID)
import '../utils/debug_log.dart';
import 'firestore_service.dart'; // ✅ AJOUT V004 : Import de FirestoreService

class MessageService {
  // L'identifiant de l'utilisateur actuel (son UID Firebase)
  final String currentUserId;
  // L'identifiant de l'autre utilisateur (le destinataire, son UID Firebase)
  final String recipientUserId; // Renommé de recipientId pour plus de clarté

  // ✅ AJOUT V004 : Champ pour l'instance injectée de FirestoreService
  final FirestoreService _firestoreService;

  // Le service est initialisé avec les UID des deux utilisateurs impliqués et FirestoreService
  // 🔄 MODIF V004 : Ajout de la dépendance à FirestoreService
  MessageService({required this.currentUserId, required this.recipientUserId, required FirestoreService firestoreService})
      : _firestoreService = firestoreService; // Initialise l'instance FirestoreService

  // Référence à la collection de messages pour CET utilisateur (chemin basé sur UID)
  // Cette référence est utilisée pour le streaming des messages dans streamMessages()
  CollectionReference get _messageRef => FirebaseFirestore.instance // NOTE : Utilise toujours FirebaseFirestore.instance pour le stream car FirestoreService n'a pas de méthode équivalente.
      .collection('users') // Collection de premier niveau basée sur l'UID
      .doc(currentUserId) // Document de l'utilisateur actuel (UID)
      .collection('recipients') // Sous-collection des destinataires
      .doc(recipientUserId) // Document du destinataire (son UID)
      .collection('messages'); // Sous-collection des messages de cette conversation

  // ✅ Stream temps réel de tous les messages de cette conversation
  // NOTE : Cette méthode utilise toujours FirebaseFirestore.instance directement.
  // TODO: Ajouter une méthode dans FirestoreService pour streamer les messages d'une conversation si la centralisation complète est nécessaire. (Étape 7.1)
  Stream<List<Message>> streamMessages() {
    debugLog("🔄 Ouverture du flux de messages entre UID $currentUserId et $recipientUserId");
    // La requête reste la même, mais opère sur la référence de collection locale
    return _messageRef
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Message.fromMap(doc.id, doc.data() as Map<String, dynamic>)) // Utilise le factory Message.fromMap (qui attend l'ID du doc et un Map avec des UID)
        .toList());
  }

  // ✅ MODIF V004 : Ajout d'un nouveau message (écrit de manière atomique dans les collections miroir des 2 utilisateurs via FirestoreService)
  Future<void> sendMessage(Message message) async {
    // Le message doit déjà avoir les UID corrects dans message.from et message.to
    debugLog("📤 Envoi d'un message de type '${message.type}' de UID ${message.from} vers UID ${message.to} via FirestoreService."); // ✅ MODIF log

    try {
      // ✅ Utilise le FirestoreService injecté pour envoyer le message de manière atomique (Point 3 du plan)
      await _firestoreService.sendMessage(
        senderUid: message.from,
        recipientUid: message.to,
        message: message,
      );
      debugLog(
        "✅ Message ${message.id} envoyé avec succès de ${message.from} à ${message.to} via FirestoreService (écriture atomique).", // ✅ MODIF log
      );
    } on FirebaseException catch (e) {
      debugLog("❌ [sendMessage] Erreur Firebase lors de l'envoi du message ${message.id} via FirestoreService : ${e.code} - ${e.message}", level: 'ERROR'); // ✅ MODIF log
      // TODO: Gérer cette erreur de manière appropriée pour l'UI (Étape 7.2)
      rethrow;
    } catch (e) {
      debugLog("❌ [sendMessage] Erreur inattendue lors de l'envoi du message ${message.id} via FirestoreService : $e", level: 'ERROR'); // ✅ MODIF log
      // TODO: Gérer cette erreur de manière appropriée pour l'UI (Étape 7.2)
      rethrow;
    }
  }
}

// <-- Fin de la classe MessageService // ✅ CORRECTION : S'assurer que le commentaire est bien à la fin de la classe

// 📄 FIN de lib/services/message_service.dart
