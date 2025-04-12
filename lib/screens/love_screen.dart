// 📄 lib/screens/love_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/i18n_service.dart';
import '../screens/settings_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 [FCM-BG] Notification reçue en arrière-plan : ${message.notification?.title}");
}

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
  Timer? pingTimer;
  String? senderName;

  @override
  void initState() {
    super.initState();
    _updateForegroundStatus(true);
    _loadDisplayName();

    _initNotifications();
    _configureFCM();

    pingTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _updateForegroundStatus(true);
    });

    FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .snapshots()
        .listen((doc) async {
      if (doc.exists && doc.data()?['messageType'] != null) {
        final String type = doc.data()?['messageType'];
      final String? receivedSenderName = doc.data()?['senderName'];

      print("🎯 Message reçu : $type");

        setState(() => showIcon = true);
        final localizedBody = getMessageBody(type, widget.deviceLang);
        await _showNotification(localizedBody, receivedSenderName);

        await Future.delayed(const Duration(seconds: 2));
        setState(() => showIcon = false);

        await FirebaseFirestore.instance
            .collection('devices')
            .doc(widget.deviceId)
            .update({'messageType': FieldValue.delete()});
      }
    });
  }

  Future<void> _loadDisplayName() async {
    final doc = await FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).get();
    senderName = doc.data()?['displayName'] ?? null;
  }

  @override
  void dispose() {
    _updateForegroundStatus(false);
    pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateForegroundStatus(bool isForeground) async {
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .update({
      'isForeground': isForeground,
      'lastPing': DateTime.now(),
    });
    print("📱 isForeground=$isForeground mis à jour pour ${widget.deviceId}");
  }

  Future<void> _initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _configureFCM() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final type = message.data['messageType'] ?? 'heart';
      print("📨 [FCM] Notification reçue (avant-plan): type=$type");

      setState(() => showIcon = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => showIcon = false);
    });

    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("🪪 Token FCM : $fcmToken");
  }

  Future<void> sendLove(String type) async {
    final deviceRef = FirebaseFirestore.instance.collection('devices').doc(widget.deviceId);
    final deviceDoc = await deviceRef.get();

    final pairingCode = deviceDoc.data()?['pairingCode'];
    if (pairingCode == null) {
      print("⚠️ Aucun code d’appairage trouvé pour ce device !");
      return;
    }

    final pairingRef = FirebaseFirestore.instance.collection('pairings').doc(pairingCode);
    final pairingDoc = await pairingRef.get();

    final data = pairingDoc.data();
    if (data == null) {
      print("⚠️ Code d’appairage non valide !");
      return;
    }

    final isDeviceA = data['deviceA'] == widget.deviceId;
    final isDeviceB = data['deviceB'] == widget.deviceId;

    if (!isDeviceA && !isDeviceB) {
      print("❌ Ce téléphone ne fait pas partie de l’appairage !");
      return;
    }

    final otherDeviceId = isDeviceA ? data['deviceB'] : data['deviceA'];
    if (otherDeviceId == null) {
      print("⏳ Appairage encore incomplet...");
      return;
    }

    final otherDeviceRef = FirebaseFirestore.instance.collection('devices').doc(otherDeviceId);
    await otherDeviceRef.update({
      'messageType': type,
      'senderName': senderName ?? 'Quelqu’un',
    });

    print('📤 Message "$type" envoyé à $otherDeviceId via appairage 🔗');
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
          return Stack(
            children: [
              Center(
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
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          currentLang: widget.deviceLang,
                          deviceId: widget.deviceId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showNotification(String body, String? receivedSenderName) async {
     final title = receivedSenderName != null
         ? "💌 ${receivedSenderName} t’a envoyé un message"
         : getUILabel('message_received_title', widget.deviceLang);

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

    final androidDetails = AndroidNotificationDetails(
      'love_channel',
      'Love Notifications',
      channelDescription: 'Affiche un cœur en surimpression 💖',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      '', // on laisse body vide pour ne pas afficher le corps du message dans la notification
      notificationDetails,
    );

    print("📢 Notification locale envoyée !");
  }
}
