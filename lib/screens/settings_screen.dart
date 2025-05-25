//  lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ajouté le 25/05/2025 — pour get uid/email
import '../services/i18n_service.dart';
import '../services/firestore_service.dart'; // ajouté le 25/05/2025 — pour saveUserProfile

class SettingsScreen extends StatefulWidget {
  final String currentLang;
  final String deviceId;
  const SettingsScreen({
    super.key,
    required this.currentLang,
    required this.deviceId,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .get();
    final name = doc.data()?['displayName'];
    if (name != null) {
      _nameController.text = name;
    }
  }

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Future<void> _saveDisplayName() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) return;

    final name = capitalize(rawName);

    // 🔁 Mise à jour devices/{deviceId}
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .update({'displayName': name});

    // 🧠 Mise à jour users/{uid}
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await saveUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        firstName: name,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getUILabel('profile_saved', widget.currentLang)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.white),
            const SizedBox(width: 8),
            Text(getUILabel('profile_title', widget.currentLang)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getUILabel('profile_firstname_label', widget.currentLang),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: getUILabel('profile_firstname_hint', widget.currentLang),
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveDisplayName,
              child: Text(getUILabel('profile_save_button', widget.currentLang)),
            ),
          ],
        ),
      ),
    );
  }
}
