// 📄 lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'register_screen.dart';
import 'love_screen.dart';
import 'firebase_test_page.dart'; // Importer la page de test Firebase

class LoginScreen extends StatefulWidget {
  final String deviceLang;
  final String deviceId;

  const LoginScreen({
    super.key,
    required this.deviceLang,
    required this.deviceId,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await AuthService().login(email, password);

      const isReceiver = true;
      await registerDevice(widget.deviceId, isReceiver);

      if (!mounted) return; // ✅ protection context
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => LoveScreen(
                deviceId: widget.deviceId,
                isReceiver: isReceiver,
                deviceLang: widget.deviceLang,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return; // ✅ protection context
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Connexion échouée : $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => RegisterScreen(
              deviceLang: widget.deviceLang,
              deviceId: widget.deviceId,
            ),
      ),
    );
  }

  // Fonction pour accéder à la page de test Firebase
  void _goToFirebaseTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                FirebaseTestPage(), // Redirection vers la page de test Firebase
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("🔐 Connexion"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                "Email",
                _emailController,
                TextInputType.emailAddress,
              ),
              _buildTextField(
                "Mot de passe",
                _passwordController,
                TextInputType.visiblePassword,
                obscure: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleLogin,
                icon: const Icon(Icons.login),
                label: Text(_isLoading ? "Connexion..." : "Se connecter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _goToRegister,
                child: const Text("Créer un compte"),
              ),
              const SizedBox(height: 16),
              // Utilisation d'un lien pour tester Firebase
              TextButton(
                onPressed: _goToFirebaseTest,
                child: const Text("Test Firebase"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    TextInputType type, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),
          ),
        ),
        validator:
            (value) => value == null || value.isEmpty ? 'Champ requis' : null,
      ),
    );
  }
}
