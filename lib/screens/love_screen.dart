import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

  // 💡 Ajout : variable pour les notifications
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    // Initialisation du plugin de notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initSettings);

    // ❌ SUPPRIMÉ : _requestNotificationPermission()
    // 📌 Depuis la version 17.x du plugin `flutter_local_notifications`,
    // la méthode `requestPermission()` n'existe plus côté Android.
    // ⚠️ Les permissions sont désormais à gérer via le manifeste pour Android 13+.
    //
    // De plus, aucun besoin de demander quoi que ce soit sur Android < 13.
    //
    // 🔐 Ancien appel désactivé :
    // _requestNotificationPermission();

    // 🔧 Test direct (notification à l'init pour debug)
    _showNotification();

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
            Text("📱 ID: ${widget.deviceId}"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: sendLove,
              icon: const Icon(Icons.favorite, color: Colors.red),
              label: const Text('Envoyer un cœur'),
            ),
            const SizedBox(height: 40),
            showIcon
                ? const Icon(Icons.star, color: Colors.amber, size: 100)
                : const Text("💤 En attente de l'amour..."),
          ],
        ),
      ),
    );
  }

  // 💡 Ajout : fonction pour afficher la notification locale
  Future<void> _showNotification() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'love_channel', // id
      'Love Notifications', // nom visible
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

// ❌ SUPPRIMÉ : _requestNotificationPermission()
// Cette méthode est désormais inutile avec `flutter_local_notifications` ≥ 17.x
// car `requestPermission()` n'est plus exposée côté Android.
// Le code suivant est conservé à titre informatif uniquement :
/*
  Future<void> _requestNotificationPermission() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final granted = await androidPlugin?.requestPermission();
      print('🔐 Permission notification : ${granted == true ? "accordée" : "refusée"}');
    } else {
      print('🔐 Android < 13 → permission automatique');
    }
  }
  */
}