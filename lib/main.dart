// 📄 lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:async';
import 'screens/home_selector.dart';
import 'services/firestore_service.dart';
import 'services/device_service.dart';
import 'firebase_options.dart';
import 'utils/debug_log.dart';
import 'screens/login_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugLog("🖙 Message reçu en arrière-plan : ${message.messageId}", level: 'INFO');
}

Future<String?> _handleManualLink(String deviceId) async {
  final Uri? deepLink = Uri.tryParse(PlatformDispatcher.instance.defaultRouteName);
  debugLog("🔗 Lien potentiel via route par défaut : $deepLink", level: 'INFO');

  if (deepLink != null && deepLink.queryParameters.containsKey('recipient')) {
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
        debugLog("✅ Appairage terminé : $recipientId a reçu l'invité $deviceId", level: 'SUCCESS');
        return recipientId;
      } catch (e) {
        debugLog("❌ Erreur lors de l'appairage Firebase : $e", level: 'ERROR');
        return null;
      }
    }
  } else {
    debugLog("⚠️ Aucun paramètre recipient trouvé dans l'URL", level: 'WARNING');
  }
  return null;
}

const bool isReceiver = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugLog("✨ Firebase initialisé", level: 'INFO');

  await FirebaseAuth.instance.authStateChanges().first;
  debugLog("👤 État d'auth Firebase synchronisé", level: 'INFO');

  final deviceId = await getDeviceId();
  final String deviceLang = PlatformDispatcher.instance.locale.languageCode;

  debugLog("🌐 Langue du téléphone : $deviceLang", level: 'INFO');
  debugLog("🔖 Device ID : $deviceId", level: 'INFO');

  await registerDevice(deviceId, isReceiver);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final token = await FirebaseMessaging.instance.getToken();
  debugLog("🪪 FCM Token: $token", level: 'INFO');

  final String? pairedRecipientId = await _handleManualLink(deviceId);

  runApp(MyApp(
    deviceId: deviceId,
    deviceLang: deviceLang,
    initialPairSuccessRecipientId: pairedRecipientId,
  ));
}

class MyApp extends StatefulWidget {
  final String deviceId;
  final String deviceLang;
  final String? initialPairSuccessRecipientId;

  const MyApp({
    super.key,
    required this.deviceId,
    required this.deviceLang,
    this.initialPairSuccessRecipientId,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showPairSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPairSuccessRecipientId != null) {
      debugLog("🚀 Affichage de l'écran de succès appairage...", level: 'INFO');
      _showPairSuccess = true;
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          debugLog("⏳ Délai écran succès terminé", level: 'INFO');
          setState(() => _showPairSuccess = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jela',
      theme: ThemeData(useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            );
          }

          final user = snapshot.data;
          if (user != null) {
            if (_showPairSuccess) {
              return PairSuccessScreen(recipientId: widget.initialPairSuccessRecipientId!);
            }
            return HomeSelector(
              deviceId: widget.deviceId,
              deviceLang: widget.deviceLang,
            );
          } else {
            return LoginScreen(deviceLang: widget.deviceLang);
          }
        },
      ),
    );
  }
}

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
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            const Text("✅ Appairage réussi !",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 10),
            Text(
              "Appairé avec : $recipientId",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text("Redirection vers l'application...",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
