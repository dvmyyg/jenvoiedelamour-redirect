// -------------------------------------------------------------
// 📄 FICHIER : lib/services/notification_config.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Centralise les définitions des détails de notification spécifiques à chaque plateforme (pour flutter_local_notifications).
// ✅ Fournit une source unique de vérité pour la configuration visuelle et comportementale des notifications locales.
// ✅ Utilisé par les services ou handlers responsables de l'affichage des notifications (ex: FcmService, background handler).
// ✅ Inclut une structure multi-plateforme (Android, iOS/macOS) pour les détails de notification.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V002 - Renommage des constantes pour plus de clarté (MessageChannel, MessageNotificationDetails). Ajout de la structure DarwinNotificationDetails pour iOS/macOS. - 2025/06/13 20h49
// V001 - Création initiale pour centraliser la configuration des notifications. - 2025/06/13 20h45
// -------------------------------------------------------------

import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import nécessaire pour les types

// =============================================================
// 📲 NOTIFICATIONS LOCALES — Détails de configuration
// =============================================================

// Détails spécifiques au canal de messagerie sur Android.
const AndroidNotificationDetails androidMessageChannel =
AndroidNotificationDetails(
  'messages_channel', // ID du canal (doit être unique pour ton app)
  'Notifications de Messages', // Nom du canal visible par l'utilisateur dans les paramètres Android
  channelDescription: 'Notifications pour les nouveaux messages reçus', // Description du canal
  importance: Importance.high, // Importance élevée pour qu'elle soit visible
  priority: Priority.high,
  // Son personnalisé ? Il faut l'ajouter aux ressources Android et le référencer ici.
  // sound: RawResourceAndroidNotificationSound('notification_sound'), // Exemple: 'notification_sound.wav' dans res/raw
  // Icônes personnalisées ?
  // largeIcon: FilePathAndroidBitmap('chemin/vers/grande_icone.png'), // Chemin vers une image dans les assets/res
  // smallIcon: '@mipmap/ic_launcher', // Doit être une ressource Android (xml vector ou png) dans mipmap/drawable
  // L'icône par défaut de l'app (@mipmap/ic_launcher) est souvent utilisée si smallIcon n'est pas spécifié.
);

// Détails spécifiques aux notifications de messagerie sur iOS et macOS.
const DarwinNotificationDetails darwinMessageDetails =
DarwinNotificationDetails(
  // TODO: Configurer les options spécifiques à iOS/macOS si nécessaire (son, badge, etc.)
  // sound: 'notification_sound.caf', // Exemple
  // presentAlert: true,
  // presentBadge: true,
  // presentSound: true,
);


// Détails de la notification de messagerie pour toutes les plateformes supportées (Android, iOS/macOS)
// C'est l'objet NotificationDetails complet qui est passé à la méthode show() du plugin.
const NotificationDetails messageNotificationDetails =
NotificationDetails(
  android: androidMessageChannel, // Utilise les détails Android spécifiques
  iOS: darwinMessageDetails,    // Utilise les détails iOS/macOS spécifiques
  macOS: darwinMessageDetails,  // Utilise les mêmes détails Darwin pour macOS (par défaut souvent suffisant)
  // TODO: Ajouter les configurations pour d'autres plateformes si nécessaire (Linux, Windows)
);


// 📄 FIN de lib/services/notification_config.dart
