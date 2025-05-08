// 📄 lib/screens/home_selector.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/love_screen.dart';
import '../screens/login_screen.dart';
import '../services/device_service.dart';
import '../services/firestore_service.dart';

class HomeSelector extends StatefulWidget {
  final String deviceLang;
  const HomeSelector({super.key, required this.deviceLang});

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

    if (user != null) {
      deviceId = await getDeviceId();
      final isReceiver = true;
      await registerDevice(deviceId, isReceiver);
      setState(() {
        _isConnected = true;
        _checkingAuth = false;
      });
    } else {
      deviceId = await getDeviceId(); // ✅ ajouté ici aussi pour non connecté
      setState(() {
        _isConnected = false;
        _checkingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    return _isConnected
        ? LoveScreen(
            deviceId: deviceId,
            isReceiver: true,
            deviceLang: widget.deviceLang,
          )
        : LoginScreen(
            deviceLang: widget.deviceLang,
            deviceId: deviceId,
          );
  }
}
