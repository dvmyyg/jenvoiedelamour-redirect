// -------------------------------------------------------------
// 📄 FICHIER : lib/services/fcm_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Gère la récupération du token FCM de l'appareil et son stockage via Firestore.
// ✅ Écoute les changements de token FCM et met à jour Firestore.
// ✅ Gère les messages FCM reçus quand l'application est au premier plan et affiche une notification locale.
// ✅ Gère le clic sur les notifications quand l'application est ouverte par le clic (via onMessageOpenedApp).
// ✅ Gère le message initial (lancement de l'app depuis état terminé par notif) et délègue navigation.
// ✅ Délègue la logique de navigation post-notification à NotificationRouter.
// ✅ Reçoit l'instance de FlutterLocalNotificationsPlugin via injection de dépendances.
// ✅ Utilise la configuration de notification centralisée (notification_config.dart).
// ✅ Gère la nullité potentielle de message.messageId pour générer l'ID local de notification.
// ✅ Initialise le plugin flutter_local_notifications et enregistre les handlers de clic (déplacé de main.dart).
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V011 - Intégration du traitement du message initial FCM et nettoyage des imports non utilisés. - 2025/06/16 19h25
// V010 - Gestion de l'avertissement "unused_element" pour la référence au handler top-level. - 2025/06/15 20h55
// V009 - Déplacement de l'initialisation du plugin flutter_local_notifications et de ses handlers de clic (onDidReceiveNotificationResponse, onDidReceiveBackgroundNotificationResponseTopLevel) depuis main.dart vers ce service. Ajout des méthodes correspondantes. Appel de la nouvelle méthode d'initialisation dans initializeFcmHandlers(). - 2025/06/15 20h00
// V008 - Utilisation de notification_config.dart pour la configuration des notifications locales (messageNotificationDetails). Ajout gestion null message.messageId pour ID local. - 2025/06/13 20h55
// V007 - Injection de FlutterLocalNotificationsPlugin via constructeur et utilisation du champ injecté. - 2025/06/13 20h53
// V006 - Suppression de la méthode obsolète handleNotificationClick + nettoyage imports. - 2025/06/10 16h52
// V005 - Utilise CurrentUserService pour les paramètres isReceiver et deviceLang dans handleNotificationClick. - 2025/06/04
// V004 - Correction de l'accès aux getters statiques onMessage et onMessageOpenedApp. - 2025/06/02
// V003 - Ajout d'un point d'entrée pour la navigation. - 2025/06/02
// V002 - Ajout des listeners pour les messages FCM reçus. - 2025/06/02
// V001 - Création du service FCM pour la gestion du token. - 2025/06/02
// -------------------------------------------------------------

// =============================================================
// 🧩 IMPORTS & DEPENDANCES
// =============================================================
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelamvp01/utils/debug_log.dart';
// ✅ Rétabli - Import de main.dart nécessaire pour référencer la fonction top-level onDidReceiveBackgroundNotificationResponse passée au plugin local notifications. Idéalement, cette fonction serait dans un fichier top-level dédié. - 2025/06/16 19h05
import 'package:jelamvp01/main.dart'; // import réactive le 2025/06/15
import 'package:jelamvp01/navigation/notification_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import nécessaire pour le type injecté
import 'notification_config.dart'; // ✅ Import de la configuration centralisée
import 'dart:async'; // Import nécessaire pour DateTime

// ⛔️ À supprimer - Import de Recipient non utilisé directement dans FcmService - 2025/06/16
// import 'package:jelamvp01/models/recipient.dart'; // Importe le modèle Recipient

// Note : L'import de CurrentUserService n'est pas nécessaire ici car la logique de navigation
// (qui pourrait utiliser CurrentUserService) est déléguée au NotificationRouter,
// et les handlers de clic locaux gèrent la lecture directe depuis Firestore si nécessaire.

// --- FIN   DU BLOC Imports --- // (Ajout d'un commentaire de fin de bloc pour clarté)

// =============================================================
// 🔐 TOKEN — Récupération et mise à jour
// =============================================================
class FcmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Champ pour l'instance injectée de FlutterLocalNotificationsPlugin (inchangé)
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // Constructeur qui accepte le plugin en paramètre (inchangé)
  FcmService(this._flutterLocalNotificationsPlugin);

  Future<void> updateTokenForCurrentUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugLog('👤 [FCM Service] Utilisateur non connecté. Impossible de mettre à jour le token FCM.', level: 'WARNING');
      return;
    }
    final String uid = currentUser.uid;
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugLog('❌ [FCM Service] Impossible d\'obtenir le token FCM.', level: 'ERROR');
        return;
      }
      debugLog('🪪 [FCM Service] Token FCM obtenu : $token', level: 'DEBUG');
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      await userRef.set({'fcmToken': token}, SetOptions(merge: true));
      debugLog('✅ [FCM Service] Token FCM mis à jour dans Firestore pour l\'UID $uid.', level: 'INFO');
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugLog('🔄 [FCM Service] Token FCM actualisé. Nouveau token : $newToken', level: 'INFO');
        await userRef.set({'fcmToken': newToken}, SetOptions(merge: true));
        debugLog('✅ [FCM Service] Nouveau token FCM actualisé dans Firestore pour l\'UID $uid.', level: 'INFO');
      }).onError((error) {
        debugLog('❌ [FCM Service] Erreur lors de l\'écoute des mises à jour du token FCM: $error', level: 'ERROR');
      });
    } catch (e) {
      debugLog('❌ [FCM Service] Erreur lors de la mise à jour du token FCM: $e', level: 'ERROR');
    }
  }

  // =============================================================
// 🔔 FCM — Initialisation des Handlers de Message et Notifications
// =============================================================
// ✅ MODIF (Étape 6.1.1) : Inclure l'initialisation des notifications locales ici.
// ✅ AJOUT (Étape 6.2) : Gérer le message initial si l'app a été lancée par une notification.
  Future<void> initializeFcmHandlers() async { // ✅ MODIF (Étape 6.2) : Rendre la méthode async
    debugLog('🚀 [FCM Service] Initialisation des Handlers FCM et notifications locales...', level: 'INFO');
    updateTokenForCurrentUser();
    // ✅ AJOUT (Étape 6.1.1) : Appeler la nouvelle méthode d'initialisation des notifs locales
    initializeLocalNotifications();

    // ✅ AJOUT (Étape 6.2) : Gérer le message initial qui a potentiellement lancé l'application
    // Ceci est l'équivalent du FirebaseMessaging.instance.getInitialMessage().then(...) qui était dans main.dart
    try {
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugLog("🔔 [FCM Service - INITIAL MESSAGE] App ouverte par notif initiale: ${initialMessage.messageId}", level: 'INFO');
        debugLog("🔔 [FCM Service - INITIAL MESSAGE] Data payload from initial message: ${initialMessage.data}", level: 'DEBUG');

        // Déléguer la logique de navigation au NotificationRouter
        // Le Router doit être capable de charger les données utilisateur/destinataire nécessaires
        // même si l'app démarre de l'état terminé.
        NotificationRouter.routeFromNotification(initialMessage.data);
        debugLog('➡️ [FCM Service - INITIAL MESSAGE] Logique de navigation déclenchée pour message initial.', level: 'INFO');
      } else {
        debugLog('🖙 [FCM Service - INITIAL MESSAGE] Aucun message FCM initial pour lancer l\'app.', level: 'INFO');
      }
    } catch (e) {
      debugLog("❌ [FCM Service - INITIAL MESSAGE] Erreur lors du traitement du message initial: $e", level: 'ERROR');
      // TODO: Gérer cette erreur (logguer dans Crashlytics?) (Étape 6.2.1)
    }


    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugLog('🔔 [FCM Service - FOREGROUND] Message reçu: ${message.messageId}', level: 'INFO');
      debugLog('🔔 [FCM Service - FOREGROUND] Notification: ${message.notification?.title} / ${message.notification?.body}', level: 'DEBUG');
      debugLog('🔔 [FCM Service - FOREGROUND] Data: ${message.data}', level: 'DEBUG');
      showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugLog('🔔 [FCM Service - CLICK OPEN] App ouverte par clic notif: ${message.messageId}', level: 'INFO');
      debugLog('🔔 [FCM Service - CLICK OPEN] Data: ${message.data}', level: 'DEBUG');
      NotificationRouter.routeFromNotification(message.data);
    });

    debugLog('🚀 [FCM Service] Handlers FCM et initialisation notifications locales activés.', level: 'INFO');
  }

// --- FIN   DU BLOC Initialisation Handlers --- // (Ajout d'un commentaire de fin de bloc pour clarté)

  // =============================================================
  // 📲 NOTIFICATIONS LOCALES — Initialisation du Plugin
  // =============================================================
  // ✅ Étape 6.1.1 : Méthode pour initialiser le plugin flutter_local_notifications
  // Cette logique est déplacée ici depuis la fonction main() dans main.dart.
  Future<void> initializeLocalNotifications() async {
    debugLog("🔔 [FCM Service] Initialisation de flutter_local_notifications...", level: 'INFO');

    // Configurer les paramètres spécifiques à Android (utilise les détails définis dans notification_config.dart)
    // Utilise le canal spécifique aux messages que nous avons défini.
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Utilise l'icône de ton app

    // TODO: Ajouter la configuration pour iOS si tu vises cette plateforme (DarwinInitializationSettings) (Étape 6.1.1.2)
    // Utilise les détails Darwin spécifiques aux messages que nous avons définis.
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: DarwinInitializationSettings(...), // Exemple pour iOS - Utilise darwinMessageDetails si tu veux une config iOS dédiée
      // macOS: DarwinInitializationSettings(...), // Exemple pour macOS - Utilise darwinMessageDetails
    );

    // Effectuer l'initialisation du plugin en lui passant les handlers de clic.
    // onDidReceiveNotificationResponse gère les clics sur la notification quand l'app est au premier plan ou en arrière-plan.
    // onDidReceiveBackgroundNotificationResponse gère les clics quand l'app est terminée sur Android >= 13+.
    // Ces handlers sont définis plus bas dans ce fichier (pour onDidReceiveNotificationResponse)
    // ou comme fonction top-level dans main.dart (pour onDidReceiveBackgroundNotificationResponse).
    try {
      // ✅ Utilise le champ injecté _flutterLocalNotificationsPlugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse, // Passe la référence à la méthode du service
        // onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse, // ✅ MODIF (Étape 6.1.1) : Passer la référence à la fonction top-level de main.dart
        // NOTE : onDidReceiveBackgroundNotificationResponse DOIT rester une fonction top-level et être enregistrée au NIVEAU NATIF.
        // La manière correcte d'enregistrer le handler background pour Android >= 13 est au moment de initialize.
        // La fonction top-level onDidReceiveBackgroundNotificationResponse dans main.dart EST le handler background qui est appelé.
        // L'initialisation ci-dessus via onDidReceiveBackgroundNotificationResponse (si décommenté) est pour le handler de "clic" pour cet handler background.
        // La logique de navigation qui était dans main.dart pour ce handler a déjà été décomposée
        // et utilise getIt, ce qui est bon. Nous devons juste nous assurer que cette fonction top-level
        // est bien celle passée ici.

        // La logique était déjà bien en place dans main.dart pour ces handlers.
        // L'étape 6.1.1 est principalement de déplacer l'appel à .initialize() et de s'assurer
        // que les handlers passés ici (qui restent dans main.dart) peuvent accéder aux services via getIt.
        // Ce qui est déjà le cas.

        // TODO: Clarifier où doit résider onDidReceiveBackgroundNotificationResponse (idéalement, un fichier top-level dédié?) et comment y accéder depuis ici. (Étape 6.1.1.3)
        // Pour l'instant, il réside dans main.dart et est accessible ici car main.dart est importé.

        // L'enregistrement du handler de clic pour le background (Android >= 13+)
        // est un paramètre de la méthode initialize.
        onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse, // Utilise la fonction top-level de main.dart
      );
      debugLog("🔔 [FCM Service] flutter_local_notifications initialisé et handlers enregistrés.", level: 'INFO');
    } catch (e) {
      debugLog("❌ [FCM Service] Erreur lors de l'initialisation de flutter_local_notifications : $e", level: 'ERROR');
      // TODO: Gérer l'erreur (ex: réessayer, logguer dans Crashlytics, afficher un message) (Étape 6.1.1.1)
    }
  }

// =============================================================
// 📲 NOTIFICATIONS LOCALES — Handlers de Clic
// =============================================================

  // ✅ Étape 6.1.1 : Handler de clic pour les notifications locales (App Ouverte/Background)
  // Cette logique est déplacée ici depuis la fonction main() dans main.dart (handler de initialize).
  // Elle est appelée par le plugin flutter_local_notifications quand l'utilisateur clique
  // sur une notification locale et que l'app est au premier plan ou en arrière-plan (pas terminée).
  // Le 'payload' contient les données passées lors de l'affichage de la notification locale.
  Future<void> _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    debugLog("🔔 [FCM Service - NOTIF CLICK] Clic sur notification locale (ouverte/background). Payload: ${notificationResponse.payload}", level: 'INFO');

    final String? senderUid = notificationResponse.payload; // Le payload est l'UID de l'expéditeur

    if (senderUid != null && senderUid.isNotEmpty) {
      debugLog('➡️ [FCM Service - NOTIF CLICK] Déclencher logique de navigation vers conversation avec $senderUid', level: 'INFO');

      // Ici, nous devons déclencher la navigation. Cette logique était dans main().
      // Idéalement, cette navigation devrait être gérée par un NotificationRouter ou similaire.
      // Ce service (FcmService) devrait DEPENDRE du NavigationService ou NotificationRouter.
      // Pour l'instant, nous allons appeler directement le NotificationRouter existant.
      // NOTE : NotificationRouter.routeFromNotification a été créé pour être appelé depuis FCM onMessageOpenedApp.
      // Sa logique DOIT gérer la navigation en utilisant un Navigator Key GLOBAL (disponible via getIt).
      // Nous devons nous assurer que le Navigator Key est bien disponible via getIt ici.
      // NotificationRouter utilise déjà getIt pour NavigatorKey.

      // TODO: Mettre à jour NotificationRouter.routeFromNotification pour accepter potentiellement
      // un UID sender direct comme paramètre, ou s'assurer que le payload est bien l'UID.
      // Pour l'instant, on appelle avec un Map comme s'il venait de FCM data payload.
      final Map<String, dynamic> payloadMap = {'senderId': senderUid}; // Recrée une map minimale pour NotificationRouter
      NotificationRouter.routeFromNotification(payloadMap);

    } else {
      debugLog('⚠️ [FCM Service - NOTIF CLICK] Payload senderId manquant ou invalide dans la réponse de notification locale. Pas de navigation ciblée.', level: 'WARNING');
      // L'app continuera son flux normal.
    }
  } // <-- Fin de la méthode _onDidReceiveNotificationResponse


// =============================================================
// 📲 NOTIFICATIONS LOCALES — Affichage (via FCM onMessage)
// =============================================================
  // ✅ Logique pour afficher une notification locale quand l'app est au premier plan (inchangé)
  Future<void> showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null && notification.title != null && notification.body != null && message.data.isNotEmpty) {
      try {
        // Utilise le hash de l'ID message ou un timestamp comme ID de notif locale (doit être un int).
        final int notificationId = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
        final String notificationClickPayload = message.data['senderId'] ?? '';

        // ✅ Utilise le champ injecté _flutterLocalNotificationsPlugin
        // ✅ Utilise messageNotificationDetails importé depuis notification_config.dart
        await _flutterLocalNotificationsPlugin.show(
          notificationId,
          notification.title,
          notification.body,
          messageNotificationDetails, // Utilise la constante importée
          payload: notificationClickPayload,
        );
        debugLog("🔔 [FCM Service] Notification locale affichée au premier plan (ID: $notificationId). Payload clic: $notificationClickPayload", level: 'INFO');
      } catch (e) {
        debugLog("❌ [FCM Service] Erreur lors de l'affichage de la notification locale au premier plan : $e", level: 'ERROR');
      }
    } else {
      debugLog("🖙 [FCM Service] Message reçu au premier plan ne contient pas les données suffisantes pour l'affichage local de notification.", level: 'DEBUG');
    }
  }

  // ✅ Étape 6.1.1 : Handler de clic pour les notifications locales (App Terminée Android >= 13)
  // Cette fonction DOIT rester une fonction TOP-LEVEL en dehors de la classe FcmService
  // pour être enregistrée par le plugin flutter_local_notifications au niveau natif.
  // Elle EST le point d'entrée appelé par l'OS.
  // Le code réel se trouve dans la fonction top-level onDidReceiveBackgroundNotificationResponse dans main.dart (ou un fichier top-level dédié).
  // Cette méthode dans la classe FcmService sert juste de *référence conceptuelle* pour dire
  // "l'initialisation du plugin dans initializeLocalNotifications() enregistre CE handler top-level ici".
  // Il n'y a pas de logique à dupliquer dans la classe FcmService pour ce handler spécifique.
  // Le code de navigation et d'accès aux services doit être dans la fonction top-level elle-même (main.dart).
  // NOTE : Le code de main.dart pour ce handler utilise déjà getIt et messageNotificationDetails.

  // ignore: unused_element // ✅ AJOUT : Ignorer l'avertissement "unused_element" pour cette méthode
  void _onDidReceiveBackgroundNotificationResponseTopLevel(NotificationResponse notificationResponse) {
    // Ce corps de méthode est vide car la logique est dans la fonction top-level réelle.
    // Cette méthode n'est qu'une référence interne dans le service.
    // debugLog('🔔 [FCM Service - NOTIF CLICK BG REF] Handler top-level appelé (référence interne).', level: 'DEBUG');
  }
} // <-- Fin de la classe FcmService

// 📄 FIN de lib/services/fcm_service.dart
