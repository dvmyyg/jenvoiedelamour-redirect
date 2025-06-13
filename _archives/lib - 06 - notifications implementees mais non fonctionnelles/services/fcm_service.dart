// -------------------------------------------------------------
// 📄 FICHIER : lib/services/fcm_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Gère la récupération du token FCM de l'appareil et son stockage.
// ✅ Écoute les changements de token FCM et met à jour Firestore.
// ✅ Gère les messages FCM reçus quand l'application est au premier plan.
// ✅ Gère le clic sur les notifications quand l'application est ouverte par le clic (via onMessageOpenedApp).
// ✅ Point d'entrée pour la logique de navigation suite au clic sur notification.
// ✅ **Utilise CurrentUserService pour la navigation post-clic.**
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - Création du service FCM pour la gestion du token. - 2025/06/02
// V002 - Ajout des listeners pour les messages FCM reçus au premier plan et via clic. - 2025/06/02
// V003 - Correction de la troncature et ajout d'un point d'entrée pour la navigation. - 2025/06/02
// V004 - Correction de l'accès aux getters statiques onMessage et onMessageOpenedApp. - 2025/06/02
// V005 - Utilise CurrentUserService pour les paramètres isReceiver et deviceLang dans handleNotificationClick et supprime l'import dart:ui superflu. - 2025/06/04 // Mise à jour le 04/06
// -------------------------------------------------------------

// GEM - Code vérifié et historique mis à jour par Gémini le 2025/06/04 // Mise à jour le 04/06

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelamvp01/utils/debug_log.dart'; // Utilise ton propre log
//import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Nécessaire si on affiche des notifs au premier plan
import 'package:jelamvp01/main.dart'; // Importe main.dart pour accéder à navigatorKey et aux détails des notifs
import 'package:flutter/material.dart'; // Nécessaire pour MaterialPageRoute si utilisé pour la navigation
import 'package:jelamvp01/screens/love_screen.dart'; // Importe l'écran LoveScreen pour la navigation post-clic
import 'package:jelamvp01/services/current_user_service.dart'; // ASSURE-TOI QUE CE CHEMIN EST CORRECT


// Déclare l'instance du plugin local de notifications comme top-level si tu l'initialises dans main()
// et que tu as besoin d'y accéder depuis ce service pour showLocalNotification.
// Si tu utilises un autre mécanisme pour y accéder (ex: Provider), cet import suffit.
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); // Exemple si déclarée globalement et non finale/const


// Déclare les détails de la notification Android comme top-level si définis dans main() et accessibles.
// const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(...); // Exemple
// const NotificationDetails platformChannelSpecifics = NotificationDetails(...); // Exemple


class FcmService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Pas besoin de stocker l'instance de FirebaseMessaging si tu n'utilises que des méthodes statiques ou .instance
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // Cette ligne peut être conservée ou supprimée si non utilisée

  // On pourrait garder des références aux subscriptions si besoin de les annuler (ex: déconnexion)
  // StreamSubscription? _tokenRefreshSubscription;
  // StreamSubscription? _onMessageSubscription;
  // StreamSubscription? _onMessageOpenedAppSubscription;


  // Fonction pour obtenir le token et le stocker dans Firestore
  // Cette fonction devrait être appelée APRES que l'utilisateur se soit connecté.
  Future<void> updateTokenForCurrentUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugLog('👤 [FCM Service] Utilisateur non connecté. Impossible de mettre à jour le token FCM.', level: 'WARNING');
      // On pourrait vouloir supprimer le token si un utilisateur se déconnecte ?
      // handleUserSignOut(); // Décommenter et implémenter si nécessaire
      return;
    }

    final String uid = currentUser.uid;

    try {
      // 1. Obtenir le token FCM actuel pour l'appareil - on utilise l'instance ici
      String? token = await FirebaseMessaging.instance.getToken(); // Accès via .instance

      if (token == null) {
        debugLog('❌ [FCM Service] Impossible d\'obtenir le token FCM.', level: 'ERROR');
        return;
      }

      debugLog('🪪 [FCM Service] Token FCM obtenu : $token', level: 'DEBUG');

      // 2. Stocker ou mettre à jour le token dans Firestore pour l'utilisateur
      // Chemin : users/{uid}
      // Tu peux choisir de stocker les tokens dans une sous-collection
      // pour supporter plusieurs appareils par utilisateur (ex: users/{uid}/tokens/{token_id})
      // Pour l'instant, stockons-le directement dans le document utilisateur pour simplifier :
      DocumentReference userRef = _firestore.collection('users').doc(uid);

      // On utilise merge: true pour ne pas écraser les autres champs du document utilisateur
      await userRef.set({'fcmToken': token}, SetOptions(merge: true));

      debugLog('✅ [FCM Service] Token FCM mis à jour dans Firestore pour l\'UID $uid.', level: 'INFO');

      // 3. Écouter les mises à jour du token et les stocker si le token change
      // Accès via .instance
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async { // Accès via .instance
        debugLog('🔄 [FCM Service] Token FCM actualisé. Nouveau token : $newToken', level: 'INFO');
        // On refait la même opération de stockage avec le nouveau token
        await userRef.set({'fcmToken': newToken}, SetOptions(merge: true));
        debugLog('✅ [FCM Service] Nouveau token FCM actualisé dans Firestore pour l\'UID $uid.', level: 'INFO');
      }).onError((error) {
        debugLog('❌ [FCM Service] Erreur lors de l\'écoute des mises à jour du token FCM: $error', level: 'ERROR');
      });
      // _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(...); // Stocker la subscription si besoin de dispose

    } catch (e) {
      debugLog('❌ [FCM Service] Erreur lors de la mise à jour du token FCM: $e', level: 'ERROR');
    }
  }

  // Méthode pour initialiser les handlers FCM une fois l'utilisateur connecté
  // Cette fonction devrait être appelée après une connexion ou vérification d'email réussie,
  // typiquement dans HomeSelector ou après une redirection vers HomeSelector.
  void initializeFcmHandlers() {
    // Appeler la mise à jour du token au moment de l'initialisation
    updateTokenForCurrentUser();

    // Configurer les listeners pour les messages reçus quand l'app est au premier plan
    // CORRECTION ICI : Accès direct via la classe FirebaseMessaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugLog('🔔 [FCM Service - FOREGROUND] Message reçu: ${message.messageId}', level: 'INFO');
      debugLog('🔔 [FCM Service - FOREGROUND] Notification: ${message.notification?.title} / ${message.notification?.body}', level: 'DEBUG');
      debugLog('🔔 [FCM Service - FOREGROUND] Data: ${message.data}', level: 'DEBUG');

      // TODO: Gérer l'affichage d'une notification locale au premier plan si souhaité.
      // Par défaut pour une messagerie, l'UI se met à jour via Firestore.
      // Afficher une notif locale ici peut être utile si l'utilisateur n'est PAS
      // dans la conversation concernée. Cela nécessite de vérifier l'état de la navigation.
      // Si tu veux toujours afficher une notif locale au premier plan (peut être intrusif), tu peux utiliser :
      showLocalNotification(message); // Une fonction que nous allons ajouter dans ce service

    });
    // _onMessageSubscription = FirebaseMessaging.onMessage.listen(...); // Stocker la subscription si besoin de dispose


    // Configurer le listener pour les clics sur les notifications quand l'app est ouverte par le clic
    // Ce handler est appelé lorsque l'utilisateur clique sur une notification ET que l'application
    // était en arrière-plan ou terminée et a été ouverte par ce clic.
    // CORRECTION ICI : Accès direct via la classe FirebaseMessaging
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugLog('🔔 [FCM Service - CLICK OPEN] App ouverte par clic notif: ${message.messageId}', level: 'INFO');
      debugLog('🔔 [FCM Service - CLICK OPEN] Data: ${message.data}', level: 'DEBUG');
      // TODO: Utilise message.data pour naviguer vers l'écran approprié (ex: conversation)
      // Le payload du clic contient l'UID de l'expéditeur (notification.data['senderId']).
      final String? senderId = message.data['senderId'];
      if (senderId != null && senderId.isNotEmpty) {
        debugLog('➡️ [FCM Service - CLICK OPEN] Déclencher navigation vers conversation avec $senderId', level: 'INFO');
        // Appelle la fonction de gestion du clic pour la navigation
        handleNotificationClick(message.data); // Appelle la fonction de gestion du clic dans ce service
      } else {
        debugLog('⚠️ [FCM Service - CLICK OPEN] Payload senderId manquant pour navigation.', level: 'WARNING');
        // Optionnel: naviguer vers l'écran principal ou afficher un message d'erreur.
      }
    });
    // _onMessageOpenedAppSubscription = FirebaseMessaging.instance.onMessageOpenedApp.listen(...); // Stocker la subscription si besoin de dispose


    // TODO: Gérer le message FCM initial si l'application a été ouverte par une notification (depuis terminated state).
    // getInitialMessage() est appelé une fois au démarrage. Son résultat peut être traité ici ou dans main().
    // C'est le message qui a lancé l'app si elle était complètement fermée.
    // Sa gestion est similaire à onMessageOpenedApp.
    // Il est souvent traité dans main() une fois, juste avant runApp.
    // Si tu le traites ici, l'instance de FcmService doit être disponible très tôt dans le cycle de vie de l'app.
    // FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) { // Accès via .instance
    //   if (message != null) {
    //      debugLog("🔔 [FCM Service - INITIAL MESSAGE] App ouverte par notif: ${message.messageId}", level: 'INFO');
    //      // Appelle la fonction de gestion du clic pour la navigation
    //      handleNotificationClick(message.data); // Appelle la fonction de gestion du clic dans ce service
    //   }
    // });


    debugLog('🚀 [FCM Service] Handlers FCM initialisés (token update et listeners activés).', level: 'INFO');
  }

  // Optionnel: Gérer la déconnexion de l'utilisateur
  // Future<void> handleUserSignOut() async {
  //   debugLog('👤 [FCM Service] Gérer la déconnexion. Nettoyage des listeners et token...', level: 'INFO');
  //   // Annuler les subscriptions pour éviter les fuites de mémoire si le service n'est pas un singleton
  //   // _tokenRefreshSubscription?.cancel();
  //   // _onMessageSubscription?.cancel();
  //   // _onMessageOpenedAppSubscription?.cancel();
  //
  //   // Optionnel: Supprimer ou invalider le token FCM de Firestore pour cet UID/appareil.
  //   // User? currentUser = FirebaseAuth.instance.currentUser; // L'utilisateur peut être déjà null ici
  //   // if (currentUser != null) {
  //   //   await _firestore.collection('users').doc(currentUser.uid).update({'fcmToken': FieldValue.delete()}); // Supprime le champ
  //   // }
  // }

  // Fonction pour afficher une notification locale depuis ce service
  // Utile si tu décides d'afficher des notifications même au premier plan (via onMessage listener).
  Future<void> showLocalNotification(RemoteMessage message) async {
    // Pour utiliser flutterLocalNotificationsPlugin ici, il faut que l'instance globale soit accessible.
    // Nous avons déclaré flutterLocalNotificationsPlugin comme une variable globale dans main.dart
    // et importé main.dart ici. C'est une façon de faire, bien que passer l'instance au constructeur
    // du service ou utiliser un pattern comme Provider pour y accéder soit parfois préférable
    // pour des raisons de testabilité et de gestion des dépendances.
    // Pour l'instant, l'accès global fonctionne.

    // Les détails spécifiques à la plateforme (androidPlatformChannelSpecifics) sont aussi nécessaires.
    // Nous les avons également définis globalement dans main.dart et nous y accédons via l'import.

    RemoteNotification? notification = message.notification;
    // On vérifie si le message contient une partie 'notification' visible par l'OS.
    // Dans la Cloud Function, nous avons mis un titre et un corps dans ce champ.
    // On vérifie aussi message.data.isNotEmpty car le champ 'data' est toujours
    // passé au handler même si le champ 'notification' n'y est pas, et contient
    // les infos (senderId, messageId, etc.) dont nous avons besoin pour potentiellement le clic.
    if (notification != null && notification.title != null && notification.body != null && message.data.isNotEmpty) {
      try {
        final int notificationId = message.messageId.hashCode; // ID unique
        // Le payload doit être une String. Utilise les données reçues.
        final String notificationClickPayload = message.data['senderId'] ?? ''; // Exemple: passe l'UID de l'expéditeur

        await flutterLocalNotificationsPlugin.show(
          notificationId,
          notification.title,
          notification.body,
          platformChannelSpecifics, // Utilise les détails définis globalement dans main.dart
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

  // Fonction centrale pour gérer la logique suite à un clic sur une notification FCM.
  // Appelée depuis onMessageOpenedApp et potentiellement getInitialMessage.
  // C'est ici que tu devras implémenter la navigation en utilisant le NavigatorKey global.
  void handleNotificationClick(Map<String, dynamic> data) {
    final String? senderId = data['senderId'];
    if (senderId != null && senderId.isNotEmpty) {
      debugLog('➡️ [FCM Service - CLICK HANDLER] Déclenchement logique de navigation vers conversation avec $senderId', level: 'INFO');
    // TODO: Implémenter la logique de navigation.
      // Utilise le navigatorKey global que nous avons défini dans main.dart
      // Assure-TOI QUE LE CONTEXTE EST PRÊT POUR LA NAVIGATION.
      // Les opérations de navigation asynchrones doivent parfois être gérées avec soin.
      // Navigator.pushNamed(context, '/chat', arguments: {'recipientId': senderId}); // Nécessite context ou Navigator Key

      // Exemple utilisant push pour naviguer vers un écran (suppose que LoveScreen prend recipientUid en paramètre):
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (context) => LoveScreen(
          recipientUid: senderId,
          isReceiver: CurrentUserService().isReceiver, // Utilise le service
          deviceLang: CurrentUserService().deviceLang, // Utilise le service
        ),

      ));

    } else {
      debugLog('⚠️ [FCM Service - CLICK HANDLER] Données de navigation (senderId) manquantes ou invalides.', level: 'WARNING');
      // Optionnel: naviguer vers l'écran principal ou afficher un message d'erreur.
      // navigatorKey.currentState?.pushReplacementNamed('/'); // Naviguer vers la racine (écran principal)
    }
  }

} // <-- Fin de la classe FcmService

// --- FIN DU FICHIER lib/services/fcm_service.dart ---
