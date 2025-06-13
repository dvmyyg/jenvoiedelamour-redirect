// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/profile_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Affiche et permet d'éditer le profil de l'utilisateur authentifié (Prénom, Email).
// ✅ Gère la sauvegarde du prénom mis à jour dans Firestore via le FirestoreService.
// ✅ Permet la déconnexion de l'utilisateur via Firebase Authentication.
// ✅ Gère la navigation pour revenir à l'écran d'accueil.
// ✅ S'appuie entièrement sur l'UID Firebase (FirebaseAuth.currentUser) pour identifier l'utilisateur.
// ✅ Utilise le FirestoreService pour toutes les interactions avec Firestore (chargement/sauvegarde profil).
// ✅ Utilise l'I18nService pour la traduction des textes de l'interface.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V008 - Suppression de l'import inutilisé 'package:cloud_firestore/cloud_firestore.dart)' suite à la centralisation des opérations Firestore dans FirestoreService. - 2025/05/30
// V007 - Correction de l'erreur 'The name '_initialDisplayName' est déjà défini' en supprimant la déclaration en double. Correction des appels aux méthodes du service (getUserProfile, saveUserProfile) pour utiliser l'instance _firestoreService, résolvant ainsi les erreurs de méthode indéfinie et les avertissements d'imports inutilisés. - 2025/05/30
// V005 - Correction de l'erreur Undefined name 'getUserProfile' en décommentant l'import de firestore_service.dart. Code refactorisé vers UID confirmé. - 2025/05/30
// V004 - Refactoring : Remplacement de deviceId par l'UID Firebase pour l'identification utilisateur. Suppression du paramètre deviceId et de la logique basée sur devices/{deviceId}. Mise à jour des paramètres passés à HomeSelector. - 2025/05/29
// V003 - Ajout import cloud_firestore pour FirebaseFirestore & SetOptions (historique hérité). - 2025/05/24 10h31
// V002 - Ajout import firebase_auth et import firestore_service (historique hérité). - 2025/05/25
// V001 - Version initiale (historique hérité). - 2025/05/21
// -------------------------------------------------------------

// GEM - Code corrigé par Gémini le 2025/05/30 // Mise à jour le 30/05


import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart'; // Toujours nécessaire pour interagir avec Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Essentiel pour obtenir l'utilisateur authentifié et son UID
import '../utils/debug_log.dart';
import '../services/i18n_service.dart'; // Pour les traductions
import '../services/firestore_service.dart'; // <-- CORRIGÉ : Décommenté l'import pour accéder à getUserProfile/saveUserProfile
// On importe HomeSelector, qui n'a plus besoin de deviceId en paramètre
import 'home_selector.dart';

class ProfileScreen extends StatefulWidget {
  // Le deviceId n'est plus pertinent ici. L'identifiant de l'utilisateur actuel est son UID Firebase,
  // obtenu via FirebaseAuth.instance.currentUser.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente

  const ProfileScreen({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  String? _email;
  bool _hasChanged = false; // Pour indiquer si le prénom a été modifié
  bool _isLoading = true; // Pour l'état de chargement initial du profil
  String? _errorMessage; // Pour afficher les erreurs
  String? _successMessage; // Pour afficher les messages de succès

  // => AJOUT DE CETTE LIGNE :
  late final FirestoreService _firestoreService; // Variable pour l'instance du service
  String? _initialDisplayName; // Stocke le prénom initial chargé

  @override
  void initState() {
    super.initState();
    // => AJOUTEZ CETTE LIGNE POUR INITIALISER LE SERVICE :
    // D'après votre firestore_service.dart, le constructeur est vide.
    _firestoreService = FirestoreService(); // Crée l'instance du service
    _loadProfile(); // Charge le profil au démarrage de l'écran
    // Ajoute un écouteur pour détecter les changements dans le champ du prénom
    _displayNameController.addListener(_onDisplayNameChanged);
  }

  // Libère les contrôleurs lorsqu'ils ne sont plus nécessaires.
  @override
  void dispose() {
    _displayNameController.removeListener(_onDisplayNameChanged); // Retire l'écouteur
    _displayNameController.dispose();
    super.dispose();
  }

  // Callback pour détecter les modifications dans le champ du prénom
  void _onDisplayNameChanged() {
    // Active le bouton de sauvegarde si le texte initial n'est pas le même que le texte actuel
    // tout en évitant de déclencher setState inutilement si le texte est identique
    if (_displayNameController.text.trim() != (_initialDisplayName ?? '')) {
      if (!_hasChanged) {
        setState(() => _hasChanged = true);
      }
    } else {
      if (_hasChanged) {
        setState(() => _hasChanged = false);
      }
    }
  }

  // Modifié pour charger le profil UNIQUEMENT depuis users/{uid}
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Obtenir l'utilisateur Firebase actuellement connecté pour son UID et email
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté (ne devrait pas arriver ici si main.dart redirige correctement)
      debugLog("⚠️ ProfileScreen : Utilisateur non connecté. Ne devrait pas arriver.", level: 'ERROR');
      setState(() {
        _email = '(Utilisateur non connecté)'; // TODO: Utiliser i18n_service
        _displayNameController.text = '';
        _initialDisplayName = '';
        _isLoading = false;
        _errorMessage = getUILabel('profile_load_error_not_logged_in', widget.deviceLang); // TODO: Add key
      });
      return;
    }

    // Utiliser l'UID de l'utilisateur pour charger le profil depuis la collection 'users'
    try {
      // => CORRECTION : Appelle la méthode via l'instance du service
      final userData = await _firestoreService.getUserProfile(user.uid);

      // Extraire le prénom (firstName est le champ préféré) ou utiliser un fallback
      final displayName = userData?['firstName'] ?? userData?['displayName'] ?? '';

      // Mettre à jour le contrôleur de texte et les variables d'état
      _displayNameController.text = displayName;
      _initialDisplayName = displayName; // Sauvegarde le nom initial
      _hasChanged = false; // Initialise à false car pas de changement au démarrage

      setState(() {
        _email = user.email ?? '(email inconnu)'; // Affiche l'email de Firebase Auth
        _isLoading = false; // Fin du chargement
        _errorMessage = null; // S'assurer qu'il n'y a pas d'ancienne erreur affichée
      });

      debugLog("📄 Chargement profil réussi pour UID ${user.uid} : $displayName (${user.email})", level: 'INFO');
    } catch (e) {
      // Gérer l'erreur de lecture Firestore via getUserProfile
      debugLog("❌ Erreur chargement profil pour UID ${user.uid} : $e", level: 'ERROR');
      setState(() {
        _errorMessage = getUILabel('profile_load_error', widget.deviceLang); // Utilise i18n_service
        _isLoading = false; // Fin du chargement (avec erreur)
      });
    }
    // L'ancienne logique de fallback sur devices/{deviceId} est supprimée.
    /*
     if (displayName.isEmpty) { // <-- Ancien fallback
        final doc = await FirebaseFirestore.instance
            .collection('devices') // <-- Ancien chemin
            .doc(widget.deviceId) // <-- Ancien ID
            .get();

        displayName = doc.data()?['displayName'] ?? '';
     }
     */
  }

  // Modifié pour enregistrer le profil UNIQUEMENT dans users/{uid} via saveUserProfile
  Future<void> _saveProfile() async {
    final newName = _displayNameController.text.trim();
    if (newName.isEmpty) {
      // Valider que le champ n'est pas vide (devrait aussi être géré par validator)
      setState(() => _errorMessage = getUILabel('required_field', widget.deviceLang)); // Utilise i18n_service
      return;
    }

    setState(() {
      _isLoading = true; // Afficher un indicateur de chargement pendant la sauvegarde
      _errorMessage = null; // Réinitialiser les messages
      _successMessage = null;
    });

    // Obtenir l'utilisateur Firebase actuellement connecté
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugLog("⚠️ ProfileScreen : Tentative de sauvegarde, mais utilisateur non connecté.", level: 'ERROR');
      setState(() {
        _errorMessage = getUILabel('profile_save_error_not_logged_in', widget.deviceLang); // TODO: Add key
        _isLoading = false;
      });
      return;
    }

    try {
      // **Suppression de l'écriture obsolète dans devices/{deviceId}**
      // await FirebaseFirestore.instance // <-- SUPPRIMÉ
      //     .collection('devices') // <-- SUPPRIMÉ
      //     .doc(widget.deviceId) // <-- SUPPRIMÉ
      //     .update({'displayName': newName}); // <-- SUPPRIMÉ


      // Enregistrer le profil dans la collection 'users' en utilisant l'UID via firestore_service
      // => CORRECTION : Appelle la méthode via l'instance du service
      await _firestoreService.saveUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        firstName: newName,
      );

      // Optionnel : Mettre à jour le displayName dans Firebase Auth aussi
      await user.updateDisplayName(newName);
      debugLog("✅ updateDisplayName Firebase Auth réussi"); // Log pour confirmation

      setState(() {
        _successMessage = getUILabel('profile_saved', widget.deviceLang); // Utilise i18n_service
        _hasChanged = false; // Réinitialise l'indicateur de changement après sauvegarde
        _initialDisplayName = newName; // Met à jour le nom initial sauvegardé
        _isLoading = false; // Fin du chargement
        _errorMessage = null; // S'assurer qu'il n'y a pas d'erreur affichée en même temps
      });

      debugLog("💾 Profil mis à jour dans Firestore (users/${user.uid}) : $newName", level: 'INFO');

      // Le message de succès s'affiche via SnackBar si implémenté, ou ici directement.
      // L'ancienne logique affichait le message dans l'UI de l'écran. On garde cette approche.

    } catch (e) {
      debugLog("❌ Erreur sauvegarde profil pour UID ${user.uid} : $e", level: 'ERROR');
      setState(() {
        _errorMessage = getUILabel('profile_save_error', widget.deviceLang); // Utilise i18n_service
        _isLoading = false; // Fin du chargement (avec erreur)
        _successMessage = null; // S'assurer qu'il n'y a pas de succès affiché en même temps
      });
    }
  }

  // Gère la déconnexion utilisateur via Firebase Auth
  Future<void> _logout() async {
    setState(() => _isLoading = true); // Peut-être afficher un indicateur pendant la déconnexion

    try {
      await FirebaseAuth.instance.signOut(); // Déconnexion via Firebase Auth
      debugLog("👋 Utilisateur déconnecté (UID: ${FirebaseAuth.instance.currentUser?.uid})", level: 'INFO');
      // Firebase Auth met à jour son état global.
      // main.dart (qui écoute authStateChanges()) détectera le passage à null
      // et naviguera automatiquement vers LoginScreen.
      // Donc, cet écran n'a PAS besoin de naviguer ici !

      // L'ancienne logique de popUntil était nécessaire si main.dart ne gérait pas la navigation globale.
      // if (mounted) Navigator.of(context).popUntil((route) => route.isFirst); // <-- Potentiellement SUPPRIMÉ si main.dart gère tout

    } catch (e) {
      debugLog("❌ Erreur déconnexion : $e", level: 'ERROR');
      setState(() {
        _errorMessage = getUILabel('logout_error', widget.deviceLang); // TODO: Add this key
        _isLoading = false;
      });
      // TODO: Afficher un message d'erreur à l'utilisateur si la déconnexion échoue ?
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fonction pour revenir à l'écran d'accueil (HomeSelector)
  // Modifié pour ne PAS passer deviceId
  void _goToHome() {
    // Navigue vers HomeSelector. On ne passe PLUS deviceId.
    // HomeSelector obtiendra l'UID via FirebaseAuth.instance.currentUser.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeSelector(
          // deviceId: widget.deviceId, // <-- SUPPRIMÉ
          deviceLang: widget.deviceLang, // La langue est toujours passée
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // L'UI reste similaire, affichant les champs de profil et les boutons d'action.
    // Elle utilise _isLoading pour désactiver les actions pendant le chargement/sauvegarde.
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
        title: Text(getUILabel('profile_title', widget.deviceLang)), // Utilise i18n_service
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    ),
    body: _isLoading && _initialDisplayName == null // Afficher l'indicateur de chargement uniquement pendant le chargement initial
    ? const Center(
    child: CircularProgressIndicator(color: Colors.pink),
    )
        : Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Section Prénom/Nom affiché
    Text(
    getUILabel('profile_firstname_label', widget.deviceLang), // Utilise i18n_service
    style: const TextStyle(
    color: Colors.white70,
    fontWeight: FontWeight.bold,
    ),
    ),
    const SizedBox(height: 4),
    // Champ de texte pour le prénom (utilise _displayNameController)
    TextFormField(
    controller: _displayNameController,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
    hintText: getUILabel('profile_firstname_hint', widget.deviceLang), // Utilise i18n_service
    hintStyle: const TextStyle(color: Colors.white38),
    enabledBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white24),
    ),
    focusedBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.pink),
    ),
    ),
    // onChanged est déjà configuré pour détecter les modifications et activer le bouton de sauvegarde
      // onChanged: (_) {
      //     if (!_hasChanged) {
      //       setState(() => _hasChanged = true);
      //     }
      //   }, // <-- Commenté car l'écouteur est ajouté dans initState
    ),
      const SizedBox(height: 32),
      // Section Email (lecture seule)
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          getUILabel('profile_email_label', widget.deviceLang), // Utilise i18n_service
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _email ?? '', // Affiche l'email chargé
          style: const TextStyle(color: Colors.white),
        ),
      ),
      const SizedBox(height: 32),
      // Affichage des messages d'erreur ou de succès
      if (_errorMessage != null)
        Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
          textAlign: TextAlign.center, // Centrer le texte
        ),
      if (_successMessage != null)
        Text(
          _successMessage!,
          style: const TextStyle(color: Colors.greenAccent),
          textAlign: TextAlign.center, // Centrer le texte
        ),
      const Spacer(), // Pousse les boutons vers le bas
      // Bouton pour sauvegarder (activé seulement si des changements ont eu lieu)
      if (_hasChanged) // Bouton visible seulement s'il y a des modifications non sauvegardées
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveProfile, // Désactivé pendant la sauvegarde
          icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save), // Indicateur de chargement sur l'icône ou texte
          label: _isLoading ? Text(getUILabel('saving', widget.deviceLang)) : Text(getUILabel('profile_save_button', widget.deviceLang)), // TODO: Add 'saving' key, texte du bouton
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      const SizedBox(height: 12),
      // Bouton de Déconnexion
      ElevatedButton.icon(
        onPressed: _isLoading ? null : _logout, // Désactivé si d'autres opérations sont en cours
        icon: const Icon(Icons.logout),
        label: Text(getUILabel('logout_button', widget.deviceLang)), // Utilise i18n_service
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      const SizedBox(height: 12),
      // Bouton pour revenir à l'accueil
      ElevatedButton.icon(
        onPressed: _isLoading ? null : _goToHome, // Désactivé si d'autres opérations sont en cours
        icon: const Icon(Icons.home),
        label: Text(getUILabel('back_home_button', widget.deviceLang)), // Utilise i18n_service
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    ],
    ),
    ),
    );
  } // <-- Fin de la méthode build

// TODO: Potentiellement ajouter d'autres méthodes liées au profil ici si nécessaire.
} // <-- Fin de la classe _ProfileScreenState

// TODO: Pensez à supprimer la classe ProfileScreen si elle n'est pas utilisée ailleurs (c'est un StatefulWidget, donc elle a sa classe State associée)

// TODO: S'assurer que ProfileScreen n'est pas appelé avec un deviceId n'importe où.
