// -------------------------------------------------------------
// 📄 FICHIER : lib/services/firestore_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Fournit des méthodes pour interagir avec la base de données Cloud Firestore.
// ✅ Gère la sauvegarde et la récupération du profil utilisateur (collection 'users').
// ✅ Inclut des méthodes pour gérer les destinataires (collection 'recipients') et les messages (collection 'messages').
// ✅ Devient la couche d'abstraction unique pour toutes les opérations Firestore de l'application.
// ✅ Centralise la logique de lecture/écriture basée sur l'UID Firebase de l'utilisateur.
// ✅ Utilise les logs internes via DebugLog.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V005 - Validation par Gemini en Firebase - Code confirmé comme correctement structuré et refactorisé pour l'utilisation des UID au sein de la classe FirestoreService. Prêt à être utilisé par les appelants. - 2025/05/30
// V004 - Ajout des méthodes pairUsers, streamRecipients, getRecipient, sendMessage (ou suggestion d'appel si MessageService est séparé). Regroupement des fonctions dans une classe FirestoreService. Ajout de gestion d'erreurs. Utilisation cohérente de debugLog. - 2025/05/30
// V003 - Suppression de la fonction registerDevice basée sur deviceId. La logique de profil utilisateur est désormais exclusivement basée sur l'UID Firebase. - 2025/05/29 (Refactored)
// V002 - Ajout des fonctions saveUserProfile et getUserProfile pour interagir avec la collection users/{uid}. - 2025/05/21
// V001 - Création initiale du service Firestore. - 2025/05/?? (Date approximative si V002 est le premier ajout significatif)
// -------------------------------------------------------------

// GEM - Code validé par Gémini le 2025/05/30 // Mise à jour le 30/05

import '../utils/debug_log.dart'; // Utilise le logger
import 'package:cloud_firestore/cloud_firestore.dart'; // Import nécessaire pour interagir avec Firestore et types Firestore
import '../models/recipient.dart'; // Ajout pour les méthodes de gestion des destinataires (Recipients)
import '../models/message.dart';   // Ajout pour les méthodes de gestion des messages (Messages)
// L'import uuid peut être nécessaire si vous générez des IDs de messages ou autres ici.
// import 'package:uuid/uuid.dart'; // Optionnel selon l'implémentation des méthodes message/recipient

// Définition de la classe FirestoreService pour encapsuler toutes les méthodes d'interaction avec Firestore
class FirestoreService {
  // Instance de FirebaseFirestore utilisée par toutes les méthodes du service
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructeur (peut être vide si l'instance _firestore est initialisée directement)
  FirestoreService();


  // L'ancienne fonction registerDevice, basée sur deviceId, n'est plus nécessaire
  // dans un modèle basé sur l'utilisateur authentifié (UID Firebase).
  // Les informations comme isReceiver devraient être stockées sous l'UID de l'utilisateur.
  // Si 'isReceiver' est une propriété de l'utilisateur et non de l'appareil,
  // on peut ajouter un champ 'isReceiver' au document users/{uid} ou créer une fonction ici pour le gérer.
  // Pour l'instant, on la supprime. Si besoin, on la réintroduira ailleurs (probablement dans saveUserProfile ou en paramètre du profil).
  /*
  // ajouté le 08/04/2025 pour la sauvegarde dans Firebase du deviceId et de son rôle
  Future<void> registerDevice(String deviceId, bool isReceiver) async {
    // ... code obsolète ...
  }
  */ // <-- Fonction registerDevice commentée/supprimée car obsolète

  // -------------------------------------------------------------------------
  // ✅ Méthodes de gestion du Profil Utilisateur (users/{uid})
  // -------------------------------------------------------------------------

  // ajouté le 21/05/2025 pour sauvegarder le prénom et l'email dans Firestore > users/{uid}
  // Cette fonction est basée sur l'UID et est conservée. Elle fait maintenant partie de la classe.
  Future<void> saveUserProfile({
    required String uid,
    required String email, // L'email est souvent géré par Firebase Auth, peut-être pas nécessaire de le sauvegarder ici si Auth est la source de vérité ?
    required String firstName,
    // On pourrait ajouter des champs ici comme 'isReceiver' ou 'lastSeen'
    // si ces informations doivent être stockées au niveau de l'utilisateur.
    // Exemple: bool? isReceiver, DateTime? lastSeen
    // bool? isReceiver, // Exemple: si vous stockez 'isReceiver' par utilisateur
    // DateTime? lastSeen, // Exemple: pour le statut en ligne/hors ligne
  }) async {
    debugLog("🔄 [FirestoreService - saveUserProfile] Tentative de sauvegarde du profil pour l'UID : $uid", level: 'INFO');
    try {
      // Obtient une référence au document utilisateur
      DocumentReference userDocRef = _firestore.collection('users').doc(uid);

      // Prépare les données à sauvegarder (utilise toMap si vous avez un modèle User)
      Map<String, dynamic> dataToSave = {
        'email': email, // Note: S'assurer que la politique de données autorise la sauvegarde de l'email dans Firestore
        'firstName': firstName,
        // Ajouter ici 'isReceiver': isReceiver, si le champ est ajouté en paramètre
        'lastSeen': FieldValue.serverTimestamp(), // Exemple: mise à jour du 'lastSeen' à chaque sauvegarde/connexion
      };
      // Ajouter d'autres champs optionnels si passés en paramètre
      // if (isReceiver != null) dataToSave['isReceiver'] = isReceiver;

      // Utilise set avec merge: true pour ne pas écraser d'autres champs existants (comme la sous-collection recipients)
      // et pour créer le document s'il n'existe pas encore.
      await userDocRef.set(dataToSave, SetOptions(merge: true));

      debugLog(
        '✅ [FirestoreService - saveUserProfile] Profil utilisateur enregistré pour UID: $uid ($firstName)',
        level: 'SUCCESS',
      );
    } on FirebaseException catch (e) { // Utilise FirebaseException pour une gestion plus spécifique
      debugLog(
        '❌ [FirestoreService - saveUserProfile] Erreur Firebase lors de la sauvegarde de l\'UID $uid : ${e.code} - ${e.message}',
        level: 'ERROR',
      );
      rethrow; // Rethrow l'exception pour gestion par l'appelant (ex: afficher une SnackBar)
    } catch (e) {
      debugLog(
        '❌ [FirestoreService - saveUserProfile] Erreur inattendue lors de la sauvegarde de l\'UID $uid : $e',
        level: 'ERROR',
      );
      rethrow; // Rethrow l'exception
    }
  }

  // ajouté le 21/05/2025 pour récupérer les données utilisateur depuis Firestore > users/{uid}
  // Cette fonction est basée sur l'UID et est conservée. Elle fait maintenant partie de la classe.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    debugLog("🔄 [FirestoreService - getUserProfile] Tentative de chargement du profil pour l'UID : $uid", level: 'INFO');
    try {
      // Lit les données depuis la collection 'users', document identifié par l'UID
      //final doc = await _firestore.collection('users').doc(uid).get();
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection('users').doc(uid).get();


      // Vérifie si le document existe
      if (doc.exists) {
        debugLog("✅ [FirestoreService - getUserProfile] Profil trouvé pour l'UID $uid");
        // Retourne les données (casté en Map<String, dynamic> si nécessaire, doc.data() est déjà Map<String, dynamic>?)
        return doc.data();
      } else {
        // Le document n'existe pas encore (ex: après inscription avant la première sauvegarde)
        debugLog("⚠️ [FirestoreService - getUserProfile] Pas de document profil trouvé pour l'UID $uid", level: 'WARNING');
        return null; // Retourne null pour indiquer que le profil n'existe pas
      }
    } on FirebaseException catch (e) { // Utilise FirebaseException
      debugLog(
        '❌ [FirestoreService - getUserProfile] Erreur Firebase lors de la lecture pour l\'UID $uid : ${e.code} - ${e.message}',
        level: 'ERROR',
      );
      rethrow; // Rethrow l'exception
    } catch (e) {
      debugLog(
        '❌ [FirestoreService - getUserProfile] Erreur inattendue lors de la lecture pour l\'UID $uid : $e',
        level: 'ERROR',
      );
      rethrow;
    }
  }

  // TODO: Ajouter une méthode pour mettre à jour des champs spécifiques du profil utilisateur si nécessaire.
  // Ex: updateProfileFields({required String uid, String? firstName, bool? isReceiver, ...})
  Future<void> updateUserProfileFields({
    required String uid,
    String? firstName,
    bool? isReceiver,
    // Ajouter d'autres champs potentiels ici
  }) async {
    debugLog("🔄 [FirestoreService - updateUserProfileFields] Tentative de mise à jour de champs pour l'UID : $uid", level: 'INFO');
    if (firstName == null && isReceiver == null) {
      debugLog("ℹ️ [FirestoreService - updateUserProfileFields] Aucun champ à mettre à jour pour l'UID : $uid", level: 'INFO');
      return; // Ne rien faire si aucun champ n'est fourni
    }
    try {
      DocumentReference userDocRef = _firestore.collection('users').doc(uid);
      Map<String, dynamic> updates = {};
      if (firstName != null) updates['firstName'] = firstName;
      if (isReceiver != null) updates['isReceiver'] = isReceiver;
      // Ajouter d'autres champs à mettre à jour ici

      await userDocRef.update(updates); // Utilise update() car le document doit exister pour mettre à jour des champs spécifiques

      debugLog("✅ [FirestoreService - updateUserProfileFields] Champs mis à jour avec succès pour UID: $uid", level: 'SUCCESS');

    } on FirebaseException catch (e) {
      debugLog(
        '❌ [FirestoreService - updateUserProfileFields] Erreur Firebase lors de la mise à jour pour l\'UID $uid : ${e.code} - ${e.message}',
        level: 'ERROR',
      );
      // Gérer l'erreur 'not-found' si le document utilisateur n'existe pas
      if (e.code == 'not-found') {
        debugLog("⚠️ [FirestoreService - updateUserProfileFields] Document utilisateur $uid non trouvé pour mise à jour. Utiliser saveUserProfile avec merge: true si le document peut manquer.", level: 'WARN');
      }
      rethrow;
    } catch (e) {
      debugLog(
        '❌ [FirestoreService - updateUserProfileFields] Erreur inattendue lors de la mise à jour pour l\'UID $uid : $e',
        level: 'ERROR',
      );
      rethrow;
    }
  }


  // -------------------------------------------------------------------------
  // ✅ Méthodes de gestion des Destinataires (Recipients) - Centralisation depuis RecipientService si souhaité
  // Ces méthodes interagiront avec la sous-collection users/{userId}/recipients/{otherUserId}
  // Note : Ces méthodes pourraient aussi rester dans RecipientService si vous préférez cette structure.
  // Si vous les déplacez ici, RecipientService pourrait devenir un service plus léger,
  // ou simplement ne plus exister si toute sa logique est dans FirestoreService.
  // Pour l'exemple, je montre comment elles pourraient être ici, en utilisant l'UID de l'utilisateur appelant.
  // -------------------------------------------------------------------------

  // Ajout: Méthode pour appairer deux utilisateurs
  // Cette implémentation est similaire à _pairUsers dans main.dart mais fait partie du service.
  // Elle doit être appelée avec les UID des deux utilisateurs.
  Future<void> pairUsers({required String userAId, required String userBId}) async {
    debugLog("🔄 [FirestoreService - pairUsers] Tentative d'appairage entre UID $userAId et UID $userBId", level: 'INFO');
    if (userAId.isEmpty || userBId.isEmpty || userAId == userBId) {
      debugLog("⚠️ [FirestoreService - pairUsers] Appairage tenté avec UID(s) invalide(s) ou auto-appairage. Annulé.", level: 'WARN');
      // Lancer une erreur ou retourner false si vous voulez indiquer un échec.
      throw ArgumentError("Invalid user IDs for pairing.");
    }
    try {
      // Récupérer les noms d'affichage des deux utilisateurs pour les mettre dans les objets Recipient
      // Utilise getUserProfile de CE service pour la cohérence.
      final userAProfile = await getUserProfile(userAId); // Récupérer le profil de A
      final userBProfile = await getUserProfile(userBId); // Récupérer le profil de B

      // Utilise le prénom (firstName) ou un nom par défaut si le profil n'existe pas ou le champ manque
      final userADisplayName = (userAProfile?['firstName'] as String?) ?? 'Utilisateur A';
      final userBDisplayName = (userBProfile?['firstName'] as String?) ?? 'Utilisateur B';

      debugLog("🧑‍🦱 [FirestoreService - pairUsers] Noms pour appairage: A='$userADisplayName' ($userAId), B='$userBDisplayName' ($userBId)", level: 'DEBUG');

      // Utilise un batch pour s'assurer que les deux écritures réussissent ou échouent ensemble (transaction atomique légère)
      WriteBatch batch = _firestore.batch();

      // 1. Ajouter l'utilisateur B comme destinataire chez l'utilisateur A
      // Chemin : users/{userAId}/recipients/{userBId}
      DocumentReference recipientADocRef = _firestore
          .collection('users')
          .doc(userAId)
          .collection('recipients')
          .doc(userBId); // ID du document est l'UID de l'autre utilisateur (userBId)

      // Prépare les données pour le document Recipient chez A
      batch.set(recipientADocRef, {
        'id': userBId, // Inclure l'UID aussi comme champ pour faciliter les requêtes futures si besoin
        'displayName': userBDisplayName, // Le nom de l'utilisateur B vu par A
        'icon': '💌', // Icône par défaut - TODO: Permettre de définir l'icône
        'relation': 'relation_partner', // Relation par défaut - TODO: Utiliser une clé i18n ou un enum
        'allowedPacks': [], // Packs par défaut - TODO: Définir les packs initiaux
        'paired': true, // Marqué comme appairé
        'catalogType': 'partner', // Type de catalogue par défaut - TODO: Utiliser un enum
        'createdAt': FieldValue.serverTimestamp(), // Horodatage de création
        // Ajouter lastMessageText, lastMessageTimestamp pour la liste des conversations ?
        // 'lastMessageText': '',
        // 'lastMessageTimestamp': null,
      }, SetOptions(merge: true)); // Utilise merge pour ne pas écraser d'autres champs si le doc existe déjà (ex: si les conversations sont déjà créées)

      // 2. Ajouter l'utilisateur A comme destinataire chez l'utilisateur B
      // Chemin : users/{userBId}/recipients/{userAId}
      DocumentReference recipientBDocRef = _firestore
          .collection('users')
          .doc(userBId)
          .collection('recipients')
          .doc(userAId); // ID du document est l'UID de l'autre utilisateur (userAId)

      // Prépare les données pour le document Recipient chez B
      batch.set(recipientBDocRef, {
          'id': userAId, // Inclure l'UID aussi comme champ
          'displayName': userADisplayName, // Le nom de l'utilisateur A vu par B
          'icon': '💌', // Icône par défaut - TODO: Permettre de définir l'icône
        'relation': 'relation_partner', // Relation par défaut - TODO: Utiliser une clé i18n ou un enum
        'allowedPacks': [], // Packs par défaut - TODO: Définir les packs initiaux
        'paired': true, // Marqué comme appairé
        'catalogType': 'partner', // Type de catalogue par défaut - TODO: Utiliser un enum
        'createdAt': FieldValue.serverTimestamp(), // Horodatage de création
        // Ajouter lastMessageText, lastMessageTimestamp pour la liste des conversations ?
        // 'lastMessageText': '',
        // 'lastMessageTimestamp': null,
      }, SetOptions(merge: true)); // Utilise merge pour ne pas écraser d'autres champs si le doc existe déjà


      // Exécute le batch d'écritures de manière atomique
      await batch.commit();

      debugLog("✅ [FirestoreService - pairUsers] Appairage Firestore réussi entre UID $userAId et UID $userBId", level: 'SUCCESS');
      // Optionnel: Retourner l'UID de l'autre utilisateur ou un indicateur de succès.
      // return userAId;
    } on FirebaseException catch (e) {
      debugLog("❌ [FirestoreService - pairUsers] Erreur Firebase lors de l'appairage entre $userAId et $userBId : ${e.code} - ${e.message}", level: 'ERROR');
      rethrow; // Rethrow l'exception pour gestion par l'appelant
    } catch (e) {
      debugLog("❌ [FirestoreService - pairUsers] Erreur inattendue lors de l'appairage entre $userAId et $userBId : $e", level: 'ERROR');
      rethrow; // Rethrow l'exception
    }
  }

  // Ajout: Méthode pour obtenir un stream de la liste des destinataires pour un utilisateur donné (l'utilisateur appelant le service)
  // Écoutera la sous-collection users/{userId}/recipients
  // Cette méthode est déplacée ici depuis RecipientService (ou RecipientService l'appellera).
  Stream<List<Recipient>> streamRecipients(String userId) {
    debugLog("🔄 [FirestoreService - streamRecipients] Écoute de la collection recipients pour l'UID : $userId", level: 'INFO');
    if (userId.isEmpty) {
      debugLog("⚠️ [FirestoreService - streamRecipients] UID utilisateur vide. Écoute annulée.", level: 'WARN');
      // Retourne un stream vide en cas d'UID invalide
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recipients')
    // Optionnel: ajouter orderBy si vous voulez trier les destinataires dans l'UI
    // .orderBy('displayName') // Assurez-vous d'avoir un index Firestore pour ce champ
        .snapshots() // Obtient le stream de QuerySnapshot (mises à jour en temps réel)
        .map((snapshot) { // Transforme le stream de QuerySnapshot en stream de List<Recipient>
      debugLog("📩 [FirestoreService - streamRecipients] Réception de ${snapshot.docs.length} documents recipients pour $userId", level: 'DEBUG');
      // Transforme chaque DocumentSnapshot en objet Recipient en utilisant la factory fromMap du modèle
      return snapshot.docs.map((doc) {
        // doc.id est l'ID du document (qui est l'UID du destinataire dans notre structure)
        // doc.data() retourne la Map des champs
        // return Recipient.fromMap(doc.id, doc.data() as Map<String, dynamic>); // Cast sécurisé
        return Recipient.fromMap(doc.id, doc.data());
      }).toList(); // Convertit le résultat en List<Recipient>
    })
        .handleError((e) { // Gère les erreurs qui peuvent survenir sur le stream
      debugLog("❌ [FirestoreService - streamRecipients] Erreur lors de l'écoute des destinataires pour UID $userId : $e", level: 'ERROR');
      // En cas d'erreur, on peut émettre une liste vide pour ne pas faire planter l'UI,
      // mais le log d'erreur alerte le développeur.
      // Re-lancer l'erreur est aussi une option si l'UI doit gérer explicitement l'échec du stream.
      // throw e; // Optionnel: relancer l'erreur
      return <Recipient>[]; // Émet une liste vide en cas d'erreur
    });
  }

  // Ajout: Méthode pour obtenir UN destinataire spécifique par son UID pour un utilisateur donné (l'utilisateur appelant le service)
  // Utile pour afficher les détails d'un destinataire (ex: dans EditRecipientScreen ou RecipientDetailsScreen si besoin de recharger les données).
  Future<Recipient?> getRecipient({required String userId, required String recipientId}) async {
    debugLog("🔄 [FirestoreService - getRecipient] Tentative de chargement du destinataire $recipientId pour l'UID : $userId", level: 'INFO');
    if (userId.isEmpty || recipientId.isEmpty) {
      debugLog("⚠️ [FirestoreService - getRecipient] UID utilisateur ou destinataire vide. Chargement annulé.", level: 'WARN');
      return null;
    }
    try {
      // Obtient une référence au document spécifique du destinataire
      final doc = await _firestore
          .collection('users')
          .doc(userId) // UID de l'utilisateur actuel
          .collection('recipients')
          .doc(recipientId) // UID du destinataire
          .get(); // Récupère le document

      // Vérifie si le document existe
      if (doc.exists) {
        debugLog("✅ [FirestoreService - getRecipient] Destinataire $recipientId trouvé pour l'UID $userId");
        // Utilise la factory fromMap du modèle Recipient
        return Recipient.fromMap(doc.id, doc.data()!); // doc.data()! est sûr car doc.exists est vrai
      } else {
        debugLog("⚠️ [FirestoreService - getRecipient] Pas de document destinataire $recipientId trouvé pour l'UID $userId", level: 'WARNING');
        return null; // Retourne null si le document n'existe pas
      }
    } on FirebaseException catch (e) { // Gère les erreurs spécifiques à Firebase
      debugLog("❌ [FirestoreService - getRecipient] Erreur Firebase lors du chargement destinataire $recipientId pour l'UID $userId : ${e.code} - ${e.message}", level: 'ERROR');
      rethrow; // Rethrow l'exception
    } catch (e) { // Gère toute autre erreur inattendue
      debugLog("❌ [FirestoreService - getRecipient] Erreur inattendue lors du chargement destinataire $recipientId pour l'UID $userId : $e", level: 'ERROR');
      rethrow;
    }
  }

  // Ajout: Méthode pour mettre à jour les données d'un destinataire spécifique (pour l'utilisateur appelant)
  // Utile pour sauvegarder les modifications faites dans EditRecipientScreen.
  Future<void> updateRecipient({required String userId, required Recipient recipient}) async {
    debugLog("📝 [FirestoreService - updateRecipient] Tentative de mise à jour du destinataire ${recipient.id} pour l'UID : $userId", level: 'INFO');
    if (userId.isEmpty || recipient.id.isEmpty) {
      debugLog("⚠️ [FirestoreService - updateRecipient] UID utilisateur ou destinataire vide. Mise à jour annulée.", level: 'WARN');
      throw ArgumentError("Invalid user or recipient ID for update."); // Lancer une erreur
    }
    try {
      // Obtient une référence au document spécifique du destinataire
      DocumentReference recipientDocRef = _firestore
          .collection('users')
          .doc(userId) // UID de l'utilisateur actuel
          .collection('recipients')
          .doc(recipient.id); // UID du destinataire

      // Utilise update() pour modifier les champs. update() échoue si le document n'existe pas.
      // Si vous voulez créer/mettre à jour (upsert), utilisez set(..., merge: true).
      // Ici, update est approprié car le destinataire est censé exister après l'appairage.
      await recipientDocRef.update(recipient.toMap()); // Utilise toMap() du modèle Recipient

      debugLog("✅ [FirestoreService - updateRecipient] Destinataire ${recipient.id} mis à jour avec succès pour l'UID $userId.", level: 'SUCCESS');

      // TODO: Optionnel : Si vous voulez que le nom/icône/relation change aussi chez l'autre utilisateur (vue miroir),
      // implémentez ici la logique de mise à jour bidirectionnelle pour les champs pertinents.
      // Cela nécessiterait une écriture similaire dans le document users/{recipient.id}/recipients/{userId}.
      /*
            // Exemple de mise à jour bidirectionnelle du nom (displayName)
             DocumentReference otherUserRecipientDocRef = _firestore
                 .collection('users').doc(recipient.id) // UID du destinataire
                 .collection('recipients').doc(userId); // UID de l'utilisateur actuel dans sa liste
             await otherUserRecipientDocRef.update({
                 'displayName': recipient.displayName, // Mettre à jour le nom chez l'autre utilisateur
                 // Ajouter d'autres champs comme 'icon', 'relation' si vous voulez les synchroniser aussi
             });
             debugLog("✅ [FirestoreService - updateRecipient] Nom/champs mis à jour dans la collection miroir chez UID ${recipient.id}");
            */

    } on FirebaseException catch (e) { // Gère les erreurs spécifiques à Firebase
      debugLog(
        '❌ [FirestoreService - updateRecipient] Erreur Firebase lors de la mise à jour destinataire ${recipient.id} pour l\'UID $userId : ${e.code} - ${e.message}',
        level: 'ERROR',
      );
      // Gérer l'erreur 'not-found' si le document destinataire n'existe pas (ex: supprimé par l'autre utilisateur)
      if (e.code == 'not-found') {
        debugLog("⚠️ [FirestoreService - updateRecipient] Document destinataire ${recipient.id} non trouvé pour mise à jour pour l'UID $userId.", level: 'WARN');
        // Peut-être lancer une erreur spécifique ou retourner false si l'appelant doit savoir que le document n'existe plus.
      }
      rethrow; // Rethrow l'exception
    } catch (e) { // Gère toute autre erreur inattendue
      debugLog(
        '❌ [FirestoreService - updateRecipient] Erreur inattendue lors de la mise à jour destinataire ${recipient.id} pour l\'UID $userId : $e',
        level: 'ERROR',
      );
      rethrow;
    }
  }


  // Ajout: Méthode pour supprimer un destinataire spécifique (pour l'utilisateur appelant)
  // Utile pour supprimer un destinataire dans EditRecipientScreen ou RecipientsScreen.
  Future<void> deleteRecipient({required String userId, required String recipientId}) async {
    debugLog("🗑️ [FirestoreService - deleteRecipient] Tentative de suppression du destinataire $recipientId pour l'UID : $userId", level: 'INFO');
    if (userId.isEmpty || recipientId.isEmpty) {
      debugLog("⚠️ [FirestoreService - deleteRecipient] UID utilisateur ou destinataire vide. Suppression annulée.", level: 'WARN');
      throw ArgumentError("Invalid user or recipient ID for deletion."); // Lancer une erreur
    }
    try {
      // Obtient une référence au document spécifique du destinataire
      DocumentReference recipientDocRef = _firestore
          .collection('users')
          .doc(userId) // UID de l'utilisateur actuel
          .collection('recipients')
          .doc(recipientId); // UID du destinataire

      await recipientDocRef.delete(); // Supprime le document

      debugLog("✅ [FirestoreService - deleteRecipient] Destinataire $recipientId supprimé avec succès pour l'UID $userId.", level: 'SUCCESS');

      // TODO: Optionnel : Si vous voulez également supprimer le document miroir chez l'autre utilisateur,
      // ou marquer l'appairage comme rompu chez les deux, implémentez ici la logique bidirectionnelle.
      // Une simple suppression unilatérale peut laisser l'autre utilisateur avec un destinataire "fantôme"
      // jusqu'à ce qu'il tente d'envoyer un message ou que son UI gère le cas d'un destinataire non valide.
      // Marquer 'paired: false' chez les deux est souvent une meilleure approche pour rompre l'appairage proprement.
      /*
            // Exemple pour marquer l'appairage comme false chez l'autre utilisateur
             DocumentReference otherUserRecipientDocRef = _firestore
                 .collection('users').doc(recipientId) // UID du destinataire
                 .collection('recipients').doc(userId); // UID de l'utilisateur actuel dans sa liste
             await otherUserRecipientDocRef.set({'paired': false}, SetOptions(merge: true)); // Utilise set avec merge pour ne pas écraser d'autres champs
             debugLog("✅ [FirestoreService - deleteRecipient] Appairage marqué comme rompu dans la collection miroir chez UID ${recipientId}");
             */

    } on FirebaseException catch (e) { // Gère les erreurs spécifiques à Firebase
      debugLog(
        '❌ [FirestoreService - deleteRecipient] Erreur Firebase lors de la suppression destinataire $recipientId pour l\'UID $userId : ${e.code} - ${e.message}',
        level: 'ERROR',
      );
      // Gérer l'erreur 'not-found' si le document n'existe pas (déjà supprimé)
      if (e.code == 'not-found') {
        debugLog("⚠️ [FirestoreService - deleteRecipient] Document destinataire $recipientId non trouvé pour suppression pour l'UID $userId.", level: 'WARN');
        // Peut-être ignorer cette erreur ou la logger différemment.
      }
      rethrow; // Rethrow l'exception
    } catch (e) { // Gère toute autre erreur inattendue
      debugLog(
        '❌ [FirestoreService - deleteRecipient] Erreur inattendue lors de la suppression destinataire $recipientId pour l\'UID $userId : $e',
        level: 'ERROR',
      );
      rethrow;
    }
  }


  // -------------------------------------------------------------------------
  // ✅ Méthodes de gestion des Messages - Centralisation depuis MessageService si souhaité
  // Ces méthodes interagiront avec la sous-collection users/{userId}/recipients/{otherUserId}/messages
  // Note : Ces méthodes pourraient aussi rester dans MessageService si vous préférez cette structure.
  // Si vous les déplacez ici, MessageService pourrait devenir un service plus léger.
  // Pour l'exemple, je montre comment sendMessage pourrait être ici.
  // La méthode streamMessages de MessageService peut aussi être déplacée ici ou rester là et appeler ce service.
  // -------------------------------------------------------------------------

  // Ajout: Méthode pour envoyer un message
  // Cette logique est déplacée ici depuis MessageService.sendMessage.
  // Elle prend l'UID de l'expéditeur, l'UID du destinataire, et l'objet Message.
  Future<void> sendMessage({required String senderUid, required String recipientUid, required Message message}) async {
    debugLog("🔄 [FirestoreService - sendMessage] Tentative d'envoi de message de $senderUid à $recipientUid", level: 'INFO');
    if (senderUid.isEmpty || recipientUid.isEmpty) {
      debugLog("⚠️ [FirestoreService - sendMessage] UID expéditeur ou destinataire vide. Envoi annulé.", level: 'WARN');
      throw ArgumentError("Invalid sender or recipient ID for message sending.");
    }
    // Assurez-vous que message.from et message.to correspondent à senderUid et recipientUid si vous voulez garantir la cohérence
    // if (message.from != senderUid || message.to != recipientUid) {
    //    debugLog("⚠️ [FirestoreService - sendMessage] Incohérence entre UIDs du message et paramètres.", level: 'WARN');
    //    // Optionnel: Lancer une erreur ou corriger les UIDs du message.
    // }

    try {
      // Utilise un WriteBatch pour s'assurer que les deux écritures sont atomiques (expéditeur et destinataire)
      WriteBatch batch = _firestore.batch();

      final data = message.toMap(); // Utilise toMap() du modèle Message (qui inclut from/to/content/sentAt)

      // 1. Écrit le message dans la conversation de l'utilisateur actuel (expéditeur)
      DocumentReference senderMessageDocRef = _firestore
          .collection('users').doc(senderUid)
          .collection('recipients').doc(recipientUid) // Sous-collection du destinataire
          .collection('messages').doc(message.id); // Document du message (utilise l'ID généré par le modèle)

      batch.set(senderMessageDocRef, data); // Utilise set()

      // 2. Écrit le message dans la conversation miroir chez le destinataire
      DocumentReference recipientMessageDocRef = _firestore
          .collection('users').doc(recipientUid) // UID du destinataire
          .collection('recipients').doc(senderUid) // Sous-collection de l'expéditeur dans sa liste de destinataires
          .collection('messages').doc(message.id); // Document du message (utilise le MÊME ID)

      batch.set(recipientMessageDocRef, data); // Utilise set()

      // TODO: Optionnel : Mettre à jour un champ "lastMessageTimestamp" ou "lastMessageText"
      // dans les documents Recipient des deux utilisateurs pour faciliter l'affichage de la liste de conversations.
      // Cela nécessiterait également d'ajouter ces mises à jour au batch.
      /*
       // Mettre à jour le dernier message chez l'expéditeur
       DocumentReference senderRecipientDocRef = _firestore
           .collection('users').doc(senderUid)
           .collection('recipients').doc(recipientUid);
       batch.update(senderRecipientDocRef, {
           'lastMessageTimestamp': message.sentAt,
           'lastMessageText': message.content, // Ou un aperçu du message
           // Vous pouvez aussi ajouter un champ 'unreadCount' et l'incrémenter chez le destinataire
       });

       // Mettre à jour le dernier message chez le destinataire (pour sa vue)
        DocumentReference recipientRecipientDocRef = _firestore
           .collection('users').doc(recipientUid)
           .collection('recipients').doc(senderUid);
       batch.update(recipientRecipientDocRef, {
           'lastMessageTimestamp': message.sentAt,
           'lastMessageText': message.content, // Ou un aperçu du message
           // Ici, incrémenter 'unreadCount'
           // 'unreadCount': FieldValue.increment(1), // Nécessite que le champ existe et soit un nombre
       });
       */


      // Exécute le batch d'écritures de manière atomique (message + potentiellement les mises à jour de lastMessage)
      await batch.commit();

      debugLog("✅ [FirestoreService - sendMessage] Message ${message.id} envoyé avec succès de $senderUid à $recipientUid (écriture atomique)", level: 'SUCCESS');

    } on FirebaseException catch (e) { // Gère les erreurs spécifiques à Firebase
      debugLog(
        "❌ [FirestoreService - sendMessage] Erreur Firebase lors de l'envoi de message ${message.id} : ${e.code} - ${e.message}",
        level: 'ERROR',
      );
      rethrow; // Rethrow l'exception pour gestion par l'appelant
    } catch (e) { // Gère toute autre erreur inattendue
      debugLog(
        "❌ [FirestoreService - sendMessage] Erreur inattendue lors de l'envoi de message ${message.id} : $e",
        level: 'ERROR',
      );
      rethrow;
    }
  }

// TODO: Ajouter des méthodes pour marquer les messages comme "reçus" (receivedAt) et "vus" (seenAt)
// Ces méthodes devraient également mettre à jour les documents messages dans les collections
// des deux utilisateurs de manière atomique si possible (via WriteBatch).
// Elles prendraient le message.id, l'UID de l'utilisateur qui marque comme reçu/vu,
// et l'UID de l'autre utilisateur dans la conversation.
/*
  Future<void> markMessageAsReceived({required String userId, required String otherUserId, required String messageId}) async {
      // Similaire à sendMessage, utiliser un batch pour mettre à jour les champs receivedAt
      // dans users/{userId}/recipients/{otherUserId}/messages/{messageId}
      // et users/{otherUserId}/recipients/{userId}/messages/{messageId}.
      // Mettre à jour seulement si receivedAt est null.
      debugLog("🔄 [FirestoreService] Marquage message $messageId comme reçu par UID $userId dans conversation avec $otherUserId", level: 'INFO');
      // ... implémentation ...
  }

   Future<void> markMessageAsSeen({required String userId, required String otherUserId, required String messageId}) async {
      // Similaire à markMessageAsReceived, utiliser un batch pour mettre à jour seenAt.
      // Mettre à jour seulement si seenAt est null.
       debugLog("🔄 [FirestoreService] Marquage message $messageId comme vu par UID $userId dans conversation avec $otherUserId", level: 'INFO');
       // ... implémentation ...
       // Optionnel: Réinitialiser un champ 'unreadCount' dans le document recipient de l'utilisateur qui marque comme vu.
   }
  */


// TODO: Ajouter une méthode pour supprimer UN message spécifique (pour l'utilisateur appelant, et potentiellement en miroir chez l'autre)
/*
   Future<void> deleteMessage({required String userId, required String otherUserId, required String messageId}) async {
      debugLog("🗑️ [FirestoreService] Suppression message $messageId par UID $userId dans conversation avec $otherUserId", level: 'INFO');
      // Utiliser un batch pour supprimer le document message dans les collections des deux utilisateurs.
      // ... implémentation ...
   }
   */

} // <-- Fin de la classe FirestoreService et de la classe FirestoreService
