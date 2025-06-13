// -------------------------------------------------------------
// 📄 FICHIER : lib/services/pairing_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Créer une relation d’appairage bilatérale dans Firestore
// ✅ Supprimer la relation d’appairage bilatérale dans Firestore
// ✅ Vérifier si deux utilisateurs sont appairés dans Firestore
// ✅ Récupérer les données d’un partenaire appairé depuis Firestore
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V003 - Correction chemins Firestore, restauration getRecipientData, amélioration pairUsers pour enregistrer données complètes Recipient. - 2025/06/14 18h00 (À remplir)
// V002 - Correction des chemins Firestore pour cohérence avec l’app - 2025/06/13 17h12
// V001 - Création initiale du squelette PairingService - 2025/06/13 15h24
// -------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get_it/get_it.dart'; // Pas utilisé pour le moment, les accès se font directement ici.
// import 'firestore_service.dart'; // Pas utilisé pour le moment.
import 'package:jelamvp01/models/recipient.dart'; // Importe le modèle Recipient
import 'package:jelamvp01/utils/debug_log.dart'; // Importe l'utilitaire de log

class PairingService {
  // Accès direct à l'instance Firestore. Ce service agit comme une couche basse
  // pour les documents de relation d'appairage spécifiquement.
  // À l'avenir, si FirestoreService englobe TOUT, cela pourrait être revu (Étape 3/5).
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NOTE sur FirestoreService injection : L'injection a été retirée car ce service
  // utilise directement FirebaseFirestore.instance. Pour l'instant, PairingService
  // est la couche "basse" pour la gestion des *documents de relation réciproque*.
  // L'Étape 3/5 de la roadmap prévoit de centraliser TOUS les accès bas niveau via FirestoreService.
  // Il faudrait alors que PairingService utilise FirestoreService.get/set/delete/batch
  // au lieu de _firestore.collection(...).
  // Pour l'instant, la priorité est de rendre CE service fonctionnel et correct dans ses chemins.
  // final FirestoreService _firestoreService = GetIt.I<FirestoreService>();


  // =============================================================
  // ❤️ APPAIRAGE — Créer une relation bilatérale
  // =============================================================
  /// 🔗 Crée ou met à jour la relation d'appairage bilatérale dans Firestore.
  /// userAId est l'UID de l'utilisateur qui initie ou accepte l'appairage (l'utilisateur courant).
  /// userBId est l'UID de l'autre utilisateur (le partenaire).
  /// La fonction récupère les noms d'affichage depuis les documents utilisateurs respectifs
  /// et les enregistre dans les documents recipients de chaque côté.
  Future<void> pairUsers(String userAId, String userBId) async {
    if (userAId.isEmpty || userBId.isEmpty || userAId == userBId) {
      debugLog("⚠️ [PairingService] Appairage tenté avec UID(s) invalide(s) ou auto-appairage.", level: 'WARN');
      return; // Ne rien faire si UIDs invalides ou identiques
    }

    try {
      final batch = _firestore.batch();

      // Chemins corrects :
      // On va chercher les documents utilisateurs pour récupérer les noms
      final userASnap = await _firestore.collection('users').doc(userAId).get();
      final userADisplayName = userASnap.exists ? (userASnap.data()?['firstName'] ?? 'Utilisateur A') : 'Utilisateur A'; // Nom de userA pour userB
      debugLog("✅ [PairingService] Nom d'affichage User A ($userAId) : $userADisplayName", level: 'DEBUG');

      final userBSnap = await _firestore.collection('users').doc(userBId).get();
      final userBDisplayName = userBSnap.exists ? (userBSnap.data()?['firstName'] ?? 'Utilisateur B') : 'Utilisateur B'; // Nom de userB pour userA
      debugLog("✅ [PairingService] Nom d'affichage User B ($userBId) : $userBDisplayName", level: 'DEBUG');


      // 1. Ajouter/Mettre à jour le document destinataire chez l'utilisateur A pour userB
      // Chemin : users/{userAId}/recipients/{userBId}
      final recipientAtoBRef = _firestore
          .collection('users')
          .doc(userAId)
          .collection('recipients')
          .doc(userBId); // ID du document est l'UID de l'autre utilisateur (userB)

      batch.set(recipientAtoBRef, {
        'id': userBId, // L'UID du partenaire (userB)
        'displayName': userBDisplayName, // Le nom de userB vu par userA
        // TODO: Ces champs doivent être cohérents avec ton modèle Recipient et potentiellement gérés ailleurs (ex: par userA)
        'icon': '💌', // Icône par défaut - Peut-être chargée depuis un profil public ou gérée par l'utilisateur
        'relation': 'relation_partner', // Relation par défaut
        'allowedPacks': [], // Packs par défaut
        'paired': true, // Marqué comme appairé
        'catalogType': 'partner', // Type de catalogue par défaut
        'createdAt': FieldValue.serverTimestamp(), // Horodatage de création ou de mise à jour (pour la première fois)
        // On utilise SetOptions(merge: true) pour ne pas écraser d'autres champs potentiellement existants (ex: modifiés par l'utilisateur)
      }, SetOptions(merge: true));
      debugLog("✅ [PairingService] Préparation batch: document recipient A->B ($userAId -> $userBId)", level: 'DEBUG');


      // 2. Ajouter/Mettre à jour le document destinataire chez l'utilisateur B pour userA
      // Chemin : users/{userBId}/recipients/{userAId}
      final recipientBtoARef = _firestore
          .collection('users')
          .doc(userBId)
          .collection('recipients')
          .doc(userAId); // ID du document est l'UID de l'autre utilisateur (userA)

      batch.set(recipientBtoARef, {
        'id': userAId, // L'UID du partenaire (userA)
        'displayName': userADisplayName, // Le nom de userA vu par userB
        // TODO: Ces champs doivent être cohérents avec ton modèle Recipient
        'icon': '💌', // Icône par défaut
        'relation': 'relation_partner', // Relation par défaut
        'allowedPacks': [], // Packs par défaut
        'paired': true, // Marqué comme appairé
        'catalogType': 'partner', // Type de catalogue par défaut
        'createdAt': FieldValue.serverTimestamp(), // Horodatage
        // On utilise SetOptions(merge: true)
      }, SetOptions(merge: true));
      debugLog("✅ [PairingService] Préparation batch: document recipient B->A ($userBId -> $userAId)", level: 'DEBUG');


      // Exécuter le batch
      await batch.commit();
      debugLog("✅ [PairingService] Batch d'appairage exécuté entre $userAId et $userBId", level: 'SUCCESS');

    } catch (e) {
      debugLog("❌ [PairingService] Erreur lors de l’appairage Firestore entre $userAId et $userBId : $e", level: 'ERROR');
      // TODO: Gérer cette erreur (ex: la propager, la logguer plus spécifiquement)
      throw e; // Relancer l'exception pour que l'appelant puisse la gérer
    }
  } // <-- Fin de la fonction pairUsers

  // =============================================================
  // ❌ APPAIRAGE — Supprimer une relation bilatérale
  // =============================================================
  /// ❌ Supprime la relation d'appairage bilatérale dans Firestore.
  /// Supprime les documents recipients sous users/{userUid}/recipients/{partnerUid} des deux côtés.
  Future<void> unpairUsers(String userAUid, String userBUid) async {
    if (userAUid.isEmpty || userBUid.isEmpty || userAUid == userBUid) {
      debugLog("⚠️ [PairingService] Suppression d’appairage tentée avec UID(s) invalide(s).", level: 'WARN');
      return;
    }

    try {
      final batch = _firestore.batch();

      // Chemin correct pour supprimer le document recipient de userB chez userA
      final recipientAtoBRef = _firestore
          .collection('users')
          .doc(userAUid)
          .collection('recipients')
          .doc(userBUid);

      // Chemin correct pour supprimer le document recipient de userA chez userB
      final recipientBtoARef = _firestore
          .collection('users')
          .doc(userBUid)
          .collection('recipients')
          .doc(userAUid);

      batch.delete(recipientAtoBRef);
      batch.delete(recipientBtoARef);

      await batch.commit();
      debugLog("✅ [PairingService] Suppression d'appairage réussie entre $userAUid et $userBUid", level: 'SUCCESS');

    } catch (e) {
      debugLog("❌ [PairingService] Erreur lors de la suppression d’appairage entre $userAUid et $userBUid : $e", level: 'ERROR');
      // TODO: Gérer cette erreur
      throw e; // Relancer l'exception
    }
  } // <-- Fin de la fonction unpairUsers


  // =============================================================
  // 🔍 APPAIRAGE — Vérifier si un utilisateur est appairé avec un partenaire spécifique
  // =============================================================
  /// 🔍 Vérifie l'existence du document recipient de partnerUid sous users/userUid/recipients/.
  /// Cette méthode vérifie l'existence d'UN SEUL CÔTÉ de la relation.
  /// Pour une vérification bilatérale stricte, il faudrait vérifier les deux sens.
  Future<bool> isPairedWith(String userUid, String partnerUid) async {
    if (userUid.isEmpty || partnerUid.isEmpty || userUid == partnerUid) {
      debugLog("⚠️ [PairingService] Vérification d’appairage tentée avec UID(s) invalide(s) ou auto-vérification.", level: 'WARN');
      return false;
    }
    try {
      // Chemin correct pour vérifier le document recipient de partnerUid chez userUid
      final doc = await _firestore
          .collection('users')
          .doc(userUid)
          .collection('recipients')
          .doc(partnerUid)
          .get();

      final isActuallyPaired = doc.exists && (doc.data()?['paired'] == true); // Double check le champ 'paired'
      debugLog("✅ [PairingService] Vérification appairage ($userUid <-> $partnerUid): ${isActuallyPaired ? 'Oui' : 'Non'}", level: isActuallyPaired ? 'INFO' : 'DEBUG');
      return isActuallyPaired;

    } catch (e) {
      debugLog("❌ [PairingService] Erreur lors de la vérification d’appairage entre $userUid et $partnerUid : $e", level: 'ERROR');
      // TODO: Gérer cette erreur
      throw e; // Relancer l'exception
    }
  } // <-- Fin de la fonction isPairedWith

  // =============================================================
  // 📥 APPAIRAGE — Récupérer les données du partenaire
  // =============================================================
  /// 📥 Récupère les données du document Recipient de partnerUid stocké sous users/userUid/recipients/.
  /// Retourne un objet Recipient si le document existe et contient les données nécessaires.
  /// Retourne null si le document n'existe pas ou si les données sont insuffisantes/invalides.
  Future<Recipient?> getRecipientData(String userUid, String partnerUid) async {
    if (userUid.isEmpty || partnerUid.isEmpty || userUid == partnerUid) {
      debugLog("⚠️ [PairingService] Récupération données destinataire tentée avec UID(s) invalide(s).", level: 'WARN');
      return null;
    }
    try {
      // Chemin correct pour récupérer le document recipient de partnerUid chez userUid
      final doc = await _firestore
          .collection('users')
          .doc(userUid)
          .collection('recipients')
          .doc(partnerUid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Tente de mapper les données au modèle Recipient
        try {
          // Assure-toi que tous les champs obligatoires de ton modèle Recipient sont présents ici
          // et que les types correspondent.
          // Ce mappage devrait idéalement être une méthode dans la classe Recipient ou un service dédié.
          final recipient = Recipient(
            id: data['id'] ?? partnerUid, // Assure l'UID est présent, fallback sur partnerUid
            displayName: data['displayName'] ?? 'Inconnu', // Nom d'affichage
            icon: data['icon'] ?? '💬', // Icône
            relation: data['relation'] ?? 'relation_partner', // Relation
            allowedPacks: (data['allowedPacks'] as List?)?.cast<String>() ?? [], // Liste de strings
            paired: data['paired'] == true, // Booléen, assure qu'il est bien true si appairé
            catalogType: data['catalogType'] ?? 'partner', // Type de catalogue
            createdAt: data['createdAt'] as Timestamp?, // Timestamp
            // TODO: Ajouter d'autres champs si ton modèle Recipient en a.
          );
          debugLog("✅ [PairingService] Détails destinataire ($partnerUid pour $userUid) chargés.", level: 'INFO');
          return recipient;

        } catch (e) {
          debugLog("❌ [PairingService] Erreur de mappage Recipient pour UID $partnerUid : $e", level: 'ERROR');
          return null; // Échec du mappage
        }
      } else {
        debugLog("⚠️ [PairingService] Document destinataire ($partnerUid pour $userUid) non trouvé ou vide.", level: 'WARNING');
        return null; // Document non trouvé ou vide
      }

    } catch (e) {
      debugLog("❌ [PairingService] Erreur lors de la récupération des données du destinataire ($partnerUid pour $userUid) : $e", level: 'ERROR');
      // TODO: Gérer cette erreur
      throw e; // Relancer l'exception
    }
  } // <-- Fin de la fonction getRecipientData


} // <-- Fin de la classe PairingService


// 📄 FIN de lib/services/pairing_service.dart
