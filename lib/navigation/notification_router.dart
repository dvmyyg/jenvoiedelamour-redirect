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
// V003 - Refactor de routeFromNotification pour utiliser CurrentUserService afin d'obtenir les données de l'utilisateur actuel. - 2025/06/18 13h48
// V002 - Implémentation de la logique de chargement des données utilisateur/destinataire et navigation vers RecipientDetailsScreen à partir du data payload. Correction de l'écran de destination et des paramètres requis. Nettoyage des imports inutilisés. - 2025/06/16 21h15
// V001 - Création initiale du routeur de notifications pour centraliser la logique post-clic. - 2025/06/10 16h30
// -------------------------------------------------------------

import 'package:flutter/material.dart';
import 'dart:ui'; // Pour lire la langue du device (fallback)
// ⛔️ À supprimer - Import de main.dart nécessaire uniquement pour la référence à navigatorKey, qui est maintenant accédé via getIt. - 2025/06/16 19h45
// import 'package:jelamvp01/main.dart'; // Access to navigatorKey (ancienne méthode)
import 'package:jelamvp01/utils/debug_log.dart'; // Pour les logs
import 'package:jelamvp01/screens/recipient_details_screen.dart'; // Le bon écran de destination
import 'package:firebase_auth/firebase_auth.dart'; // Pour obtenir l'utilisateur actuel (UID)
// ⛔️ À supprimer — Accès direct à Firestore remplacé par CurrentUserService — 2025/06/18
// import 'package:cloud_firestore/cloud_firestore.dart'; // Pour lire isReceiver
// ⛔️ FIN du bloc à supprimer — 2025/06/18
import 'package:jelamvp01/models/recipient.dart'; // Pour le type Recipient
import 'package:jelamvp01/models/user_profile.dart'; // ✅ AJOUT V004 (Correction Import) : Import du modèle UserProfile
import 'package:jelamvp01/services/pairing_service.dart'; // Pour charger les détails du destinataire
import 'package:jelamvp01/utils/service_locator.dart'; // Pour getIt (contient navigatorKey, PairingService et CurrentUserService)
import 'package:jelamvp01/services/current_user_service.dart'; // ✅ AJOUT V003 : Import de CurrentUserService

// ⛔️ À supprimer - Import de LoveScreen plus utilisé - 2025/06/16 19h45
// import 'package:jelamvp01/screens/love_screen.dart';

// --- FIN   DU BLOC Imports --- // (Ajout d'un commentaire de fin de bloc pour clarté)

class NotificationRouter {
  // Cette méthode est appelée par FcmService (pour les messages foreground/opened/initial).
  // Elle reçoit les données de la notification (qui devraient contenir au moins 'senderId').
  static Future<void> routeFromNotification(Map<String, dynamic> data) async { // Rendre async est correct

    final String? senderUid = data['senderId']; // Extraire le senderId de la map data

    if (senderUid == null || senderUid.isEmpty) {
      debugLog('⚠️ [NotificationRouter] Données de navigation manquantes ou invalides (senderId).', level: 'WARNING');
      // Naviguer vers l'écran principal si l'UID de l'expéditeur est manquant
      getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // Navigation par défaut
      return; // Sortie précoce
    }

    // Utilise FirebaseAuth pour vérifier si un utilisateur est connecté.
    // CurrentUserService peut être null si l'app vient juste de démarrer et l'auth n'est pas encore complètement initialisée.
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugLog('⚠️ [NotificationRouter] Utilisateur non connecté. Impossible de naviguer post-notification.', level: 'WARNING');
      // L'app devrait afficher l'écran de connexion via le StreamBuilder dans main().
      return; // Sortie précoce
    }

    if (currentUser.uid == senderUid) {
      debugLog('⚠️ [NotificationRouter] Clic sur notification de soi-même ($senderUid). Pas de navigation ciblée.', level: 'INFO');
      // Optionnel : naviguer vers l'écran principal si tu veux
      // getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/');
      return; // Sortie précoce
    }

    // ✅ MODIF V003 : Obtenir les données de l'utilisateur actuel depuis CurrentUserService
    final CurrentUserService currentUserService = getIt<CurrentUserService>();
    final UserProfile? currentUserProfile = currentUserService.userProfile;

    if (currentUserProfile == null) {
      debugLog('⚠️ [NotificationRouter] Profil utilisateur actuel non chargé dans CurrentUserService. Impossible de naviguer post-notification.', level: 'WARNING');
      // Le profil utilisateur devrait être chargé par CurrentUserService au moment où l'utilisateur est connecté.
      // Si CurrentUserService n'a pas encore chargé le profil, il y a potentiellement un problème d'initialisation
      // ou de synchronisation. Dans un MVP, naviguer par défaut peut être acceptable.
      getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // Navigation par défaut
      // TODO: Gérer ce cas d'erreur plus finement (ex: attendre le chargement du profil, afficher un message) (Étape 6.3.2)
      return; // Sortie précoce si le profil utilisateur n'est pas disponible
    }


    debugLog('➡️ [NotificationRouter] Tentative de navigation vers conversation avec $senderUid...', level: 'INFO');

    // Charger les données nécessaires pour RecipientDetailsScreen
    // ✅ MODIF V003 : Obtenir isReceiver et deviceLang depuis currentUserProfile
    final String currentUserDeviceLang = currentUserProfile.deviceLang; // Utilise la langue du profil
    final bool currentUserIsReceiver = currentUserProfile.isReceiver; // Utilise le rôle du profil

    // ⛔️ À supprimer — Logique de chargement direct de isReceiver/deviceLang depuis Firestore — 2025/06/18
    // String currentUserDeviceLang = PlatformDispatcher.instance.locale.languageCode; // Langue du device comme fallback
    // bool currentUserIsReceiver = false; // Valeur par défaut
    //
    // try {
    //   final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    //   if (userDoc.exists) {
    //     final userData = userDoc.data();
    //     currentUserIsReceiver = userData?['isReceiver'] == true;
    //     // La langue pourrait aussi être lue ici si stockée dans Firestore
    //     // currentUserDeviceLang = userData?['deviceLang'] ?? currentUserDeviceLang;
    //     debugLog("✅ [NotificationRouter] Données utilisateur (isReceiver) chargées depuis Firestore.", level: 'INFO');
    //   } else {
    //     debugLog("⚠️ [NotificationRouter] Document utilisateur actuel (${currentUser.uid}) non trouvé pour charger isReceiver.", level: 'WARNING');
    //   }
    // } catch (e) {
    //   debugLog("❌ [NotificationRouter] Erreur lors du chargement des données utilisateur : $e", level: 'ERROR');
    //   // Continuer avec les valeurs par défaut ou gérer l'erreur
    // }
    // ⛔️ FIN du bloc à supprimer — 2025/06/18


    Recipient? recipientDetails; // Initialise à null

    try {
      // Utilise le service PairingService pour charger les détails du destinataire
      // PairingService.getRecipientData utilise RecipientService.getRecipient en interne.
      recipientDetails = await getIt<PairingService>().getRecipientData(currentUser.uid, senderUid);
      debugLog("✅ [NotificationRouter] Détails destinataire ($senderUid) chargés via PairingService (qui utilise RecipientService).", level: 'INFO'); // ✅ MODIF log
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
      // Optionnel : naviguer vers l'écran principal si les détails du destinataire ne sont pas trouvés
      getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // Navigation par défaut en cas d'échec de chargement
    }
  }
} // <-- Fin de la classe NotificationRouter

// 📄 FIN de lib/navigation/notification_router.dart
