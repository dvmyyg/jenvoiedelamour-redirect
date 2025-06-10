// -------------------------------------------------------------
// 📄 FICHIER : lib/services/fcm_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Gère la récupération du token FCM de l'appareil et son stockage.
// ✅ Écoute les changements de token FCM et met à jour Firestore.
// ✅ Gère les messages FCM reçus quand l'application est au premier plan.
// ✅ Gère le clic sur les notifications quand l'application est ouverte par le clic (via onMessageOpenedApp).
// ✅ Délègue la logique de navigation post-notification à NotificationRouter.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
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
import 'package:jelamvp01/main.dart';
import 'package:jelamvp01/navigation/notification_router.dart';

// =============================================================
// 🔐 TOKEN — Récupération et mise à jour
// =============================================================
class FcmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  // 🔔 FCM — Initialisation des Handlers de Message
  // =============================================================
  void initializeFcmHandlers() {
    updateTokenForCurrentUser();

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

    debugLog('🚀 [FCM Service] Handlers FCM initialisés (token update et listeners activés).', level: 'INFO');
  }

  // =============================================================
  // 📲 NOTIFICATIONS LOCALES — Affichage au premier plan
  // =============================================================
  Future<void> showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null && notification.title != null && notification.body != null && message.data.isNotEmpty) {
      try {
        final int notificationId = message.messageId.hashCode;
        final String notificationClickPayload = message.data['senderId'] ?? '';
        await flutterLocalNotificationsPlugin.show(
          notificationId,
          notification.title,
          notification.body,
          platformChannelSpecifics,
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

} // <-- Fin de la classe FcmService

// 📄 FIN de lib/services/fcm_service.dart
