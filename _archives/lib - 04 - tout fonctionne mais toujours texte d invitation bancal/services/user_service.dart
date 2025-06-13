// -------------------------------------------------------------
// 📄 FICHIER : lib/services/user_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Service utilitaire simple pour récupérer l'identifiant unique (UID) de l'utilisateur Firebase actuellement connecté.
// ✅ Permet aux autres parties de l'application d'accéder facilement à l'UID de l'utilisateur sans interagir directement avec l'instance FirebaseAuth.
// ✅ Retourne l'UID si un utilisateur est connecté, ou null sinon.
// ✅ S'appuie sur FirebaseAuth.instance.currentUser pour obtenir l'utilisateur.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V002 - Code examiné par Gemini. Fonction getCurrentUserUid confirmée comme utilisant correctement FirebaseAuth.instance.currentUser.uid. Le fichier est validé pour son rôle simple d'accès à l'UID. - 2025/05/31
// V001 - refactoring deviceId > userId - Création initiale de la fonction getCurrentUserUid basée sur FirebaseAuth. - 2025/05/29
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/31 // Mise à jour le 31/05

// On importe le package Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';
// On garde l'import pour le log, si vous souhaitez continuer à l'utiliser
import '../utils/debug_log.dart';

/// Récupère l'UID de l'utilisateur Firebase actuellement connecté.
/// Retourne l'UID (String?) si un utilisateur est signé, sinon retourne null.
/// Cette fonction ne crée PAS d'utilisateur ; elle récupère simplement celui qui est déjà signé.
Future<String?> getCurrentUserUid() async { // Le type de retour est maintenant Future<String?> car l'UID peut être null
  // On accède à l'instance de Firebase Authentication
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Si user n'est pas null, cela signifie qu'un utilisateur est connecté
    debugLog(
      '👤 [getCurrentUserUid] Utilisateur connecté trouvé. UID: ${user.uid}',
      level: 'INFO',
    );
    // On retourne l'UID de l'utilisateur connecté
    return user.uid;
  } else {
    // Si user est null, aucun utilisateur n'est connecté
    debugLog(
      '🚫 [getCurrentUserUid] Aucun utilisateur connecté trouvé.',
      level: 'INFO',
    );
    // On retourne null pour indiquer qu'il n'y a pas d'utilisateur connecté
    return null;
  }
}

// TODO: Ajoutez ici d'autres fonctions liées à l'utilisateur si nécessaire,
// comme signInWithEmailPassword, signUpWithEmailPassword, signOut,
// ou un stream pour écouter les changements d'état d'authentification.
