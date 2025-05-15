// 📄 lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:async'; // Import pour Timer

// 🔐 Notifications locales
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🌟 Écrans + services
import 'screens/home_selector.dart'; // Assurez-vous que ce chemin est correct
import 'services/firestore_service.dart'; // Assurez-vous que ce chemin est correct
import 'services/device_service.dart'; // Assurez-vous que getDeviceId et registerDevice sont ici
import 'firebase_options.dart'; // Assurez-vous que ce chemin est correct
import 'utils/debug_log.dart'; // Assurez-vous que debugLog est ici

// --- Fonctions de base ---

// Gestion des messages FCM en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ✅ Protection anti-double initialisation ici (nécessaire pour l'isolate background)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugLog("🖙 Message reçu en arrière-plan : ${message.messageId}", level: 'INFO');
  // Ici, vous pourriez traiter le message si nécessaire, par exemple afficher une notification locale.
  // Notez que vous ne pouvez PAS mettre à jour l'interface utilisateur ici.
}

// 🔔 Plugin notifications locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Initialisation du plugin de notifications locales et demande de permission
Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugLog('🔐 Notification permission: ${settings.authorizationStatus}', level: 'INFO');
}

// Gestion du lien manuel (Deep Link) - Ne gère PLUS l'UI !
// Cette fonction renvoie l'ID du destinataire si l'appairage réussit, sinon null.
Future<String?> _handleManualLink(String deviceId) async {
  // Utilise defaultRouteName qui peut contenir un deep link d'ouverture initial
  // Vous pourriez ajuster cela si votre stratégie de deep linking est différente (ex: package uni_links).
  final Uri? deepLink = Uri.tryParse(PlatformDispatcher.instance.defaultRouteName);

  debugLog("🔗 Lien potentiel via route par défaut : $deepLink", level: 'INFO');

  if (deepLink != null && deepLink.queryParameters.containsKey('recipient')) {
    final recipientId = deepLink.queryParameters['recipient'];

    debugLog("📨 Paramètre recipient détecté : $recipientId", level: 'INFO');

    if (recipientId != null && recipientId.isNotEmpty) {
      try {
        // Appairage Firestore
        final docRef = FirebaseFirestore.instance
            .collection('devices')
            .doc(recipientId)
            .collection('recipients')
            .doc(deviceId);

        await docRef.set({'deviceId': deviceId}, SetOptions(merge: true));

        debugLog("✅ Appairage terminé : $recipientId a reçu l'invité $deviceId", level: 'SUCCESS');
        return recipientId; // Retourne l'ID du destinataire si l'appairage réussi
      } catch (e) {
        debugLog("❌ Erreur lors de l'appairage Firebase : $e", level: 'ERROR');
        // Gérer l'erreur (ex: afficher un message d'erreur à l'utilisateur plus tard)
        return null; // Retourne null en cas d'erreur
      }
    }
  } else {
    debugLog("⚠️ Aucun paramètre recipient trouvé dans l'URL ou route par défaut", level: 'WARNING');
  }
  return null; // Retourne null si aucun lien valide n'est trouvé ou si le paramètre est vide
}


// --- Point d'entrée principal ---

// Nous devons maintenant passer le résultat du deep link à notre widget principal
// pour qu'il puisse afficher l'écran de succès OU l'écran normal.
Future<void> main() async {
  // S'assure que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialisation Firebase ---
  // ✅ Correction : Supprime la protection anti-double initialisation ici.
  // Initialisation standard de Firebase dans l'isolate principal.
  // Cette ligne DOIT être appelée une seule fois dans l'isolate principal.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugLog("✨ Firebase initialisé dans l'isolate principal.", level: 'INFO');

  // ✅ Attente de la synchronisation utilisateur (si nécessaire pour l'init suivante)
  // Cela assure que l'état d'authentification est connu avant de continuer.
  await FirebaseAuth.instance.authStateChanges().first;
  debugLog("👤 État d'auth Firebase initial synchronisé.", level: 'INFO');


  // --- Récupération des infos appareil ---
  final deviceId = await getDeviceId(); // Assurez-vous que getDeviceId est bien async et retourne String
  final String deviceLang = PlatformDispatcher.instance.locale.languageCode;

  debugLog("🌐 Langue du téléphone : $deviceLang", level: 'INFO');
  debugLog("🔖 Device ID détecté : $deviceId", level: 'INFO');

  // App Check désactivé volontairement - Assurez-vous que c'est le comportement désiré
  await registerDevice(deviceId, isReceiver); // Assurez-vous que registerDevice est bien async

  // --- Configuration FCM ---
  // Gère les messages reçus quand l'app est en arrière-plan/terminée
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final token = await FirebaseMessaging.instance.getToken();
  debugLog("🪪 FCM Token: $token", level: 'INFO');

  await _initializeNotifications();

  // --- Gestion du Deep Link avant de lancer l'UI ---
  // On appelle _handleManualLink pour tenter l'appairage via le lien
  final String? pairedRecipientId = await _handleManualLink(deviceId);

  // Maintenant, on lance l'application principale, mais on lui passe
  // l'information si l'appairage via deep link a réussi ou non.
  runApp(MyApp(
    deviceLang: deviceLang,
    initialPairSuccessRecipientId: pairedRecipientId, // Passons l'info à MyApp
  ));
}

// 🧱 Rôle : true = receveur, false = émetteur
const bool isReceiver = true; // Cette constante peut rester ici si elle est utilisée ailleurs

// --- Widgets de l'Application ---

// Widget principal de l'application
class MyApp extends StatefulWidget {
  final String deviceLang;
  // Ajout du paramètre pour savoir si l'appairage initial a réussi
  final String? initialPairSuccessRecipientId;

  const MyApp({
    super.key,
    required this.deviceLang,
    this.initialPairSuccessRecipientId,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // État pour gérer l'affichage temporaire de l'écran de succès
  bool _showPairSuccess = false;

  @override
  void initState() {
    super.initState();
    // Si l'appairage initial via deep link a réussi...
    if (widget.initialPairSuccessRecipientId != null) {
      debugLog("🚀 Affichage de l'écran de succès appairage...", level: 'INFO');
      // On met l'état à true pour afficher l'écran de succès.
      _showPairSuccess = true;
      // Puis on lance un timer pour repasser à l'écran principal après un délai.
      Timer(const Duration(seconds: 3), () { // Délai de 3 secondes par exemple
        if (mounted) { // Vérifie que le widget est toujours monté avant de faire setState
          debugLog("⏳ Délai de l'écran de succès terminé. Affichage de l'écran principal.", level: 'INFO');
          setState(() {
            _showPairSuccess = false; // Cache l'écran de succès et rebuild
          });
        }
      });
    } else {
      debugLog("🔄 Pas d'appairage initial via deep link. Affichage de l'écran principal directement.", level: 'INFO');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilise un Ternary Operator pour choisir quel widget afficher
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jela',
      theme: ThemeData(useMaterial3: true),
      // Si _showPairSuccess est true, affiche l'écran de succès.
      // Sinon, affiche l'écran principal (HomeSelector).
      home: _showPairSuccess
          ? PairSuccessScreen(recipientId: widget.initialPairSuccessRecipientId!)
          : HomeSelector(deviceLang: widget.deviceLang), // Passe la langue à HomeSelector
    );
  }
}

// Nouveau Widget pour afficher l'écran de succès de l'appairage
class PairSuccessScreen extends StatelessWidget {
  final String recipientId;
  const PairSuccessScreen({super.key, required this.recipientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              "✅ Appairage réussi !",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              "Appairé avec : $recipientId",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            // Optionnel: Indicateur que quelque chose se passe avant de passer à l'app
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Redirection vers l'application...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
