// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/register_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Permet aux nouveaux utilisateurs de créer un compte avec email et mot de passe via Firebase Auth.
// ✅ Gère la saisie du prénom, de l'email et du mot de passe.
// ✅ Valide les données du formulaire.
// ✅ Sauvegarde le prénom et l'email dans la collection 'users' sous l'UID du nouvel utilisateur via FirestoreService.
// ✅ Envoie un email de vérification au nouvel utilisateur.
// ✅ S'appuie sur le flux d'authentification centralisé (main.dart) pour la navigation post-inscription.
// ✅ Affiche des indicateurs de chargement et des messages d'erreur.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V005 - Correction de l'appel à saveUserProfile pour utiliser l'instance de FirestoreService. - 2025/05/30
// V004 - Amélioration de la gestion d'erreurs Firebase Auth. Utilisation cohérente de debugLog. Ajout de TODOs pour i18n. Ajout de commentaires sur l'intégration potentielle avec AuthService. - 2025/05/30
// V003 - Refactoring : Suppression du paramètre deviceId. L'écran s'appuie sur FirebaseAuth pour l'inscription. Suppression de l'écriture obsolète dans devices/{deviceId} après inscription. S'appuie sur main.dart pour la navigation après changement d'état d'auth (vers EmailVerificationScreen). Utilisation potentielle de AuthService (si implémenté/préféré) pour la logique d'inscription. - 2025/05/29
// V002 - ajout de la sauvegarde du prénom dans Firestore et Firebase Auth + champ prénom - 2025/05/25 21h30 (Historique hérité)
// V001 - version initiale - 2025/05/22 (Historique hérité)
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/30 // Mise à jour de la date au 30/05

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Essentiel pour l'inscription
import '../services/firestore_service.dart'; // Import du FirestoreService
// L'import de cloud_firestore n'est plus nécessaire ici car on utilise firestore_service pour saveUserProfile.
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- SUPPRIMÉ
import '../services/i18n_service.dart'; // Pour les traductions UI
import '../utils/debug_log.dart'; // Votre utilitaire de log
// EmailVerificationScreen n'est pas importé si on ne navigue pas directement vers lui.
// import '../screens/email_verification_screen.dart'; // <-- SUPPRIMÉ
// L'import de firestore_service est déjà fait au-dessus.
// import '../services/firestore_service.dart'; // <-- Redondant, supprimé

// Optionnel : Importer AuthService si vous préférez centraliser la logique d'inscription là-bas.
// import '../services/auth_service.dart'; // <-- Optionnel

class RegisterScreen extends StatefulWidget {
  // Le deviceId n'est plus requis ici. L'écran gère l'inscription via Firebase Auth.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente

  const RegisterScreen({
    super.key,
    required this.deviceLang,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Champ prénom

  // Ajoutez cette ligne pour créer une instance de FirestoreService
  final FirestoreService _firestoreService = FirestoreService(); // Initialise le service Firestore


  bool _isLoading = false; // Indicateur de chargement
  String? _errorMessage; // Pour afficher les erreurs

  @override
  void dispose() {
    debugLog("🚪 RegisterScreen dispose. Libération des contrôleurs.", level: 'INFO');
    // Libère les contrôleurs lorsqu'ils ne sont plus nécessaires.
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Gère le processus d'inscription utilisateur
  Future<void> _register() async {
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      debugLog("⚠️ [register] Formulaire invalide. Inscription annulée.", level: 'WARN');
      // Optionnel: Afficher un message générique si validation échoue
      // setState(() => _errorMessage = getUILabel('form_validation_error', widget.deviceLang)); // TODO: Add key
      return;
    }

    setState(() {
      _isLoading = true; // Active l'indicateur de chargement
      _errorMessage = null; // Réinitialise l'erreur précédente
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text; // Ne pas trimmer le mot de passe
    final displayName = _nameController.text.trim(); // Prénom

    debugLog("🔄 [register] Tentative d'inscription pour email : $email", level: 'INFO');

    try {
      // --- Inscription Firebase Auth ---
      // Optionnel : Utiliser AuthService().register(email, password) ici si vous centralisez dans AuthService
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Vérifie si la création a vraiment retourné un utilisateur
      final user = credential.user;
      if (user == null) {
        // Ce cas ne devrait pas arriver avec une création réussie de Firebase Auth
        debugLog("❌ [register] Erreur interne: Utilisateur null après createUserWithEmailAndPassword.", level: 'ERROR');
        // Lancer une erreur pour qu'elle soit gérée par le catch générique
        throw Exception("Internal error: User object is null after registration.");
      }
      final uid = user.uid; // UID du nouvel utilisateur

      debugLog("✅ [register] Compte Firebase Auth créé pour ${user.email} (UID: $uid)", level: 'SUCCESS');

      // **Suppression de l'écriture obsolète dans devices/{deviceId}**
      // Cette écriture associait des infos utilisateur à l'ancien deviceId. Elle est obsolète et a été retirée.
      /*
      await FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).set({ ... });
      */ // <-- Logique obsolète retirée

      // --- Sauvegarde du profil dans Firestore (users/{uid}) ---
      // Utilise firestore_service.dart pour sauvegarder les données utilisateur.
      // Appelle saveUserProfile VIA L'INSTANCE DE FirestoreService.
      await _firestoreService.saveUserProfile( // <-- CORRIGÉ ICI !
        uid: uid, // UID du nouvel utilisateur
        email: email, // Email de l'utilisateur
        firstName: displayName, // Prénom
      );
      debugLog("💾 [register] Profil utilisateur sauvegardé dans Firestore (users/$uid)", level: 'INFO');
      // --- Mise à jour du displayName dans le profil Firebase Auth (Optionnel mais bonne pratique) ---
      // Permet d'afficher le nom dans la console Firebase ou d'autres services Auth.
      await user.updateDisplayName(displayName);
      debugLog("✅ [register] updateDisplayName Firebase Auth réussi", level: 'INFO');


      // --- Envoi de l'email de vérification ---
      // L'utilisateur créé aura user.emailVerified = false initialement.
      // Cet email contient un lien que l'utilisateur doit cliquer.
      await user.sendEmailVerification();
      debugLog("📩 [register] Email de vérification envoyé à ${user.email}", level: 'INFO');


      // --- Navigation post-inscription ---
      // L'inscription a réussi et l'email de vérification a été envoyé.
      // **IMPORTANT :** Ne pas naviguer directement ici vers EmailVerificationScreen !
      // main.dart (qui écoute authStateChanges()) détectera que user est non-null
      // et que user.emailVerified est false, et naviguera automatiquement
      // vers EmailVerificationScreen au prochain rebuild de MyApp.
      // Cela centralise la logique de flux post-authentification.

      // Afficher un message de succès temporaire (optionnel) avant que la navigation automatique ait lieu.
      if (mounted) { // Vérifie si le widget est monté
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getUILabel('register_success_check_email', widget.deviceLang))), // TODO: Add success message key
        );
        // Ne pas naviguer ici. La navigation est gérée par main.dart.
        // Navigator.pop(context); // Optionnel: Revenir à l'écran précédent si la navigation auto ne suffit pas
      }
      debugLog("✅ [register] Processus d'inscription terminé. Attente de la navigation automatique via main.dart.", level: 'INFO');


    } on FirebaseAuthException catch (e) {
      // --- Gérer les erreurs spécifiques de Firebase Auth lors de l'inscription ---
      debugLog("❌ [register] Erreur Firebase Auth lors de la création compte : ${e.code} - ${e.message}", level: 'ERROR');
      String errorMessage = getUILabel('register_error_generic', widget.deviceLang); // Message générique par défaut

      // TODO: Affiner le message d'erreur basé sur e.code pour une meilleure expérience utilisateur
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = getUILabel('register_error_email_in_use', widget.deviceLang); // TODO: Add key: "Cet email est déjà utilisé."
          break;
        case 'weak-password':
          errorMessage = getUILabel('register_error_weak_password', widget.deviceLang); // TODO: Add key: "Mot de passe trop faible. Il doit contenir au moins 6 caractères."
          break;
        case 'invalid-email':
          errorMessage = getUILabel('register_error_invalid_email', widget.deviceLang); // TODO: Add key: "L'adresse email n'est pas valide."
          break;
      // ... gérer d'autres codes d'erreur pertinents si nécessaire ...
        default:
        // Utilise le message d'erreur Firebase par défaut si on n'a pas de traduction spécifique
          errorMessage = "${getUILabel('register_error_firebase', widget.deviceLang)}: ${e.message}"; // TODO: Add key: "Erreur Firebase"
          break;
      }

      setState(() => _errorMessage = errorMessage); // Affiche le message d'erreur à l'utilisateur
    } catch (e) {
      // --- Gérer les autres types d'erreurs inattendues ---
      debugLog("❌ [register] Erreur inattendue lors de la création compte (autre erreur) : $e", level: 'ERROR');
      // Afficher un message d'erreur générique pour les erreurs non Firebase Auth
      setState(() => _errorMessage = getUILabel('register_error_unexpected', widget.deviceLang)); // TODO: Add key: "Une erreur inattendue est survenue."
    } finally {
      // S'exécute après try/catch, que l'inscription ait réussi ou échoué
      if (mounted) { // Assurez-vous que le widget est toujours monté avant de mettre à jour l'état
        setState(() => _isLoading = false); // Désactive l'indicateur de chargement
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.deviceLang;

    // L'UI reste globalement la même pour les champs et les boutons.
// La logique du bouton appelle la méthode _register refactorisée.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(getUILabel('register_title', lang)), // Utilise i18n_service
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView( // Utilise ListView pour permettre
            shrinkWrap: true, // Permet au ListView de ne prendre que l'espace nécessaire
            // Si le formulaire devient très long, ajouter physics: AlwaysScrollableScrollPhysics() ou similaire
            children: [
              // Champ Prénom
    TextFormField(
    controller: _nameController,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
    labelText: getUILabel('profile_firstname_label', lang), // Utilise i18n_service
    labelStyle: const TextStyle(color: Colors.white),
    enabledBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white24),
    ),
    focusedBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.pink),
    ),
    ),
    validator: (value) =>
    value == null || value.trim().isEmpty ? getUILabel('required_field', lang) : null, // Utilise i18n_service
    ),
    const SizedBox(height: 16),
    // Champ Email
    TextFormField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress, // Clavier adapté pour email
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
    labelText: getUILabel('email_label', lang), // Utilise i18n_service
    labelStyle: const TextStyle(color: Colors.white),
    enabledBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white24),
    ),
    focusedBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.pink),
    ),
    ),
    // Validation basique de l'email (présence de '@', non vide après trim)
    validator: (value) {
    if (value == null || value.trim().isEmpty) {
    return getUILabel('required_field', lang); // Champ requis
    }
    if (!value.contains('@')) {
    return getUILabel('invalid_email', lang); // Format email invalide
    }
    // Vous pourriez ajouter une validation regex plus complète ici
    return null; // Validation réussie
    },
    ),
    const SizedBox(height: 16),
    // Champ Mot de passe
    TextFormField(
    controller: _passwordController,
    obscureText: true, // Masque le texte
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: getUILabel('password_label', lang), // Utilise i18n_service
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.pink),
        ),
      ),
      // Validation basique du mot de passe (longueur minimum)
      validator: (value) {
        if (value == null || value.isEmpty) {
          return getUILabel('required_field', lang); // Champ requis
        }
        if (value.length < 6) { // Minimum 6 caractères comme requis par Firebase Auth
          return getUILabel('password_min_length', lang); // TODO: Add key: "Le mot de passe doit contenir au moins 6 caractères."
        }
        return null; // Validation réussie
      },
    ),
      const SizedBox(height: 32), // Espacement avant le message d'erreur ou le bouton
      // Affichage du message d'erreur si _errorMessage n'est pas null
      if (_errorMessage != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 20), // Espacement avant le bouton
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.redAccent), // Couleur pour les erreurs
            textAlign: TextAlign.center, // Centrer le texte d'erreur
          ),
        ),
      // Bouton d'Inscription
      ElevatedButton.icon(
        // Désactiver le bouton et afficher un indicateur si _isLoading est vrai
        onPressed: _isLoading ? null : _register,
        // Afficher un indicateur de chargement sur l'icône ou le texte
        icon: _isLoading ? const SizedBox( // Utilise un SizedBox pour centrer le CircularProgressIndicator
          width: 24, // Largeur égale à l'icône
          height: 24, // Hauteur égale à l'icône
          child: CircularProgressIndicator( // Indicateur de chargement
            color: Colors.white, // Couleur de l'indicateur
            strokeWidth: 3, // Épaisseur de l'indicateur
          ),
        ) : const Icon(Icons.person_add), // Icône par défaut
        // Modifier le texte du bouton en fonction de l'état de chargement
        label: _isLoading ? Text(getUILabel('registering', lang)) : Text(getUILabel('register_button', lang)), // TODO: Add 'registering' key, texte du bouton (internationalisé)
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink, // Couleur de fond du bouton
          foregroundColor: Colors.white, // Couleur du texte/icône
          minimumSize: const Size.fromHeight(48), // Bouton pleine largeur
        ),
      ),
      // TODO: Optionnel : Bouton pour revenir à l'écran de connexion si l'utilisateur a cliqué "Créer un compte" par erreur.
      const SizedBox(height: 16), // Espacement entre les boutons
      TextButton(
                onPressed: _isLoading ? null : () {
                  debugLog("➡️ Navigation retour vers LoginScreen", level: 'INFO');
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: Text(getUILabel('back_to_login_button', lang)), // placé en dernier
              ),
              // TODO: Ajouter un lien "Mot de passe oublié ?" si nécessaire.
      // Cela naviguerait vers un écran de réinitialisation de mot de passe.

    ], // <-- Fin des enfants du ListView
    ), // <-- Fin du ListView
    ), // <-- Fin du Form
        ), // <-- Fin du Padding
    ); // <-- Fin du Scaffold
  } // <-- Fin de la méthode build
} // <-- Fin de la classe _RegisterScreenState et de la classe RegisterScreen

// TODO: S'assurer que RegisterScreen n'est pas appelé avec un deviceId n'importe où dans l'application.
// Vérifier tous les appels à RegisterScreen(...) et retirer le paramètre deviceId s'il est présent.

// 📄 FIN de lib/screens/register_screen.dart
