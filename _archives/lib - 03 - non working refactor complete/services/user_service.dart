// 📄 lib/services/user_service.dart

// Historique du fichier
// V001 - refactoring deviceId > userId - 2025/05/29

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
