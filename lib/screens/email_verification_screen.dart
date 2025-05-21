//  lib/screens/email_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/i18n_service.dart';
import '../utils/debug_log.dart';
import 'profile_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;

  const EmailVerificationScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _errorMessage;
  String? _successMessage;

  // ajouté le 21/05/2025 — vérifie si l'utilisateur a confirmé son email
  Future<void> _checkEmailVerified() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser?.emailVerified == true) {
      debugLog("✅ Email vérifié, accès autorisé");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            deviceId: widget.deviceId,
            deviceLang: widget.deviceLang,
          ),
        ),
      );
    } else {
      debugLog("❌ Email non vérifié");
      setState(() {
        _errorMessage = getUILabel('email_not_verified', widget.deviceLang);
        _isChecking = false;
      });
    }
  }

  // ajouté le 21/05/2025 — renvoie l'email de vérification
  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugLog("📩 Email de vérification renvoyé à ${user.email}");
        setState(() {
          _successMessage = getUILabel('email_resent_success', widget.deviceLang);
        });
      }
    } catch (e) {
      debugLog("❌ Erreur envoi email de vérification : $e", level: 'ERROR');
      setState(() {
        _errorMessage = getUILabel('email_resent_error', widget.deviceLang);
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('email_verification_title', widget.deviceLang)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getUILabel('email_verification_message', widget.deviceLang),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (_successMessage != null)
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.greenAccent),
              ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkEmailVerified,
              icon: const Icon(Icons.check),
              label: Text(getUILabel('email_verification_check_button', widget.deviceLang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _resendVerificationEmail,
              icon: const Icon(Icons.email),
              label: Text(getUILabel('email_verification_resend_button', widget.deviceLang)),
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
