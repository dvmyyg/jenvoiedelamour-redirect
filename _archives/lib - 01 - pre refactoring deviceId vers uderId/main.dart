// 📄 lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart'; // ajouté le 24/05/2025 — remplacement de uni_links
import 'dart:ui';
import 'dart:async';

import 'screens/home_selector.dart';
import 'services/firestore_service.dart';
import 'services/device_service.dart';
import 'firebase_options.dart';
import 'utils/debug_log.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart'; // ajouté le 21/05/2025 — rediriger si email non vérifié

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugLog("🖙 Message reçu en arrière-plan : ${message.messageId}", level: 'INFO');
}

// ajouté le 24/05/2025 — capture les liens d'appairage intent://recipient=... via app_links
Future<String?> handleAppLinks(String deviceId) async {
  final AppLinks appLinks = AppLinks();

  // lien de démarrage
  final Uri? initialUri = await appLinks.getInitialAppLink();
  if (initialUri != null && initialUri.queryParameters.containsKey('recipient')) {
    final recipientId = initialUri.queryParameters['recipient'];
    debugLog("📨 AppLink (initial) → recipient=$recipientId", level: 'INFO');
    await _pairWith(recipientId, deviceId);
    return recipientId;
  }

  // 🔁 écoute des liens à chaud
  appLinks.uriLinkStream.listen((Uri? uri) async {
    if (uri != null && uri.queryParameters.containsKey('recipient')) {
      final recipientId = uri.queryParameters['recipient'];
      debugLog("📨 AppLink (stream) → recipient=$recipientId", level: 'INFO');
      await _pairWith(recipientId, deviceId);
    }
  });

  return null;
}

Future<String?> _pairWith(String? recipientId, String deviceId) async {
  if (recipientId == null || recipientId.isEmpty) return null;
  try {
    final docRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(recipientId)
        .collection('recipients')
        .doc(deviceId);

    await docRef.set({'deviceId': deviceId}, SetOptions(merge: true));
    debugLog("✅ Appairage réussi : $recipientId ↔ $deviceId", level: 'SUCCESS');
    return recipientId;
  } catch (e) {
    debugLog("❌ Erreur d’appairage Firestore : $e", level: 'ERROR');
    return null;
  }
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

  final String? pairedRecipientId = await handleAppLinks(deviceId);

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
      debugLog("🚀 Affichage écran succès appairage", level: 'INFO');
      _showPairSuccess = true;
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          debugLog("⏳ Fin écran succès", level: 'INFO');
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
            if (!user.emailVerified) {
              debugLog("🔒 Email non vérifié — accès restreint", level: 'WARNING');
              return EmailVerificationScreen(
                deviceId: widget.deviceId,
                deviceLang: widget.deviceLang,
              );
            }

            if (_showPairSuccess) {
              return PairSuccessScreen(recipientId: widget.initialPairSuccessRecipientId!);
            }

            return HomeSelector(
              deviceId: widget.deviceId,
              deviceLang: widget.deviceLang,
            );
          } else {
            return LoginScreen(
              deviceLang: widget.deviceLang,
              deviceId: widget.deviceId,
            );
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
