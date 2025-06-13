// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/settings_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Permet à l'utilisateur authentifié d'afficher et de modifier son prénom (nom d'affichage).
// ✅ Charge le prénom de l'utilisateur depuis son document dans la collection 'users' (basé sur son UID).
// ✅ Sauvegarde le prénom modifié dans le document utilisateur via FirestoreService.
// ✅ Utilise l'UID Firebase de l'utilisateur actuel pour toutes les opérations Firestore liées à son profil.
// ✅ N'utilise plus deviceId pour l'identification ou les opérations sur le profil.
// ✅ Gère l'état de connexion de l'utilisateur pour activer/désactiver la fonctionnalité.
// ✅ Inclut une validation simple pour le champ du nom.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V003 - Amélioration de la gestion d'erreurs lors du chargement et de la sauvegarde. Utilisation cohérente de debugLog. Désactivation des champs/bouton si utilisateur non connecté. Ajout de TODOs pour i18n. - 2025/05/30
// V002 - Refactoring : Remplacement de deviceId par l'UID Firebase de l'utilisateur actuel pour l'accès Firestore (users/{userId}/recipients/{recipient.id}). Utilisation de l'UID du destinataire (stocké dans recipient.id) comme ID de document. Suppression du paramètre deviceId. Accès à l'UID via FirebaseAuth. Adaptation de la fonction de partage de lien pour utiliser l'UID de l'utilisateur actuel et l'UID du destinataire. - 2025/05/29
// V001 - version initiale (basée sur deviceId et création d'un destinataire en attente localement) - 2025/05/21
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/30 // Mise à jour de la date au 30/05

import 'package:flutter/material.dart';
// On n'a plus besoin d'importer cloud_firestore directement ici pour les opérations de profil, car on utilise le service.
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- POTENTIELLEMENT SUPPRIMÉ si FirestoreService gère tout
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
import '../services/i18n_service.dart';
import '../services/firestore_service.dart'; // Utilise le FirestoreService pour les opérations sur le profil utilisateur
import '../utils/debug_log.dart'; // Ajout pour le logging

class SettingsScreen extends StatefulWidget {
  final String currentLang;
  // Le deviceId n'est plus requis. L'UID de l'utilisateur actuel est utilisé à la place.
  // final String deviceId; // <-- SUPPRIMÉ

  const SettingsScreen({
    super.key,
    required this.currentLang,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  // Initialise le service (on peut le faire ici ou dans initState après avoir l'UID)
  // Si FirestoreService a besoin de l'UID dans son constructeur, il faudra l'initialiser dans initState.
  // Si ses méthodes prennent l'UID en paramètre, l'initialiser ici est OK.
  // Vérifiez l'implémentation de FirestoreService. Pour l'instant, je garde ici.
  final FirestoreService _firestoreService = FirestoreService();


  // Variable pour stocker l'UID de l'utilisateur actuel.
  String? _currentUserId;
  bool _isLoading = true; // Indicateur de chargement pour le profil initial

  @override
  void initState() {
    super.initState();
    debugLog("🔄 SettingsScreen initialisé.", level: 'INFO');
    // Obtenir l'UID de l'utilisateur actuel dès que l'écran s'initialise
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (_currentUserId == null) {
      debugLog("⚠️ SettingsScreen : Utilisateur non connecté. Impossible de charger/sauvegarder le profil.", level: 'ERROR');
      // L'UI dans build affichera un message et désactivera les champs.
      setState(() => _isLoading = false); // Arrête l'indicateur si non connecté
    } else {
      _loadDisplayName(); // Charger le nom si l'utilisateur est connecté
    }
  }

  // Charge le nom d'affichage NON PAS depuis le deviceId, mais depuis le document utilisateur via son UID
  Future<void> _loadDisplayName() async {
    setState(() => _isLoading = true); // Active l'indicateur de chargement

    if (_currentUserId == null) {
      debugLog("⚠️ [loadDisplayName] _currentUserId est null. Chargement annulé.", level: 'WARN');
      setState(() => _isLoading = false);
      return; // Ne rien faire si l'UID n'est pas disponible
    }

    debugLog("🔄 [loadDisplayName] Chargement du nom d'affichage pour UID: $_currentUserId", level: 'INFO');

    try {
      // Utilise le FirestoreService pour récupérer les données de l'utilisateur par son UID
      // Assurez-vous que getUserProfile retourne bien une Map<String, dynamic>? et gère le cas null.
      final userData = await _firestoreService.getUserProfile(_currentUserId!); // _currentUserId! car vérifié au-dessus

      // Vérifie si des données ont été retournées et si le champ firstName existe
      if (userData != null && (userData['firstName'] as String?) != null) { // Cast sécurisé
        final name = userData['firstName'] as String; // Cast sécurisé
        _nameController.text = name;
        debugLog("✅ [loadDisplayName] Nom d'affichage chargé : $name", level: 'SUCCESS');
      } else {
        debugLog("🔍 [loadDisplayName] Document utilisateur trouvé pour $_currentUserId, mais champ 'firstName' manquant ou vide.", level: 'INFO');
        // Le champ peut être manquant si c'est la première fois ou n'a pas été défini. Laisse _nameController vide.
      }
    } on FirebaseException catch (e) {
      debugLog("❌ [loadDisplayName] Erreur Firebase lors du chargement pour UID $_currentUserId : ${e.code} - ${e.message}", level: 'ERROR');
      // TODO: Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // TODO: Use i18n_service
          SnackBar(content: Text("Erreur lors du chargement du profil : ${e.message}")),
        );
      }
    } catch (e) {
      debugLog("❌ [loadDisplayName] Erreur inattendue lors du chargement pour UID $_currentUserId : $e", level: 'ERROR');
      // TODO: Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // TODO: Use i18n_service
          SnackBar(content: Text("Erreur inattendue lors du chargement du profil : $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Arrête l'indicateur de chargement
      }
    }
  }

  // Sauvegarde le nom d'affichage via FirestoreService
  Future<void> _saveDisplayName() async {
    // Vérifier si l'utilisateur est connecté
    if (_currentUserId == null) {
      debugLog("⚠️ [saveDisplayName] Impossible de sauvegarder le nom : Utilisateur non connecté.", level: 'ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // TODO: Use i18n_service
          SnackBar(content: Text("Erreur: Vous devez être connecté pour sauvegarder votre profil.")),
        );
      }
      return;
    }

    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      debugLog("⚠️ [saveDisplayName] Nom d'affichage vide. Sauvegarde annulée.", level: 'WARN');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUILabel('profile_name_cannot_be_empty', widget.currentLang)), // TODO: Add this key
          ),
        );
      }
      return;
    }

    // Capitalise le nom (si vous le souhaitez)
    final name = capitalize(rawName);

    setState(() => _isLoading = true); // Active l'indicateur de chargement pour la sauvegarde

    debugLog("💾 [saveDisplayName] Tentative de sauvegarde du nom '$name' pour UID: $_currentUserId", level: 'INFO');
    try {
      // Utilise le FirestoreService pour sauvegarder le profil.
      // La fonction saveUserProfile devrait gérer la mise à jour du document users/{uid}.
      // Assurez-vous que saveUserProfile prend bien uid, email (si besoin), et firstName.
      // L'email peut être récupéré de FirebaseAuth.currentUser si nécessaire.
      final user = FirebaseAuth.instance.currentUser; // Récupère l'utilisateur pour son email
      await _firestoreService.saveUserProfile(
        uid: _currentUserId!, // UID de l'utilisateur actuel
        email: user?.email ?? '', // Email de l'utilisateur (peut être null si Auth n'est pas email/password)
        firstName: name, // Le nom à sauvegarder dans le champ 'firstName'
        // Si votre service attend un champ 'displayName' au lieu de 'firstName', ajustez ici ou dans le service.
        // Assurez-vous que saveUserProfile met à jour le champ correct.
      );

      // Optionnel: Mettre à jour également le displayName dans le profil Firebase Auth
      // (indépendant du FirestoreService)
      await user?.updateDisplayName(name);
      debugLog("✅ [saveDisplayName] updateDisplayName Firebase Auth réussi", level: 'INFO');


      debugLog("✅ [saveDisplayName] Nom d'affichage sauvegardé avec succès pour UID $_currentUserId.", level: 'SUCCESS');

      if (!mounted) return; // Vérifier si le widget est toujours monté
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getUILabel('profile_saved', widget.currentLang))),
      );

      // Optionnel: Revenir en arrière après la sauvegarde (décommenter si souhaité)
      // Navigator.pop(context);


    } on FirebaseException catch (e) {
      // Gérer les erreurs spécifiques à Firebase
      debugLog("❌ [saveDisplayName] Erreur Firebase lors de la sauvegarde pour UID $_currentUserId : ${e.code} - ${e.message}", level: 'ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // TODO: Add a specific save_failed key for profile
            content: Text("❌ ${getUILabel('save_failed', widget.currentLang)} : ${e.message}"),
          ),
        );
      }
      // Ne rethrow pas car l'erreur est gérée et affichée
    } catch (e) {
      // Gérer toute autre erreur inattendue
      debugLog("❌ [saveDisplayName] Erreur inattendue lors de la sauvegarde pour UID $_currentUserId : $e", level: 'ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // TODO: Add a specific save_failed key for profile (unexpected)
            content: Text("❌ ${getUILabel('save_failed', widget.currentLang)} : $e"),
          ),
        );
      }
      // Ne rethrow pas
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Arrête l'indicateur de chargement
      }
    }
  }

  @override
  void dispose() {
    debugLog("🚪 SettingsScreen dispose. Libération des contrôleurs.", level: 'INFO');
    _nameController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Vérifier si l'utilisateur actuel est connecté pour activer/désactiver les éléments UI
    final bool isUserConnected = _currentUserId != null;

    // Afficher un message ou un indicateur de chargement pendant le chargement initial du profil
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(getUILabel('profile_title', widget.currentLang)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    // Si l'utilisateur n'est pas connecté (et non en cours de chargement), afficher un message d'erreur
    if (!isUserConnected) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(getUILabel('profile_title', widget.currentLang)), // Peut-être un titre générique ici
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          // TODO: Use i18n_service for this message
          child: Text("Veuillez vous connecter pour gérer votre profil.", style: TextStyle(color: Colors.red)),
        ),
      );
    }


    // Si l'utilisateur est connecté et les données chargées (_isLoading est false)
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
        children: [
        const Icon(Icons.settings, color: Colors.white),
    const SizedBox(width: 8),
    Text(getUILabel('profile_title', widget.currentLang)),
    ],
    ),
    ),
    body: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    getUILabel('profile_firstname_label', widget.currentLang),
    style: const TextStyle(color: Colors.white, fontSize: 16),
    ),
    const SizedBox(height: 10),
    TextField(
    controller: _nameController,
    decoration: InputDecoration(
    hintText: getUILabel('profile_firstname_hint', widget.currentLang),
      hintStyle: const TextStyle(color: Colors.grey),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      // Validation basique pour le champ de texte du nom
      // validator: (value) {
      //    if (value == null || value.trim().isEmpty) {
      //      return getUILabel('required_field', widget.currentLang); // TODO: Add required field key
      //    }
      //    return null; // Validation réussie
      // },
    ),
      style: const TextStyle(color: Colors.white),
      // Optionnel: Désactiver le champ si l'utilisateur n'est pas connecté ou si l'on charge
      enabled: isUserConnected && !_isLoading,
    ),
      const SizedBox(height: 10),
      // Bouton de sauvegarde
      ElevatedButton(
        // Désactive le bouton si l'utilisateur n'est pas connecté, si l'on charge, ou si le champ nom est vide après trim
        onPressed: isUserConnected && !_isLoading && _nameController.text.trim().isNotEmpty ? _saveDisplayName : null,
        // Afficher un indicateur sur le bouton si l'on sauvegarde
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(getUILabel('profile_save_button', widget.currentLang)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48), // Pleine largeur
          // Styles pour le bouton désactivé
          disabledBackgroundColor: Colors.grey,
          disabledForegroundColor: Colors.white70,
        ),
      ),
      // TODO: Potentiellement ajouter un bouton "Déconnexion" ou "Supprimer compte" ici.
      // Ces actions appelleraient des méthodes dans AuthService.
      // Exemple :
      // const SizedBox(height: 20),
      // TextButton(
      //    onPressed: isUserConnected && !_isLoading ? () async {
      //       await AuthService().logout(); // Appelle la méthode de déconnexion du AuthService
      //       // La navigation vers LoginScreen sera gérée par main.dart (écoute authStateChanges)
      //    } : null,
      //    child: Text(getUILabel('logout_button', widget.currentLang)), // TODO: Add logout button key
      // ),
      // TextButton(
      //    onPressed: isUserConnected && !_isLoading ? () async {
      //       // TODO: Afficher une boîte de dialogue de confirmation avant de supprimer
      //       await AuthService().deleteAccount(); // Appelle la méthode de suppression de compte du AuthService
      //       // La navigation post-suppression sera gérée par main.dart
      //    } : null,
      //    child: Text(getUILabel('delete_account_button', widget.currentLang)), // TODO: Add delete account button key
      //    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
      // ),

      ],
    ),
    ),
    );
  } // <-- Fin de la méthode build

  // La méthode capitalize (conservée si elle est utilisée pour la sauvegarde, ce qui est le cas)
  String capitalize(String input) {
    if (input.isEmpty) return input;
    // Gère le cas d'un seul caractère
    if (input.length == 1) return input.toUpperCase();
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }


} // <-- Fin de la classe _SettingsScreenState et de la classe SettingsScreen
