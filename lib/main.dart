// -------------------------------------------------------------
// 📄 FICHIER : lib/main.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Point d'entrée principal de l'application Flutter.
// ✅ Initialise Firebase et gère l'état d'authentification initial.
// ✅ Initialise le conteneur d'injection de dépendances (get_it) et enregistre les services/ressources.
// ✅ Détermine l'écran initial affiché à l'utilisateur (Login, Email Verification, HomeSelector, PairSuccessScreen).
// ✅ Gère les deep links d'appairage via app_links (logique déplacée vers un service dédié ultérieurement).
// ⛔️ La logique de la fonction d'appairage bilatéral 'pairUsers' a été commentée/déplacée vers PairingService.
// ✅ Gère la langue de l'appareil (via CurrentUserService - rôle réévalué ultérieurement, ou fallback système).
// ✅ Configure la gestion des messages FCM en arrière-plan, au premier plan, et à l'ouverture par clic (logique déplacée vers FcmService ultérieurement).
// ✅ Initialise le plugin flutter_local_notifications pour l'affichage local des notifications (logique déplacée vers FcmService ultérieurement).
// ✅ Rend le NavigatorKey global accessible via le conteneur d'injection.
// ✅ Rend le plugin flutter_local_notifications accessible via le conteneur d'injection.
// ✅ Implémente et enregistre les handlers de clic pour notifications locales (onDidReceiveNotificationResponse, onDidReceiveBackgroundNotificationResponse) - logique déplacée vers FcmService ultérieurement.
// ✅ Lit le statut isReceiver et la langue depuis Firestore/PlatformDispatcher dans les handlers de navigation post-notification si CurrentUserService n'est pas fiable à ce stade.
// ✅ Annule les subscriptions aux listeners FCM (onMessage, onMessageOpenedApp) dans dispose().
// ✅ Utilise la configuration de notification centralisée (notification_config.dart).
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V019 - Utilisation de notification_config.dart pour la configuration des notifications locales. Suppression des constantes de configuration locales. - 2025/06/16 18h56
// V018 - Commenté proprement la fonction pairUsers (devenue obsolète). Ajout d’un tag de dépréciation. Confirmation de la présence correcte du dispose(). Ajustement du plan d'action et vérification de la cohérence entre blocs. - 2025/06/13 19h50
// V017 - Intégration de get_it pour l'injection de dépendances. Remplacement des accès globaux à navigatorKey et flutterLocalNotificationsPlugin par des appels via getIt. Appel à setupLocator dans main(). Suppression (commentée) des déclarations globales de ces variables. Mise à jour de la description des fonctionnalités impactées dans l'en-tête. - 2025/06/11 17h25
// V016 - Suppression de la constante globale isReceiver ; lecture du statut isReceiver depuis Firestore dans les handlers de notification pour une source de vérité unique et fiable. - 2025/06/07
// V015 - Correction de l'avertissement '!' sur currentUser.uid et ajout de la parenthèse fermante manquante dans le listener onMessageOpenedApp. - 2025/06/07
// V014 - Initialisation du plugin flutter_local_notifications directement dans le handler background _firebaseMessagingBackgroundHandler. - 2025/06/07
// V013 - Ajout des listeners FCM onMessage (premier plan) et onMessageOpenedApp (clic sur notif). - 2025/06/07
// V012 - Déclaration globale du plugin flutterLocalNotificationsPlugin. - 2025/06/07
// V011 - Implémente et enregistre le handler onDidReceiveBackgroundNotificationResponse pour Android >= 13+. - 2025/06/04
// V010 - Implémente la logique de navigation pour les clics sur notifications locales (onDidReceiveNotificationResponse). - 2025/06/04
// V009 - Ajout d'un NavigatorKey global pour navigation hors contexte widget. - 2025/06/02
// V008 - Affichage de la notification locale dans le background handler FCM. - 2025/06/02
// V007 - Initialisation de flutter_local_notifications. - 2025/06/02
// V006 - Correction des appels internes à pairUsers. - 2025/05/30
// V005 - HomeSelector converti en StatefulWidget pour gérer le token FCM. - 2025/06/02
// V004 - Correction deviceLang dans un StatelessWidget. - 2025/05/30
// V003 - Refactoring vers UID Firebase. - 2025/05/29
// V002 - Ajout explicite du paramètre displayName. - 2025/05/24
// V001 - Version initiale nécessitant correction prénom utilisateur. - 2025/05/23
// -------------------------------------------------------------

// GEM - code corrigé et historique mis à jour par Gémini le 2025/06/13 21h25
// GEM - Import CurrentUserService commenté car plus utilisé dans main.dart - 2025/06/15

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Essentiel pour l'authentification basée sur l'utilisateur
import 'package:app_links/app_links.dart'; // Reste pour gérer les deep links
import 'dart:ui'; // Nécessaire pour PlatformDispatcher.instance.locale
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import nécessaire pour les notifs locales

// ✅ AJOUT : Import du service locator
import 'utils/service_locator.dart';

// ✅ AJOUT : Import de la configuration de notification centralisée
import 'services/notification_config.dart'; // Ajuste le chemin si nécessaire

// On importe les écrans principaux. Ils devront maintenant gérer l'UID via FirebaseAuth.currentUser
// ou le recevoir en paramètre si l'action concerne un autre utilisateur.
import 'screens/home_selector.dart';
import 'screens/login_screen.dart'; // Écran de connexion pour les utilisateurs non connectés
import 'screens/email_verification_screen.dart'; // Écran de vérification pour les nouveaux comptes

import 'firebase_options.dart';
import 'utils/debug_log.dart'; // Votre utilitaire de log

import 'package:jelamvp01/models/recipient.dart'; // Importe le modèle Recipient
import 'package:jelamvp01/screens/recipient_details_screen.dart'; // Importe l'écran de chat

// ⛔️ À supprimer - Import CurrentUserService plus utilisé dans ce fichier - 2025/06/15
// import 'package:jelamvp01/services/current_user_service.dart'; // ASSURE-TOI QUE CE CHEMIN EST CORRECT
// TODO: Etape 2 - Réévaluer le rôle de CurrentUserService // Ce TODO reste pour la refacto future
import 'package:jelamvp01/services/pairing_service.dart'; // ✅ AJOUT : Import de PairingService

// --- FIN   DU BLOC 01 ---

// --- DEBUT DU BLOC 02 ---

// Déclare un Navigator Key global. Utilisé pour naviguer depuis des contextes sans BuildContext (comme les handlers FCM).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Instance du plugin local de notifications - Reste en dehors de main()
// Doit être accessible par le background handler et potentiellement d'autres parties de l'app
// ⛔️ À supprimer - plugin désormais injecté via getIt - 2025/06/12
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// TODO: Définir les détails de la notification Android une fois (peut-être dans un service ou ici)
// Ces détails sont réutilisés pour toutes les notifications Android.
// ⛔️ À supprimer - Logique déplacée vers notification_config.dart - 2025/06/15
// const AndroidNotificationDetails androidPlatformChannelSpecifics =
// AndroidNotificationDetails(
//   'messages_channel', // ID du canal (doit être unique pour ton app)
//   'Notifications de Messages', // Nom du canal visible par l'utilisateur dans les paramètres Android
//   channelDescription: 'Notifications pour les nouveaux messages reçus', // Description du canal
//   importance: Importance.high, // Importance élevée pour qu'elle soit visible
//   priority: Priority.high,
//   // Son personnalisé ? Il faut l'ajouter aux ressources Android et le référencer ici.
//   // sound: RawResourceAndroidNotificationSound('notification_sound'), // Exemple: 'notification_sound.wav' dans res/raw
//   // Icônes personnalisées ?
//   // largeIcon: FilePathAndroidBitmap('chemin/vers/grande_icone.png'), // Chemin vers une image dans les assets/res
//   // smallIcon: '@mipmap/ic_launcher', // Doit être une ressource Android (xml vector ou png) dans mipmap/drawable
//   // L'icône par défaut de l'app (@mipmap/ic_launcher) est souvent utilisée si smallIcon n'est pas spécifié.
// );

// Détails de la notification pour différentes plateformes (pour l'instant, principalement Android)
// ⛔️ À supprimer - Logique déplacée vers notification_config.dart - 2025/06/15
// const NotificationDetails platformChannelSpecifics =
// NotificationDetails(android: androidPlatformChannelSpecifics);


// TOP LEVEL FUNCTION: obligatoire pour le background handler FCM
// Elle DOIT être déclarée en dehors de toute classe ou fonction
// Le décorateur @pragma('vm:entry-point') est crucial pour les versions récentes de Flutter/Dart.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Assurer que Firebase est initialisé, car cette fonction peut s'exécuter en dehors du contexte principal
  // où main() a été appelé. Vérifier Firebase.apps.isEmpty est une bonne pratique pour éviter la double initialisation.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugLog("🖙 [FCM-BG] Firebase initialisé dans le background handler.", level: 'INFO');
  }

  debugLog("🖙 [FCM-BG] Message reçu en arrière-plan : ${message.messageId}", level: 'INFO');
  debugLog("🖙 [FCM-BG] Notification payload: ${message.notification?.title} / ${message.notification?.body}", level: 'DEBUG');
  debugLog("🖙 [FCM-BG] Data payload: ${message.data}", level: 'DEBUG');

  // --- Logique pour afficher une notification locale ---
  // Cette logique s'exécute UNIQUEMENT si l'app est en arrière-plan ou terminée.
  // Si l'app est au premier plan, le message est géré par FirebaseMessaging.onMessage (à implémenter plus tard).

  RemoteNotification? notification = message.notification;
  // On vérifie si le message contient une partie 'notification' visible par l'OS.
  // Dans la Cloud Function, nous avons mis un titre et un corps dans ce champ.
  // On vérifie aussi message.data.isNotEmpty car le champ 'data' est toujours
  // passé au handler même si le champ 'notification' n'y est pas, et contient
  // les infos (senderId, messageId, etc.) dont nous avons besoin pour potentiellement le clic.
  if (notification != null && message.data.isNotEmpty) {
    try {
      // Utilise flutter_local_notifications pour afficher la notification locale.
      // Chaque notification a besoin d'un ID entier unique. Si tu envoies plusieurs
      // notifications (ex: plusieurs messages), chaque nouvelle notif devrait avoir un ID
      // différent, sinon elle écraserait la précédente dans la barre de notifs.
      // Utiliser messageId (qui est une String) ne fonctionne pas directement ici.
      // Il faut générer un ID entier unique. Utiliser un hash basé sur l'ID du message
      // ou l'UID de l'expéditeur est une option simple. Assure-toi que le hash est un int.
      // Un ID basé sur le temps (DateTime.now().millisecondsSinceEpoch % 2147483647)
      // peut aussi être utilisé, mais ne regroupe pas les notifs par conversation.
      // Pour l'instant, utilisons un hash simple de l'ID du message pour avoir un ID "unique" par message.
      // Conversion de l'ID String en un entier unique (potentiellement en utilisant String.hashCode)
      final int notificationId = message.messageId.hashCode; // Utilise le hash de l'ID message comme ID de notif locale

      // Le 'payload' de show() est une chaîne de caractères qui est renvoyée
      // quand l'utilisateur clique sur la notification. Il doit contenir les
      // informations nécessaires (comme l'UID de l'expéditeur) pour que l'app
      // puisse naviguer vers la bonne conversation au clic.
      // On utilise les données personnalisées ('data') envoyées par la Cloud Function.
      // IMPORTANT: Ce payload doit être une STRING.
      final String notificationClickPayload = message.data['senderId'] ?? ''; // Exemple: passe l'UID de l'expéditeur comme payload

      await getIt<FlutterLocalNotificationsPlugin>().show( // <-- Utilisation de getIt ici
        notificationId, // ID unique de la notification locale (entier)
        notification.title, // Titre de la notification (vient du champ 'notification' FCM)
        notification.body, // Corps de la notification (vient du champ 'notification' FCM)
        // ⛔️ À remplacer - Utilise messageNotificationDetails de notification_config.dart - 2025/06/15
        // platformChannelSpecifics, // Détails spécifiques à la plateforme (Android) définis plus haut
        messageNotificationDetails, // ✅ Remplacé par messageNotificationDetails de notification_config.dart
        payload: notificationClickPayload, // Données passées à l'app lors du clic (String)
      );
      debugLog("🔔 [FCM-BG] Notification locale affichée (ID: $notificationId). Payload clic: $notificationClickPayload", level: 'INFO');

    } catch (e) {
      debugLog("❌ [FCM-BG] Erreur lors de l'affichage de la notification locale : $e", level: 'ERROR');
    }
  } else {
    debugLog("🖙 [FCM-BG] Message reçu ne contient pas les données suffisantes pour l'affichage local de notification.", level: 'DEBUG');
    // Ce cas pourrait arriver si la Cloud Function n'inclut pas le champ 'notification'
    // ou les données nécessaires dans le champ 'data'.
    // Tu peux aussi traiter les messages qui contiennent UNIQUEMENT des données ('data') ici
    // en construisant la notification locale à partir de message.data si nécessaire.
    // Exemple: if (message.data.isNotEmpty) { buildAndShowLocalNotificationFromData(message.data); }
  }


  // TODO: Ajouter ici toute autre logique nécessaire en arrière-plan (ex: sauvegarder dans Firestore, etc.)
  // Note: Le temps d'exécution des background handlers est limité par l'OS. Ne fais pas d'opérations longues ou complexes.

  // Le handler doit retourner un Future<void> et ne pas se terminer prématurément.
  // Toutes les opérations asynchrones (comme show()) doivent être await-ées.
  return Future<void>.value(); // Explicitly return a completed Future<void>
} // <-- FIN DE LA FONCTION _firebaseMessagingBackgroundHandler

// --- FIN   DU BLOC 02 ---

// --- DEBUT DU BLOC 03 ---

// Capture et gestion des liens d'appairage via app_links.
// Cette fonction suppose maintenant que l'utilisateur est CONNECTÉ lorsqu'il clique sur un lien d'appairage.
// Le lien devrait contenir l'UID Firebase de l'inviteur ('recipient' est l'inviteur).
Future<String?> handleAppLinks() async {
  final AppLinks appLinks = AppLinks();

  // Écoute des liens d'appairage à chaud pendant que l'app est ouverte
  appLinks.uriLinkStream.listen((Uri? uri) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && uri != null && uri.queryParameters.containsKey('recipient')) {
      final String? recipientInviterUid = uri.queryParameters['recipient']; // C'est l'UID de l'inviteur
      if (recipientInviterUid != null && recipientInviterUid.isNotEmpty && currentUser.uid != recipientInviterUid) {
        debugLog("📨 AppLink (stream) → Inviteur UID=$recipientInviterUid", level: 'INFO');
        // Tente d'appairer cet utilisateur (currentUser.uid) avec l'inviteur (recipientInviterUid)
        // ⛔️ À remplacer - appel à la fonction locale pairUsers
        // final String? pairedWithUid = await pairUsers(recipientInviterUid, currentUser.uid);
        // ✅ Remplacé par appel PairingService
        try {
          await getIt<PairingService>().pairUsers(currentUser.uid, recipientInviterUid);
          debugLog("✅ Appairage stream réussi avec UID $recipientInviterUid", level: 'SUCCESS');
          // TODO: Potentiellement naviguer vers l'écran de succès ou rafraîchir la liste des destinataires
          // ou afficher une notification locale "Appairage réussi" si l'app n'est pas au premier plan.
          // Si l'app est au premier plan, une simple mise à jour de l'UI peut suffire.
        } catch (e) {
          debugLog("❌ Appairage stream échoué avec UID $recipientInviterUid : $e", level: 'ERROR');
          // Gérer l'erreur (afficher un message ?)
        }
      } else {
        debugLog("⚠️ AppLink stream reçu mais utilisateur non connecté, ou lien invalide, ou auto-appairage.", level: 'WARNING');
      }
    }
  });

  // Vérification d'un lien d'appairage initial lors du démarrage de l'app
  final Uri? initialUri = await appLinks.getInitialAppLink();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && initialUri != null && initialUri.queryParameters.containsKey('recipient')) {
    final String? recipientInviterUid = initialUri.queryParameters['recipient']; // C'est l'UID de l'inviteur
    if (recipientInviterUid != null && recipientInviterUid.isNotEmpty && currentUser.uid != recipientInviterUid) {
      debugLog("📨 AppLink (initial) → Inviteur UID=$recipientInviterUid", level: 'INFO');
      // Tente d'appairer cet utilisateur (currentUser.uid) avec l'inviteur (recipientInviterUid)
      // ⛔️ À remplacer - appel à la fonction locale pairUsers
      // final String? pairedWithUid = await pairUsers(recipientInviterUid, currentUser.uid);
      // ✅ Remplacé par appel PairingService
      try {
        await getIt<PairingService>().pairUsers(currentUser.uid, recipientInviterUid);
        debugLog("✅ Appairage initial réussi avec UID $recipientInviterUid", level: 'SUCCESS');
        return recipientInviterUid; // Retourne l'UID du destinataire appairé pour affichage initial

      } catch (e) {
        debugLog("❌ Appairage initial échoué avec UID $recipientInviterUid : $e", level: 'ERROR');
        // Gérer l'erreur (afficher un message ?)
        return null; // Aucun appairage initial via lien réussi
      }
    } else {
      debugLog("⚠️ AppLink initial reçu mais utilisateur non connecté, ou lien invalide, ou auto-appairage.", level: 'WARNING');
    }
  }

  return null; // Aucun appairage initial via lien (ou échec)
}

// --- FIN   DU BLOC 03 ---

// --- DEBUT DU BLOC 04 ---

// ⛔️ À supprimer — Obsolète depuis l'implémentation de PairingService — 2025/06/13
/*

// Fonction d'appairage bilatéral entre deux utilisateurs (identifiés par UID)
// Met à jour les collections 'recipients' sous les UID des deux utilisateurs dans Firestore.
// userAId est l'UID de l'utilisateur qui a partagé le lien (l'inviteur)
// userBId est l'UID de l'utilisateur qui a cliqué sur le lien (l'invité, l'utilisateur actuel)
Future<String?> pairUsers(String userAId, String userBId) async {
  if (userAId.isEmpty || userBId.isEmpty || userAId == userBId) {
    debugLog("⚠️ Appairage tenté avec UID(s) invalide(s) ou auto-appairage.", level: 'WARN');
    return null;
  }
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Récupérer les noms d'affichage des deux utilisateurs pour les mettre dans les objets Recipient
    // On doit s'assurer que les documents utilisateurs existent avant de tenter de lire firstName.
    final userASnap = await firestore.collection('users').doc(userAId).get();
    final userADisplayName = userASnap.exists ? (userASnap.data()?['firstName'] ?? 'Utilisateur A') : 'Utilisateur A'; // Default name if doc doesn't exist or no firstName
    final userBSnap = await firestore.collection('users').doc(userBId).get();
    final userBDisplayName = userBSnap.exists ? (userBSnap.data()?['firstName'] ?? 'Utilisateur B') : 'Utilisateur B'; // Default name if doc doesn't exist or no firstName

    // 1. Ajouter l'utilisateur B comme destinataire chez l'utilisateur A
    // Chemin : users/{userAId}/recipients/{userBId}
    await firestore
        .collection('users')
        .doc(userAId)
        .collection('recipients')
        .doc(userBId) // ID du document est l'UID de l'autre utilisateur
        .set({
      'id': userBId, // Inclure l'UID aussi comme champ pour faciliter les requêtes futures si besoin
      'displayName': userBDisplayName, // Le nom de l'utilisateur B vu par A
      'icon': '💌', // Icône par défaut
      'relation': 'relation_partner', // Relation par défaut
      'allowedPacks': [], // Packs par défaut
      'paired': true, // Marqué comme appairé
      'catalogType': 'partner', // Type de catalogue par défaut
      'createdAt': FieldValue.serverTimestamp(), // Horodatage de création
    }, SetOptions(merge: true)); // Utilise merge pour ne pas écraser d'autres champs si le doc existe déjà

    // 2. Ajouter l'utilisateur A comme destinataire chez l'utilisateur B
    // Chemin : users/{userBId}/recipients/{userAId}
    await firestore
        .collection('users')
        .doc(userBId)
        .collection('recipients')
        .doc(userAId) // ID du document est l'UID de l'autre utilisateur
        .set({
      'id': userAId, // Inclure l'UID aussi comme champ
      'displayName': userADisplayName, // Le nom de l'utilisateur A vu par B
      'icon': '💌', // Icône par défaut
      'relation': 'relation_partner', // Relation par défaut
      'allowedPacks': [], // Packs par défaut
      'paired': true, // Marqué comme appairé
      'catalogType': 'partner', // Type de catalogue par défaut
      'createdAt': FieldValue.serverTimestamp(), // Horodatage de création
    }, SetOptions(merge: true));

    debugLog("✅ Appairage réussi entre UID $userAId et UID $userBId", level: 'SUCCESS');
    return userAId; // Retourne l'UID de l'inviteur pour confirmation
  } catch (e) {
    debugLog("❌ Erreur d’appairage Firestore entre $userAId et $userBId : $e", level: 'ERROR');
    // TODO: Gérer cette erreur (afficher message à l'utilisateur ?)
    return null;
  }
} // <-- Fin de la fonction pairUsers

*/
// ⛔️ FIN du bloc à supprimer — 2025/06/13

// --- FIN   DU BLOC 04 ---

// --- DEBUT DU BLOC 05 ---

Future<void> main() async {
  // Assure que les bindings Flutter sont initialisés. Crucial avant d'appeler des méthodes natives (comme Firebase ou les notifs locales).
  WidgetsFlutterBinding.ensureInitialized();
  debugLog("🛠️ WidgetsFlutterBinding initialized", level: 'INFO');

  setupLocator(); // <-- Ligne à ajouter ici
  debugLog("🛠️ Service locator initialisé", level: 'INFO');

  // Initialisation de Firebase
  await Firebase.initializeApp();
  debugLog("✅ Firebase initialized", level: 'INFO');

  // Ajouté pour connaitre le token FCM d'un téléphone qui se connecte
  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugLog("📱 Token FCM : $fcmToken", level: 'INFO');

  // Initialisation de flutter_local_notifications TRES TOT
  // Configurer les paramètres spécifiques à Android (utilise les détails définis plus haut)
  // Assure-toi que les 'androidPlatformChannelSpecifics' et 'platformChannelSpecifics' sont définis AVANT cet appel.
  // ⛔️ À supprimer - Initialisation déplacée vers FcmService.initializeLocalNotifications() - 2025/06/15
  // const AndroidInitializationSettings initializationSettingsAndroid =
  // AndroidInitializationSettings('@mipmap/ic_launcher'); // Utilise l'icône de ton app

  // TODO: Ajouter la configuration pour iOS si tu vises cette plateforme
  // ⛔️ À supprimer - Initialisation déplacée vers FcmService.initializeLocalNotifications() - 2025/06/15
  // const InitializationSettings initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  //   // ios: IOSInitializationSettings(
  //   //   onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Nécessaire pour iOS <= 10
  //   // ),
  // );

  // Effectuer l'initialisation du plugin.
  // onDidReceiveNotificationResponse gère les clics sur la notification quand l'app est au premier plan ou en arrière-plan.
  // onDidReceiveBackgroundNotificationResponse gère les clics quand l'app est terminée sur Android >= 13+.
  // Nous allons aborder la logique à l'intérieur de ces handlers plus tard.
  // ⛔️ À supprimer - Initialisation déplacée vers FcmService.initializeLocalNotifications() - 2025/06/15
  // await getIt<FlutterLocalNotificationsPlugin>().initialize(
  //     initializationSettings,
  //     onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
  //       debugLog("🔔 [MAIN] Clic sur notification (ouverte/background). Payload: ${notificationResponse.payload}", level: 'INFO');
  //
  //       final String? senderUid = notificationResponse.payload; // Le payload est l'UID de l'expéditeur
  //
  //       if (senderUid != null && senderUid.isNotEmpty) {
  //         debugLog('➡️ [MAIN - NOTIF CLICK] Déclencher logique de navigation vers conversation avec $senderUid', level: 'INFO');
  //
  //         // Utilise CurrentUserService pour obtenir les données de l'utilisateur actuel.
  //         // On suppose que CurrentUserService a été initialisé (typiquement dans HomeSelector).
  //         // Si l'app est ouverte par une notification depuis l'état terminé, Flutter initie main()
  //         // et getInitialMessage est appelé avant runApp qui affiche l'UI.
  //         HomeSelector
  //         // sera l'écran initial pour un utilisateur connecté, et c'est là que CurrentUserService
  //         // est initialisé. Donc au moment d'un clic, CurrentUserService devrait être prêt.
  //         final String currentUserDeviceLang = CurrentUserService().deviceLang;
  //         // ⛔️ À modifier - Variable 'currentUserIsReceiver' déclarée final, incompatible avec réassignation ci-dessous - 2025/06/14
  //         // final bool currentUserIsReceiver = CurrentUserService().isReceiver;
  //         bool currentUserIsReceiver = CurrentUserService().isReceiver; // ✅ Correction : Déclarée comme non-final
  //
  //         final User? currentUser = FirebaseAuth.instance.currentUser;
  //         Recipient? recipientDetails; // Initialise à null
  //
  //         // S'assurer que l'utilisateur actuel est connecté avant de tenter de charger les destinataires
  //         if (currentUser != null && currentUser.uid != senderUid) { // Ajoute aussi une vérification pour ne pas naviguer vers soi-même
  //           // TODO: Etape 3 - Déplacer cet accès Firestore vers FirestoreService.get...()
  //           try {
  //             final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
  //             if (userDoc.exists) {
  //               final userData = userDoc.data();
  //               currentUserIsReceiver = userData?['isReceiver'] == true; // <= PLUS D ERREUR ICI
  //               // Tu pourrais aussi stocker la langue préférée de l'utilisateur dans son doc si tu ne veux pas utiliser PlatformDispatcher
  //               // currentUserDeviceLang = userData?['deviceLang'] ?? PlatformDispatcher.instance.locale.languageCode;
  //               debugLog("✅ [MAIN - NOTIF CLICK] Données utilisateur (isReceiver) chargées depuis Firestore pour navigation.", level: 'INFO');
  //             } else {
  //               debugLog("⚠️ [MAIN - NOTIF CLICK] Document utilisateur actuel (${currentUser.uid}) non trouvé pour charger isReceiver.", level: 'WARNING');
  //             }
  //           } catch (e) {
  //             debugLog("❌ [MAIN - NOTIF CLICK] Erreur lors du chargement des données utilisateur pour navigation : $e", level: 'ERROR');
  //             // Gérer l'erreur (ex: ne pas naviguer, afficher un message d'erreur)
  //           }
  //
  //           // Charger les détails du destinataire pour la navigation.
  //           // Recipient? recipientDetails; // Initialise à null // Déclarée en dehors du if
  //
  //           // TODO: Etape 3 - Déplacer cet accès Firestore vers FirestoreService.getRecipient(...) // ⛔️ À supprimer - Logique déplacée vers PairingService - 2025/06/14
  //           // try {
  //           //   final recipientSnap = await FirebaseFirestore.instance
  //           //       .collection('users')
  //           //       .doc(currentUser.uid) // UID de l'utilisateur actuellement connecté (currentUser est non-null ici)
  //           //       .collection('recipients')
  //           //       .doc(senderUid) // L'UID du document est l'UID de l'expéditeur
  //           //       .get(); // <-- Cette ligne termine l'appel .doc(...).get()
  //           //
  //           //   if (recipientSnap.exists) {
  //           //     final data = recipientSnap.data();
  //           //     recipientDetails = Recipient(
  //           //       id: senderUid, // L'UID du destinataire (l'expéditeur du message)
  //           //       displayName: data?['displayName'] ?? 'Inconnu',
  //           // Nom d'affichage du destinataire (si trouvé dans Firestore)
  //           //       icon: data?['icon'] ?? '💬', // Icône par défaut si non trouvée
  //           //       relation: data?['relation'] ?? 'relation_partner', // Relation par défaut si non trouvée
  //           //       allowedPacks: (data?['allowedPacks'] as List?)?.cast<String>() ?? [], // Gérer la liste
  //           //       paired: data?['paired'] == true, // Gérer le booléen
  //           //       catalogType: data?['catalogType'] ?? 'partner', // Type de catalogue
  //           //       createdAt: data?['createdAt'] as Timestamp?, // Timestamp
  //           //     );
  //           //     debugLog("✅ [MAIN - NOTIF CLICK] Détails destinataire ($senderUid) chargés pour navigation.", level: 'INFO');
  //           //
  //           //   } else {
  //           //     debugLog("⚠️ [MAIN - NOTIF CLICK] Destinataire ($senderUid) non trouvé dans la liste de l'utilisateur actuel pour navigation.", level: 'WARNING');
  //           // // Optionnel: Naviguer vers l'écran principal ou afficher un message si le destinataire n'est pas appairé.
  //           // // ✅ Utilisation de getIt pour accéder au navigatorKey
  //           // // getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // TODO: Revoir la navigation
  //           // // navigatorKey.currentState?.pushReplacementNamed('/');
  //           // }
  //           // } catch (e) {
  //           // debugLog("❌ [MAIN - NOTIF CLICK] Erreur lors du chargement des détails du destinataire ($senderUid) pour navigation : $e", level: 'ERROR');
  //           // // Gérer l'erreur (ex: ne pas naviguer, afficher un message d'erreur)
  //           // }
  //           // ✅ Remplacé par appel PairingService
  //           try {
  //             recipientDetails = await getIt<PairingService>().getRecipientData(currentUser.uid, senderUid);
  //             debugLog("✅ [MAIN - NOTIF CLICK] Détails destinataire ($senderUid) chargés via PairingService.", level: 'INFO');
  //           } catch (e) {
  //             debugLog("❌ [MAIN - NOTIF CLICK] Erreur lors du chargement des détails du destinataire ($senderUid) via PairingService : $e", level: 'ERROR');
  //             recipientDetails = null; // Assurer que recipientDetails est null en cas d'erreur
  //           }
  //
  //
  //           // Naviguer si les details du destinataire sont trouvés.
  //           if (recipientDetails != null) {
  //             // Utilise le navigatorKey global pour naviguer.
  //             // Assure-toi que la navigation se fait après que l'UI initiale soit construite.
  //             // Utiliser un Future.delayed(Duration.zero) est parfois utile pour s'assurer
  //             // que la navigation est poussée après le rendu initial.
  //             Future.delayed(Duration.zero, () { // Utilise un petit délai pour la robustesse
  //               // ✅ Utilisation de getIt pour accéder au navigatorKey
  //               getIt<GlobalKey<NavigatorState>>().currentState?.push(MaterialPageRoute( // <-- Utilisation de getIt ici
  //                 //navigatorKey.currentState?.push(MaterialPageRoute(
  //                 builder: (context) => RecipientDetailsScreen(
  //                   deviceLang: currentUserDeviceLang, // Langue de l'utilisateur actuel via CurrentUserService
  //                   recipient: recipientDetails!, // Objet Recipient chargé
  //                   isReceiver: currentUserIsReceiver, // Rôle de l'utilisateur actuel via CurrentUserService
  //                 ),
  //               ));
  //               debugLog("➡️ [MAIN - NOTIF CLICK] Navigation vers RecipientDetailsScreen réussie pour UID destinataire $senderUid", level: 'INFO');
  //             });
  //
  //           } else {
  //             debugLog("⚠️ [MAIN - NOTIF CLICK] Navigation vers RecipientDetailsScreen annulée car détails destinataire non chargés.", level: 'WARNING');
  //             // Optionnel : Naviguer vers l'écran principal si la navigation ciblée échoue
  //             // ✅ Utilisation de getIt pour accéder au navigatorKey
  //             // Future.delayed(Duration.zero, () { // <-- Ligne à modifier ici
  //             //   getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/');
  //             // }); // TODO: Revoir la navigation si les détails du destinataire ne sont pas trouvés
  //           }
  //
  //         } else {
  //           debugLog('⚠️ [MAIN - NOTIF CLICK] Payload senderId manquant ou invalide dans la réponse de notification. Pas de navigation ciblée.', level: 'WARNING');
  //           // Le payload ne contient pas l'UID de l'expéditeur. L'app continuera son flux normal.
  //         }
  //       }
  //       // Pour Android >= 13+, il est recommandé d'enregistrer un handler spécifique pour les clics
  //       // lorsque l'application est complètement terminée. Ce handler doit aussi être une fonction de top-level.
  //       onDidReceiveBackgroundNotificationResponse ; }
  // );
  // ⛔️ FIN du bloc à supprimer - Initialisation déplacée vers FcmService.initializeLocalNotifications() - 2025/06/15
  // debugLog("🔔 flutter_local_notifications initialisé", level: 'INFO');

  // Enregistrement du background handler FCM TRES TOT, juste après ensureInitialized et les notifs locales
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  debugLog("🖙 FCM background handler enregistré", level: 'INFO');

  // Initialiser Firebase (important avant d'utiliser Firebase Auth ou Firestore)
  // Assure-toi que ton fichier firebase_options.dart est correct.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  debugLog("✨ Firebase initialisé", level: 'INFO');

  // Attendre que Firebase Auth récupère l'état de connexion persistant.
  // Cela est crucial pour savoir si un utilisateur est déjà connecté au démarrage.
  await FirebaseAuth.instance.authStateChanges().first;
  debugLog("👤 État d'auth Firebase synchronisé", level: 'INFO');

  // La langue du téléphone reste utile pour l'internationalisation et peut être récupérée indépendamment de l'identifiant utilisateur.
  final String deviceLang = PlatformDispatcher.instance.locale.languageCode; // La langue reste importante
  debugLog("🌐 Langue du téléphone : $deviceLang", level: 'INFO');

  // TODO: La sauvegarde/mise à jour du token FCM est maintenant gérée par le FcmService
  // qui est appelé dans HomeSelector après authentification/vérification email réussie.
  // Nous n'avons plus besoin de cette logique ici dans main().

  final String? initialPairedRecipientUid = await handleAppLinks();

  // ⛔️ À supprimer - Traitement du message initial déplacé vers FcmService.initializeFcmHandlers() - 2025/06/15
  // FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) async { // <-- Début de l'appel .then()
  //   if (message != null) { // <-- Début du bloc si message non null
  //     debugLog("🔔 [MAIN] App ouverte par notif initiale: ${message.messageId}", level: 'INFO');
  //     debugLog("🔔 [MAIN] Data payload from initial message: ${message.data}", level: 'DEBUG');
  //
  //     final String? senderUid = message.data['senderId']; // Le champ est 'senderId' dans ton payload de Cloud Function
  //
  //     if (senderUid != null && senderUid.isNotEmpty) { // <-- Début du bloc si senderUid non null/vide
  //       debugLog('➡️ [MAIN - INITIAL MESSAGE] Déclencher logique de navigation vers conversation avec $senderUid', level: 'INFO');
  //
  //       // Ces variables doivent être déclarées AVANT les blocs conditionnels où elles sont utilisées.
  //       // La langue du téléphone peut être obtenue via PlatformDispatcher.
  //       final String currentUserDeviceLang = PlatformDispatcher.instance.locale.languageCode; // Utilise PlatformDispatcher
  //       bool currentUserIsReceiver = false; // Valeur par défaut prudente. Sera chargée depuis Firestore si utilisateur connecté.
  //
  //       final User? currentUser = FirebaseAuth.instance.currentUser;
  //       Recipient? recipientDetails; // Initialise à null
  //
  //       // --- DÉBUT DE LA CHAÎNE IF/ELSE IF POUR currentUser ---
  //       // Ce bloc vérifie l'état de l'utilisateur actuel et charge ses données/celles du destinataire si nécessaire.
  //       if (currentUser != null && currentUser.uid != senderUid) { // <-- Début du bloc si l'utilisateur est connecté et n'est pas l'expéditeur
  //         // Charger les données isReceiver depuis Firestore si l'utilisateur est connecté.
  //         // TODO: Etape 3 - Déplacer cet accès Firestore vers FirestoreService.get...() // ⛔️ À supprimer - Logique déplacée vers CurrentUserService (futur) ou FirestoreService - 2025/06/14
  //         try {
  //           final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
  //           if (userDoc.exists) {
  //             final userData = userDoc.data();
  //             currentUserIsReceiver = userData?['isReceiver'] == true;
  //             // Tu pourrais aussi stocker la langue préférée de l'utilisateur dans son doc si tu ne veux pas utiliser PlatformDispatcher
  //             // currentUserDeviceLang = userData?['deviceLang'] ?? PlatformDispatcher.instance.locale.languageCode;
  //             debugLog("✅ [MAIN - INITIAL MESSAGE] Données utilisateur (isReceiver) chargées depuis Firestore pour navigation.", level: 'INFO');
  //           } else {
  //             debugLog("⚠️ [MAIN - INITIAL MESSAGE] Document utilisateur actuel (${currentUser.uid}) non trouvé pour charger isReceiver.", level: 'WARNING');
  //           }
  //         } catch (e) {
  //           debugLog("❌ [MAIN - INITIAL MESSAGE] Erreur lors du chargement des données utilisateur pour navigation : $e", level: 'ERROR');
  //           // Gérer l'erreur (ex: ne pas naviguer, afficher un message d'erreur)
  //         }
  //
  //         // Charger les détails du destinataire pour la navigation.
  //         // Recipient? recipientDetails; // Initialise à null // Déclarée en dehors du if
  //
  //         // TODO: Etape 3 - Déplacer cet accès Firestore vers FirestoreService.getRecipient(...) // ⛔️ À supprimer - Logique déplacée vers PairingService - 2025/06/14
  //         // try {
  //         //   final recipientSnap = await FirebaseFirestore.instance
  //         //       .collection('users')
  //         //       .doc(currentUser.uid) // UID de l'utilisateur actuellement connecté (currentUser est non-null ici)
  //         //       .collection('recipients')
  //         //       .doc(senderUid) // L'UID du document est l'UID de
  //         //       .get(); // <-- Cette ligne termine l'appel .doc(...).get()
  //         //
  //         //   if (recipientSnap.exists) {
  //         //     final data = recipientSnap.data();
  //         //     recipientDetails = Recipient(
  //         //       id: senderUid, // L'UID du destinataire (l'expéditeur du message)
  //         //       displayName: data?['displayName'] ?? 'Inconnu', // Nom d'affichage du destin
  //         //       icon: data?['icon'] ?? '💬', // Icône par défaut si non trouvée
  //         //       relation: data?['relation'] ?? 'relation_partner', // Relation par défaut si non trouvée
  //         //       allowedPacks: (data?['allowedPacks'] as List?)?.cast<String>() ?? [], // Gérer la liste
  //         //       paired: data?['paired'] == true, // Gérer le booléen
  //         //       catalogType: data?['catalogType'] ?? 'partner', // Type de catalogue
  //         //       createdAt: data?['createdAt'] as Timestamp?, // Timestamp
  //         //     );
  //         //     debugLog("✅ [MAIN - INITIAL MESSAGE] Détails destinataire ($senderUid) chargés pour navigation.", level: 'INFO');
  //         //
  //         //   } else {
  //         //     debugLog("⚠️ [MAIN - INITIAL MESSAGE] Destinataire ($senderUid) non trouvé dans la liste de l'utilisateur actuel (${currentUser.uid}) pour navigation.", level: 'WARNING');
  //         //       // Optionnel: Naviguer vers l'écran principal ou afficher un message si le destinataire n'est pas appairé.
  //         //       // getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // TODO: Revoir la navigation
  //         //       // navigatorKey.currentState?.pushReplacementNamed('/');
  //         //   }
  //         // } catch (e) {
  //         //   debugLog("❌ [MAIN - INITIAL MESSAGE] Erreur lors du chargement des détails du destinataire ($senderUid) pour navigation : $e", level: 'ERROR');
  //         //   // Gérer l'erreur (ex: ne pas naviguer, afficher un message d'erreur)
  //         // }
  //         // ✅ Remplacé par appel PairingService
  //         try {
  //           recipientDetails = await getIt<PairingService>().getRecipientData(currentUser.uid, senderUid);
  //           debugLog("✅ [MAIN - INITIAL MESSAGE] Détails destinataire ($senderUid) chargés via PairingService.", level: 'INFO');
  //         } catch (e) {
  //           debugLog("❌ [MAIN - INITIAL MESSAGE] Erreur lors du chargement des détails du destinataire ($senderUid) via PairingService : $e", level: 'ERROR');
  //           recipientDetails = null; // Assurer que recipientDetails est null en cas d'erreur
  //         }
  //
  //
  //         // Naviguer si les details du destinataire sont trouvés.
  //         if (recipientDetails != null) {
  //           // Utilise le navigatorKey global pour naviguer via getIt.
  //           // Utiliser Future.delayed(Duration.zero) est une bonne pratique ici aussi.
  //           Future.delayed(Duration.zero, () {
  //             getIt<GlobalKey<NavigatorState>>().currentState?.push(MaterialPageRoute( // <-- getIt usage #1 (corrected)
  //               builder: (context) => RecipientDetailsScreen(
  //                 deviceLang: currentUserDeviceLang, // Langue - lue depuis Firestore ou PlatformDispatcher
  //                 recipient: recipientDetails!, // Objet Recipient chargé
  //                 isReceiver: currentUserIsReceiver, // Rôle de l'utilisateur actuel - lue depuis Firestore
  //               ),
  //             ));
  //             debugLog("➡️ [MAIN - INITIAL MESSAGE] Navigation vers RecipientDetailsScreen réussie pour UID destinataire $senderUid", level: 'INFO');
  //           });
  //         } else {
  //           debugLog("⚠️ [MAIN - INITIAL MESSAGE] Navigation vers RecipientDetailsScreen annulée car détails destinataire non chargés ou introuvables.", level: 'WARNING');
  //           // Optionnel : Naviguer vers l'écran principal si la navigation ciblée échoue
  //           // getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // <-- getIt usage #2 (commented duplicate)
  //         }
  //
  //       } else if (currentUser == null) { // <-- Début du bloc si l'utilisateur n'est pas connecté
  //         debugLog("⚠️ [MAIN - INITIAL MESSAGE] Utilisateur actuel null lors du chargement des détails du destinataire pour navigation.", level: 'WARNING');
  //         // Si l'utilisateur actuel est null ici, c'est un problème de flux d'authentification.
  //         // Ne pas naviguer vers l'écran de chat.
  //       } else if (currentUser.uid == senderUid) { // <-- Début du bloc si c'est le même utilisateur
  //         debugLog("⚠️ [MAIN - INITIAL MESSAGE] Clic sur notification de soi-même ($senderUid). Pas de navigation ciblée.", level: 'INFO');
  //         // Ne rien faire ou naviguer vers l'écran principal si tu veux.
  //         // getIt<GlobalKey<NavigatorState>>().currentState?.pushReplacementNamed('/'); // <-- getIt usage #3 (commented)
  //       } // <-- Fin de la chaîne IF/ELSE IF POUR currentUser
  //
  //     } else { // <-- ELSE POUR `if (senderUid != null && senderUid.isNotEmpty)` (senderUid est null/vide)
  //       debugLog('⚠️ [MAIN - INITIAL MESSAGE] Payload senderId manquant ou invalide dans le message initial. Pas de navigation ciblée.', level: 'WARNING');
  //       // Le message initial n'a pas le bon format pour déclencher une navigation ciblée vers le chat.
  //       // L'application continuera son flux normal (affichage de LoveScreen si l'utilisateur est connecté, etc.)
  //     } // <-- Fin du bloc if (senderUid != null && senderUid.isNotEmpty)
  //
  //   } else { // <-- ELSE POUR `if (message != null)` (message est null)
  //     // Le message initial était null (l'application n'a pas été lancée par une notif FCM)
  //     debugLog('🖙 [MAIN - INITIAL MESSAGE] Aucun message FCM initial pour lancer l\'app.', level: 'INFO');
  //   } // <-- Fin du bloc if (message != null)
  //
  // }); // <-- Fin de l'appel .then()
  // ⛔️ FIN du bloc à supprimer - Traitement du message initial déplacé vers FcmService.initializeFcmHandlers() - 2025/06/15


  // Lance l'application principale ...
  runApp(MyApp(
    // deviceId: deviceId, // <-- SUPPRIMÉ du constructeur de MyApp
    deviceLang: deviceLang, // La langue reste pertinente
    // On passe l'UID de l'autre utilisateur si un appairage via deep link a réussi au démarrage
    initialPairSuccessRecipientUid: initialPairedRecipientUid,
  ));
}

// --- FIN   DU BLOC 05 ---

// --- DEBUT DU BLOC 06 ---

// Le widget racine de l'application.
// Utilise StreamBuilder pour écouter l'état d'authentification Firebase et décider quel écran afficher.
class MyApp extends StatefulWidget {
  // Le deviceId n'est plus requis, car l'identité de l'utilisateur est gérée par Firebase Auth.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste un paramètre utile
  // Le paramètre initialPairSuccessRecipientId est maintenant l'UID de l'autre utilisateur
  final String? initialPairSuccessRecipientUid;


  const MyApp({
    super.key,
    required this.deviceLang,
    this.initialPairSuccessRecipientUid, // Optionnel, utilisé si un appairage initial via lien a eu lieu
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

// --- FIN   DU BLOC 06 ---

// --- DEBUT DU BLOC 07 ---

class _MyAppState extends State<MyApp> {
  // Indicateur pour afficher temporairement l'écran de succès d'appairage si déclenché par un lien au démarrage
  bool _showPairSuccess = false;

  // Stocke les souscriptions aux listeners FCM pour pouvoir les annuler dans dispose()
  // >>> AJOUTEZ CES DEUX LIGNES CI-DESSOUS <<<
  // ⛔️ À supprimer - Listeners FCM déplacés vers FcmService - 2025/06/15
  // StreamSubscription? _onMessageSubscription;
  // StreamSubscription? _onMessageOpenedAppSubscription;
  // >>> FIN DES LIGNES À AJOUTER <<<

  // --- FIN   DU BLOC 07 ---

// --- DEBUT DU BLOC 08 ---
  @override
  void initState() {
    super.initState();
    // Si un appairage initial via deep link a réussi (UID de l'autre utilisateur reçu)
    if (widget.initialPairSuccessRecipientUid != null) {
      debugLog("🚀 Déclenchement de l'affichage de l'écran succès appairage pour UID ${widget.initialPairSuccessRecipientUid}", level: 'INFO');
      _showPairSuccess = true;
      // Afficher l'écran de succès pendant quelques secondes, puis masquer
      Timer(const Duration(seconds: 4), () { // Augmenté légèrement le délai pour une meilleure lecture
        if (mounted) {
          debugLog("⏳ Fin de l'affichage de l'écran succès", level: 'INFO');
          setState(() => _showPairSuccess = false);
          // TODO: Potentiellement, après l'écran de succès, naviguer vers l'écran des destinataires
          // ou rafraîchir la liste sur l'écran principal si on y retourne automatiquement.
          // Pour l'instant, masquer l'écran de succès ramène à l'écran déterminé par authStateChanges (HomeSelector si connecté).
          // Note: Si tu veux naviguer ici, il te faudra un Navigator Key global accessible depuis ce contexte.
        }
      });

    }

    // ⛔️ À supprimer - TODO obsolète, logique implémentée ci-dessous - 2025/06/13
    // TODO: Ajouter ici la gestion des messages FCM reçus quand l'app est au premier plan (FirebaseMessaging.onMessage)
    // et potentiellement la gestion du clic sur la notification quand l'app est ouverte par le clic (FirebaseMessaging.onMessageOpenedApp).
    // Ces listeners peuvent être mis en place ici ou dans un service FCM dédié qui gère aussi le token.
    // S'ils sont mis ici, assure-toi de les nettoyer (annuler la subscription) dans la méthode dispose().

    // --- DÉBUT DU BLOC LISTENERS FCM ACTIFS ---
    // Ces listeners gèrent les messages FCM quand l'app est au premier plan ou en arrière-plan actif.

    // ⛔️ À supprimer - Listeners FCM déplacés vers FcmService.initializeFcmHandlers() - 2025/06/15
    // Listener pour les messages reçus quand l'app est au PREMIER PLAN
    // Les messages avec à la fois 'notification' et 'data' payloads déclenchent CE listener.
    // Les messages avec UNIQUEMENT 'data' payload déclenchent AUSSI ce listener.
    // _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   debugLog('🔔 [FOREGROUND] Message reçu: ${message.messageId}', level: 'INFO');
    //   debugLog('🔔 [FOREGROUND] Notification payload: ${message.notification?.title} / ${message.notification?.body}', level: 'DEBUG');
    //   debugLog('🔔 [FOREGROUND] Data payload: ${message.data}', level: 'DEBUG');
    //
    //   // Quand l'app est au premier plan, l'OS Android ne montre PAS automatiquement la notification
    //   // si le payload contient à la fois 'notification' et 'data'. C'est à toi de décider
    //   // comment alerter l'utilisateur. Afficher une notification locale est une approche courante.
    //   // Utilise flutter_local_notifications.show() comme dans le background handler.
    //   // Assure-toi d'utiliser un ID de notification unique pour chaque nouveau message.
    //   // Le payload de la notification locale doit contenir les infos nécessaires (ex: senderId) pour la navigation si l'utilisateur clique.
    //
    //   RemoteNotification? notification = message.notification;
    //   // On vérifie si le message contient une partie 'notification' visible par l'OS (pour le titre/corps)
    //   // ET si message.data est non vide (pour le payload du clic, qui doit être dans data).
    //   if (notification != null && message.data.isNotEmpty) {
    //     try {
    //       // Utilise le hash de l'ID message comme ID de notif locale ( doit être un int).
    //       final int notificationId = message.messageId.hashCode;
    //
    //       // Le 'payload' de show() est la donnée passée au handler onDidReceiveNotificationResponse (qui est déjà en place).
    //       final String notificationClickPayload = message.data['senderId'] ?? '';
    //
    //       // Afficher la notification locale.
    //       // Note: utiliser const 'platformChannelSpecifics' défini globalement.
    //       // ⛔️ À supprimer - accès direct à flutterLocalNotificationsPlugin - remplacé par getIt - 2025/06/12
    //       // flutterLocalNotificationsPlugin.show(
    //       getIt<FlutterLocalNotificationsPlugin>().show(
    //         notificationId, // ID unique de la notification locale (entier)
    //         notification.title, // Titre (via champ notification FCM)
    //         notification.body, // Corps (via champ notification FCM)
    //         platformChannelSpecifics, // Détails spécifiques à la plateforme
    //         payload: notificationClickPayload, // Données pour le clic
    //       );
    //       debugLog("🔔 [FOREGROUND] Notification locale affichée via onMessage (ID: $notificationId). Payload clic: $notificationClickPayload", level: 'INFO');
    //
    //     } catch (e) {
    //       debugLog("❌ [FOREGROUND] Erreur lors de l'affichage de la notification locale via onMessage : $e", level: 'ERROR');
    //     }
    //   } else {
    //     debugLog("🖙 [FOREGROUND] Message reçu via onMessage ne contient pas les données suffisantes pour l'affichage local de notification ou est un message data-only non traité ici.", level: 'DEBUG');
    //     // Tu peux ajouter ici une logique pour traiter les messages data-only si nécessaire (ex: rafraîchir une liste de messages sans afficher de notif).
    //   }
    // });
    // debugLog("🔔 FCM onMessage listener enregistré", level: 'INFO');

    // ⛔️ À supprimer - Listeners FCM déplacés vers FcmService.initializeFcmHandlers() - 2025/06/15
    // Listener pour les messages quand l'app est ouverte par un CLIC sur une notification.
    // Cela se déclenche quand l'app était en arrière-plan (pas terminée) et que l'utilisateur a cliqué sur la notification dans la barre d'état.
    // C'est complémentaire à getInitialMessage (app terminée) et onDidReceiveNotificationResponse (handler du clic pour les notifs locales que nous affichons).
    // Ce listener est utile car il est le mécanisme STANDARD de FCM pour ce scénario.
    // On va utiliser message.data pour naviguer.
    // _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async { // Le handler doit être async
    //   debugLog('🔔 [CLICK - onMessageOpenedApp] App ouverte par clic notif: ${message.messageId}', level: 'INFO');
    //   debugLog('🔔 [CLICK - onMessageOpenedApp] Data payload: ${message.data}', level: 'DEBUG');
    //
    //   final String? senderUid = message.data['senderId']; // Le champ 'senderId' devrait être dans le data payload
    //
    //   if (senderUid != null && senderUid.isNotEmpty) {
    //     debugLog('➡️ [CLICK - onMessageOpenedApp] Déclencher logique de navigation vers conversation avec $senderUid', level: 'INFO');
    //
    //     // La logique de navigation est très similaire à celle que tu as déjà dans getInitialMessage().
    //     // Il faut charger les détails du destinataire et utiliser navigatorKey.
    //     // Comme dans le handler background, il faut être prudent avec CurrentUserService si l'app
    //     // n'était pas complètement chargée. Relire isReceiver et deviceLang de Firestore/PlatformDispatcher
    //     // est ici aussi l'approche la plus sûre avant de naviguer.
    //
    //     final User? currentUser = FirebaseAuth.instance.currentUser;
    //
    //     if (currentUser != null && currentUser.uid != senderUid) { // Ne pas naviguer vers soi-même
    //       String currentUserDeviceLang = PlatformDispatcher.instance.locale.languageCode; // Fallback
    //       bool currentUserIsReceiver = false; // Default
    //
    //       try {
    //         final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser
    //             .uid)
    //             .get();
    //         if (userDoc.exists) {
    //           final userData = userDoc.data();
    //           currentUserIsReceiver = userData?['isReceiver'] == true;
    //           // Langue peut aussi être lue ici si stockée
    //         }
    //       } catch (e) {
    //         debugLog("❌ [CLICK - onMessageOpenedApp] Erreur lors du chargement des données utilisateur pour navigation : $e",
    //             level: 'ERROR');
    //       }
    //
    //       Recipient? recipientDetails; // Initialise à null
    //
    //       // TODO: Etape 3 - Déplacer cet accès Firestore vers FirestoreService.getRecipient(...)
    //       // ⛔️ À supprimer - Logique déplacée vers PairingService - 2025/06/13
    //       // try {
    //       //   // Charger les détails du destinataire depuis la sous-collection 'recipients' de l'utilisateur actuel
    //       //   final recipientSnap = await FirebaseFirestore.instance
    //       //       .collection('users')
    //       //       .doc(currentUser.uid) // UID de l'utilisateur actuellement connecté (currentUser est non-null ici)
    //       //       .collection('recipients')
    //       //       .doc(senderUid) // L'UID du document est l'UID de
    //       //       .get(); // <-- Cette ligne termine l'appel .doc(...).get()
    //       //
    //       //   if (recipientSnap.exists) {
    //       //     final data = recipientSnap.data();
    //       //     recipientDetails = Recipient(
    //       //       id: senderUid, // L'UID du destinataire (l'expéditeur du message)
    //       //       displayName: data?['displayName'] ?? 'Inconnu', // Nom d'affichage du destinataire (si trouvé dans Firestore)
    //       //       icon: data?['icon'] ?? '💬', // Icône par défaut si non trouvée
    //       //       relation: data?['relation'] ?? 'relation_partner', // Relation par défaut si non trouvée
    //       //       allowedPacks: (data?['allowedPacks'] as List?)?.cast<String>() ?? [], // Gérer la liste
    //       //       paired: data?['paired'] == true, // Gérer le booléen
    //       //       catalogType: data?['catalogType'] ?? 'partner', // Type de catalogue
    //       //       createdAt: data?['createdAt'] as Timestamp?, // Timestamp
    //       //     );
    //       //     debugLog("✅ [CLICK - onMessageOpenedApp] Détails destinataire ($senderUid) chargés pour navigation.", level: 'INFO');
    //       //
    //       //   } else {
    //       //     debugLog("⚠️ [CLICK - onMessageOpenedApp] Destinataire ($senderUid) non trouvé dans la liste de l'utilisateur actuel (${currentUser.uid}) pour navigation.", level: 'WARNING');
    //       //       // Optionnel: Naviguer vers l'écran principal ou afficher un message si le destinataire n'est pas appairé.
    //       //       // navigatorKey.currentState?.pushReplacementNamed('/'); // TODO: Revoir la navigation si le destinataire n'est pas trouvé
    //       //   }
    //       // } catch (e) {
    //       //   debugLog("❌ [CLICK - onMessageOpenedApp] Erreur lors du chargement des détails du destinataire ($senderUid) pour navigation : $e", level: 'ERROR');
    //       //   // Gérer l'erreur (ex: ne pas naviguer, afficher un message d'erreur)
    //       // }
    //       // ✅ Remplacé par appel PairingService
    //       try {
    //         recipientDetails = await getIt<PairingService>().getRecipientData(currentUser.uid, senderUid);
    //         debugLog("✅ [CLICK - onMessageOpenedApp] Détails destinataire ($senderUid) chargés via PairingService.", level: 'INFO');
    //       } catch (e) {
    //         debugLog("❌ [CLICK - onMessageOpenedApp] Erreur lors du chargement des détails du destinataire ($senderUid) via PairingService : $e", level: 'ERROR');
    //         recipientDetails = null; // Assurer que recipientDetails est null en cas d'erreur
    //       }
    //
    //
    //       if (recipientDetails != null) {
    //         // Utilise le navigatorKey global pour naviguer.
    //         // Utiliser Future.delayed(Duration.zero) est une bonne pratique ici aussi.
    //         Future.delayed(Duration.zero, () {
    //           // ⛔️ À supprimer - accès direct à navigatorKey - remplacé par getIt - 2025/06/12
    //           // navigatorKey.currentState?.push(MaterialPageRoute(
    //           getIt<GlobalKey<NavigatorState>>().currentState?.push(MaterialPageRoute(
    //             builder: (context) => RecipientDetailsScreen(
    //               deviceLang: currentUserDeviceLang, // Langue - lue depuis Firestore ou PlatformDispatcher
    //               recipient: recipientDetails!, // Objet Recipient chargé
    //               isReceiver: currentUserIsReceiver, // Rôle de l'utilisateur actuel - lue depuis Firestore
    //             ),
    //           ));
    //           debugLog("➡️ [CLICK - onMessageOpenedApp] Navigation vers RecipientDetailsScreen réussie pour UID destinataire $senderUid", level: 'INFO');
    //         });
    //       } else {
    //         debugLog("⚠️ [CLICK - onMessageOpenedApp] Navigation vers RecipientDetailsScreen annulée car détails destinataire non chargés ou introuvables.", level: 'WARNING');
    //         // Optionnel : Naviguer vers l'écran principal si la navigation ciblée échoue
    //         // Future.delayed(Duration.zero, () {
    //         //   navigatorKey.currentState?.pushReplacementNamed('/');
    //         // }); // TODO: Revoir la navigation si les détails du destinataire ne sont pas trouvés
    //       }
    //
    //     } else if (currentUser == null) {
    //       debugLog("⚠️ [CLICK - onMessageOpenedApp] Utilisateur actuel null lors du clic sur notification. Impossible de naviguer.", level: 'WARNING');
    //       // L'application devrait gérer la redirection vers LoginScreen via le StreamBuilder.
    //     } else if (currentUser.uid == senderUid) {
    //       debugLog("⚠️ [CLICK - onMessageOpenedApp] Clic sur notification de soi-même ($senderUid). Pas de navigation ciblée.", level: 'INFO');
    //       // Ne rien faire ou naviguer vers l'écran principal si tu veux.
    //       // Future.delayed(Duration.zero, () {
    //       //   navigatorKey.currentState?.pushReplacementNamed('/');
    //       // });
    //     } else {
    //       debugLog("⚠️ [CLICK - onMessageOpenedApp] Payload senderId manquant ou invalide dans le message opened app. Pas de navigation ciblée.", level: 'WARNING');
    //       // L'app continuera son flux normal.
    //     }
    //   } // <-- FIN DE LA CHAÎNE IF/ELSE IF POUR currentUser
    // }); // <-- FIN DU LISTENER onMessageOpenedApp
    // ⛔️ FIN du bloc à supprimer - Listeners FCM déplacés vers FcmService.initializeFcmHandlers() - 2025/06/15


    // debugLog("🔔 FCM onMessageOpenedApp listener enregistré", level: 'INFO');
  } // <-- Fin de la méthode initState de _MyAppState

  // --- FIN   DU BLOC 08 ---

  // --- DEBUT DU BLOC 09 ---

  // Nettoyage des listeners pour éviter les fuites de mémoire
  // ⛔️ À supprimer - Listeners FCM déplacés vers FcmService, donc dispose() devient vide - 2025/06/15
  // @override
  // void dispose() {
  //   // Annule les souscriptions aux streams FCM si elles existent
  //   _onMessageSubscription?.cancel(); // Utilise le '?' pour appeler cancel() seulement si la subscription n'est pas null
  //   _onMessageOpenedAppSubscription?.cancel(); // Idem pour le second listener
  //   debugLog("🧹 FCM listeners annulés dans dispose.", level: 'INFO');
  //   super.dispose();
  // }

// --- FIN   DU BLOC 09 ---

  // --- DEBUT DU BLOC 10 ---

  @override
  Widget build(BuildContext context) {
    // StreamBuilder écoute les changements de l'état d'authentification Firebase (connexion/déconnexion)
    // Il est déjà correct pour déterminer l'écran initial.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        title: 'Jela', // TODO: Utiliser getUILabel pour le titre de l'app ?
        theme: ThemeData(useMaterial3: true), // TODO: Configurer le thème global ici
        // AJOUTE CETTE LIGNE : Assigne le Navigator Key global à ton MaterialApp
        navigatorKey: getIt<GlobalKey<NavigatorState>>(), // <-- Utilisation de getIt ici
    //navigatorKey: navigatorKey, // <-- AJOUTEZ CETTE LIGNE (Ancienne ligne à commenter ou supprimer)

    // Utilise le StreamBuilder sur l'état d'authentification pour décider de l'écran de départ
    home: StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(), // Le stream qui émet l'utilisateur actuel ou null
    builder: (context, snapshot) {
    // Afficher un indicateur de chargement pendant que l'état d'auth est déterminé
    if (snapshot.connectionState == ConnectionState.waiting) {
            debugLog("⏳ Attente état d'authentification Firebase...", level: 'DEBUG');
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            );
          }

          // Récupérer l'utilisateur connecté (ou null s'il n'y en a pas)
          final User? user = snapshot.data;
          debugLog("👤 État actuel de l'utilisateur : ${user == null ? 'Déconnecté' : 'Connecté (UID: ${user.uid})'}", level: 'INFO');

          // Si un utilisateur est connecté...
          if (user != null) {
            // Vérifier si son email est vérifié
            if (!user.emailVerified) {
              debugLog("🔒 Email non vérifié — Redirection vers EmailVerificationScreen", level: 'WARNING');
              // Rediriger vers l'écran de vérification email.
              // Cet écran n'a plus besoin du deviceId, mais de la langue. L'UID est accessible via FirebaseAuth.currentUser.
              return EmailVerificationScreen(
                // deviceId: widget.deviceId, // <-- SUPPRIMÉ
                deviceLang: widget.deviceLang,
              );
            }

            // Si l'email est vérifié, vérifier si un appairage initial via deep link a eu lieu et a réussi.
            if (_showPairSuccess && widget.initialPairSuccessRecipientUid != null) {
              debugLog("🎉 Affichage temporaire de PairSuccessScreen", level: 'INFO');
              // Afficher l'écran de succès d'appairage.
              // On lui passe l'UID de l'autre utilisateur, pas l'ancien deviceId.
              return PairSuccessScreen(recipientUid: widget.initialPairSuccessRecipientUid!);
            }

            // Si l'utilisateur est connecté, email vérifié, et pas d'écran de succès temporaire :
            // Afficher l'écran principal (HomeSelector).
            // HomeSelector n'a plus besoin du deviceId. Il devra accéder à l'UID via FirebaseAuth.currentUser.
            debugLog("➡️ Redirection vers HomeSelector pour UID ${user.uid}", level: 'INFO');
            return HomeSelector(
              // deviceId: widget.deviceId, // <-- SUPPRIMÉ
              deviceLang: widget.deviceLang,
              // HomeSelector devra charger les données de l'utilisateur connecté (basé sur user.uid)
              // et ses destinataires (basé sur user.uid)
            );

          } else {
            // Si aucun utilisateur n'est connecté :
            // Rediriger vers l'écran de connexion.
            // LoginScreen n'a plus besoin du deviceId, juste de la langue.
            debugLog("➡️ Redirection vers LoginScreen (aucun utilisateur connecté)", level: 'INFO');
            return LoginScreen(
              deviceLang: widget.deviceLang,
              // deviceId: widget.deviceId, // <-- SUPPRIMÉ
              // LoginScreen gérera la connexion et l'inscription via Firebase Auth.
            );
          }
        },
      ),
    );
  } // <-- Fin de la méthode build de _MyAppState
} // <-- Fin de la classe _MyAppState

// --- FIN   DU BLOC 10 ---

// --- DEBUT DU BLOC 11 ---

// Écran temporaire pour montrer le succès de l'appairage via deep link.
// Il affiche maintenant l'UID de l'autre utilisateur.
class PairSuccessScreen extends StatelessWidget {
  // Reçoit l'UID de l'autre utilisateur (l'inviteur) qui a été appairé.
  final String recipientUid; // Renommé de recipientId pour refléter qu'il s'agit de l'UID

  const PairSuccessScreen({super.key, required this.recipientUid});

  @override
  Widget build(BuildContext context) {
    // TODO: Afficher le prénom de l'autre utilisateur au lieu de son UID pour une meilleure expérience.
    // Cela nécessiterait de charger le profil de cet UID depuis Firestore dans ce widget.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            const Text("✅ Appairage réussi !", // TODO: Utiliser getUILabel
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 10),
            // Afficher l'UID de l'autre utilisateur (temporaire, afficher le nom serait mieux)
            Text(
              "Appairé avec (UID) : $recipientUid", // TODO: Afficher le nom réel de l'autre utilisateur
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text("Redirection vers l'application...", // TODO: Utiliser getUILabel
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
} // <-- Fin de la classe PairSuccessScreen

// --- FIN   DU BLOC 11 ---

// --- DEBUT DU BLOC 12 ---

// TOP LEVEL FUNCTION: Recommandée pour la gestion des clics sur notifications locales depuis l'état TERMINÉ sur Android >= 13
// Elle DOIT être déclarée en dehors de toute classe ou fonction
// Le décorateur @pragma('vm:entry-point') est crucial pour les versions récentes de Flutter/Dart.
@pragma('vm:entry-point')
Future<void> onDidReceiveBackgroundNotificationResponse(
    NotificationResponse notificationResponse) async {
  debugLog("🔔 [MAIN - BG NOTIF CLICK] Clic sur notification (terminée, Android 13+). Payload: ${notificationResponse.payload}", level: 'INFO');

  // Assurer que Firebase est initialisé, car cette fonction peut s'exécuter en dehors du contexte principal
  // où main() a été appelé. Vérifier Firebase.apps.isEmpty est une bonne pratique pour éviter la double initialisation.
  // On utilise un try-catch car cette initialisation pourrait échouer dans des cas extrêmes.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugLog("🖙 [MAIN - BG NOTIF CLICK] Firebase initialisé.", level: 'INFO');
    }
  } catch (e) {
    debugLog("❌ [MAIN - BG NOTIF CLICK] Erreur lors de l'initialisation de Firebase : $e", level: 'ERROR');
    // Si Firebase ne s'initialise pas, nous ne pouvons pas charger les données ou naviguer, on s'arrête ici.
    return; // Sortie précoce
  }


  final String? senderUid = notificationResponse.payload; // Le payload de la notification locale est l'UID de l'expéditeur

  // S'assurer que le payload contient bien un UID valide et que l'utilisateur actuel est connecté.
  // Pour un lancement depuis l'état terminé via ce handler, l'utilisateur DEVRAIT être connecté (sinon LoginScreen s'affiche en premier),
  // mais une vérification est plus robuste.
  final User? currentUser = FirebaseAuth.instance.currentUser;

  if (senderUid != null && senderUid.isNotEmpty && currentUser != null && currentUser.uid != senderUid) {
    debugLog('➡️ [MAIN - BG NOTIF CLICK] Tentative de navigation vers conversation avec $senderUid', level: 'INFO');

    // Utilise CurrentUserService pour obtenir les données de l'utilisateur actuel.
    // Pour ce handler spécifique (Android 13+, terminé), CurrentUserService N'EST PAS initialisé par HomeSelector
    // CAR HomeSelector ne sera pas affiché AVANT la navigation déclenchée ici.
    // C'est une limite de cette approche Singleton simple dans ce scénario précis.
    // Cependant, pour les besoins de la démo et si les valeurs isReceiver/deviceLang ne changent pas souvent
    // APRES la connexion, tu pourrais les relire ici ou accepter une valeur par défaut.
    // Relire Firestore pour isReceiver/deviceLang est possible mais moins performant.
    // Pour l'instant, utilisons la langue du système comme fallback si CurrentUserService n'est pas fiable à ce stade.
    // La variable 'isReceiver' est plus problématique. Elle DOIT venir des données utilisateur.
    // TODO: Idéalement, CurrentUserService devrait être initialisable plus tôt ou ses données devraient être stockées
    // de manière persistante et chargées très tôt dans main().
    // Pour l'instant, nous allons LIRE la langue et isReceiver depuis Firestore ICI.
    // C'est moins propre que via CurrentUserService, mais nécessaire si ce handler s'exécute AVANT HomeSelector.

    String currentUserDeviceLang = PlatformDispatcher.instance.locale.languageCode; // Fallback sur langue système
    bool currentUserIsReceiver = false; // Valeur par défaut prudente

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        currentUserIsReceiver = userData?['isReceiver'] == true;
        // Tu pourrais aussi stocker la langue préférée de l'utilisateur dans son doc si tu ne veux pas utiliser PlatformDispatcher
        // currentUserDeviceLang = userData?['deviceLang'] ?? PlatformDispatcher.instance.locale.languageCode;
        debugLog("✅ [MAIN - BG NOTIF CLICK] Données utilisateur (isReceiver) chargées depuis Firestore pour navigation.", level: 'INFO');
      } else {
        debugLog("⚠️ [MAIN - BG NOTIF CLICK] Document utilisateur actuel (${currentUser.uid}) non trouvé pour charger isReceiver.", level: 'WARNING');
      }
    } catch (e) {
      debugLog("❌ [MAIN - BG NOTIF CLICK] Erreur lors du chargement des données utilisateur pour navigation : $e", level: 'ERROR');
    }

    Recipient? recipientDetails; // Initialise à null

    try {
      // Charger les détails du destinataire depuis la sous-collection 'recipients' de l'utilisateur actuel
      final recipientSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid) // UID de l'utilisateur actuellement connecté
          .collection('recipients')
          .doc(senderUid) // L'UID du document est l'UID de l'expéditeur (le destinataire de notre point de vue)
          .get();

      if (recipientSnap.exists) {
        final data = recipientSnap.data();
        recipientDetails = Recipient(
          id: senderUid, // L'UID du destinataire (l'expéditeur du message)
          displayName: data?['displayName'] ?? 'Inconnu', // Nom d'affichage du destinataire (si trouvé dans Firestore)
          icon: data?['icon'] ?? '💬', // Icône par défaut si non trouvée
          relation: data?['relation'] ?? 'relation_partner', // Relation par défaut si non trouvée
          allowedPacks: (data?['allowedPacks'] as List?)?.cast<String>() ?? [], // Gérer la liste
          paired: data?['paired'] == true, // Gérer le booléen
          catalogType: data?['catalogType'] ?? 'partner', // Type de catalogue
          createdAt: data?['createdAt'] as Timestamp?, // Timestamp
        );
        debugLog("✅ [MAIN - BG NOTIF CLICK] Détails destinataire ($senderUid) chargés pour navigation.", level: 'INFO');

      } else {
        debugLog("⚠️ [MAIN - BG NOTIF CLICK] Destinataire ($senderUid) non trouvé dans la liste de l'utilisateur actuel (${currentUser.uid}) pour navigation.", level: 'WARNING');
        // Optionnel: Naviguer vers l'écran principal ou afficher un message si le destinataire n'est pas appairé.
        // navigatorKey.currentState?.pushReplacementNamed('/');
      }
    } catch (e) {
      debugLog("❌ [MAIN - BG NOTIF CLICK] Erreur lors du chargement des détails du destinataire ($senderUid) pour navigation : $e", level: 'ERROR');
      // Gérer l'erreur (ex: ne pas naviguer, afficher un message d'erreur)
    }

    if (recipientDetails != null) {
      // Utilise le navigatorKey global pour naviguer.
      // Utiliser Future.delayed(Duration.zero) est une bonne pratique pour s'assurer
      // que la navigation est poussée après que l'UI initiale potentielle (comme un SplashScreen)
      // soit rendue, mais AVANT que le reste de l'app ne soit complètement chargé.
      Future.delayed(Duration.zero, () {
        // ⛔️ À supprimer - accès direct à navigatorKey - remplacé par getIt - 2025/06/12
        // navigatorKey.currentState?.push(MaterialPageRoute(
        getIt<GlobalKey<NavigatorState>>().currentState?.push(MaterialPageRoute(
          builder: (context) => RecipientDetailsScreen(
            deviceLang: currentUserDeviceLang, // Langue - lue depuis Firestore ou PlatformDispatcher
            recipient: recipientDetails!, // Objet Recipient chargé
            isReceiver: currentUserIsReceiver, // Rôle de l'utilisateur actuel - lu depuis Firestore
          ),
        ));
        debugLog("➡️ [MAIN - BG NOTIF CLICK] Navigation vers RecipientDetailsScreen réussie pour UID destinataire $senderUid", level: 'INFO');
      });


    } else {
      debugLog("⚠️ [MAIN - BG NOTIF CLICK] Navigation vers RecipientDetailsScreen annulée car détails destinataire non chargés ou introuvables.", level: 'WARNING');
      // Optionnel : Naviguer vers l'écran principal si la navigation ciblée échoue
      // Future.delayed(Duration.zero, () {
      //   navigatorKey.currentState?.pushReplacementNamed('/');
      // });
    }

  } else {
    // Cas où senderUid est invalide, currentUser est null, ou clic sur sa propre notification
    if (currentUser == null) {
      debugLog("⚠️ [MAIN - BG NOTIF CLICK] Utilisateur actuel null. Impossible de naviguer post-notification locale.", level: 'WARNING');
      // Le flux normal de l'app devrait ramener l'utilisateur à l'écran de connexion via le StreamBuilder.
    } else if (senderUid == null || senderUid.isEmpty) {
      debugLog('⚠️ [MAIN - BG NOTIF CLICK] Payload senderId manquant ou invalide dans la réponse de notification. Pas de navigation ciblée.', level: 'WARNING');
      // L'app continuera son flux normal.
    } else if (currentUser.uid == senderUid) {
      debugLog("⚠️ [MAIN - BG NOTIF CLICK] Clic sur notification de soi-même ($senderUid). Pas de navigation ciblée.", level: 'INFO');
      // Ne rien faire ou naviguer vers l'écran principal.
      // Future.delayed(Duration.zero, () {
      //   navigatorKey.currentState?.pushReplacementNamed('/');
      // });
    }
  }
}

// --- FIN   DU BLOC 12 ---

// =============================================================
// 🎯 TODO REFAC : Découpler les responsabilités de main.dart
// =============================================================
// `main.dart` gère actuellement Firebase Init, Auth State, Deep Links,
// Appairage (`pairUsers`), FCM Config & Listeners, Navigation globale.
//
// À terme, envisager de déléguer ces logiques à des services dédiés
// (ex: `FcmService`, `DeepLinkService`, `PairingService`) pour
// améliorer la modularité et la maintenabilité du code.
// =============================================================

// 📄 FIN de lib/main.dart
