//  lib/screens/love_screen.dart

// Historique du fichier
// V002 - ajout explicite du paramètre displayName (prénom) - 2025/05/24 08h20
// V001 - version nécessitant une correction pour le prénom utilisateur - 2025/05/23 21h00

import '../utils/debug_log.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/i18n_service.dart';
import '../screens/recipients_screen.dart';
import '../screens/send_message_screen.dart';
import '../models/recipient.dart';
import '../services/recipient_service.dart';
import '../screens/profile_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugLog(
    "🔔 [FCM-BG] Notification reçue en arrière-plan : ${message.notification?.title}",
  );
}

class LoveScreen extends StatefulWidget {
  final String deviceId;
  final bool isReceiver;
  final String deviceLang;
  final String? displayName; // 👈 ajout du prénom utilisateur

  const LoveScreen({
    super.key,
    required this.deviceId,
    required this.isReceiver,
    required this.deviceLang,
    this.displayName, // 👈 injection optionnelle
  });

  @override
  State<LoveScreen> createState() => _LoveScreenState();
}

class _LoveScreenState extends State<LoveScreen> {
  bool showIcon = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Timer? pingTimer;
  String? senderName;
  List<Recipient> recipients = [];

  @override
  void initState() {
    super.initState();
    _updateForegroundStatus(true);
    _loadDisplayName();
    _loadRecipients();
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
      final data = doc.data();
      if (data != null && data['messageType'] != null) {
        final messageType = data['messageType'] as String;
        final receivedSenderName = data['senderName'] as String?;

        debugLog("🌟 Message reçu : $messageType");

        setState(() => showIcon = true);
        final localizedBody = getMessageBody(
          messageType,
          widget.deviceLang,
        );
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
    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .get();
    senderName = doc.data()?['displayName'] as String?;
    debugLog("💛 Nom du device (senderName) : $senderName");
  }

  Future<void> _loadRecipients() async {
    final service = RecipientService(widget.deviceId);
    final list = await service.fetchRecipients();
    setState(() {
      recipients = list;
    });
    debugLog("👥 ${recipients.length} destinataires chargés depuis Firestore");
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
        .set(
      {
        'isForeground': isForeground,
        'lastPing': DateTime.now(),
      },
      SetOptions(merge: true),
    );
    debugLog(
      "📱 isForeground=$isForeground mis à jour pour ${widget.deviceId}",
    );
  }

  Future<void> _initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
      final messageType = message.data['messageType'] as String? ?? 'heart';
      debugLog("📨 [FCM] Notification reçue (avant-plan): type=$messageType");

      setState(() => showIcon = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => showIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(getUILabel('love_screen_title', widget.deviceLang)),
              ],
            ),
            if (widget.displayName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.displayName!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: getUILabel('manage_recipients_tooltip', widget.deviceLang),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipientsScreen(
                    deviceId: widget.deviceId,
                    deviceLang: widget.deviceLang,
                  ),
                ),
              );
              _loadRecipients();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: recipients.length + 1,
              itemBuilder: (context, index) {
                if (index == recipients.length) {
                  return Center(
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipientsScreen(
                              deviceId: widget.deviceId,
                              deviceLang: widget.deviceLang,
                            ),
                          ),
                        );
                        _loadRecipients();
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  );
                } else {
                  final r = recipients[index];
                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        debugLog(
                          "📨 Message tap sur destinataire : ${r.displayName} (${r.id})",
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendMessageScreen(
                              deviceId: widget.deviceId,
                              deviceLang: widget.deviceLang,
                              recipient: r,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 140,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(r.icon, style: const TextStyle(fontSize: 36)),
                            const SizedBox(height: 10),
                            Text(
                              r.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              getUILabel(r.relation, widget.deviceLang),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          if (showIcon)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Icon(Icons.star, color: Colors.amber, size: 100),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "ID: ${widget.deviceId}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.settings, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                deviceId: widget.deviceId,
                deviceLang: widget.deviceLang,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNotification(String body, String? receivedSenderName) async {
    final title = receivedSenderName != null
        ? "💌 $receivedSenderName t’a envoyé un message"
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
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
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
      '',
      notificationDetails,
    );

    debugLog("📢 Notification locale envoyée !");
  }
}
