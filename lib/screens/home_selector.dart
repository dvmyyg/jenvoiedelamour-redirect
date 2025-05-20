// 📄 lib/screens/home_selector.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'love_screen.dart';

class HomeSelector extends StatelessWidget {
  final String deviceId;
  final String deviceLang;

  const HomeSelector({
    super.key,
    required this.deviceId,
    required this.deviceLang,
  });

  Future<bool> _isReceiver() async {
    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .get();
    return doc.data()?['isReceiver'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isReceiver(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.pink),
            ),
          );
        }

        return LoveScreen(
          deviceId: deviceId,
          deviceLang: deviceLang,
          isReceiver: snapshot.data!,
        );
      },
    );
  }
}
