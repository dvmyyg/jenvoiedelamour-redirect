//  lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/debug_log.dart';
import 'email_verification_screen.dart'; // ajouté le 21/05/2025 pour rediriger si email non vérifié
import '../services/i18n_service.dart'; // ajouté le 21/05/2025 — accès aux traductions dynamiques

class RegisterScreen extends StatefulWidget {
  final String deviceLang;
  final String deviceId; // ajouté le 21/05/2025 car nécessaire à la suite du parcours

  const RegisterScreen({
    super.key,
    required this.deviceLang,
    required this.deviceId,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // modifié le 21/05/2025 — redirige vers EmailVerificationScreen si l’email n’est pas validé
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugLog("📩 Email de vérification envoyé à $email");

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
        return;
      }

      // normalement inatteignable ici, sauf si le mail a déjà été vérifié manuellement
      debugLog("✅ Utilisateur inscrit et email déjà vérifié (rare) : $email");
      _successMessage = getUILabel('email_verified_info', widget.deviceLang);
    } on FirebaseAuthException catch (e) {
      debugLog("❌ Erreur d'enregistrement : ${e.message}", level: 'ERROR');
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('register_title', widget.deviceLang)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: getUILabel('email_label', widget.deviceLang),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? getUILabel('required_field', widget.deviceLang) : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: getUILabel('password_label', widget.deviceLang),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : getUILabel('password_min_length', widget.deviceLang),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.greenAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(getUILabel('create_account_button', widget.deviceLang)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
