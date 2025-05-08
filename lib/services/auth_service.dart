// 📄 lib/services/auth_service.dart

import '../utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Inscription
  Future<User?> register(
    String email,
    String password,
    String deviceId,
    String lang,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = result.user!;
      await user.sendEmailVerification();

      debugLog(
        "✅ [register] Utilisateur retourné par Firebase : ${user.uid}",
        level: 'INFO',
      );

      try {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'deviceId': deviceId,
          'lang': lang,
          'createdAt': DateTime.now().toIso8601String(),
        });

        debugLog(
          "✅ [register] Utilisateur enregistré dans Firestore : ${user.uid}",
          level: 'SUCCESS',
        );
      } catch (e) {
        debugLog(
          "❌ [register] Échec de l'enregistrement Firestore : $e",
          level: 'ERROR',
        );
      }

      return user;
    } catch (e) {
      debugLog("❌ [register] Erreur Auth : $e", level: 'ERROR');
      rethrow;
    }
  }

  // ✅ Connexion
  Future<User?> login(String email, String password) async {
    try {
      debugLog("🔑 Tentative de connexion avec email: $email", level: 'INFO');

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugLog(
        "✅ [login] Utilisateur retourné par Firebase : ${result.user?.uid}",
        level: 'SUCCESS',
      );

      return result.user;
    } catch (e) {
      debugLog("❌ [login] Erreur : $e", level: 'ERROR');
      rethrow;
    }
  }

  // ✅ Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
    debugLog("🚪 Utilisateur déconnecté", level: 'INFO');
  }

  // ✅ Accès utilisateur courant
  User? get currentUser => _auth.currentUser;

  // ✅ Email vérifié ?
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}
