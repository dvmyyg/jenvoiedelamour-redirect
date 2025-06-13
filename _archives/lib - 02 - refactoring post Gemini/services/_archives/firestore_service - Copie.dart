//  lib/services/firestore_service.dart

import '../utils/debug_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// GEM - code corrigé par Gémini le 2025/05/29

// L'ancienne fonction registerDevice, basée sur deviceId, n'est plus nécessaire
// dans un modèle basé sur l'utilisateur authentifié (UID Firebase).
// Les informations comme isReceiver devraient être stockées sous l'UID de l'utilisateur.
// Si 'isReceiver' est une propriété de l'utilisateur et non de l'appareil,
// on peut ajouter un champ 'isReceiver' au document users/{uid} ou créer une fonction ici pour le gérer.
// Pour l'instant, on la supprime. Si besoin, on la réintroduira ailleurs.
/*
// ajouté le 08/04/2025 pour la sauvegarde dans Firebase du deviceId et de son rôle
Future<void> registerDevice(String deviceId, bool isReceiver) async {
  final deviceDoc = FirebaseFirestore.instance
      .collection('devices')
      .doc(deviceId);

  try {
    await deviceDoc.set({
      'deviceId': deviceId,
      'isReceiver': isReceiver,
      'lastSeen': DateTime.now().toIso8601String(),
    });

    debugLog(
      '✅ [registerDevice] Appareil enregistré : $deviceId (receiver: $isReceiver)',
      level: 'SUCCESS',
    );
  } catch (e) {
    debugLog(
      '❌ [registerDevice] Échec de l\'enregistrement du deviceId=$deviceId : $e',
      level: 'ERROR',
    );
  }
}
*/ // <-- Fonction registerDevice commentée/supprimée

// ajouté le 21/05/2025 pour sauvegarder le prénom et l'email dans Firestore > users/{uid}
// Cette fonction est déjà basée sur l'UID, elle est donc conservée.
Future<void> saveUserProfile({
  required String uid,
  required String email,
  required String firstName,
  // On pourrait ajouter des champs ici comme 'isReceiver' ou 'lastSeen'
  // si ces informations doivent être stockées au niveau de l'utilisateur.
  // Par exemple: bool? isReceiver, DateTime? lastSeen
}) async {
  try {
    // Les données sont enregistrées dans la collection 'users', document identifié par l'UID
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'firstName': firstName,
      // Ajouter ici 'isReceiver': isReceiver, si le champ est ajouté en paramètre
      // Ajouter ici 'lastSeen': lastSeen, si le champ est ajouté en paramètre
    }, SetOptions(merge: true));

    debugLog(
      '✅ [saveUserProfile] Utilisateur enregistré : $email ($firstName) [UID: $uid]',
      level: 'SUCCESS',
    );
  } catch (e) {
    debugLog(
      '❌ [saveUserProfile] Erreur lors de la sauvegarde de $email [UID: $uid] : $e',
      level: 'ERROR',
    );
  }
}

// ajouté le 21/05/2025 pour récupérer les données utilisateur depuis Firestore > users/{uid}
// Cette fonction est déjà basée sur l'UID, elle est donc conservée.
Future<Map<String, dynamic>?> getUserProfile(String uid) async {
  debugLog("🔄 Tentative de chargement du profil pour l'UID : $uid");
  try {
    // Lit les données depuis la collection 'users', document identifié par l'UID
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      debugLog("✅ Profil trouvé pour l'UID $uid");
      return doc.data();
    } else {
      debugLog("⚠️ Pas de document profil trouvé pour l'UID $uid", level: 'WARNING');
      return null;
    }
  } catch (e) {
    debugLog(
      '❌ [getUserProfile] Erreur de lecture Firestore pour l\'UID $uid : $e',
      level: 'ERROR',
    );
    return null;
  }
}

// TODO: Ajouter ici d'autres fonctions utilitaires pour Firestore si nécessaire,
// toujours basées sur l'UID de l'utilisateur si elles concernent des données utilisateur.
