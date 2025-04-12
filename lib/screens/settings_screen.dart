// 📄 lib/screens/settings_screen.dart

import 'dart:async';
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
  final TextEditingController _nameController = TextEditingController();
  String? pairingStatus;
  StreamSubscription<DocumentSnapshot>? _pairingListener;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final doc = await FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).get();
    final name = doc.data()?['displayName'];
    if (name != null) {
      _nameController.text = name;
    }
  }

  Future<void> handlePairing(String code, String myDeviceId) async {
    final pairingRef = FirebaseFirestore.instance.collection('pairings').doc(code);
    final doc = await pairingRef.get();

    if (!doc.exists) {
      await pairingRef.set({'deviceA': myDeviceId});
      pairingStatus = "🕐 En attente d’un autre appareil...";
      _listenForPairingCompletion(pairingRef, myDeviceId);
      print("🔗 Code créé : $code (deviceA)");
    } else {
      final data = doc.data();
      if (data != null && data['deviceA'] != myDeviceId && data['deviceB'] == null) {
        await pairingRef.update({'deviceB': myDeviceId});
        pairingStatus = "✅ Appairage terminé !";
        print("🔗 Appairé avec deviceA : ${data['deviceA']}");
      } else if (data?['deviceA'] == myDeviceId || data?['deviceB'] == myDeviceId) {
        pairingStatus = "🔁 Déjà appairé.";
        print("⚠️ Déjà appairé ou même appareil.");
      } else {
        pairingStatus = "❌ Code déjà utilisé par 2 appareils.";
        print("⚠️ Code déjà complet.");
      }
    }

    await FirebaseFirestore.instance
        .collection('devices')
        .doc(myDeviceId)
        .update({'pairingCode': code});

    print("✅ Code $code enregistré dans le profil device $myDeviceId");

    setState(() {});
  }

  void _listenForPairingCompletion(DocumentReference pairingRef, String myDeviceId) {
    _pairingListener?.cancel();
    _pairingListener = pairingRef.snapshots().listen((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['deviceB'] != null) {
        pairingStatus = "✅ Appairage terminé !";
        print("📡 Mise à jour détectée : deviceB ajouté !");
        setState(() {});
        _pairingListener?.cancel();
      }
    });
  }

  Future<void> _saveDisplayName() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .update({'displayName': name});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Nom enregistré")),
      );
    }
  }

  @override
  void dispose() {
    _pairingListener?.cancel();
    super.dispose();
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
            const Text("👤 Nom affiché dans les messages", style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Ex : Bini',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveDisplayName,
              child: const Text("Enregistrer le nom"),
            ),
            const SizedBox(height: 40),

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
