//  lib/screens/email_verification_screen.dart

// Historique du fichier
// V002 - suppression flèche retour + redirection automatique vers HomeSelector - 2025/05/25 21h45
// V001 - ajout polling automatique + boutons de vérif - 2025/05/22

import 'dart:async'; // ajouté le 22/05/2025 — pour timer périodique
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/i18n_service.dart';
import '../utils/debug_log.dart';
import 'profile_screen.dart';
import 'home_selector.dart'; // ajouté pour redirection directe après vérif

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
  Timer? _pollingTimer; // ajouté le 22/05/2025 — pour vérification automatique toutes les 3s

  @override
  void initState() {
    super.initState();
    _startAutoCheck(); // lancé dès l’arrivée
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          debugLog("✅ Email vérifié via polling, redirection automatique");
          _pollingTimer?.cancel();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeSelector(
                deviceId: widget.deviceId,
                deviceLang: widget.deviceLang,
              ),
            ),
          );
        }
      }
    });
  }

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
      debugLog("✅ Email vérifié (manuel), accès autorisé");
      _pollingTimer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeSelector(
            deviceId: widget.deviceId,
            deviceLang: widget.deviceLang,
          ),
        ),
      );
    } else {
      debugLog("❌ Email non vérifié (manuel)");
      setState(() {
        _errorMessage = getUILabel('email_not_verified', widget.deviceLang);
        _isChecking = false;
      });
    }
  }

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
        automaticallyImplyLeading: false, // 🔒 empêche retour via flèche
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
