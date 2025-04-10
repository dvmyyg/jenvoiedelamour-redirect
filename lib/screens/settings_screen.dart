// 📄 lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/i18n_service.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLang;
  final String deviceId;
  const SettingsScreen({super.key, required this.currentLang, required this.deviceId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? pairingStatus;

  Future<void> handlePairing(String code, String myDeviceId) async {
    final pairingRef = FirebaseFirestore.instance.collection('pairings').doc(code);
    final doc = await pairingRef.get();

    if (!doc.exists) {
      // 👤 Premier appareil
      await pairingRef.set({'deviceA': myDeviceId});
      pairingStatus = "🕐 En attente d’un autre appareil...";
      print("🔗 Code créé : $code (deviceA)");

      await FirebaseFirestore.instance
          .collection('devices')
          .doc(myDeviceId)
          .update({'pairingCode': code});

    } else {
      final data = doc.data();

      if (data?['deviceA'] == myDeviceId || data?['deviceB'] == myDeviceId) {
        // 🔁 Cet appareil est déjà appairé
        pairingStatus = "🔁 Déjà appairé.";
        print("⚠️ Déjà appairé ou même appareil.");

      } else if (data?['deviceB'] == null) {
        // 👥 Deuxième appareil
        await pairingRef.update({'deviceB': myDeviceId});
        pairingStatus = "✅ Appairage terminé !";
        print("🔗 Appairé avec deviceA : ${data?['deviceA']}");

        await FirebaseFirestore.instance
            .collection('devices')
            .doc(myDeviceId)
            .update({'pairingCode': code});

      } else {
        // ❌ Code déjà utilisé par deux autres
        pairingStatus = "❌ Code déjà utilisé par 2 appareils.";
        print("⚠️ Code déjà complet.");
        return;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.white),
            SizedBox(width: 8),
            Text("Réglages"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🔗 Appairage", style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 200,
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    hintText: 'Entrer un code à 4 chiffres',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final code = _codeController.text;
                if (code.length == 4) {
                  handlePairing(code, widget.deviceId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ Code invalide (4 chiffres)")),
                  );
                }
              },
              child: const Text("Appairer"),
            ),
            const SizedBox(height: 20),
            if (pairingStatus != null)
              Text(
                pairingStatus!,
                style: const TextStyle(color: Colors.amber),
              ),
          ],
        ),
      ),
    );
  }
}