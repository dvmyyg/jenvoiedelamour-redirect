// lib/services/recipient_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipient.dart';

class RecipientService {
  final String deviceId;

  RecipientService(this.deviceId);

  CollectionReference get _recipientsRef =>
      FirebaseFirestore.instance.collection('devices').doc(deviceId).collection('recipients');

  Future<List<Recipient>> fetchRecipients() async {
    final snapshot = await _recipientsRef.get();
    return snapshot.docs
        .map((doc) => Recipient.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> addRecipient(Recipient recipient) async {
    await _recipientsRef.doc(recipient.id).set(recipient.toMap());
  }

  Future<void> updateRecipient(Recipient recipient) async {
    await _recipientsRef.doc(recipient.id).update(recipient.toMap());
  }

  Future<void> deleteRecipient(String id) async {
    await _recipientsRef.doc(id).delete();
  }
}
