// 📄 lib/screens/recipient_details_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipient.dart';
import '../services/i18n_service.dart';
import 'edit_recipient_screen.dart';

class RecipientDetailsScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;
  final Recipient recipient;

  const RecipientDetailsScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
    required this.recipient,
  });

  @override
  State<RecipientDetailsScreen> createState() => _RecipientDetailsScreenState();
}

class _RecipientDetailsScreenState extends State<RecipientDetailsScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? pairingStatus;
  StreamSubscription<DocumentSnapshot>? _pairingListener;

  @override
  void dispose() {
    _pairingListener?.cancel();
    super.dispose();
  }

  Future<void> handlePairing(String code) async {
    final pairingRef = FirebaseFirestore.instance.collection('pairings').doc(code);
    final doc = await pairingRef.get();

    if (!doc.exists) {
      await pairingRef.set({'deviceA': widget.deviceId});
      pairingStatus = getUILabel('pairing_status_waiting', widget.deviceLang);
      _listenForPairingCompletion(pairingRef);
    } else {
      final data = doc.data();
      if (data != null && data['deviceA'] != widget.deviceId && data['deviceB'] == null) {
        await pairingRef.update({'deviceB': widget.deviceId});
        pairingStatus = getUILabel('pairing_status_success', widget.deviceLang);
        await _markRecipientAsPaired(data['deviceA']);
      } else {
        pairingStatus = getUILabel('pairing_status_error', widget.deviceLang);
      }
    }

    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .update({'pairingCode': code});

    setState(() {});
  }

  void _listenForPairingCompletion(DocumentReference pairingRef) {
    _pairingListener?.cancel();
    _pairingListener = pairingRef.snapshots().listen((doc) async {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['deviceB'] != null) {
        pairingStatus = getUILabel('pairing_status_success', widget.deviceLang);
        await _markRecipientAsPaired(data['deviceB']);
        setState(() {});
        _pairingListener?.cancel();
      }
    });
  }

  Future<void> _markRecipientAsPaired(String otherDeviceId) async {
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .collection('recipients')
        .doc(widget.recipient.id)
        .update({
      'paired': true,
      'deviceId': otherDeviceId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipient = widget.recipient;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("📄 Fiche destinataire"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow("Nom affiché", recipient.displayName),
            _buildRow("Relation", recipient.relation),
            _buildRow("Icône", recipient.icon),
            _buildRow("Appairé", recipient.paired ? "Oui" : "Non"),
            const SizedBox(height: 20),
            const Text("Packs autorisés :", style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: recipient.allowedPacks.map((pack) {
                return Chip(
                  label: Text(pack),
                  backgroundColor: Colors.pink,
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),

            if (!recipient.paired) ...[
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: getUILabel('pairing_code_hint', widget.deviceLang),
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final code = _codeController.text;
                  if (code.length == 4) {
                    handlePairing(code);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(getUILabel('invalid_code', widget.deviceLang))),
                    );
                  }
                },
                icon: const Icon(Icons.link),
                label: Text(getUILabel('pair_button', widget.deviceLang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              if (pairingStatus != null)
                Text(pairingStatus!, style: const TextStyle(color: Colors.amber)),
            ],

            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditRecipientScreen(
                        deviceId: widget.deviceId,
                        deviceLang: widget.deviceLang, // ✅ AJOUT ICI
                        recipient: widget.recipient,
                      ),
                    ),
                  );

                  if (updated == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Modifications enregistrées")),
                    );
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text("Modifier"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _confirmDelete(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete),
                label: const Text("Supprimer ce destinataire"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            "$label : ",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("❌ Confirmation"),
        content: const Text("Supprimer ce destinataire ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRecipient(context);
    }
  }

  Future<void> _deleteRecipient(BuildContext context) async {
    final docRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .collection('recipients')
        .doc(widget.recipient.id);

    await docRef.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Destinataire supprimé ✅")),
    );

    Navigator.pop(context);
  }
}
