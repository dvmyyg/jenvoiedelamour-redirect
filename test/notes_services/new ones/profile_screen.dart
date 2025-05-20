// 📄 lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/debug_log.dart';

class ProfileScreen extends StatefulWidget {
  final String deviceId;
  const ProfileScreen({super.key, required this.deviceId});

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
        _errorMessage = "Erreur de chargement";
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
        _successMessage = "Profil mis à jour ✅";
        _hasChanged = false;
      });

      debugLog("💾 Profil mis à jour : $newName");
    } catch (e) {
      debugLog("❌ Erreur sauvegarde profil : $e", level: 'ERROR');
      setState(() {
        _errorMessage = "Erreur de sauvegarde";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Mon profil"),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Prénom",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _displayNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Entrez votre prénom",
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Mon email (identifiant)",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                      label: const Text("Sauvegarder"),
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
