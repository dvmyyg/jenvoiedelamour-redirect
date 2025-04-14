// 📄 lib/screens/love_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/i18n_service.dart';
import '../screens/settings_screen.dart';
import '../screens/recipients_screen.dart';
import '../models/recipient.dart';
import '../services/recipient_service.dart';

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
  List<Recipient> recipients = [];
  Recipient? selectedRecipient;

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
      if (doc.exists && doc.data()?['messageType'] != null) {
        final String type = doc.data()?['messageType'];
        final String? receivedSenderName = doc.data()?['senderName'];

        print("🌟 Message reçu : $type");

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

  Future<void> _loadRecipients() async {
    final service = RecipientService(widget.deviceId);
    final list = await service.fetchRecipients();
    setState(() {
      recipients = list;
      if (recipients.isNotEmpty) {
        selectedRecipient = recipients[0];
      }
    });
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
    print("🧪 Token FCM : $fcmToken");
  }

  Future<void> sendLove(String type) async {
    if (selectedRecipient == null || !selectedRecipient!.paired || selectedRecipient!.deviceId == null) {
      print("❌ Aucun destinataire sélectionné ou non appairé");
      return;
    }

    final otherDeviceId = selectedRecipient!.deviceId!;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: "Gérer les destinataires",
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
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recipients.length + 1,
              itemBuilder: (context, index) {
                if (index == recipients.length) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipientsScreen(
                            deviceId: widget.deviceId,
                            deviceLang: widget.deviceLang,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  );
                } else {
                  final r = recipients[index];
                  final isSelected = r.id == selectedRecipient?.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRecipient = r;
                      });
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pink : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(r.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 6),
                          Text(r.displayName, style: const TextStyle(color: Colors.white)),
                          Text(r.relation, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20),
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
            onPressed: selectedRecipient != null && selectedRecipient!.paired ? () => sendLove(selectedMessageType) : null,
            icon: const Icon(Icons.send),
            label: Text(getUILabel('send', widget.deviceLang)),
          ),
          const SizedBox(height: 40),
          if (showIcon) const Icon(Icons.star, color: Colors.amber, size: 100),
          const SizedBox(height: 20),
          Text("📱 ID: ${widget.deviceId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      floatingActionButton: IconButton(
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

    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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

    print("📢 Notification locale envoyée !");
  }
}
