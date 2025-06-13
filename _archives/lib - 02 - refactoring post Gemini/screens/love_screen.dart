// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/love_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Écran principal de l'application affichant la liste des destinataires de l'utilisateur actuel.
// ✅ Permet de naviguer vers les écrans de chat (via SendMessageScreen ou RecipientDetailsScreen), gestion des destinataires (RecipientsScreen), et profil (ProfileScreen).
// ✅ Charge la liste des destinataires en temps réel via RecipientService.streamPairedRecipients.
// ✅ Affiche le nom d'affichage de l'utilisateur actuel (passé en paramètre).
// ✅ N'utilise plus deviceId pour l'identification ou les opérations Firestore.
// ⚠️ NOTE : La logique de réception de messages/notifications en temps réel sur cet écran et la gestion de la présence ont été retirées car basées sur l'ancien modèle deviceId. Elles nécessiteront une réimplémentation basée sur les UID et/ou FCM/Firestore streams si nécessaire. Le simple indicateur showIcon est supprimé. L'affichage de la notification locale est conservé mais sa déclenchement lié à l'ancienne écoute est retiré.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V004 - Refonte majeure : Suppression de toute la logique basée sur deviceId (écoute Firestore devices, présence, chargement nom/recipients via deviceId, passage deviceId aux autres écrans). Utilisation de l'UID Firebase (obtenu via FirebaseAuth.currentUser) pour l'initialisation de RecipientService et la navigation. Simplification de l'écran pour afficher la liste des destinataires en temps réel via RecipientService.streamPairedRecipients. Suppression de l'ancien mécanisme de notification/icône showIcon et de la logique FCM en avant-plan associée. Le nom de l'utilisateur actuel et son rôle sont passés en paramètres. - 2025/05/30
// V003 - ajout explicite du paramètre displayName (prénom) - 2025/05/24 08h20 (Historique hérité)
// V002 - ajout explicite du paramètre displayName (prénom) - 2025/05/24 08h20 (Historique hérité)
// V001 - version nécessitant une correction pour le prénom utilisateur - 2025/05/23 21h00 (Historique hérité)
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/30 // Mise à jour de la date au 30/05

import '../utils/debug_log.dart'; // Utilise la fonction unique de debug_log.dart
import 'dart:async'; // Reste si d'autres timers sont ajoutés (comme pour rafraîchir la liste si pas de stream)
import 'package:flutter/material.dart';
// On n'a plus besoin d'importer cloud_firestore directement ici pour la plupart des opérations, on utilise les services.
// L'import est conservé pour Timestamp si Message.sentAt l'utilise directement dans l'UI (ce qui n'est pas le cas ici).
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- POTENTIELLEMENT SUPPRIMÉ
// Les imports pour les notifications locales et FCM sont conservés si vous comptez les utiliser,
// mais la logique spécifique dans initState a été retirée de cet écran.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/i18n_service.dart'; // Import conservé pour l'internationalisation (getUILabel, getMessageBody, getPreviewText)
import '../screens/recipients_screen.dart'; // Navigation vers cet écran
// Renommé SendMessageScreen en ChatScreen pour plus de clarté et d'alignement avec le fichier corrigé précédemment
// import '../screens/send_message_screen.dart'; // <-- POTENTIELLEMENT RENOMMÉ/SUPPRIMÉ
// Décidez quel écran vous utilisez pour le chat : ChatScreen ou RecipientDetailsScreen.
// Pour l'exemple, je vais importer les deux et utiliser RecipientDetailsScreen car il a un champ texte.
// Si vous utilisez SendMessageScreen pour l'envoi rapide et un autre pour le chat complet, ajustez la navigation.
// import '../screens/chat_screen.dart'; // Si vous utilisez ChatScreen pour le chat
import '../screens/recipient_details_screen.dart'; // Si vous utilisez RecipientDetailsScreen pour le chat
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé
import '../services/recipient_service.dart'; // Utilise le RecipientService refactorisé
import '../screens/profile_screen.dart'; // Navigation vers cet écran
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
// import 'package:firebase_core/firebase_core.dart'; // Ajout pour l'initialisation Firebase dans le handler BG si nécessaire

// Le handler de message en arrière-plan est défini ici mais enregistré dans main.dart.
// Sa logique est simple et ne dépend pas directement du deviceId, donc on la conserve.
// Il devrait être capable d'afficher une notification locale si les données le permettent.
// NOTE: Cette fonction @pragma('vm:entry-point') doit être une fonction de niveau supérieur (top-level function),
// elle ne peut pas être une méthode de classe. Sa définition ici est correcte mais son enregistrement doit se faire dans main.dart.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Assurer que Firebase est initialisé, car cette fonction peut s'exécuter en dehors du contexte principal
  // NOTE: Cette initialisation est déjà gérée dans main.dart pour le handler, donc potentiellement redondant ici,
  // mais ne fait pas de mal par sécurité si ce handler devait être appelé différemment (par exemple, via une workmanager task).
  // if (Firebase.apps.isEmpty) {
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Nécessite import firebase_core
  // }
  debugLog(
    "🔔 [FCM-BG] Notification reçue en arrière-plan : ${message.notification?.title}",
    level: 'INFO',
  );
  // TODO: Ajouter ici la logique pour traiter le message/notification en arrière-plan.
  // Cela pourrait impliquer de sauvegarder des données en local (si besoin) ou de déclencher une notification locale.
  // Si vous voulez afficher une notification locale, vous aurez besoin de l'instance de FlutterLocalNotificationsPlugin.
  // Il est recommandé de gérer l'initialisation et l'affichage des notifications locales
  // dans une classe ou un service dédié qui peut être accessible ici ou dans main.dart.
  if (message.notification != null) {
    // Exemple minimal pour logguer les détails de la notification en arrière-plan
    debugLog("📢 [FCM-BG] Titre: ${message.notification?.title}, Body: ${message.notification?.body}", level: 'DEBUG');
    // Vous pouvez accéder aux données via message.data (ex: UID de l'expéditeur)
    // final String? senderUid = message.data['from'];
    // final String? messageContent = message.data['content'];
    // Ici, vous déclencheriez potentiellement une notification locale si c'est le comportement souhaité.
  }
}

class LoveScreen extends StatefulWidget {
  // Le deviceId n'est plus requis. L'identifiant de l'utilisateur actuel est son UID Firebase,
  // accessible via FirebaseAuth.instance.currentUser.
  // final String deviceId; // <-- SUPPRIMÉ du widget

  // Ces informations sont maintenant passées par HomeSelector qui les a chargées depuis users/{uid}.
  final bool isReceiver; // Rôle chargé depuis HomeSelector
  final String deviceLang; // Langue passée depuis main.dart
  final String? displayName; // Nom d'affichage chargé depuis HomeSelector

  const LoveScreen({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.isReceiver,
    required this.deviceLang,
    this.displayName, // Nom d'affichage est maintenant un paramètre optionnel/injecté
  });

  @override
  State<LoveScreen> createState() => _LoveScreenState();
}

class _LoveScreenState extends State<LoveScreen> {
  // showIcon, senderName, pingTimer et la liste des destinataires sont maintenant gérés différemment.
  // showIcon et senderName sont obsolètes car liés à l'ancienne logique de réception via devices/{deviceId}.
  // bool showIcon = false; // <-- SUPPRIMÉ
  // String? senderName; // <-- SUPPRIMÉ
  // Timer? pingTimer; // <-- SUPPRIMÉ (logique de présence obsolète)

  // La liste des destinataires sera obtenue via un Stream<List<Recipient>> depuis RecipientService.
  // List<Recipient> recipients = []; // <-- SUPPRIMÉ, le StreamBuilder gère la liste

  // Instance du RecipientService (initialisée une fois avec l'UID de l'utilisateur actuel)
  late RecipientService _recipientService;
  // Variable pour stocker l'UID de l'utilisateur actuel
  String? _currentUserId;

  // Notifications locales plugin instance
  // Conserver si vous comptez utiliser les notifications locales déclenchées par FCM en avant-plan ou arrière-plan.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // StreamSubscription pour l'ancienne écoute Firestore (supprimé)
  // StreamSubscription? _deviceListener; // <-- SUPPRIMÉ

  // StreamSubscription pour l'écoute FCM en avant-plan (supprimé ou adapté)
  // StreamSubscription? _fcmForegroundListener; // <-- SUPPRIMÉ

  @override
  void initState() {
    super.initState();
    debugLog("🔄 LoveScreen initialisé.", level: 'INFO');

    // Obtenir l'UID de l'utilisateur actuel dès que possible.
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Vérifier si l'utilisateur est connecté. LoveScreen devrait toujours être atteint par un utilisateur connecté (via HomeSelector).
    if (_currentUserId == null) {
      debugLog("⚠️ LoveScreen : Utilisateur non connecté. Cela ne devrait pas arriver ici.", level: 'ERROR');
      // TODO: Gérer cette erreur critique (ex: afficher un message, rediriger vers Login).
      // MessageService ou RecipientService ne pourront pas être initialisés sans UID.
      // On pourrait potentiellement naviguer vers LoginScreen ici.
      // if (mounted) {
      //    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen(deviceLang: widget.deviceLang))); // Nécessite import LoginScreen
      // }
      return; // Sortir tôt si l'UID n'est pas disponible
    }

    // Initialiser le RecipientService avec l'UID de l'utilisateur actuel
    _recipientService = RecipientService(_currentUserId!); // _currentUserId! est sûr car vérifié au-dessus

    // L'ancienne logique de mise à jour de l'état de présence _updateForegroundStatus est supprimée.
    // _updateForegroundStatus(true); // <-- SUPPRIMÉ

    // L'ancien chargement initial du nom du device _loadDisplayName est supprimé. Le nom est passé en paramètre.
    // _loadDisplayName(); // <-- SUPPRIMÉ

    // L'ancien chargement initial unique des destinataires _loadRecipients est remplacé par un stream dans le build.
    // _loadRecipients(); // <-- SUPPRIMÉ

    // Initialiser le plugin de notifications locales si vous l'utilisez toujours pour les notifications FCM.
    // Cette méthode contient maintenant des paramètres iOS
    _initNotifications();

    // Configurer FCM. La logique FCM en avant-plan qui utilisait showIcon a été retirée.
    _configureFCM();

    // L'ancien timer de ping pour la présence est supprimé.
    // pingTimer = Timer.periodic(...); // <-- SUPPRIMÉ

    // L'ancienne écoute Firestore sur devices/{deviceId} pour la réception de message est supprimée.
    // FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).snapshots().listen(...); // <-- SUPPRIMÉ
  }

  // Initialise le plugin de notifications locales.
  Future<void> _initNotifications() async {
    debugLog("🔔 Initialisation des notifications locales.", level: 'INFO');
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      // 'ic_launcher' est le nom du drawable dans les ressources Android
      '@mipmap/ic_launcher', // Assurez-vous que cette ressource existe dans votre projet Android (android/app/src/main/res/mipmap-*)
    );
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings( // iOS settings
      requestAlertPermission: true, // Demande la permission pour les alertes
      requestBadgePermission: true, // Demande la permission pour les badges d'icône
      requestSoundPermission: true, // Demande la permission pour les sons
      // onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
      //   // TODO: Gérer la réception de notifications locales en avant-plan sur les anciennes versions d'iOS (< 10)
      //   // Cette méthode est dépréciée dans les versions récentes.
      //   debugLog("📢 [iOS Legacy] Notification locale reçue en avant-plan: $title", level: 'DEBUG');
      // },
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings); // Combiner les settings Android et iOS

    try {
      bool? initialized = await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        // onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        //   // TODO: Gérer la réponse utilisateur à la notification (ex: tap sur la notification) pour les versions récentes (>= 10)
        //   // Cela se déclenche lorsque l'utilisateur interagit avec une notification (locale ou affichée suite à FCM).
        //   // Vous pouvez accéder au payload via notificationResponse.payload si vous en avez défini un lors de l'affichage.
        //   // Vous pourriez par exemple naviguer vers l'écran de chat correspondant au message.
        //   debugLog("📢 Réponse notification reçue: ${notificationResponse.notificationResponseType}", level: 'DEBUG');
        //   debugLog("📢 Payload: ${notificationResponse.payload}", level: 'DEBUG');
        //   // Exemple de gestion basique : si payload contient un UID de destinataire, naviguer vers le chat
        //   // if (notificationResponse.payload != null && notificationResponse.payload!.startsWith('chat:')) {
        //   //    final recipientUid = notificationResponse.payload!.substring(5); // Extraire l'UID après 'chat:'
        //   //    // Trouver le destinataire correspondant dans la liste chargée ou le charger depuis Firestore
        //   //    final recipient = _findRecipientByUid(recipientUid); // Cette méthode doit être implémentée
        //   //    if (recipient != null && mounted) {
        //   //       Navigator.push(context, MaterialPageRoute(builder: (_) => RecipientDetailsScreen(deviceLang: widget.deviceLang, recipient: recipient)));
        //   //    }
        //   // }
        // },
        // onDidReceiveBackgroundNotificationResponse: (NotificationResponse notificationResponse) {
        //   // TODO: Gérer la réponse utilisateur à la notification reçue en arrière-plan (Android 12+ ou si setup headless est fait)
        //   // C'est l'équivalent pour les actions en arrière-plan/terminé. Nécessite un setup spécifique du plugin.
        //   debugLog("📢 Réponse notification BACKGROUND reçue: ${notificationResponse.notificationResponseType}", level: 'DEBUG');
        //   debugLog("📢 Payload BACKGROUND: ${notificationResponse.payload}", level: 'DEBUG');
        // }
      );

      if (initialized != null && initialized) {
        debugLog("✅ Notifications locales initialisées avec succès.", level: 'SUCCESS');
      } else {
        debugLog("❌ Échec de l'initialisation des notifications locales.", level: 'ERROR');
        // TODO: Afficher un message à l'utilisateur si les notifications ne fonctionnent pas.
      }
  } catch (e) {
  debugLog("❌ Erreur lors de l'initialisation des notifications locales : $e", level: 'ERROR');
  // TODO: Afficher un message d'erreur plus détaillé à l'utilisateur.
  }
}

// Configure Firebase Cloud Messaging (FCM).
// La logique FCM en avant-plan qui utilisait showIcon a été retirée car basée sur l'ancien modèle.
// Vous pouvez réimplémenter la gestion des notifications FCM en avant-plan ici si nécessaire,
// en utilisant les données de la notification (RemoteMessage) pour déclencher par exemple une notification locale.
Future<void> _configureFCM() async {
  debugLog("⚙️ Configuration de FCM.", level: 'INFO');
  // Demander la permission de recevoir des notifications (pour iOS et Web).
  // Sur Android, les permissions sont généralement gérées au niveau de l'installation de l'appli.
  try {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugLog('✅ Permissions notification accordées: ${settings.authorizationStatus}', level: 'INFO');

    // TODO: Gérer la sauvegarde/mise à jour du token FCM.
    // Le token est lié à l'installation de l'appli sur cet appareil.
    // Il est généralement utile de l'associer à l'UID de l'utilisateur *connecté*
    // pour pouvoir lui envoyer des notifications ciblées sur CET appareil.
    // Cela nécessiterait une fonction dans un service (ex: FirestoreService ou un nouveau service FCM)
    // qui prendrait l'UID de l'utilisateur actuel et le token FCM et l'enregistrerait dans Firestore
    // (par exemple, sous users/{uid}/fcmTokens/{thisDeviceToken}).
    // final token = await FirebaseMessaging.instance.getToken();
    // debugLog("🪪 FCM Token: $token", level: 'INFO');
    // if (_currentUserId != null && token != null) {
    //   // await _firestoreService.saveFcmTokenForUser(_currentUserId!, token); // Cette fonction saveFcmTokenForUser doit exister.
    //    debugLog("ℹ️ TODO: Sauvegarder/mettre à jour le token FCM pour l'UID $_currentUserId.", level: 'DEBUG');
    // }

    // Écouter les messages FCM reçus pendant que l'application est au premier plan.
    // L'ancienne logique d'affichage de showIcon est supprimée.
    // Vous pouvez utiliser ceci pour afficher une notification locale (via flutter_local_notifications)
    // ou mettre à jour l'UI en temps réel si le message FCM contient des données pertinentes.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugLog("📨 [FCM-FG] Message reçu en avant-plan : ${message.messageId}", level: 'INFO');
      // TODO: Traiter le message FCM en avant-plan.
      // Par exemple, afficher une notification locale ou rafraîchir l'UI.
      if (message.notification != null) {
        debugLog("📢 [FCM-FG] Titre: ${message.notification?.title}, Body: ${message.notification?.body}", level: 'DEBUG');
        // Exemple: Afficher une notification locale basée sur le message FCM
        //_showNotification(message.notification!.body ?? '', message.notification!.title); // Nécessite adaptation de _showNotification
      }
      // Vous pouvez accéder aux données via message.data
      // final String? senderUid = message.data['from'];
      // final String? messageContent = message.data['content'];
      // Si le message contient des données sur un nouveau message, vous pourriez vouloir
      // rafraîchir la liste des conversations ou indiquer un message non lu.
      // RecipientService streamMessages ou streamPairedRecipients devrait gérer cela
      // si l'écriture dans Firestore déclenche la notification FCM.
    });

    // Écouter les interactions avec les notifications quand l'appli est ouverte (depuis terminated ou background).
    // Géré par onDidReceiveNotificationResponse dans _initNotifications().
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //    debugLog("🚀 [FCM] Application ouverte depuis notification : ${message.messageId}", level: 'INFO');
    //    // TODO: Gérer l'action lorsque l'utilisateur tape sur la notification.
    //    // Ceci est généralement utilisé pour naviguer vers un écran spécifique (ex: l'écran de chat).
    //    // Vous pouvez utiliser message.data ou message.notification.body pour décider où naviguer.
    //    // Si vous avez mis un payload dans la notification locale affichée suite au FCM,
    //    // le handling via onDidReceiveNotificationResponse dans _initNotifications est peut-être suffisant.
    // });

    // Vous pouvez aussi gérer l'état initial (si l'app est lancée en tapant sur une notification)
    // FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    //   if (message != null) {
    //     debugLog("🚀 [FCM] Application lancée depuis notification initiale : ${message.messageId}", level: 'INFO');
    //     // TODO: Gérer l'action de lancement depuis notification initiale.
    //     // Similaire à onMessageOpenedApp, mais pour le lancement initial.
    //   }
    // });

  } catch (e) {
    debugLog("❌ Erreur lors de la configuration de FCM ou des permissions : $e", level: 'ERROR');
    // TODO: Afficher un message à l'utilisateur.
  }

  // NOTE: La gestion des messages en arrière-plan (quand l'appli est suspendue ou fermée)
  // est gérée par la fonction top-level _firebaseMessagingBackgroundHandler
  // qui doit être enregistrée dans main.dart.

}

// L'ancienne méthode _updateForegroundStatus est supprimée car liée au modèle deviceId.
// Future<void> _updateForegroundStatus(bool isForeground) async { ... } // <-- SUPPRIMÉ

// L'ancienne méthode _loadDisplayName est supprimée car le nom est passé en paramètre.
// Future<void> _loadDisplayName() async { ... } // <-- SUPPRIMÉ

// L'ancienne méthode _loadRecipients est remplacée par l'écoute du stream dans le build.
// Future<void> _loadRecipients() async { ... } // <-- SUPPRIMÉ

// La méthode _showNotification (affichage notification locale) est conservée mais sa logique de déclenchement a changé.
// Elle n'est plus appelée par l'ancien listener Firestore, mais peut être appelée par le listener FCM en avant-plan.
// Pour l'instant, elle n'est pas appelée du tout dans le code refactorisé.
Future<void> _showNotification(String body, String? receivedSenderName) async {
  // Adapter le titre si nécessaire, peut-être basé sur le nom de l'expéditeur réel via UID si disponible dans le message FCM.
  final title = receivedSenderName != null && receivedSenderName.isNotEmpty
      ? "💌 $receivedSenderName t’a envoyé un message" // TODO: Use i18n_service + interpolate name
      : getUILabel('message_received_title', widget.deviceLang); // Titre générique si pas de nom


  // Assurez-vous que le canal de notification est créé AVANT d'afficher la notification sur Android O+ (API 26+).
  // La création du canal peut être faite une seule fois (par exemple, dans _initNotifications ou au démarrage de l'appli).
  // Le code de création du canal est déjà inclus ici mais il est commenté dans la version initiale.

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'love_channel', // ID unique du canal
    'Love Notifications', // Nom du canal visible par l'utilisateur
    description: 'Notifications pour les messages d\'amour', // Description visible par l'utilisateur
    importance: Importance.high, // Niveau d'importance (High ou Max pour son/vibration)
    playSound: true,
    enableVibration: true,
    // Vous pouvez aussi configurer un son personnalisé ici
    // sound: RawResourceAndroidNotificationSound('mysound'), // Requires sound file in res/raw
  );

  // Créer le canal de notification sur Android
  // Ceci peut être fait une seule fois. Faire ici à chaque _showNotification n'est pas optimal.
  // Déplacez la création du canal dans _initNotifications si vous voulez le créer une fois.
  final AndroidFlutterLocalNotificationsPlugin? androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    try {
      await androidPlugin.createNotificationChannel(channel);
      // debugLog("✅ Canal de notification 'love_channel' créé ou mis à jour.", level: 'DEBUG');
    } catch (e) {
      debugLog("❌ Erreur lors de la création du canal de notification : $e", level: 'ERROR');
    }
  }


  final androidDetails = AndroidNotificationDetails(
    channel.id, // Utilise l'ID du canal défini ci-dessus
    channel.name, // Utilise le nom du canal défini ci-dessus
    channelDescription: channel.description, // Utilise la description du canal
    importance: channel.importance, // Utilise l'importance du canal
    priority: Priority.high,
    playSound: channel.playSound,
    enableVibration: channel.enableVibration,
    // Autres options comme largeIcon, smallIcon, color, actions, etc.
    // largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Une icône plus grande
    // smallIcon: '@mipmap/ic_launcher', // L'icône qui s'affiche dans la barre de notification
    // color: Colors.pink.toAccentColor(), // Couleur de l'icône et titre (si icône smallIcon est monochrome)
    // payload: 'chat:${senderUid}', // Exemple de payload pour naviguer au tap (doit être une String)
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    // Paramètres spécifiques à iOS
    presentAlert: true, // Afficher une alerte
    presentBadge: true, // Mettre à jour le badge
    presentSound: true, // Jouer un son
    // sound: 'mysound.caf', // Son personnalisé (doit être inclus dans le bundle de l'appli)
  );

  final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

  try {
    await flutterLocalNotificationsPlugin.show(
      0, // ID unique de la notification (si vous affichez plusieurs notifications, utilisez des IDs différents)
      title, // Titre de la notification
      body, // Corps de la notification (le message localisé)
      notificationDetails, // Les détails de la plateforme
      // payload: 'your_payload_data', // Optionnel: une chaîne de caractères associée à la notification
    );
    debugLog("📢 Notification locale affichée !", level: 'SUCCESS');
  } catch (e) {
    debugLog("❌ Erreur lors de l'affichage de la notification locale : $e", level: 'ERROR');
    // TODO: Gérer l'échec d'affichage de la notification.
  }
}


@override
void dispose() {
  debugLog("🚪 LoveScreen dispose. Libération des ressources.", level: 'INFO');
  // L'ancienne logique de mise à jour de l'état de présence _updateForegroundStatus est supprimée.
  // _updateForegroundStatus(false); // <-- SUPPRIMÉ
  // Annuler le timer de ping (si vous en ajoutez un nouveau basé sur l'UID)
  // pingTimer?.cancel(); // <-- SUPPRIMÉ
  // Annuler l'ancienne StreamSubscription Firestore (déjà supprimée)
  // _deviceListener?.cancel(); // <-- SUPPRIMÉ
  // Annuler l'ancienne StreamSubscription FCM en avant-plan (déjà supprimée)
  // _fcmForegroundListener?.cancel(); // <-- SUPPRIMÉ

  super.dispose();
}


@override
Widget build(BuildContext context) {
  // Vérifier si l'UID de l'utilisateur actuel est disponible.
  // LoveScreen devrait toujours être atteint par un utilisateur connecté (via HomeSelector).
  // Cette vérification est surtout pour la robustesse, si le flux de navigation échoue.
  if (_currentUserId == null) {
    debugLog("⚠️ LoveScreen build : _currentUserId est null. Affichage de l'écran d'erreur.", level: 'ERROR');
    // Afficher un écran d'erreur ou rediriger
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('app_title', widget.deviceLang)), // TODO: Fallback title
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        // TODO: Use i18n_service
        child: Text("Erreur : Utilisateur non identifié. Veuillez vous reconnecter.", style: TextStyle(color: Colors.red)),
      ),
    );
  }

  // Si l'utilisateur est connecté (_currentUserId n'est pas null)
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min, // Adapter la taille de la Row au contenu
              children: [
                const Icon(Icons.favorite, color: Colors.red), // Icône d'amour
                const SizedBox(width: 8),
                Text(getUILabel('love_screen_title', widget.deviceLang)), // Titre de l'écran (internationalisé)
              ],
            ),
            // Afficher le nom de l'utilisateur si disponible (passé en paramètre)
            if (widget.displayName != null && widget.displayName!.isNotEmpty) // Vérifier aussi si non vide
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.displayName!, // Nom d'affichage de l'utilisateur actuel
                  style: const TextStyle(
                    color: Colors.white70, // Couleur discrète
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // TODO: Afficher 'isReceiver' ou un statut pertinent si nécessaire
            // Text(widget.isReceiver ? 'Rôle: Récepteur' : 'Rôle: Expéditeur', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
    // Bouton pour gérer les destinataires (appelle RecipientsScreen)
    IconButton(
    icon: const Icon(Icons.group), // Icône de groupe/contacts
    tooltip: getUILabel('manage_recipients_tooltip', widget.deviceLang), // Tooltip internationalisé
    onPressed: () async {
      debugLog("➡️ Navigation vers RecipientsScreen", level: 'INFO');
      // Navigue vers RecipientsScreen. On ne passe PLUS deviceId.
      // RecipientsScreen devra utiliser FirebaseAuth.currentUser?.uid pour le RecipientService.
      // L'écran RecipientsScreen n'a besoin que de la langue.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipientsScreen(
            // deviceId: widget.deviceId, // <-- SUPPRIMÉ
            deviceLang: widget.deviceLang, // Passer la langue
          ),
        ),
      );
      // TODO: Si RecipientsScreen permet des modifications (ajout/suppression),
      // le stream streamPairedRecipients dans ce build rechargera automatiquement la liste.
      // L'appel explicite _loadRecipients() n'est plus nécessaire si on utilise un stream.
      // _loadRecipients(); // <-- Supprimer si le stream est utilisé
    },
  ),
  // Bouton pour aller aux paramètres/profil (appelle ProfileScreen ou SettingsScreen)
  IconButton( // Ajout du bouton Settings/Profile
  icon: const Icon(Icons.settings), // Icône paramètres
  tooltip: getUILabel('settings_tooltip', widget.deviceLang), // TODO: Add settings tooltip key
  onPressed: () {
  debugLog("➡️ Navigation vers ProfileScreen/SettingsScreen", level: 'INFO');
  // Navigue vers ProfileScreen (ou SettingsScreen si ProfileScreen est juste un wrapper).
  // L'écran ProfileScreen/SettingsScreen n'a besoin que de la langue. L'UID est accessible via FirebaseAuth.currentUser.
  Navigator.push(
    context,
    MaterialPageRoute(
      // builder: (_) => ProfileScreen(deviceId: widget.deviceId, deviceLang: widget.deviceLang,), // Ancien appel avec deviceId
      // Utilise ProfileScreen (ou SettingsScreen) sans deviceId
      builder: (_) => ProfileScreen(
        // deviceId: widget.deviceId, // <-- SUPPRIMÉ
          deviceLang: widget.deviceLang
      ),
    ),
  );
  },
  ),
        ],
    ),
    // Le corps de l page affiche la liste des destinataires via un StreamBuilder
    body: Column( // Utilise Column pour structurer le corps
      children: [
        const SizedBox(height: 12), // Espacement en haut

        // Utilise un StreamBuilder pour écouter les changements dans la liste des destinataires
        Expanded( // Le StreamBuilder prend l'espace restant
          // Le stream vient du RecipientService et écoute la sous-collection 'recipients' de l'utilisateur actuel.
          // Il émet une nouvelle liste de destinataires chaque fois que la collection change.
          child: StreamBuilder<List<Recipient>>(
            stream: _recipientService.streamPairedRecipients(), // Utilise la méthode streamPairedRecipients du service
            builder: (context, snapshot) {
              // Gérer les différents états du stream (chargement, erreur, données)
              if (snapshot.connectionState == ConnectionState.waiting) {
                debugLog("⏳ LoveScreen StreamBuilder : Attente des destinataires...", level: 'DEBUG');
                // Afficher un indicateur de chargement pendant le chargement initial
                return const Center(child: CircularProgressIndicator(color: Colors.pink));
              }

              if (snapshot.hasError) {
                debugLog("❌ LoveScreen StreamBuilder Error: ${snapshot.error}", level: 'ERROR');
                // Afficher un message d'erreur si le stream rencontre un problème
                // TODO: Utiliser i18n_service pour le message d'erreur
                return Center(child: Text("Erreur lors du chargement des destinataires.", style: TextStyle(color: Colors.red)));
              }

              // Si snapshot.data est null ou vide, afficher un message "Pas de destinataires" ou le bouton d'ajout
              // Le cas snapshot.data est null ne devrait pas arriver si le stream retourne List<Recipient>[], mais on vérifie par sécurité.
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                debugLog("ℹ️ LoveScreen StreamBuilder : Aucun destinataire appairé trouvé.", level: 'INFO');
                // Afficher un message ou un widget spécial (ex: invitation à ajouter un destinataire)
                return Center(
                    child: _buildAddRecipientCard(context) // Widget pour ajouter un destinataire
                );
              }

              // Les données sont disponibles et non vides
              final recipients = snapshot.data!; // Liste des destinataires (non null ici)
              debugLog("✅ LoveScreen StreamBuilder : ${recipients.length} destinataires appairés reçus.", level: 'INFO');

              // Afficher la liste des destinataires via un PageView (scroll vertical)
              return PageView.builder(
                scrollDirection: Axis.vertical, // Défilement vertical
                itemCount: recipients.length, // Plus +1 pour le bouton d'ajout ici, car géré conditionnellement au-dessus
                itemBuilder: (context, index) {
                  final r = recipients[index]; // Le destinataire pour cet index

                  // Utilise un GestureDetector pour rendre le conteneur cliquable (navigue vers l'écran de chat/message)
                  return Center( // Centre chaque élément du PageView
                    child: GestureDetector(
                      onTap: () {
                        debugLog(
                          "📨 [LoveScreen] Destinataire sélectionné pour chat : ${r.displayName} (UID: ${r.id})",
                          level: 'INFO',
                        );
                        // Navigue vers l'écran de chat/message (RecipientDetailsScreen ou SendMessageScreen).
                        // On passe l'objet Recipient (qui contient l'UID) et la langue.
                        // L'écran de destination utilisera l'UID de l'utilisateur actuel (via FirebaseAuth.currentUser)
                        // et l'UID du destinataire (via r.id).
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipientDetailsScreen( // Ou ChatScreen(
                              // deviceId: widget.deviceId, // <-- SUPPRIMÉ
                              deviceLang: widget.deviceLang, // Passer la langue
                              recipient: r, // Passer l'objet Recipient (contient l'UID)
                            ),
                          ),
                        );
                      },
                      // Le conteneur affichant les informations du destinataire
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8, // Largeur relative à l'écran
                        height: 140, // Hauteur fixe
                        padding: const EdgeInsets.all(16), // Espacement interne
                        decoration: BoxDecoration(
                          color: Colors.pink, // Couleur de fond
                          borderRadius: BorderRadius.circular(16), // Coins arrondis
                        ),
                        child: Column( // Colonne pour aligner les éléments verticalement
                          mainAxisAlignment: MainAxisAlignment.center, // Centrer les éléments dans la colonne
                          children: [
                            // Affichage de l'icône du destinataire (champ 'icon' du modèle Recipient)
                            Text(r.icon, style: const TextStyle(fontSize: 36)),
                            const SizedBox(height: 10), // Espacement
                            // Affichage du nom du destinataire (champ 'displayName')
                            Text(
                              r.displayName, // Nom d'affichage du destinataire
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            // Affichage de la relation (champ 'relation', internationalisé via i18n_service)
                            Text(
                              getUILabel(r.relation, widget.deviceLang), // Libellé internationalisé de la relation
                              style: const TextStyle(color: Colors.white70), // Couleur discrète
                            ),
                            // TODO: Afficher un indicateur si l'utilisateur est en ligne (si la logique de présence est réimplémentée)
                            // if (r.isOnline == true) Icon(Icons.circle, color: Colors.greenAccent, size: 12)
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Ancien indicateur showIcon (supprimé)
        // if (showIcon)
        //   const Padding(
        //     padding: EdgeInsets.only(bottom: 20),
        //     child: Icon(Icons.star, color: Colors.amber, size: 100),
        //   ),

        // Ancien affichage du deviceId (supprimé)
        // Padding(
        //   padding: const EdgeInsets.only(bottom: 8),
        //   child: Text(
        //     "ID: ${widget.deviceId}", // <-- SUPPRIMÉ
        //     style: const TextStyle(color: Colors.grey, fontSize: 12),
        //   ),
        // ),
        const SizedBox(height: 8), // Un peu d'espace en bas

        // Si la liste des destinataires était vide, on peut aussi afficher ici
        // le bouton d'ajout en bas de l'écran au lieu de le centrer dans le PageView.
        // Cela dépend de votre préférence UI. Si vous l'affichez toujours en bas :
        // _buildAddRecipientCard(context), // Décommenter si vous préférez le voir en bas

      ],
    ),
    // Floating Action Button pour aller aux paramètres/profil (déjà ajouté dans les actions de l'AppBar, peut être supprimé ici si redondant)
    // floatingActionButton: IconButton(
    //   icon: const Icon(Icons.settings, color: Colors.white),
    //   onPressed: () { ... navigation vers ProfileScreen ... },
    // ),
    // Si vous voulez un FAB, utilisez FloatingActionButton au lieu de IconButton dans cette position.
    // Exemple de FAB simple pour les paramètres :
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        debugLog("➡️ Navigation vers ProfileScreen/SettingsScreen via FAB", level: 'INFO');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(deviceLang: widget.deviceLang),
          ),
        );
      },
      backgroundColor: Colors.white10, // Fond sombre
      foregroundColor: Colors.white, // Icône blanche
      child: const Icon(Icons.settings), // Icône
      tooltip: getUILabel('settings_tooltip', widget.deviceLang), // Tooltip internationalisé
    ),
  );
} // <-- Fin de la méthode build

  // Widget séparé pour le bouton "Ajouter un destinataire"
  // Peut être utilisé dans le StreamBuilder si la liste est vide, ou toujours en bas de l'écran.
  Widget _buildAddRecipientCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        debugLog("➡️ Navigation vers RecipientsScreen (pour ajouter/gérer)", level: 'INFO');
        // Navigue vers RecipientsScreen (où l'utilisateur peut ajouter de nouveaux destinataires ou voir la liste complète).
        // RecipientsScreen n'a besoin que de la langue.
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipientsScreen(
              // deviceId: widget.deviceId, // <-- SUPPRIMÉ
              deviceLang: widget.deviceLang,
            ),
          ),
        );
        // Si RecipientsScreen permet d'ajouter/modifier, le stream streamPairedRecipients rechargera automatiquement.
        // L'appel _loadRecipients() n'est plus nécessaire.
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8, // Largeur relative
        height: 140, // Hauteur fixe
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey), // Bordure grise
          borderRadius: BorderRadius.circular(16), // Coins arrondis
        ),
        child: Center( // Centrer l'icône
          child: Icon(Icons.add, color: Colors.white, size: 40), // Icône d'ajout
        ),
      ),
    );
  }


  // La méthode _showNotification (affichage notification locale) est conservée mais sa logique de déclenchement a changé.
  // Elle n'est plus appelée par l'ancien listener Firestore, mais peut être appelée par le listener FCM en avant-plan.
  // Pour l'instant, elle n'est pas appelée du tout dans le code refactorisé de cet écran.
  // Sa définition complète est incluse ici pour référence, même si elle n'est pas appelée actuellement.
  Future<void> _showNotification(String body, String? receivedSenderName) async {
    // Adapter le titre si nécessaire, peut-être basé sur le nom de l'expéditeur réel via UID si disponible dans le message FCM.
    final title = receivedSenderName != null && receivedSenderName.isNotEmpty
        ? "💌 $receivedSenderName t’a envoyé un message" // TODO: Use i18n_service + interpolate name
        : getUILabel('message_received_title', widget.deviceLang); // Titre générique si pas de nom


    // Assurez-vous que le canal de notification est créé AVANT d'afficher la notification sur Android O+ (API 26+).
    // La création du canal peut être faite une seule fois (par exemple, dans _initNotifications ou au démarrage de l'appli).
    // Le code de création du canal est déjà inclus ici mais il est commenté dans la version initiale.

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'love_channel', // ID unique du canal
      'Love Notifications', // Nom du canal visible par l'utilisateur
      description: 'Notifications pour les messages d\'amour', // Description visible par l'utilisateur
      importance: Importance.high, // Niveau d'importance (High ou Max pour son/vibration)
      playSound: true,
      enableVibration: true,
      // Vous pouvez aussi configurer un son personnalisé ici
      // sound: RawResourceAndroidNotificationSound('mysound'), // Requires sound file in res/raw
    );

    // Créer le canal de notification sur Android
    // Ceci peut être fait une seule fois. Faire ici à chaque _showNotification n'est pas optimal.
    // Déplacez la création du canal dans _initNotifications si vous voulez le créer une fois.
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        await androidPlugin.createNotificationChannel(channel);
        // debugLog("✅ Canal de notification 'love_channel' créé ou mis à jour.", level: 'DEBUG');
      } catch (e) {
        debugLog("❌ Erreur lors de la création du canal de notification : $e", level: 'ERROR');
      }
    }


    final androidDetails = AndroidNotificationDetails(
      channel.id, // Utilise l'ID du canal défini ci-dessus
      channel.name, // Utilise le nom du canal défini ci-dessus
      channelDescription: channel.description, // Utilise la description du canal
      importance: channel.importance, // Utilise l'importance du canal
      priority: Priority.high,
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
      // Autres options comme largeIcon, smallIcon, color, actions, etc.
      // largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Une icône plus grande
      // smallIcon: '@mipmap/ic_launcher', // L'icône qui s'affiche dans la barre de notification
      // color: Colors.pink.toAccentColor(), // Couleur de l'icône et titre (si icône smallIcon est monochrome)
      // payload: 'chat:${senderUid}', // Exemple de payload pour naviguer au tap (doit être une String)
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      // Paramètres spécifiques à iOS
      presentAlert: true, // Afficher une alerte
      presentBadge: true, // Mettre à jour le badge
      presentSound: true, // Jouer un son
      // sound: 'mysound.caf', // Son personnalisé (doit être inclus dans le bundle de l'appli)
    );

    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
        0, // ID unique de la notification (si vous affichez plusieurs notifications, utilisez des IDs différents)
        title, // Titre de la notification
        body, // Corps de la notification (le message localisé)
        notificationDetails, // Les détails de la plateforme
        // payload: 'your_payload_data', // Optionnel: une chaîne de caractères associée à la notification
      );
      debugLog("📢 Notification locale affichée !", level: 'SUCCESS');
    } catch (e) {
      debugLog("❌ Erreur lors de l'affichage de la notification locale : $e", level: 'ERROR');
      // TODO: Gérer l'échec d'affichage de la notification.
    }
  }

// TODO: Implémenter _findRecipientByUid(String uid) pour la navigation depuis la notification si vous ajoutez un payload avec l'UID.
// Cela pourrait chercher le destinataire dans la liste actuellement affichée par le StreamBuilder
// ou faire un appel rapide à RecipientService.getRecipient(uid).
// Recipient? _findRecipientByUid(String uid) {
//   // Chercher dans la liste recipients si elle est accessible ici (elle l'est via le snapshot du StreamBuilder)
//   // Si vous stockez la liste dans une variable d'état (moins réactif que le stream direct), cherchez ici.
//   // Sinon, utilisez le service.
//    return null; // Implémentation réelle nécessaire
// }


}
