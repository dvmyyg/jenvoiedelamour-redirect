import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔐 Ajouté pour la gestion des permissions Android 13+
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 📌 Ajouté le 08/04/2025 pour la partie bidirectionnelle
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// 📦 Ajouté le 09/04/2025 pour la partie refactoring
import 'screens/love_screen.dart';
import 'services/firestore_service.dart';
import 'services/device_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔙 Message reçu en arrière-plan : ${message.messageId}");
}

// 🧭 Détermine le rôle de l'appareil
const bool isReceiver = true; // ← Xiaomi B = true, Xiaomi A = false

// 🔔 Obligatoire pour les notifications locales (Android)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// ⚙️ Initialise la gestion des notifications (canaux, permissions, etc.)
Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Android 13+ → demande de permission explicite
  final messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ Optionnel : log le statut des permissions
  print('🔐 Notification permission: ${settings.authorizationStatus}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🧠 Identifiant local pour ce device
  final deviceId = await getDeviceId();

  // 🔥 Initialise Firebase + enregistre l'appareil dans Firestore
  await Firebase.initializeApp();
  await registerDevice(deviceId, isReceiver);

  // 🔁 Ajouté le 10/04/2025 pour la réception en arrière-plan (FCM)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 📱 Ajouté le 10/04/2025 pour obtenir le token FCM
  final token = await FirebaseMessaging.instance.getToken();
  print("📱 FCM Token: $token");

  // 🔔 Initialise les notifications (channel + permission)
  await _initializeNotifications();

  runApp(MyApp(deviceId: deviceId));
}

// 🌈 Interface principale de l'application
class MyApp extends StatelessWidget {
  final String deviceId;
  const MyApp({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jela',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: LoveScreen(
        deviceId: deviceId,
        isReceiver: isReceiver,
      ),
    );
  }
}