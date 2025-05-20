// 📄 lib/screens/home_selector.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/love_screen.dart';
import '../screens/login_screen.dart';
import '../services/device_service.dart';
import '../services/firestore_service.dart';
import '../utils/debug_log.dart';

class HomeSelector extends StatefulWidget {
  final String deviceLang;

  const HomeSelector({
    super.key,
    required this.deviceLang,
  });

  @override
  State<HomeSelector> createState() => _HomeSelectorState();
}

class _HomeSelectorState extends State<HomeSelector> {
  bool _checkingAuth = true;
  bool _isConnected = false;
  late String deviceId;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final user = FirebaseAuth.instance.currentUser;

    deviceId = await getDeviceId();

    if (user != null) {
      const isReceiver = true;
      await registerDevice(deviceId, isReceiver);
      debugLog("🔐 Utilisateur connecté : ${user.email}");
      setState(() {
        _isConnected = true;
        _checkingAuth = false;
      });
    } else {
      debugLog("👤 Aucun utilisateur connecté.");
      setState(() {
        _isConnected = false;
        _checkingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _checkingAuth
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            )
          : _isConnected
              ? LoveScreen(
                  deviceId: deviceId,
                  isReceiver: true,
                  deviceLang: widget.deviceLang,
                )
              : LoginScreen(
                  deviceLang: widget.deviceLang,
                  deviceId: deviceId,
                ),
    );
  }
}
