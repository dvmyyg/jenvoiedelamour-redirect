// -------------------------------------------------------------
// 📄 FICHIER : lib/services/current_user_service.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Service Singleton pour gérer le profil de l'utilisateur actuellement connecté.
// ✅ Stocke et expose les données du profil utilisateur (UserProfile) via un ValueNotifier.
// ✅ Permet d'accéder aux données du profil (prénom, rôle, langue) et à l'UID de l'utilisateur courant.
// ✅ Servira de source de vérité pour les informations du profil utilisateur partout dans l'application.
// ✅ La logique de chargement initial des données depuis Firestore est implémentée (Étape 2.3).
// ✅ La logique de synchronisation des données via un listener Firestore est ajoutée (Étape 2.4).
// ✅ La gestion du cycle de vie (en fonction de l'état d'authentification) est ajoutée (Étape 2.5).
// ✅ Reçoit l'instance de FirestoreService via injection de dépendances.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V006 - Implémentation logique gestion cycle de vie (écoute authStateChanges, méthodes _startAuthListener, _cancelAuthListener, _authStateSubscription). Appel de loadUserProfile, _startProfileSubscription, clearUserProfile et _cancelProfileSubscription selon l'état d'authentification. Appel _startAuthListener dans init(). - 2025/06/14 00h15 (Heure à remplir)
// V005 - Ajout logique gestion cycle de vie (écoute authStateChanges, méthodes _startAuthListener, _cancelAuthListener, _authStateSubscription). Appel de loadUserProfile, _startProfileSubscription, clearUserProfile et _cancelProfileSubscription selon l'état d'authentification. - 2025/06/13 23h51
// V004 - Ajout logique synchronisation profil (listener Firestore, méthodes _startProfileSubscription, _cancelProfileSubscription, _profileSubscription). - 2025/06/13 23h50
// V003 - Ajout de la dépendance à FirestoreService via constructeur. Mise à jour de la description des fonctionnalités. - 2025/06/13 23h25
// V002 - Refactorisation pour gérer et exposer un objet UserProfile via ValueNotifier. Remplacement des champs individuels (_isReceiver, etc.) par _userProfileNotifier. Ajout getters pour userProfile et uid. La logique de chargement/synchronisation sera ajoutée ultérieurement. - 2025/06/13 23h17
// V001 - Création initiale du service Singleton pour l'utilisateur actuel. - 2025/06/03
// -------------------------------------------------------------

import 'package:flutter/foundation.dart'; // For ValueNotifier
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user UID and listen to authStateChanges
import 'package:jelamvp01/models/user_profile.dart'; // Import du nouveau modèle UserProfile
import 'firestore_service.dart'; // Import de FirestoreService
import '../utils/debug_log.dart'; // Import the logger
import 'dart:async'; // Import pour StreamSubscription et Timestamp (potentiel)
import 'package:cloud_firestore/cloud_firestore.dart'; // Import pour DocumentSnapshot

class CurrentUserService {
  // ⭐️ Étape 1 : Créer l'instance statique et le factory constructor (inchangé)
  // La seule instance de ce service.
  static final CurrentUserService _instance = CurrentUserService._internal();

  // Factory constructor pour retourner l'instance unique.
  factory CurrentUserService() {
    return _instance;
  }

  // Constructeur privé pour empêcher l'instanciation directe.
  CurrentUserService._internal();

  // Champ pour l'instance injectée de FirestoreService (inchangé)
  late final FirestoreService _firestoreService;

  // ✅ Étape 2.5 : Ajouter le champ pour la souscription au listener d'état d'authentification
  StreamSubscription<User?>? _authStateSubscription;

  // Méthode d'initialisation pour injecter les dépendances (appelée par service_locator)
  // Nous utilisons une méthode init() au lieu du constructeur pour les Singletons
  // enregistrés comme LazySingleton dans GetIt qui ont des dépendances cycliques
  // ou des dépendances non disponibles au moment de la création du Singleton.
  // Initialize le service avec ses dépendances.
  void init({required FirestoreService firestoreService}) {
    _firestoreService = firestoreService;
    debugLog('👤 [CurrentUserService] Initialized with FirestoreService.', level: 'INFO');
    // ✅ MODIF (Étape 2.5) : Démarrer l'écoute des changements d'état d'authentification ici
    _startAuthListener();
  }

  // ⭐️ Étape 2 : Déclarer le ValueNotifier pour stocker et exposer le profil (inchangé)
  // Remplace les champs individuels (_isReceiver, _deviceLang, _displayName).
  // Initialisé à null, car l'utilisateur n'est pas forcément connecté ou le profil chargé au démarrage.
  final ValueNotifier<UserProfile?> _userProfileNotifier = ValueNotifier<UserProfile?>(null);

  // Champ pour la souscription au listener Firestore (inchangé)
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSubscription;

  // ⭐️ Étape 3 : Définir les getters publics (inchangé)
  // Expose le ValueNotifier pour permettre à l'UI de l'écouter (ex: via ValueListenableBuilder).
  ValueListenable<UserProfile?> get userProfileListenable => _userProfileNotifier;

  // Expose l'objet UserProfile actuel (sera null si non chargé)
  UserProfile? get userProfile => _userProfileNotifier.value;

  // Fournit l'UID de l'utilisateur actuellement connecté (directement depuis FirebaseAuth pour l'instant)
  // Idéalement, cela pourrait être géré en interne en écoutant authStateChanges pour être réactif,
  // mais pour un accès synchrone à l'état actuel connu, c'sont accessibles via Firebase Auth
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  // ⭐️ Étape 4 : Méthode interne pour mettre à jour le profil (sera appelée par la logique de chargement/synchro) (inchangé)
  // Cette méthode est privée car la logique de chargement doit être gérée par le service lui-même.
  void _setUserProfile(UserProfile? profile) {
    debugLog('👤 [CurrentUserService] Profil mis à jour: ${profile != null ? profile.uid : 'null'}', level: 'DEBUG');
    _userProfileNotifier.value = profile;
  }

  // ⭐️ Étape 5 : Méthode pour nettoyer le profil lors de la déconnexion (sera appelée par la logique du cycle de vie) (inchangé)
  void clearUserProfile() {
    debugLog('👤 [CurrentUserService] Nettoyage du profil utilisateur.', level: 'INFO');
    _cancelProfileSubscription(); // Annule le listener Firestore du profil
    _setUserProfile(null); // Met le profil à null
  }

  // ✅ Étape 2.3 : Logique de chargement initial du profil depuis Firestore (inchangé)
  // Cette méthode est responsable de lire le document '/users/{uid}' pour l'utilisateur courant
  // et de mettre à jour le _userProfileNotifier.
  // Elle sera appelée lors des changements d'état d'authentification (Étape 2.5).
  Future<void> loadUserProfile() async {
    final uid = currentUid; // Récupère l'UID de l'utilisateur courant
    if (uid == null) {
      debugLog('👤 [CurrentUserService - loadUserProfile] Aucun utilisateur connecté. Nettoyage du profil.', level: 'WARNING');
      _setUserProfile(null); // Assure que le profil est null si pas d'utilisateur
      return;
    }

    debugLog('🔄 [CurrentUserService - loadUserProfile] Tentative de chargement initial du profil pour UID: $uid', level: 'INFO');
    // On utilise get() pour le chargement initial. La synchronisation se fera via le listener.
    try {
      // Utilise le FirestoreService injecté pour obtenir les données brutes du profil
      final userData = await _firestoreService.getUserProfile(uid); // FirestoreService.getUserProfile retourne Map<String, dynamic>?

      if (userData != null) {
        final userProfile = UserProfile.fromFirestore(uid, userData);
        _setUserProfile(userProfile);
        debugLog('✅ [CurrentUserService - loadUserProfile] Profil chargé et mis à jour via get() pour UID: $uid', level: 'INFO');
        // ✅ MODIF (Étape 2.5) : Démarrer l'écoute des mises à jour après le chargement initial réussi
        _startProfileSubscription(); // Démarrer le listener maintenant
      } else {
        debugLog('⚠️ [CurrentUserService - loadUserProfile] Document profil non trouvé pour UID: $uid. Création d\'un profil par défaut.', level: 'WARNING');
        // Le document utilisateur n'existe pas encore. Créer un profil de base et le sauvegarder.
        UserProfile defaultProfile = UserProfile(
          uid: uid,
          firstName: 'Nouveau', // Nom par défaut
          isReceiver: false,    // Rôle par défaut
          // TODO: Récupérer la langue du système ou une langue par défaut plus intelligente (Étape 2.3.1)
          deviceLang: 'en', // Langue par défaut
        );
        _setUserProfile(defaultProfile);
        debugLog('✅ [CurrentUserService - loadUserProfile] Profil par défaut créé pour UID: $uid', level: 'INFO');
        // TODO: Ajouter une logique pour sauvegarder ce profil par défaut si créé ici (Étape 2.3.2)
        // await _firestoreService.saveUserProfile(uid: uid, email: FirebaseAuth.instance.currentUser!.email!, firstName: defaultProfile.firstName, isReceiver: defaultProfile.isReceiver);
        // Démarrer le listener même si on vient de créer le document.
        _startProfileSubscription(); // Démarrer le listener maintenant
      }
    } catch (e) {
      debugLog('❌ [CurrentUserService - loadUserProfile] Erreur lors du chargement initial du profil pour UID $uid: $e', level: 'ERROR');
      _setUserProfile(null); // Assure que le profil est null en cas d'erreur
      // TODO: Gérer l'erreur (ex: afficher un message à l'utilisateur ?) (Étape 2.3.3)
    }
  }

  // ✅ Étape 2.4 : Logique de synchronisation du profil (listener Firestore) (inchangé)
  // Démarre l'écoute en temps réel des changements sur le document /users/{uid}.
  void _startProfileSubscription() {
    final uid = currentUid;
    if (uid == null) {
      debugLog('👤 [CurrentUserService - _startProfileSubscription] Aucun utilisateur connecté. Annulation.', level: 'WARNING');
      _cancelProfileSubscription(); // Assure qu'aucune souscription n'est active
      _setUserProfile(null);
      return;
    }

    // Annule toute souscription existante avant d'en démarrer une nouvelle
    _cancelProfileSubscription();

    debugLog('🔄 [CurrentUserService - _startProfileSubscription] Démarrage du listener Firestore pour profil UID: $uid', level: 'INFO');

    // Utilise le FirestoreService pour obtenir une référence au document utilisateur
    // et écoute les snapshots en temps réel.
    // TODO: Implémenter getUserProfileStream dans FirestoreService (Étape 5)
    _profileSubscription = _firestoreService
        .getUserProfileStream(uid) // Supposons que FirestoreService a une méthode pour obtenir un stream de document
        .listen(
          (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        debugLog('📩 [CurrentUserService - _startProfileSubscription] Snapshot reçu pour profil UID: ${snapshot.id}', level: 'DEBUG');
        if (snapshot.exists && snapshot.data() != null) {
          // Crée/met à jour le UserProfile à partir des données du snapshot
          final userProfile = UserProfile.fromFirestore(snapshot.id, snapshot.data());
          _setUserProfile(userProfile); // Met à jour le ValueNotifier
          debugLog('✅ [CurrentUserService - _startProfileSubscription] Profil mis à jour depuis snapshot pour UID: ${snapshot.id}', level: 'INFO');
        } else {
          // Document supprimé ou vide. Traiter cela
          debugLog('⚠️ [CurrentUserService - _startProfileSubscription] Document profil UID ${snapshot.id} non trouvé ou vide dans le snapshot. Nettoyage du profil.', level: 'WARNING');
          _setUserProfile(null); // Met le profil à null si le document disparaît
          // TODO: Annuler la souscription ici si le document disparaît est le signal de déconnexion du profil (Étape 2.5)
          // _cancelProfileSubscription();
        }
      }, // <-- Fin du callback du listen
      onError: (error) {
        debugLog('❌ [CurrentUserService - _startProfileSubscription] Erreur lors de l\'écoute du profil UID $uid: $error', level: 'ERROR');
        _setUserProfile(null); // Met le profil à null en cas d'erreur du listener
        // TODO: Gérer l'erreur du listener (ex: réessayer, afficher un message) (Étape 2.4.1)
      },
      // L'événement 'onDone' n'est généralement pas émis pour les listeners Firestore en temps réel
      // car le stream est conçu pour être permanent tant que la connexion est active.
      // On peut l'ignorer ou le logguer si nécessaire.
      // onDone: () {
      //   debugLog('ℹ️ [CurrentUserService - _startProfileSubscription] Listener de profil Firestore terminé.', level: 'INFO');
      //   _setUserProfile(null); // Assure le nettoyage si le stream se termine inopinément
      // },
    ); // <-- Fin de l'appel .listen()
  }

  // ✅ Étape 2.4 : Ajouter la logique d'annulation du listener Firestore
  // Annule la souscription active au listener Firestore pour éviter les fuites de mémoire.
  // Appelée lors de la déconnexion de l'utilisateur (Étape 2.5) ou avant de redémarrer un listener.
  void _cancelProfileSubscription() {
    if (_profileSubscription != null) {
      debugLog('🧹 [CurrentUserService - _cancelProfileSubscription] Annulation de la souscription Firestore pour le profil.', level: 'INFO');
      _profileSubscription?.cancel(); // Annule la souscription
      _profileSubscription = null; // Remet la référence à null
    }
  }

  // ✅ Étape 2.5 : Ajouter la logique du cycle de vie (écouter FirebaseAuth.instance.authStateChanges)
  // Cette méthode écoute les changements d'état d'authentification (connexion/déconnexion)
  // et déclenche le chargement/synchronisation ou le nettoyage du profil.
  void _startAuthListener() {
    debugLog('🔄 [CurrentUserService - _startAuthListener] Démarrage de l\'écoute des changements d\'état d\'authentification.', level: 'INFO');
    // Annule toute souscription existante avant d'en démarrer une nouvelle
    _cancelAuthListener(); // Assure qu'un seul listener d'auth est actif

    // TODO: Annuler le listener de profil aussi en cas de redémarrage du listener d'auth ? _cancelProfileSubscription();
    // Si le listener d'auth est relancé, on veut s'assurer que l'ancien listener de profil est bien arrêté.
    // _cancelProfileSubscription(); // <- À appeler ici ? Ou seulement dans clearUserProfile ?
    // La logique est : si l'état change (ex: déconnexion), clearUserProfile est appelé qui annule le listener profil.
    // Si on redémarre le listener d'auth (ce qui ne devrait arriver qu'à l'initialisation du service),
    // on veut aussi s'assurer que le listener profil est arrêté. L'appel dans clearUserProfile est la bonne place
    // pour la déconnexion. Appeler ici pourrait être redondant ou incorrect si on relance le listener d'auth
    // sans changer d'état. Laissons l'appel dans clearUserProfile pour l'instant.


    // Écoute le stream des changements d'état d'authentification
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Utilisateur connecté. Charger/Synchroniser son profil.
        debugLog('👤 [CurrentUserService - _startAuthListener] Changement d\'état: Utilisateur connecté (UID: ${user.uid}).', level: 'INFO');
        // TODO: Gérer le cas où l'utilisateur est déjà connecté au démarrage (getInitialUser() ou équivalent) (Étape 2.5.1)
        // loadUserProfile() est appelé pour un chargement unique. Pour la synchronisation continue, _startProfileSubscription est préférable.
        // On peut appeler loadUserProfile() la première fois qu'un utilisateur se connecte APRÈS l'initialisation de l'app,
        // puis _startProfileSubscription() pour les mises à jour. Ou simplement toujours _startProfileSubscription().
        // L'approche avec listener est plus réactive. Utilisons directement _startProfileSubscription().
        _startProfileSubscription(); // Démarre l'écoute en temps réel du profil.
        // TODO: Gérer l'affichage du profil par défaut si le document n'existe pas encore lors de la première connexion. (Étape 2.3.1, 2.3.2)

      } else {
        // Utilisateur déconnecté. Nettoyer le profil.
        debugLog('👤 [CurrentUserService - _startAuthListener] Changement d\'état: Utilisateur déconnecté.', level: 'INFO');
        clearUserProfile(); // Nettoie le profil et annule le listener Firestore du profil
      }
    },
      onError: (error) {
        debugLog('❌ [CurrentUserService - _startAuthListener] Erreur lors de l\'écoute des changements d\'état d\'authentification : $error', level: 'ERROR');
        // En cas d'erreur sur le listener d'auth, on considère l'utilisateur comme déconnecté par sécurité.
        clearUserProfile();
        // TODO: Gérer l'erreur du listener d'auth (ex: afficher un message) (Étape 2.5.2)
      },
      // L'événement 'onDone' n'est généralement pas émis pour authStateChanges stream.
    );
  }

  // ✅ Étape 2.5 : Ajouter la logique d'annulation du listener d'état d'authentification
  // Annule la souscription active au listener authStateChanges.
  // Utile si le service devait être détruit (peu probable pour un Singleton global) ou lors d'un arrêt propre de l'app.
  void _cancelAuthListener() {
    if (_authStateSubscription != null) {
      debugLog('🧹 [CurrentUserService - _cancelAuthListener] Annulation de la souscription authStateChanges.', level: 'INFO');
      _authStateSubscription?.cancel(); // Annule la souscription
      _authStateSubscription = null; // Remet la référence à null
    }
  }


// TODO: Ajouter la logique pour sauvegarder les modifications du profil utilisateur (Étape 2.6/5)
// Future<void> saveUserProfileChanges(UserProfile profile) async { ... }
// Utiliserait _firestoreService.saveUserProfile ou updateUserProfileFields

// Ancienne structure du service (champs individuels et setUserData) (inchangé - toujours commenté)
// ⛔️ À supprimer — Remplacée par la gestion de UserProfile et ValueNotifier — 2025/06/13
/*
        // ⭐️ Étape 2 (Ancienne) : Déclarer les champs pour stocker les données utilisateur
        // Utilise 'late' car ces champs seront initialisés plus tard par setUserData.
        // Utilise nullable String pour displayName car il peut être absent.
        late bool _isReceiver;
        late String _deviceLang;
        String? _displayName; // displayName peut être nullable

          // ⭐️ Étape 3 (Ancienne) : Définir une méthode pour initialiser/mettre à jour les données
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

        // ⭐️ Étape 4 (Ancienne) : Définir les getters publics pour accéder aux données
        // Utilise 'instance' pour accéder aux getters : CurrentUserService.instance.isReceiver
        // bool get isReceiver => _isReceiver; // Commented out or removed in V002
        // String get deviceLang => _deviceLang; // Commented out or removed in V002
        // String? get displayName => _displayName; // Commented out or removed in V002

        // Optionnel (Ancienne): Ajouter une méthode pour vérifier si les données sont initialisées
        // bool get isInitialized => ::_isReceiver != null && _deviceLang != null; // Commented out or removed in V002
        // Note: Avec 'late', l'accès avant initialisation lèvera une LateInitializationError.
        // Si tu veux éviter ça, utilise des champs nullable (bool?, String?) et gère les nulls dans les getters ou à l'appel.
        // Pour une approche lean post-auth flow, 'late' est acceptable si HomeSelector garantit l'appel à setUserData.
        */ // ⛔️ FIN du bloc à supprimer — 2025/06/13

} // <-- Fin de la classe CurrentUserService

// 📄 FIN de lib/services/current_user_service.dart
