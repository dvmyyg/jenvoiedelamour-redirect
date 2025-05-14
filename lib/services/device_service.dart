// 📄 lib/services/device_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/debug_log.dart'; // Utilise la fonction unique de debug_log.dart

// ajouté le 08/04/2025 pour la partie bidirectionnelle
Future<String> getDeviceId() async { // <-- Promet de retourner un String (non-nullable)
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('deviceId');

  if (deviceId == null) {
    // Si l'ID n'existe pas, génère-en un nouveau
    deviceId = const Uuid().v4();
    // Sauvegarde le nouvel ID pour les prochains lancements
    await prefs.setString('deviceId', deviceId);
    debugLog(
      '🆕 [getDeviceId] Nouveau deviceId généré et enregistré : $deviceId',
      level: 'INFO',
    );
  } else {
    // Si l'ID existe, loggue qu'il a été récupéré
    debugLog(
      '📲 [getDeviceId] deviceId récupéré depuis SharedPreferences : $deviceId',
      level: 'INFO',
    );
  }

  return deviceId; // <-- Retourne un String non-nullable (car on l'a généré s'il était null)
}
