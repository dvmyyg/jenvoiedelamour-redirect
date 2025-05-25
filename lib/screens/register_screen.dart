//  lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/i18n_service.dart';
import '../utils/debug_log.dart';
import '../screens/email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;

  const RegisterScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ajouté le 22/05/2025 — champ prénom à la création
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _nameController.text.trim();

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user?.uid;
      if (uid == null) throw Exception("UID null");

      // Sauvegarde dans Firestore
      await FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).set({
        'deviceId': widget.deviceId,
        'email': email,
        'displayName': displayName,
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));

      await credential.user?.sendEmailVerification();

      debugLog("✅ Compte créé : $email / $displayName");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            deviceId: widget.deviceId,
            deviceLang: widget.deviceLang,
          ),
        ),
      );
    } catch (e) {
      debugLog("❌ Erreur création compte : $e", level: 'ERROR');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.deviceLang;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(getUILabel('register_title', lang)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: getUILabel('profile_firstname_label', lang),
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? getUILabel('required_field', lang) : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: getUILabel('email_label', lang),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                validator: (value) =>
                value != null && value.contains('@') ? null : getUILabel('invalid_email', lang),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: getUILabel('password_label', lang),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                validator: (value) =>
                value != null && value.length >= 6 ? null : getUILabel('password_min_length', lang),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _register,
                icon: const Icon(Icons.person_add),
                label: Text(getUILabel('register_button', lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
