//  lib/screens/home_selector.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/debug_log.dart';
import 'love_screen.dart';

class HomeSelector extends StatelessWidget {
  final String deviceId;
  final String deviceLang;

  const HomeSelector({
    super.key,
    required this.deviceId,
    required this.deviceLang,
  });

  // 🔄 Corrigé le 23/05/2025 — récupère aussi displayName
  Future<Map<String, dynamic>> _loadIsReceiverAndName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('devices')
          .doc(deviceId)
          .get();

      final data = doc.data() ?? {};
      final isReceiver = data['isReceiver'] == true;
      final displayName = data['displayName'] ?? '';

      debugLog("🏠 HomeSelector : isReceiver=$isReceiver, name=$displayName");
      return {
        'isReceiver': isReceiver,
        'displayName': displayName,
      };
    } catch (e) {
      debugLog("❌ Erreur chargement HomeSelector : $e", level: 'ERROR');
      return {
        'isReceiver': false,
        'displayName': '',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadIsReceiverAndName(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.pink),
            ),
          );
        }

        final isReceiver = snapshot.data?['isReceiver'] == true;
        final displayName = snapshot.data?['displayName'] ?? '';

        return LoveScreen(
          deviceId: deviceId,
          deviceLang: deviceLang,
          isReceiver: isReceiver,
          displayName: displayName,
        );
      },
    );
  }
}
