import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ajouté le 08/04/2025 pour la partie bidirectionnelle
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ajutés le 09/04/2025 pour la partie refactoring
import 'screens/love_screen.dart';
import 'services/firestore_service.dart';
import 'services/device_service.dart';

// Détermine le rôle de l'appareil
const bool isReceiver = true; // ← Xiaomi B = true, Xiaomi A = false

// ajouté le 08/04/2025 pour la partie bidirectionnelle
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deviceId = await getDeviceId();
  // ajouté le 08/04/2025 pour la sauvegarde dans Firebase du deviceId et de son rôle
  await Firebase.initializeApp(); // important si absent
  await registerDevice(deviceId, isReceiver);
  // fin ajout
  runApp(MyApp(deviceId: deviceId));
}

// mis à jour le 08/04/2025 pour afficher l’écran combiné
class MyApp extends StatelessWidget {
  final String deviceId;
  const MyApp({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoveScreen(
        deviceId: deviceId,
        isReceiver: isReceiver,
      ),
    );
  }
}