// -------------------------------------------------------------
// 📄 FICHIER : lib/utils/service_locator.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Configure le conteneur d'injection de dépendances (get_it).
// ✅ Enregistre les instances singleton des services (AuthService, FirestoreService, FcmService).
// ✅ RecipientService est temporairement non enregistré car son constructeur nécessite un UID utilisateur.
// ✅ Enregistre les instances singleton de ressources globales (GlobalKey<NavigatorState>, FlutterLocalNotificationsPlugin).
// ✅ Permet d'accéder aux services et ressources via getIt<T>().
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V002 - Commenté l'enregistrement de RecipientService pour corriger l'erreur de type, car son constructeur attend une String (UID utilisateur) et non FirestoreService. - 2025/06/12 15h30
// V001 - Création du fichier et configuration initiale de get_it avec enregistrement des services et ressources existants. - 2025/06/12 HHhMM (Date/heure initiale)
// -------------------------------------------------------------

import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart'; // Pour GlobalKey
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Pour FlutterLocalNotificationsPlugin

// Importe tes services
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/fcm_service.dart';
import '../services/recipient_service.dart'; // L'import reste nécessaire pour les types
// import '../services/message_service.dart'; // Ne pas enregistrer, car il est instancié par conversation

// ⭐️ Obtient l'instance globale de GetIt
final getIt = GetIt.instance;

// ⭐️ Fonction de configuration du locator
void setupLocator() {
  // Enregistre les services comme Lazy Singletons (créés seulement à la première demande)
  // Ils n'ont pas encore de dépendances injectées, on le fera plus tard (Étape 5)
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  // FirestoreService doit être enregistré pour être injecté dans d'autres services métier (Étape 5)
  getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());
  // RecipientService dépendra de FirestoreService, on injecte déjà ici
  // ⛔️ À supprimer/revoir (Étape 5) : RecipientService nécessite un UID utilisateur (String) dans son constructeur, ce qui est incompatible avec un enregistrement LazySingleton standard où l'UID n'est pas encore connu.
  // getIt.registerLazySingleton<RecipientService>(() => RecipientService(getIt<FirestoreService>()));
  // FcmService a des dépendances (notifs locales, nav key), on les injectera bientôt (Étape 6)
  getIt.registerLazySingleton<FcmService>(() => FcmService());

  // MessageService n'est PAS enregistré ici car il est instancié par conversation avec des paramètres spécifiques.
  // Il devra simplement recevoir ses dépendances (comme FirestoreService) au moment de sa création si nécessaire.

  // Enregistre les ressources globales comme Singletons (créées tout de suite)
  // Elles sont nécessaires tôt dans le cycle de vie de l'app (Étape 1.3).
  getIt.registerSingleton<GlobalKey<NavigatorState>>(GlobalKey<NavigatorState>());
  getIt.registerSingleton<FlutterLocalNotificationsPlugin>(FlutterLocalNotificationsPlugin());


  // TODO: Enregistrer d'autres services ou ressources si nécessaire par la suite.
  // Ex: DeepLinkService, NotificationRouter (Étape 6)
}

// 📄 FIN de lib/utils/service_locator.dart
