import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 🔁 Fonction globale pour recevoir les notifications même en arrière-plan ou app fermée
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 [FCM-BG] Notification reçue en arrière-plan : ${message.notification?.title}");
  // On pourrait relancer une notification ici si nécessaire
}

// ajouté le 08/04/2025 pour l’écran combiné envoi + réception
class LoveScreen extends StatefulWidget {
  final String deviceId;
  final bool isReceiver;
  const LoveScreen({super.key, required this.deviceId, required this.isReceiver});

  @override
  State<LoveScreen> createState() => _LoveScreenState();
}

class _LoveScreenState extends State<LoveScreen> {
  bool showIcon = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    _initNotifications();
    _configureFCM();

    // 🔁 Écoute des mises à jour Firestore
    FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .snapshots()
        .listen((doc) async {
      if (doc.exists && doc.data()?['showIcon'] == true) {
        print("🎯 Cœur reçu → animation");
        setState(() => showIcon = true);

        await _showNotification();

        await Future.delayed(const Duration(seconds: 2));
        setState(() => showIcon = false);

        await FirebaseFirestore.instance
            .collection('devices')
            .doc(widget.deviceId)
            .update({'showIcon': false});
      }
    });
  }

  Future<void> _initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _configureFCM() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🔔 App en avant-plan : on affiche la notif manuellement
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📨 [FCM] Notification reçue (avant-plan): ${message.notification?.title}");
      _showNotification();
    });

    // 📬 Pour test/debug : affichage du token FCM (utilisable pour envoi ciblé)
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("🪪 Token FCM : $fcmToken");
  }

  Future<void> sendLove() async {
    final devices = await FirebaseFirestore.instance.collection('devices').get();
    for (final doc in devices.docs) {
      if (doc.id != widget.deviceId) {
        await doc.reference.update({'showIcon': true});
      }
    }

    print('❤️ Cœur envoyé à tous les autres devices !');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("J'envoie de l'amour")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("📱 ID: \${widget.deviceId}"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: sendLove,
              icon: const Icon(Icons.favorite, color: Colors.red),
              label: const Text('Envoyer un cœur'),
            ),
            const SizedBox(height: 40),
            showIcon
                ? const Icon(Icons.star, color: Colors.amber, size: 100)
                : const Text("🛌 En attente de l'amour..."),
          ],
        ),
      ),
    );
  }

  // 💡 Fonction pour afficher la notification locale
  Future<void> _showNotification() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'love_channel',
      'Love Notifications',
      description: 'Affiche un cœur en surimpression 💖',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    const androidDetails = AndroidNotificationDetails(
      'love_channel',
      'Love Notifications',
      channelDescription: 'Affiche un cœur en surimpression 💖',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '💌 Message reçu',
      'Quelqu’un pense à toi 💖',
      notificationDetails,
    );

    print("📢 Notification locale envoyée !");
  }
}