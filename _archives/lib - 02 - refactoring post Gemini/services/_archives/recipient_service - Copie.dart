// -------------------------------------------------------------
// 📄 FICHIER : lib/services/recipient_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Gère les destinataires liés à l'utilisateur authentifié (par UID)
// ✅ Envoi, récupération, mise à jour, suppression des destinataires dans Firestore
// ✅ Interagit avec la collection Firestore users/{userId}/recipients
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V002 - Remplacement de deviceId par l'UID de l'utilisateur authentifié pour l'accès Firestore (users/{userId}/recipients). Adaptation des requêtes. - 2025/05/29
// V001 - Version initiale (basée sur deviceId)
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé
import '../utils/debug_log.dart';

class RecipientService {
  // L'identifiant de l'utilisateur actuel est maintenant son UID Firebase
  final String currentUserId;

  // Le service est initialisé avec l'UID de l'utilisateur
  RecipientService(this.currentUserId);

  // Référence à la sous-collection des destinataires pour l'utilisateur actuel, basée sur son UID
  CollectionReference get _recipientsRef => FirebaseFirestore.instance
      .collection('users') // Collection de premier niveau basée sur l'UID
      .doc(currentUserId) // Document de l'utilisateur actuel (UID)
      .collection('recipients'); // Sous-collection des destinataires

  // ✅ Récupérer les destinataires appairés pour l'utilisateur actuel
  Future<List<Recipient>> fetchRecipients() async {
    debugLog("🔄 Chargement des destinataires pour l'utilisateur : $currentUserId");
    final snapshot = await _recipientsRef
    // On filtre maintenant sur le champ 'paired' qui est plus sémantique
    // L'ancien filtre .where('deviceId', isNotEqualTo: null) est supprimé
        .where('paired', isEqualTo: true) // ✅ filtre : uniquement ceux qui sont appairés
        .get();

    debugLog(
      "✅ ${snapshot.docs.length} destinataires appairés récupérés depuis Firestore pour $currentUserId",
    );

    // Utilise le factory Recipient.fromMap (qui attend l'UID comme doc.id)
    return snapshot.docs
        .map(
          (doc) =>
          Recipient.fromMap(doc.id, doc.data() as Map<String, dynamic>),
    )
        .toList();
  }

  // ✅ Ajouter un destinataire (pour l'utilisateur actuel)
  // Le recipient.id doit être l'UID de l'autre utilisateur
  Future<void> addRecipient(Recipient recipient) async {
    debugLog("📝 Ajout d'un destinataire pour $currentUserId : ${recipient.displayName} (ID: ${recipient.id})");
    // recipient.id contient maintenant l'UID de l'autre utilisateur
    await _recipientsRef.doc(recipient.id).set(recipient.toMap());
    debugLog(
      "✅ Destinataire ajouté pour $currentUserId : ${recipient.displayName} (ID: ${recipient.id})",
    );
  }

  // ✅ Mettre à jour un destinataire (pour l'utilisateur actuel)
  // Le recipient.id doit être l'UID de l'autre utilisateur
  Future<void> updateRecipient(Recipient recipient) async {
    debugLog("📝 Mise à jour du destinataire pour $currentUserId : ${recipient.displayName} (ID: ${recipient.id})");
    // recipient.id contient maintenant l'UID de l'autre utilisateur
    await _recipientsRef.doc(recipient.id).update(recipient.toMap());
    debugLog(
      "✅ Destinataire mis à jour pour $currentUserId : ${recipient.displayName} (ID: ${recipient.id})",
    );
  }

  // ✅ Supprimer un destinataire (pour l'utilisateur actuel)
  // L'id doit être l'UID de l'autre utilisateur
  Future<void> deleteRecipient(String recipientUserId) async { // Renommé le paramètre pour plus de clarté
    debugLog("🗑️ Suppression du destinataire ${recipientUserId} pour l'utilisateur : $currentUserId");
    // recipientUserId est l'UID de l'autre utilisateur
    await _recipientsRef.doc(recipientUserId).delete();
    debugLog("✅ Destinataire ${recipientUserId} supprimé pour $currentUserId");
  }
}
