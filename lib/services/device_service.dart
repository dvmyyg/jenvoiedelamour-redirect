// 📄 lib/services/device_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/debug_log.dart'; // Utilise la fonction unique de debug_log.dart

// ajouté le 08/04/2025 pour la partie bidirectionnelle
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('deviceId');

  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await prefs.setString('deviceId', deviceId);
    debugLog(
      '🆕 [getDeviceId] Nouveau deviceId généré et enregistré : $deviceId',
      level: 'INFO',
    );
  } else {
    debugLog(
      '📲 [getDeviceId] deviceId récupéré depuis SharedPreferences : $deviceId',
      level: 'INFO',
    );
  }

  return deviceId;
}
