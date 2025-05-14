// 📄 lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

// 🔐 Notifications locales
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🌟 Écrans + services
import 'screens/home_selector.dart';
import 'services/firestore_service.dart';
import 'services/device_service.dart';
import 'firebase_options.dart';
import 'utils/debug_log.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugLog(
    "🔙 Message reçu en arrière-plan : ${message.messageId}",
    level: 'INFO',
  );
}

// 🧱 Rôle : true = receveur, false = émetteur
const bool isReceiver = true;

// 🔔 Plugin notifications locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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

  debugLog(
    '🔐 Notification permission: ${settings.authorizationStatus}',
    level: 'INFO',
  );
}

Future<void> _handleManualLink(String deviceId) async {
  final Uri deepLink = Uri.base;

  debugLog("🔗 Lien reçu via Uri.base : $deepLink", level: 'INFO');

  if (deepLink.queryParameters.containsKey('recipient')) {
    final recipientId = deepLink.queryParameters['recipient'];

    debugLog("📨 Paramètre recipient détecté : $recipientId", level: 'INFO');

    if (recipientId != null && recipientId.isNotEmpty) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('devices')
            .doc(recipientId)
            .collection('recipients')
            .doc(deviceId);

        await docRef.set({'deviceId': deviceId}, SetOptions(merge: true));

        debugLog(
          "✅ Appairage terminé : $recipientId a reçu l'invité $deviceId",
          level: 'SUCCESS',
        );

        Future.delayed(const Duration(seconds: 1), () {
          runApp(
            MaterialApp(
              home: Scaffold(
                backgroundColor: Colors.black,
                body: const Center(
                  child: Text(
                    "✅ Appairage réussi !",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),
              ),
            ),
          );
        });

        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        debugLog("❌ Erreur lors de l'appairage Firebase : $e", level: 'ERROR');
      }
    }
  } else {
    debugLog(
      "⚠️ Aucun paramètre recipient trouvé dans l'URL",
      level: 'WARNING',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final deviceId = await getDeviceId();
  final String deviceLang = PlatformDispatcher.instance.locale.languageCode;
  debugLog("🌐 Langue du téléphone : $deviceLang", level: 'INFO');
  debugLog("🔖 Device ID détecté : $deviceId", level: 'INFO');

  // Initialisation de Firebase avec les options correctes
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ App Check désactivé

  await registerDevice(deviceId, isReceiver);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final token = await FirebaseMessaging.instance.getToken();
  debugLog("🪪 FCM Token: $token", level: 'INFO');

  await _initializeNotifications();
  await _handleManualLink(deviceId);

  runApp(MyApp(deviceLang: deviceLang));
}

class MyApp extends StatelessWidget {
  final String deviceLang;
  const MyApp({super.key, required this.deviceLang});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jela',
      theme: ThemeData(useMaterial3: true),
      home: HomeSelector(deviceLang: deviceLang),
    );
  }
}
