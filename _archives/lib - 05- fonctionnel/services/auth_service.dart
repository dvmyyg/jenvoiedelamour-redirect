// -------------------------------------------------------------
// 📄 FICHIER : lib/services/auth_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Service dédié à la gestion de l'authentification utilisateur via Firebase Authentication.
// ✅ Fournit des méthodes pour l'enregistrement (email/password), la connexion (email/password), la déconnexion.
// ✅ Permet l'envoi d'email de vérification et la suppression du compte utilisateur.
// ✅ S'appuie entièrement sur l'instance de FirebaseAuth et l'objet User (identifié par UID).
// ✅ Inclut une méthode pour vérifier si l'utilisateur est connecté et son email vérifié.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - Création du service d'authentification utilisant FirebaseAuth pour la gestion des utilisateurs (email/password, déconnexion, suppression, vérification email, état auth+verif). Structure initiale du service. - 2025/05/XX (Date de création approximative si non spécifiée)
// -------------------------------------------------------------

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
