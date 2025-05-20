// 📄 lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/debug_log.dart';
import '../services/i18n_service.dart';

class ProfileScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;

  const ProfileScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  String? _email;
  bool _hasChanged = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .get();

      final displayName = doc.data()?['displayName'] ?? '';
      _displayNameController.text = displayName;

      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _email = user?.email ?? '(email inconnu)';
        _isLoading = false;
      });

      debugLog("📄 Chargement profil : $displayName ($_email)");
    } catch (e) {
      debugLog("❌ Erreur chargement profil : $e", level: 'ERROR');
      setState(() {
        _errorMessage = getUILabel('profile_load_error', widget.deviceLang);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final newName = _displayNameController.text.trim();
    if (newName.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .update({'displayName': newName});

      setState(() {
        _successMessage = getUILabel('profile_saved', widget.deviceLang);
        _hasChanged = false;
      });

      debugLog("💾 Profil mis à jour : $newName");
    } catch (e) {
      debugLog("❌ Erreur sauvegarde profil : $e", level: 'ERROR');
      setState(() {
        _errorMessage = getUILabel('profile_save_error', widget.deviceLang);
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    debugLog("👋 Utilisateur déconnecté");
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('profile_title', widget.deviceLang)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.pink),
      )
          : Padding(
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
              controller: _displayNameController,
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
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                getUILabel('profile_email_label', widget.deviceLang),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _email ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            if (_successMessage != null)
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.greenAccent),
              ),
            const Spacer(),
            if (_hasChanged)
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: Text(getUILabel('profile_save_button', widget.deviceLang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: Text(getUILabel('logout_button', widget.deviceLang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
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
