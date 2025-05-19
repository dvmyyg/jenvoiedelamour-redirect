// 📄 lib/services/recipient_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipient.dart';
import '../utils/debug_log.dart'; // Importation du logger

class RecipientService {
  final String deviceId;

  RecipientService(this.deviceId);

  CollectionReference get _recipientsRef => FirebaseFirestore.instance
      .collection('devices')
      .doc(deviceId)
      .collection('recipients');

  // ✅ Récupérer uniquement les destinataires appairés
  Future<List<Recipient>> fetchRecipients() async {
    debugLog("🔄 Chargement des destinataires pour l'appareil : $deviceId");
    final snapshot = await _recipientsRef
        .where('deviceId', isNotEqualTo: null) // ✅ filtre : uniquement ceux qui sont appairés
        .get();

    debugLog(
      "✅ ${snapshot.docs.length} destinataires connectés récupérés depuis Firestore",
    );

    return snapshot.docs
        .map(
          (doc) =>
          Recipient.fromMap(doc.id, doc.data() as Map<String, dynamic>),
    )
        .toList();
  }

  // ✅ Ajouter un destinataire
  Future<void> addRecipient(Recipient recipient) async {
    debugLog("📝 Ajout d'un destinataire : ${recipient.displayName}");
    await _recipientsRef.doc(recipient.id).set(recipient.toMap());
    debugLog(
      "✅ Destinataire ajouté : ${recipient.displayName} (ID: ${recipient.id})",
    );
  }

  // ✅ Mettre à jour un destinataire
  Future<void> updateRecipient(Recipient recipient) async {
    debugLog("📝 Mise à jour du destinataire : ${recipient.displayName}");
    await _recipientsRef.doc(recipient.id).update(recipient.toMap());
    debugLog(
      "✅ Destinataire mis à jour : ${recipient.displayName} (ID: ${recipient.id})",
    );
  }

  // ✅ Supprimer un destinataire
  Future<void> deleteRecipient(String id) async {
    debugLog("🗑️ Suppression du destinataire avec ID : $id");
    await _recipientsRef.doc(id).delete();
    debugLog("✅ Destinataire supprimé : ID $id");
  }
}
