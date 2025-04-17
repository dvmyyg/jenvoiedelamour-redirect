// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

// 🔐 Notifications locales
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 📌 Appairage + préférences
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// 🌟 Écrans + services
import 'screens/love_screen.dart';
import 'services/firestore_service.dart';
import 'services/device_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔙 Message reçu en arrière-plan : ${message.messageId}");
}

// 🧭 Rôle : true = receveur, false = émetteur
const bool isReceiver = true;

// 🔔 Plugin notifications locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('🔐 Notification permission: ${settings.authorizationStatus}');
}

Future<void> _handleManualLink(String deviceId) async {
  final Uri deepLink = Uri.base;

  print("🔗 Lien reçu via Uri.base : $deepLink");

  if (deepLink.queryParameters.containsKey('recipient')) {
    final recipientId = deepLink.queryParameters['recipient'];

    if (recipientId != null && recipientId.isNotEmpty) {
      final docRef = FirebaseFirestore.instance
          .collection('devices')
          .doc(deviceId)
          .collection('recipients')
          .doc(recipientId);

      await docRef.update({'deviceId': deviceId});
      print("✅ Appairage terminé avec le destinataire $recipientId");

      Future.delayed(const Duration(seconds: 1), () {
        runApp(MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: Text("✅ Appairage réussi !",
                  style: TextStyle(color: Colors.white, fontSize: 22)),
            ),
          ),
        ));
      });

      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final deviceId = await getDeviceId();
  final String deviceLang = PlatformDispatcher.instance.locale.languageCode;
  print("🌐 Langue du téléphone : $deviceLang");

  await Firebase.initializeApp();
  await registerDevice(deviceId, isReceiver);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final token = await FirebaseMessaging.instance.getToken();
  print("📱 FCM Token: $token");

  await _initializeNotifications();
  await _handleManualLink(deviceId);

  runApp(MyApp(deviceId: deviceId, deviceLang: deviceLang));
}

class MyApp extends StatelessWidget {
  final String deviceId;
  final String deviceLang;
  const MyApp({super.key, required this.deviceId, required this.deviceLang});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jela',
      theme: ThemeData(useMaterial3: true),
      home: LoveScreen(
        deviceId: deviceId,
        isReceiver: isReceiver,
        deviceLang: deviceLang,
      ),
    );
  }
}
