// 📄 lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import '../utils/debug_log.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Enregistrement avec email + mot de passe
  Future<User?> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      debugLog("✅ Enregistrement réussi : ${result.user?.uid}");
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugLog("❌ Erreur enregistrement : ${e.code}", level: 'ERROR');
      rethrow;
    }
  }

  // ✅ Connexion avec email + mot de passe
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      debugLog("✅ Connexion réussie : ${result.user?.uid}");
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugLog("❌ Erreur connexion : ${e.code}", level: 'ERROR');
      rethrow;
    }
  }

  // ✅ Envoi d’un email de vérification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      debugLog("📩 Email de vérification envoyé à ${user.email}");
    }
  }

  // ✅ Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
    debugLog("🚪 Déconnexion réussie");
  }

  // ✅ Supprimer le compte
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
      debugLog("🗑️ Compte supprimé : ${user.uid}");
    }
  }

  // ✅ Vérifie si connecté et email vérifié
  Future<bool> isAuthenticatedAndVerified() async {
    final user = _auth.currentUser;
    await user?.reload();
    final refreshed = _auth.currentUser;
    final status = refreshed != null && refreshed.emailVerified;
    debugLog("👤 Auth+verif ? $status");
    return status;
  }
}
