// -------------------------------------------------------------
// 📄 FICHIER : lib/navigation/notification_router.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Centralise la navigation suite à un clic sur une notification FCM.
// ✅ Analyse les données du message FCM (relation, senderId, etc.).
// ✅ Redirige vers l'écran approprié via navigatorKey.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - Création initiale du routeur de notifications pour centraliser la logique post-clic. - 2025/06/10 16h30
// -------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:jelamvp01/main.dart';
import 'package:jelamvp01/screens/love_screen.dart';

class NotificationRouter {
  static void routeFromNotification(Map<String, dynamic> data) {
    final relation = data['relation'];
    final recipientId = data['senderId'];

    // Redirection selon le type de relation
    switch (relation) {
      case 'relation_partner':
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => LoveScreen(recipientId: recipientId),
        ));
        break;

    // 🔜 Autres relations possibles à ajouter ici (relation_ami, relation_famille, etc.)

      default:
      // 🛑 Cas non géré — pas de redirection
        debugPrint("🔕 Notification ignorée : relation non reconnue ($relation)");
        break;
    }
  }
}

// 📄 FIN de lib/navigation/notification_router.dart
