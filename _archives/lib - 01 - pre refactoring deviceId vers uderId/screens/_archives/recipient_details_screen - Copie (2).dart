// lib/screens/recipient_details_screen.dart

// Historique du fichier
// V002 - remplacement du bouton bas par navigation directe vers ChatScreen - 2025/05/26 21h44
// V001 - version initiale - 2025/05/24

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipient.dart';
import '../services/firestore_service.dart';
import '../services/i18n_service.dart';
import '../services/debug_log.dart';
import 'chat_screen.dart';

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
  final TextEditingController _nameController = TextEditingController();
  bool _hasChanged = false;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.recipient.displayName;

    // 👉 Navigation directe vers ChatScreen à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            deviceId: widget.deviceId,
            deviceLang: widget.deviceLang,
            recipient: widget.recipient,
          ),
        ),
      );
    });
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.recipient.displayName) return;

    final updated = widget.recipient.copyWith(displayName: newName);
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .collection('recipients')
        .doc(widget.recipient.id)
        .update(updated.toMap());

    setState(() {
      _successMessage = getUILabel('profile_saved', widget.deviceLang);
      _hasChanged = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('edit_recipient_title', widget.deviceLang)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                getUILabel('profile_firstname_label', widget.deviceLang),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: getUILabel('profile_firstname_hint', widget.deviceLang),
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink),
                ),
              ),
              onChanged: (_) {
                if (!_hasChanged) {
                  setState(() => _hasChanged = true);
                }
              },
            ),
            const SizedBox(height: 24),
            if (_successMessage != null)
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.greenAccent),
              ),
            const Spacer(),
            if (_hasChanged)
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: Text(getUILabel('profile_save_button', widget.deviceLang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
