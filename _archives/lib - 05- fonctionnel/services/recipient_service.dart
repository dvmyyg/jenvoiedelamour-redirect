// -------------------------------------------------------------
// 📄 FICHIER : lib/services/recipient_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Gère les destinataires (autres utilisateurs avec qui l'utilisateur actuel interagit) liés à l'utilisateur authentifié (par UID).
// ✅ Interagit avec la sous-collection Firestore users/{userId}/recipients.
// ✅ Fournit des méthodes pour récupérer, ajouter, mettre à jour et supprimer des destinataires.
// ✅ Utilise l'UID Firebase du destinataire comme identifiant des documents dans la sous-collection 'recipients'.
// ✅ Utilise les logs internes via DebugLog.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V003 - Ajout de la gestion d'erreurs (try/catch avec FirebaseException) pour les opérations Firestore. - 2025/05/30
// V002 - Remplacement de deviceId par l'UID de l'utilisateur authentifié pour l'accès Firestore (users/{userId}/recipients). Adaptation des requêtes. - 2025/05/29
// V001 - Version initiale (basée sur deviceId)
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/30 // Mise à jour de la date au 30/05

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé
import '../utils/debug_log.dart';

class RecipientService {
  // L'identifiant de l'utilisateur actuel est maintenant son UID Firebase
  final String currentUserId;

  // Référence à l'instance Firestore (initialisée une fois pour le service)
  final FirebaseFirestore _firestore;

  // Le service est initialisé avec l'UID de l'utilisateur
  RecipientService(this.currentUserId)
      : _firestore = FirebaseFirestore.instance; // Initialise l'instance Firestore ici

  // Référence à la sous-collection des destinataires pour l'utilisateur actuel, basée sur son UID
  CollectionReference get _recipientsRef => _firestore
      .collection('users') // Collection de premier niveau basée sur l'UID
      .doc(currentUserId) // Document de l'utilisateur actuel (UID)
      .collection('recipients'); // Sous-collection des destinataires de l'utilisateur actuel

  // ✅ Récupérer les destinataires appairés pour l'utilisateur actuel
  Future<List<Recipient>> fetchRecipients() async {
    debugLog("🔄 [fetchRecipients] Chargement des destinataires pour l'utilisateur : $currentUserId");
    try {
      final snapshot = await _recipientsRef
      // On filtre maintenant sur le champ 'paired' qui est plus sémantique
      // L'ancien filtre .where('deviceId', isNotEqualTo: null) est supprimé
          .where('paired', isEqualTo: true) // ✅ filtre : uniquement ceux qui sont appairés
          .get();

      debugLog(
        "✅ [fetchRecipients] ${snapshot.docs.length} destinataires appairés récupérés depuis Firestore pour $currentUserId",
      );

      // Utilise le factory Recipient.fromMap (qui attend l'ID du doc et un Map avec les données)
      return snapshot.docs
          .map(
            (doc) =>
            Recipient.fromMap(doc.id, doc.data() as Map<String, dynamic>), // Cast sécurisé
      )
          .toList();

    } on FirebaseException catch (e) {
      // Gère les erreurs spécifiques à Firebase
      debugLog(
        "❌ [fetchRecipients] Erreur Firebase lors du chargement des destinataires pour $currentUserId : ${e.code} - ${e.message}",
        level: 'ERROR',
      );
      rethrow; // Rethrow l'exception
    } catch (e) {
      // Gère toute autre erreur inattendue
      debugLog(
        "❌ [fetchRecipients] Erreur inattendue lors du chargement des destinataires pour $currentUserId : $e",
        level: 'ERROR',
      );
      rethrow;
    }
  }

  // ✅ Ajouter un destinataire (pour l'utilisateur actuel)
  // Le recipient.id doit être l'UID de l'autre utilisateur.
  // Utilise set() avec merge: true pour éviter d'écraser d'autres champs si le document existe déjà.
  Future<void> addRecipient(Recipient recipient) async {
    debugLog("📝 [addRecipient] Tentative d'ajout d'un destinataire pour $currentUserId : ${recipient.displayName} (UID: ${recipient.id})");
    if (recipient.id.isEmpty) {
      debugLog("⚠️ [addRecipient] UID destinataire vide. Ajout annulé.", level: 'WARN');
      // Optionnel: Lancer une exception ici.
      return;
    }
    try {
      // recipient.id contient maintenant l'UID de l'autre utilisateur
      // set() est utilisé au cas où le document existerait déjà (ex: si l'appairage a déjà créé le doc)
      await _recipientsRef.doc(recipient.id).set(recipient.toMap(), SetOptions(merge: true));
      debugLog(
        "✅ [addRecipient] Destinataire ajouté/mis à jour pour $currentUserId : ${recipient.displayName} (UID: ${recipient.id})",
      );
    } on FirebaseException catch (e) {
      debugLog(
        "❌ [addRecipient] Erreur Firebase lors de l'ajout destinataire ${recipient.id} pour $currentUserId : ${e.code} - ${e.message}",
        level: 'ERROR',
      );
      rethrow;
    } catch (e) {
      debugLog(
        "❌ [addRecipient] Erreur inattendue lors de l'ajout destinataire ${recipient.id} pour $currentUserId : $e",
        level: 'ERROR',
      );
      rethrow;
    }
  }

  // ✅ Mettre à jour un destinataire (pour l'utilisateur actuel)
  // Le recipient.id doit être l'UID de l'autre utilisateur
  Future<void> updateRecipient(Recipient recipient) async {
    debugLog("📝 [updateRecipient] Tentative de mise à jour du destinataire pour $currentUserId : ${recipient.displayName} (UID: ${recipient.id})");
    if (recipient.id.isEmpty) {
      debugLog("⚠️ [updateRecipient] UID destinataire vide. Mise à jour annulée.", level: 'WARN');
      // Optionnel: Lancer une exception ici.
      return;
    }
    try {
      // recipient.id contient maintenant l'UID de l'autre utilisateur
      // update() échouera si le document n'existe pas. Si vous voulez créer si inexistant, utilisez set(..., merge: true).
      await _recipientsRef.doc(recipient.id).update(recipient.toMap());
      debugLog(
        "✅ [updateRecipient] Destinataire mis à jour pour $currentUserId : ${recipient.displayName} (UID: ${recipient.id})",
      );
    } on FirebaseException catch (e) {
      debugLog(
        "❌ [updateRecipient] Erreur Firebase lors de la mise à jour destinataire ${recipient.id} pour $currentUserId : ${e.code} - ${e.message}",
        level: 'ERROR',
      );
      // Gérer l'erreur "document n'existe pas" si nécessaire
      if (e.code == 'not-found') {
        debugLog("⚠️ [updateRecipient] Document destinataire ${recipient.id} non trouvé pour mise à jour.", level: 'WARN');
        // Optionnel: Gérer ce cas spécifiquement, peut-être ignorer ou logger différemment.
      }
      rethrow;
    } catch (e) {
      debugLog(
        "❌ [updateRecipient] Erreur inattendue lors de la mise à jour destinataire ${recipient.id} pour $currentUserId : $e",
        level: 'ERROR',
      );
      rethrow;
    }
  }

  // ✅ Supprimer un destinataire (pour l'utilisateur actuel)
  // L'id doit être l'UID de l'autre utilisateur
  Future<void> deleteRecipient(String recipientUserId) async {
    debugLog("🗑️ [deleteRecipient] Tentative de suppression du destinataire $recipientUserId pour l'utilisateur : $currentUserId");
    if (recipientUserId.isEmpty) {
      debugLog("⚠️ [deleteRecipient] UID destinataire vide. Suppression annulée.", level: 'WARN');
      // Optionnel: Lancer une exception ici.
      return;
    }
    try {
      // recipientUserId est l'UID de l'autre utilisateur
      await _recipientsRef.doc(recipientUserId).delete();
      debugLog("✅ [deleteRecipient] Destinataire $recipientUserId supprimé pour $currentUserId");
    } on FirebaseException catch (e) {
      debugLog(
        "❌ [deleteRecipient] Erreur Firebase lors de la suppression destinataire $recipientUserId pour $currentUserId : ${e.code} - ${e.message}",
        level: 'ERROR',
      );
      // Gérer l'erreur "document n'existe pas" si nécessaire
      if (e.code == 'not-found') {
        debugLog("⚠️ [deleteRecipient] Document destinataire $recipientUserId non trouvé pour suppression.", level: 'WARN');
        // Optionnel: Gérer ce cas spécifiquement.
      }
      rethrow;
    } catch (e) {
      debugLog(
        "❌ [deleteRecipient] Erreur inattendue lors de la suppression destinataire $recipientUserId pour $currentUserId : $e",
        level: 'ERROR',
      );
      rethrow;
    }
  }

  // TODO: Ajouter une méthode pour obtenir un stream des destinataires appairés (pour l'UI en temps réel)
  // Similaire à fetchRecipients mais utilisant .snapshots() au lieu de .get().
  // Cela serait la méthode préférée pour afficher la liste des destinataires dans une UI réactive.

  Stream<List<Recipient>> streamPairedRecipients() {
    debugLog("🔄 [streamPairedRecipients] Ouverture du flux des destinataires appairés pour l'UID : $currentUserId", level: 'INFO');
    return _recipientsRef
        .where('paired', isEqualTo: true)
    // Optionnel: ajouter orderBy
    // .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      debugLog("📩 [streamPairedRecipients] Réception de ${snapshot.docs.length} documents destinataires appairés pour $currentUserId", level: 'DEBUG');
      return snapshot.docs.map((doc) {
        return Recipient.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    })
        .handleError((e) {
      debugLog("❌ [streamPairedRecipients] Erreur lors de l'écoute des destinataires appairés pour UID $currentUserId : $e", level: 'ERROR');
      return <Recipient>[];
    });
  }

  // TODO: Ajouter une méthode pour obtenir UN destinataire spécifique par son UID (pour l'écran de détails par exemple)
  Future<Recipient?> getRecipient(String recipientUid) async {
    debugLog("🔄 [getRecipient] Tentative de chargement du destinataire $recipientUid pour l'UID : $currentUserId", level: 'INFO');
    if (recipientUid.isEmpty) {
      debugLog("⚠️ [getRecipient] UID destinataire vide. Chargement annulé.", level: 'WARN');
      return null;
    }
    try {
      final doc = await _recipientsRef.doc(recipientUid).get();

      if (doc.exists) {
        debugLog("✅ Destinataire $recipientUid trouvé pour l'UID $currentUserId");
        return Recipient.fromMap(doc.id, doc.data()! as Map<String, dynamic>);
      } else {
        debugLog("⚠️ Pas de document destinataire $recipientUid trouvé pour l'UID $currentUserId", level: 'WARNING');
        return null;
      }
    } on FirebaseException catch (e) {
      debugLog("❌ [getRecipient] Erreur Firebase lors du chargement destinataire $recipientUid pour l'UID $currentUserId : ${e.code} - ${e.message}", level: 'ERROR');
      rethrow;
    } catch (e) {
      debugLog("❌ [getRecipient] Erreur inattendue lors du chargement destinataire $recipientUid pour l'UID $currentUserId : $e", level: 'ERROR');
      rethrow;
    }
  }

}
