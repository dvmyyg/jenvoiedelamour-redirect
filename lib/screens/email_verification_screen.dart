// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/email_verification_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Écran d'attente pour la vérification de l'adresse email après inscription ou connexion.
// ✅ Vérifie périodiquement l'état de vérification de l'email de l'utilisateur actuel via Firebase Authentication.
// ✅ Redirige automatiquement vers l'écran HomeSelector une fois l'email vérifié.
// ✅ Permet de renvoyer l'email de vérification manuellement.
// ✅ S'appuie entièrement sur FirebaseAuth.instance.currentUser pour la logique utilisateur.
// ✅ N'utilise plus deviceId pour l'identification ou la logique.
// ✅ Boutons de vérification manuelle et de renvoi.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V004 - Code examiné par Gemini. Logique de vérification automatique (polling) et manuelle confirmée comme fonctionnelle et basée sur l'UID Firebase. - 2025/05/31
// V003 - Refactoring : Suppression du paramètre deviceId. L'écran s'appuie entièrement sur FirebaseAuth.instance.currentUser.
//      - Suppression du passage de deviceId lors de la navigation vers HomeSelector. - 2025/05/29
// V002 - suppression flèche retour + redirection automatique vers HomeSelector - 2025/05/25 21h45 (Historique hérité)
// V001 - ajout polling automatique + boutons de vérif - 2025/05/22 (Historique hérité)
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/31 // Mise à jour le 31/05


import 'dart:async'; // pour timer périodique
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Essentiel pour la vérification email
import '../services/i18n_service.dart';
import '../utils/debug_log.dart';
// On importe HomeSelector, qui n'a plus besoin de deviceId en paramètre
import 'home_selector.dart';

// On supprime l'import de ProfileScreen car il n'est pas utilisé ici
// import 'profile_screen.dart'; // <-- SUPPRIMÉ


class EmailVerificationScreen extends StatefulWidget {
  // Le deviceId n'est plus pertinent ici. L'état de vérification et l'utilisateur
  // sont gérés par FirebaseAuth.instance.currentUser.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente

  const EmailVerificationScreen({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
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
  Timer? _pollingTimer; // pour vérification automatique périodique

  @override
  void initState() {
    super.initState();
    // Lance la vérification automatique de l'état de vérification de l'email
    _startAutoCheck();
  }

  @override
  void dispose() {
    // Annule le timer lorsque l'écran est détruit pour éviter les fuites de mémoire
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Démarre un timer pour vérifier périodiquement l'état de vérification de l'email
  void _startAutoCheck() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      // Obtient l'utilisateur Firebase actuellement connecté.
      // Si l'utilisateur est null, le timer s'arrête implicitement car on ne fait rien.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Recharge l'état de l'utilisateur depuis Firebase (y compris l'état emailVerified)
        await user.reload();
        // Vérifie si l'email est maintenant vérifié
        if (user.emailVerified) {
          debugLog("✅ Email vérifié via polling, redirection automatique", level: 'INFO');
          // Annule le timer et navigue si l'écran est toujours monté
          _pollingTimer?.cancel();
          if (!mounted) return;
          // Navigue vers HomeSelector. On ne passe PLUS deviceId.
          // HomeSelector obtiendra l'UID via FirebaseAuth.instance.currentUser.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeSelector(
                // deviceId: widget.deviceId, // <-- SUPPRIMÉ
                deviceLang: widget.deviceLang, // La langue est toujours passée
              ),
            ),
          );
        }
      }
    });
  }

  // Vérifie manuellement l'état de vérification de l'email
  Future<void> _checkEmailVerified() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté (ne devrait pas arriver ici)
      setState(() {
        _errorMessage = getUILabel('email_verification_error_not_logged_in', widget.deviceLang); // TODO: Ajouter cette clé de traduction
        _isChecking = false;
      });
      debugLog("⚠️ Vérification manuelle échouée : Utilisateur non connecté.", level: 'WARNING');
      return;
    }

    await user.reload(); // Recharge l'état de l'utilisateur
    // Récupère l'utilisateur après rechargement (au cas où l'objet User aurait changé, bien que reload modifie souvent l'objet existant)
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // Vérifie si l'email est vérifié après rechargement
    if (refreshedUser?.emailVerified == true) {
      debugLog("✅ Email vérifié (manuel), accès autorisé", level: 'INFO');
      // Annule le timer et navigue si l'écran est toujours monté
      _pollingTimer?.cancel();
      if (!mounted) return;
      // Navigue vers HomeSelector. On ne passe PLUS deviceId.
      // HomeSelector obtiendra l'UID via FirebaseAuth.instance.currentUser.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeSelector(
            // deviceId: widget.deviceId, // <-- SUPPRIMÉ
            deviceLang: widget.deviceLang, // La langue est toujours passée
          ),
        ),
      );
    } else {
      debugLog("❌ Email non vérifié (manuel)", level: 'WARNING');
      setState(() {
        _errorMessage = getUILabel('email_not_verified', widget.deviceLang); // Utilise i18n_service
        _isChecking = false;
      });
    }
  }

  // Renvoie l'email de vérification
  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      // Vérifie qu'un utilisateur est connecté et que son email n'est pas déjà vérifié
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification(); // Envoie l'email via Firebase Auth
        debugLog("📩 Email de vérification renvoyé à ${user.email}", level: 'INFO');
        setState(() {
          _successMessage = getUILabel('email_resent_success', widget.deviceLang); // Utilise i18n_service
        });
      } else if (user != null && user.emailVerified) {
        // Cas où l'email est déjà vérifié mais le bouton renvoyer est cliqué (devrait être désactivé)
        debugLog("ℹ️ Tentative de renvoi d'email, mais l'email est déjà vérifié.", level: 'INFO');
        setState(() {
          _errorMessage = getUILabel('email_already_verified', widget.deviceLang); // TODO: Ajouter cette clé
        });
      } else {
        // Cas où l'utilisateur est null
        debugLog("⚠️ Tentative de renvoi d'email, mais utilisateur non connecté.", level: 'WARNING');
        setState(() {
          _errorMessage = getUILabel('email_verification_error_not_logged_in', widget.deviceLang); // TODO: Ajouter cette clé
        });
      }
    } catch (e) {
      debugLog("❌ Erreur envoi email de vérification : $e", level: 'ERROR');
      setState(() {
        _errorMessage = getUILabel('email_resent_error', widget.deviceLang); // Utilise i18n_service
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // L'UI reste globalement la même, car elle ne dépendait pas du deviceId pour son affichage.
    // Elle utilise FirebaseAuth.currentUser en interne pour la logique.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('email_verification_title', widget.deviceLang)), // Utilise i18n_service
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Empêche le retour arrière avec la flèche
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getUILabel('email_verification_message', widget.deviceLang), // Utilise i18n_service
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            // Affichage des messages de succès ou d'erreur
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
            // Bouton pour vérifier manuellement (appelle _checkEmailVerified refactorisé)
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkEmailVerified,
              icon: const Icon(Icons.check),
              label: Text(getUILabel('email_verification_check_button', widget.deviceLang)), // Utilise i18n_service
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            // Bouton pour renvoyer l'email (appelle _resendVerificationEmail refactorisé)
            ElevatedButton.icon(
              onPressed: _isSending ? null : _resendVerificationEmail,
              icon: const Icon(Icons.email),
              label: Text(getUILabel('email_verification_resend_button', widget.deviceLang)), // Utilise i18n_service
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            // TODO: Potentiellement ajouter un bouton pour se déconnecter ici,
            // si l'utilisateur ne veut pas vérifier son email tout de suite et veut revenir à la page de connexion.
            // ElevatedButton( onPressed: () async { await FirebaseAuth.instance.signOut(); }, child: Text(getUILabel('logout_button', widget.deviceLang)))
          ],
        ),
      ),
    );
  }
}
// 📄 FIN de lib/screens/email_verification_screen.dart
