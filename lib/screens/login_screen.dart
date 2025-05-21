//  lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import '../utils/debug_log.dart';
import '../services/i18n_service.dart'; // ajouté le 21/05/2025 — pour accès aux traductions UI

class LoginScreen extends StatefulWidget {
  final String deviceLang;
  final String deviceId; // ajouté le 21/05/2025 — requis pour register_screen.dart

  const LoginScreen({
    super.key,
    required this.deviceLang,
    required this.deviceId,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      debugLog("❌ Login failed: $e", level: 'ERROR');
      setState(() => _error = getUILabel('login_error', widget.deviceLang));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              getUILabel('login_title', widget.deviceLang),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: getUILabel('email_label', widget.deviceLang),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: getUILabel('password_label', widget.deviceLang),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              child: Text(getUILabel('login_button', widget.deviceLang)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(
                      deviceLang: widget.deviceLang,
                      deviceId: widget.deviceId,
                    ),
                  ),
                );
              },
              child: Text(getUILabel('create_account_button', widget.deviceLang)),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
