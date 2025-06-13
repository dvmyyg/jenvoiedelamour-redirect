// -------------------------------------------------------------
// 📄 FICHIER : lib/services/current_user_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Service Singleton pour stocker les données de l'utilisateur actuellement connecté.
// ✅ Permet d'accéder au rôle isReceiver, nom d'affichage et langue de l'appareil de l'utilisateur actuel depuis n'importe où.
// ✅ Doit être initialisé une fois après le chargement des données utilisateur (ex: dans HomeSelector).
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - Création initiale du service Singleton pour l'utilisateur actuel. - 2025/06/03
// -------------------------------------------------------------

// GEM - Code créé par Gémini le 2025/06/03 // Mise à jour le 03/06

class CurrentUserService {
  // ⭐️ Étape 1 : Créer l'instance statique et le factory constructor
  // La seule instance de ce service.
  static final CurrentUserService _instance = CurrentUserService._internal();

  // Factory constructor pour retourner l'instance unique.
  factory CurrentUserService() {
    return _instance;
  }

  // Constructeur privé pour empêcher l'instanciation directe.
  CurrentUserService._internal();


  // ⭐️ Étape 2 : Déclarer les champs pour stocker les données utilisateur
  // Utilise 'late' car ces champs seront initialisés plus tard par setUserData.
  // Utilise nullable String pour displayName car il peut être absent.
  late bool _isReceiver;
  late String _deviceLang;
  String? _displayName; // displayName peut être nullable

  // ⭐️ Étape 3 : Définir une méthode pour initialiser/mettre à jour les données
  void setUserData({
    required bool isReceiver,
    required String deviceLang,
    String? displayName, // Accepte un displayName nullable
  }) {
    _isReceiver = isReceiver;
    _deviceLang = deviceLang;
    _displayName = displayName;
    // Optionnel: ajouter un log pour confirmer que les données sont définies
    // print('✅ CurrentUserService initialisé/mis à jour : isReceiver=$_isReceiver, deviceLang=$_deviceLang, displayName=$_displayName');
  }

  // ⭐️ Étape 4 : Définir les getters publics pour accéder aux données
  // Utilise 'instance' pour accéder aux getters : CurrentUserService.instance.isReceiver
  bool get isReceiver => _isReceiver;
  String get deviceLang => _deviceLang;
  String? get displayName => _displayName;

// Optionnel: Ajouter une méthode pour vérifier si les données sont initialisées (si nécessaire pour la robustesse)
// bool get isInitialized => ::_isReceiver != null && _deviceLang != null;
// Note: Avec 'late', l'accès avant initialisation lèvera une LateInitializationError.
// Si tu veux éviter ça, utilise des champs nullable (bool?, String?) et gère les nulls dans les getters ou à l'appel.
// Pour une approche lean post-auth flow, 'late' est acceptable si HomeSelector garantit l'appel à setUserData.

}

// 📄 FIN de lib/services/current_user_service.dart
