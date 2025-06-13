// -------------------------------------------------------------
// 📄 FICHIER : lib/utils/service_locator.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Configure le conteneur d'injection de dépendances (get_it).
// ✅ Enregistre les instances singleton des services (AuthService, FirestoreService, FcmService, PairingService, CurrentUserService). // Mis à jour
// ✅ RecipientService est temporairement non enregistré car son constructeur nécessite un UID utilisateur.
// ✅ Enregistre les instances singleton de ressources globales (GlobalKey<NavigatorState>, FlutterLocalNotificationsPlugin).
// ✅ Permet d'accéder aux services et ressources via getIt<T>().
// ✅ Enregistre l'instance singleton de PairingService.
// ✅ Initialise CurrentUserService avec sa dépendance (FirestoreService).
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V004 - Modification de l'enregistrement de CurrentUserService pour utiliser la méthode init() et injecter FirestoreService. Mise à jour de la description. - 2025/06/13 23h45
// V003 - Enregistrement de PairingService dans le conteneur d'injection de dépendances. Mise à jour de la description des fonctionnalités. - 2025/06/13 15h25
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
import '../services/pairing_service.dart'; // Import de PairingService
import '../services/current_user_service.dart'; // ✅ AJOUT : Import de CurrentUserService

// import '../services/message_service.dart'; // Ne pas enregistrer

// ⭐️ Obtient l'instance globale de GetIt (inchangé)
final getIt = GetIt.instance;

// ⭐️ Fonction de configuration du locator
void setupLocator() {
  // Enregistre les services comme Lazy Singletons (créés seulement à la première demande)
  // Ils n'ont pas encore de dépendances injectées, on le fera plus tard (Étape 5)
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // FirestoreService doit être enregistré avant CurrentUserService car CurrentUserService en dépend.
  getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());

  // ⭐️ Service : CurrentUserService
  // ✅ MODIF : Enregistrement de CurrentUserService. Notez l'appel à init() après la création.
  getIt.registerLazySingleton<CurrentUserService>(() {
    final service = CurrentUserService(); // Crée l'instance
    service.init(firestoreService: getIt<FirestoreService>()); // Appelle init() pour lui passer sa dépendance
    return service;
  });

  // ⭐️ Service : PairingService (inchangé)
  getIt.registerLazySingleton<PairingService>(() => PairingService());

  // RecipientService dépendra de FirestoreService, on injecte déjà ici
  // ⛔️ À supprimer/revoir (Étape 5) : RecipientService nécessite un UID utilisateur (String) dans son constructeur, ce qui est incompatible avec un enregistrement LazySingleton standard où l'UID n'est pas encore connu. (inchangé)
  // getIt.registerLazySingleton<RecipientService>(() => RecipientService(getIt<FirestoreService>()));

  // FcmService a des dépendances (notifs locales, nav key), on les injectera bientôt (Étape 6)
  // ✅ MODIF : Enregistrement de FcmService pour lui passer le plugin de notifications.
  getIt.registerLazySingleton<FcmService>(() => FcmService(getIt<FlutterLocalNotificationsPlugin>()));

  // MessageService n'est PAS enregistré ici car il est instancié par conversation avec des paramètres spécifiques. (inchangé)
  // Il devra simplement recevoir ses dépendances (comme FirestoreService) au moment de sa création si nécessaire.

  // Enregistre les ressources globales comme Singletons (créées tout de suite) (inchangé)
  // Elles sont nécessaires tôt dans le cycle de vie de l'app (Étape 1.3).
  getIt.registerSingleton<GlobalKey<NavigatorState>>(GlobalKey<NavigatorState>());
  getIt.registerSingleton<FlutterLocalNotificationsPlugin>(FlutterLocalNotificationsPlugin());

  // TODO: Enregistrer d'autres services ou ressources si nécessaire par la suite. (inchangé)
  // Ex: DeepLinkService, NotificationRouter (Étape 6)
}

// 📄 FIN de lib/utils/service_locator.dart
