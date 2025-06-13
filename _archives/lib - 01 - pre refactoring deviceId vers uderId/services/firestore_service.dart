//  lib/services/firestore_service.dart

import '../utils/debug_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

// ajouté le 21/05/2025 pour sauvegarder le prénom et l'email dans Firestore > users/{uid}
Future<void> saveUserProfile({
  required String uid,
  required String email,
  required String firstName,
}) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'firstName': firstName,
    }, SetOptions(merge: true));

    debugLog(
      '✅ [saveUserProfile] Utilisateur enregistré : $email ($firstName)',
      level: 'SUCCESS',
    );
  } catch (e) {
    debugLog(
      '❌ [saveUserProfile] Erreur lors de la sauvegarde de $email : $e',
      level: 'ERROR',
    );
  }
}

// ajouté le 21/05/2025 pour récupérer les données utilisateur depuis Firestore > users/{uid}
Future<Map<String, dynamic>?> getUserProfile(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  } catch (e) {
    debugLog(
      '❌ [getUserProfile] Erreur de lecture Firestore : $e',
      level: 'ERROR',
    );
    return null;
  }
}
