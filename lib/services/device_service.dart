// lib/services/device_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ajouté le 08/04/2025 pour la partie bidirectionnelle
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('deviceId');

  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await prefs.setString('deviceId', deviceId);
    print('🆕 Nouveau deviceId généré : $deviceId');
  } else {
    print('📲 DeviceId existant : $deviceId');
  }

  return deviceId;
}