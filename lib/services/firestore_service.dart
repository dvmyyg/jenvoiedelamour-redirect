// 📄 lib/services/firestore_service.dart

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
