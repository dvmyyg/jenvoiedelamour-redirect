// -------------------------------------------------------------
// 📄 FICHIER : lib/navigation/notification_router.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Centralise la navigation suite à un clic sur une notification FCM ou locale.
// ✅ Reçoit le data payload de la notification (doit contenir 'senderId').
// ✅ Charge les informations nécessaires (utilisateur actuel via CurrentUserService, destinataire via PairingService).
// ✅ Redirige vers l'écran de chat (RecipientDetailsScreen) si les données sont valides.
// ✅ Utilise le NavigatorKey global via GetIt pour la navigation.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V005 - Rendu la méthode routeFromNotification autonome pour l'initialisation de GetIt/services. - 2025/06/21 10h40
// V004 - Suppression des blocs de code marqués ⛔️ À supprimer. - 2025/06/20 03h44
// V003 - Refactor de routeFromNotification pour utiliser CurrentUserService afin d'obtenir les données de l'utilisateur actuel. - 2025/06/18 13h48
// V002 - Implémentation de la logique de chargement des données utilisateur/destinataire et navigation vers RecipientDetailsScreen à partir du data payload. Correction de l'écran de destination et des paramètres requis. Nettoyage des imports inutilisés. - 2025/06/16 21h15
// V001 - Création initiale du routeur de notifications pour centraliser la logique post-clic. - 2025/06/10 16h30
// -------------------------------------------------------------

import 'package:flutter/material.dart';
import 'dart:ui'; // Pour lire la langue du device (fallback)
import 'package:jelamvp01/utils/debug_log.dart'; // Pour les logs
import 'package:jelamvp01/screens/recipient_details_screen.dart'; // Le bon écran de destination
import 'package:firebase_auth/firebase_auth.dart'; // Pour obtenir l'utilisateur actuel (UID)
import 'package:jelamvp01/models/recipient.dart'; // Pour le type Recipient
import 'package:jelamvp01/models/user_profile.dart'; // ✅ AJOUT V004 (Correction Import) : Import du modèle UserProfile
import 'package:jelamvp01/services/pairing_service.dart'; // Pour charger les détails du destinataire
import 'package:jelamvp01/utils/service_locator.dart'; // Pour getIt (contient navigatorKey, PairingService et CurrentUserService)
import 'package:jelamvp01/services/current_user_service.dart'; // ✅ AJOUT V003 : Import de CurrentUserService

// --- FIN   DU BLOC Imports ---

class NotificationRouter {
  // Cette méthode est appelée par FcmService (pour les messages foreground/opened/initial)
  // ou par onDidReceiveBackgroundNotificationResponse (pour les clics sur notifications locales).
  // Elle reçoit le data payload de la notification (doit contenir 'senderId').
  static Future<void> routeFromNotification(Map<String, dynamic> data) async {
    debugLog("🔔 [NotificationRouter] Tentative de routage depuis notification. Data: $data", level: 'INFO');

    // --- ÉTAPE CRITIQUE : Assurer l'initialisation de GetIt et des services ---
    // Cette fonction peut être appelée quand l'app est lancée depuis un état 'terminated'
    // par un clic sur notification, AVANT que main() n'ait eu l'occasion de configurer GetIt.
    try {
      if (!getIt.isRegistered<CurrentUserService>()) { // Vérifie si un service clé est enregistré pour juger si GetIt est "prêt"
        debugLog("🖙 [NotificationRouter] GetIt non configuré ou services non enregistrés. Appel de setupLocator().", level: 'INFO');
        setupLocator();
        // Force l'initialisation de CurrentUserService si c'est un LazySingleton et que c'est la première fois
        getIt<CurrentUserService>(); // Ceci déclenchera l'initialisation de CurrentUserService (et ses dépendances comme FirestoreService)
        debugLog("🖙 [NotificationRouter] GetIt et services essentiels configurés et initialisés.", level: 'INFO');
      } else {
        debugLog("🖙 [NotificationRouter] GetIt et services essentiels déjà initialisés.", level: 'DEBUG');
      }
    } catch (e) {
      debugLog("❌ [NotificationRouter] Erreur critique lors de l'initialisation de GetIt/Services : $e", level: 'ERROR');
      // Si GetIt/Services ne s'initialisent pas, la navigation ne peut pas fonctionner.
      // On tente de naviguer vers l'écran principal comme fallback.
      getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/');
      return; // Sortie précoce
    }

    final String? senderUid = data['senderId'];

    if (senderUid == null || senderUid.isEmpty) {
      debugLog('⚠️ [NotificationRouter] Données de navigation manquantes ou invalides (senderId).', level: 'WARNING');
      getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/');
      return;
    }

    // Utilise FirebaseAuth pour vérifier si un utilisateur est connecté.
    // FirebaseAuth.instance.currentUser est robuste même si l'app vient d'être lancée depuis l'état terminé.
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugLog('⚠️ [NotificationRouter] Utilisateur non connecté. Impossible de naviguer post-notification.', level: 'WARNING');
      // L'app devrait afficher l'écran de connexion via le StreamBuilder dans main().
      return; // Sortie précoce
    }

    if (currentUser.uid == senderUid) {
      debugLog('⚠️ [NotificationRouter] Clic sur notification de soi-même ($senderUid). Pas de navigation ciblée.', level: 'INFO');
      return; // Sortie précoce
    }

    // Obtenir les données de l'utilisateur actuel depuis CurrentUserService.
    // CurrentUserService est maintenant garanti d'être initialisé grâce au bloc try/catch initial.
    final CurrentUserService currentUserService = getIt<CurrentUserService>();
    final UserProfile? currentUserProfile = currentUserService.userProfile;

    if (currentUserProfile == null) {
      debugLog('⚠️ [NotificationRouter] Profil utilisateur actuel non chargé dans CurrentUserService. Impossible de naviguer post-notification.', level: 'WARNING');
      // Le profil utilisateur devrait être chargé par CurrentUserService au moment où l'utilisateur est connecté.
      // Si CurrentUserService n'a pas encore chargé le profil, il y a potentiellement un problème d'initialisation
      // ou de synchronisation.
      getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // Navigation par défaut
      // TODO: Gérer ce cas d'erreur plus finement (ex: attendre le chargement du profil, afficher un message) (Étape 6.3.2)
      return; // Sortie précoce si le profil utilisateur n'est pas disponible
    }

    debugLog('➡️ [NotificationRouter] Tentative de navigation vers conversation avec $senderUid...', level: 'INFO');

    // Charger les données nécessaires pour RecipientDetailsScreen
    final String currentUserDeviceLang = currentUserProfile.deviceLang; // Utilise la langue du profil
    final bool currentUserIsReceiver = currentUserProfile.isReceiver; // Utilise le rôle du profil

    Recipient? recipientDetails; // Initialise à null

    try {
      // Utilise le service PairingService pour charger les détails du destinataire.
      // PairingService est maintenant garanti d'être initialisé grâce au bloc try/catch initial.
      recipientDetails = await getIt<PairingService>().getRecipientData(currentUser.uid, senderUid);
      debugLog("✅ [NotificationRouter] Détails destinataire ($senderUid) chargés via PairingService (qui utilise RecipientService).", level: 'INFO');
    } catch (e) {
      debugLog("❌ [NotificationRouter] Erreur lors du chargement des détails du destinataire ($senderUid) via PairingService : $e", level: 'ERROR');
      recipientDetails = null; // S'assurer que recipientDetails est null en cas d'erreur
      // TODO: Gérer l'erreur (afficher un message à l'utilisateur, naviguer vers l'écran principal?) (Étape 6.3.1)
      getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // Exemple de navigation d'erreur
      return; // Sortie précoce si le destinataire ne peut pas être chargé
    }

    // Naviguer si les details du destinataire sont trouvés.
    if (recipientDetails != null) {
      // Utilise le navigatorKey global via getIt pour naviguer.
      // Utiliser Future.delayed(Duration.zero) est une bonne pratique pour s'assurer
      // que la navigation est poussée après que l'UI initiale soit construite,
      // surtout si l'app vient d'être lancée.
      Future.delayed(Duration.zero, () {
        getIt<GlobalKey<NavigatorState>>().currentState?.push(MaterialPageRoute(
          builder: (context) => RecipientDetailsScreen(
            deviceLang: currentUserDeviceLang, // Langue - lue depuis CurrentUserService
            recipient: recipientDetails!, // Objet Recipient chargé
            isReceiver: currentUserIsReceiver, // Rôle de l'utilisateur actuel - lue depuis CurrentUserService
          ),
        ));
        debugLog("➡️ [NotificationRouter] Navigation vers RecipientDetailsScreen réussie pour UID destinataire $senderUid", level: 'INFO');
      });

    } else {
      // Ce cas ne devrait normalement pas arriver si PairingService.getRecipientData a déjà géré l'erreur,
      // mais c'est une vérification supplémentaire.
      debugLog("⚠️ [NotificationRouter] Navigation vers RecipientDetailsScreen annulée car détails destinataire non chargés ou introuvables.", level: 'WARNING');
      getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // Navigation par défaut en cas d'échec de chargement
    }
  }
} // <-- Fin de la classe NotificationRouter

// 📄 FIN de lib/navigation/notification_router.dart
