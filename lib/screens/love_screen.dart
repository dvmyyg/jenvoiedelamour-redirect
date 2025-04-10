// love_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/i18n_service.dart';


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
  final String deviceLang;
  const LoveScreen({super.key, required this.deviceId, required this.isReceiver, required this.deviceLang});

  @override
  State<LoveScreen> createState() => _LoveScreenState();
}

class _LoveScreenState extends State<LoveScreen> {
  String selectedMessageType = 'heart';
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
      if (doc.exists && doc.data()?['messageType'] != null) {
        final String type = doc.data()?['messageType'];
        print("🎯 Message reçu : $type");

        setState(() => showIcon = true);
        final localizedBody = getMessageBody(type, widget.deviceLang);
        await _showNotification(localizedBody);

        await Future.delayed(const Duration(seconds: 2));
        setState(() => showIcon = false);

        await FirebaseFirestore.instance
            .collection('devices')
            .doc(widget.deviceId)
            .update({'messageType': FieldValue.delete()});
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
      final type = message.data['messageType'] ?? 'heart';
      print("📨 [FCM] Notification reçue (avant-plan): type=$type");
      final body = getMessageBody(type, widget.deviceLang);
      _showNotification(body);

    });

    // 📬 Pour test/debug : affichage du token FCM (utilisable pour envoi ciblé)
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("🪪 Token FCM : $fcmToken");
  }

  Future<void> sendLove(String type) async {
    final devices = await FirebaseFirestore.instance.collection('devices').get();
    for (final doc in devices.docs) {
      if (doc.id != widget.deviceId) {
        await doc.reference.update({'messageType': type});
      }
    }

    print('📤 Message "$type" envoyé à un autre device !');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.favorite, color: Colors.red),
            SizedBox(width: 8),
            Text("J'envoie de l'amour"),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: selectedMessageType,
                    dropdownColor: Colors.black,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: getAllMessageTypes().map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          getPreviewText(value, widget.deviceLang),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMessageType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => sendLove(selectedMessageType),
                    icon: const Icon(Icons.send),
                    label: Text(getUILabel('send', widget.deviceLang)),
                  ),
                  const SizedBox(height: 60),
                  if (showIcon)
                    const Icon(Icons.star, color: Colors.amber, size: 100),
                  const SizedBox(height: 60),
                  Text(
                    "📱 ID: ${widget.deviceId}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// 💡 Fonction pour afficher la notification locale
  Future<void> _showNotification(String body) async {
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
      getUILabel('message_received_title', widget.deviceLang),
      body,
      notificationDetails,
    );

    print("📢 Notification locale envoyée !");
  }
}