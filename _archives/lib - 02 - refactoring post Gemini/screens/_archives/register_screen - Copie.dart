//  lib/screens/register_screen.dart

// Historique du fichier
// V003 - Refactoring : Suppression du paramètre deviceId. L'écran s'appuie sur FirebaseAuth pour l'inscription.
//      - Suppression de l'écriture obsolète dans devices/{deviceId} après inscription.
//      - S'appuie sur main.dart pour la navigation après changement d'état d'auth (vers EmailVerificationScreen).
//      - Utilisation potentielle de AuthService (si implémenté/préféré) pour la logique d'inscription. - 2025/05/29
// V002 - ajout de la sauvegarde du prénom dans Firestore et Firebase Auth + champ prénom - 2025/05/25 21h30 (Historique hérité)
// V001 - version initiale - 2025/05/22 (Historique hérité)

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Essentiel pour l'inscription
// L'import de cloud_firestore n'est plus nécessaire ici si on supprime l'écriture directe dans devices/{deviceId}
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- POTENTIELLEMENT SUPPRIMÉ
import '../services/i18n_service.dart'; // Pour les traductions UI
import '../utils/debug_log.dart'; // Votre utilitaire de log
// EmailVerificationScreen n'est plus importé si on ne navigue pas directement vers lui
// import '../screens/email_verification_screen.dart'; // <-- SUPPRIMÉ
// L'import de firestore_service est toujours nécessaire pour saveUserProfile
import '../services/firestore_service.dart';

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

  bool _isLoading = false; // Indicateur de chargement
  String? _errorMessage; // Pour afficher les erreurs

  @override
  void dispose() {
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
      return;
    }

    setState(() {
      _isLoading = true; // Active l'indicateur de chargement
      _errorMessage = null; // Réinitialise l'erreur précédente
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text; // Ne pas trimmer le mot de passe
    final displayName = _nameController.text.trim(); // Prénom

    try {
      // Appelle la méthode de création de compte de Firebase Authentication
      // Alternativement, si vous utilisez AuthService:
      // final credential = await AuthService().register(email, password);
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Si la création réussit, credential.user n'est pas null
      final user = credential.user;
      if (user == null) {
        // Ce cas ne devrait pas arriver avec une création réussie
        throw Exception("Erreur interne: Utilisateur null après création de compte."); // Lance une exception pour une erreur inattendue
      }
      final uid = user.uid; // UID du nouvel utilisateur

      debugLog("✅ Compte créé pour ${user.email} (UID: $uid)", level: 'SUCCESS');

      // **Suppression de l'écriture obsolète dans devices/{deviceId}**
      // Cette écriture associait des infos utilisateur à l'ancien deviceId. Elle est obsolète.
      /*
      await FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).set({ // <-- Ancien chemin basé sur deviceId
        'deviceId': widget.deviceId, // <-- deviceId obsolète
        'email': email, // Cet email est déjà dans Firebase Auth et sera sauvegardé sous users/{uid}
        'displayName': displayName, // Ce nom sera sauvegardé sous users/{uid}
        'createdAt': Timestamp.now(), // Timestamp sera géré par saveUserProfile ou ajouté si besoin
      }, SetOptions(merge: true));
      */ // <-- Logique obsolète commentée/supprimée


      // Enregistrer les informations de profil (email, prénom) dans la collection 'users' en utilisant l'UID
      // Cette partie était déjà correctement basée sur l'UID et est conservée.
      await saveUserProfile( // Utilise firestore_service refactorisé
        uid: uid, // UID du nouvel utilisateur
        email: email, // Email de l'utilisateur
        firstName: displayName, // Prénom
      );
      debugLog("💾 Profil utilisateur sauvegardé dans Firestore (users/$uid)", level: 'INFO');


      // Mettre à jour le displayName dans le profil Firebase Auth (Optionnel mais bonne pratique)
      // Cela permet d'afficher le nom dans la console Firebase ou potentiellement dans d'autres services Firebase.
      await user.updateDisplayName(displayName);
      debugLog("✅ updateDisplayName Firebase Auth réussi", level: 'INFO');


      // Envoyer l'email de vérification.
      // L'utilisateur créé aura user.emailVerified = false initialement.
      await user.sendEmailVerification();
      debugLog("📩 Email de vérification envoyé à ${user.email}", level: 'INFO');


      // L'inscription a réussi et l'email de vérification a été envoyé.
      // main.dart (qui écoute authStateChanges()) détectera que user est non-null
      // et que user.emailVerified est false, et naviguera automatiquement
      // vers EmailVerificationScreen.
      // Donc, cet écran n'a PAS besoin de naviguer ici !
      /*
      if (!mounted) return; // <-- Cette vérification n'est plus nécessaire si on ne navigue pas
      Navigator.pushReplacement( // <-- SUPPRIMÉ
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            deviceId: widget.deviceId, // <-- deviceId obsolète, non nécessaire pour EmailVerificationScreen refactorisé
            deviceLang: widget.deviceLang,
          ),
        ),
      );
      */ // <-- Logique de navigation supprimée


    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs spécifiques de Firebase Auth lors de l'inscription
      debugLog("❌ Erreur création compte : ${e.code} - ${e.message}", level: 'ERROR');
      String errorMessage = getUILabel('register_error_generic', widget.deviceLang); // TODO: Add this key for generic registration error

      // TODO: Affiner le message d'erreur basé sur e.code si vous voulez être plus précis
      // switch (e.code) {
      //   case 'email-already-in-use':
      //     errorMessage = getUILabel('register_error_email_in_use', widget.deviceLang); // TODO: Add key
      //     break;
      //   case 'weak-password':
      //     errorMessage = getUILabel('register_error_weak_password', widget.deviceLang); // TODO: Add key
      //     break;
      //   // ... autres codes ...
      //   default:
      //     errorMessage = getUILabel('register_error_generic', widget.deviceLang); // Use the generic one defined above
      // }

      setState(() => _errorMessage = errorMessage); // Affiche le message d'erreur
    } catch (e) {
      // Gérer les autres types d'erreurs
      debugLog("❌ Erreur création compte (autre erreur) : $e", level: 'ERROR');
      setState(() => _errorMessage = getUILabel('register_error_generic', widget.deviceLang)); // Use generic error
    } finally {
      // S'exécute après try/catch, que l'inscription ait réussi ou échoué
      setState(() => _isLoading = false); // Désactive l'indicateur de chargement
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
            validator: (value) =>
            value != null && value.contains('@') && value.trim().isNotEmpty ? null : getUILabel('invalid_email', lang), // Utilise i18n_service, ajout check isEmpty/trim
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
            validator: (value) =>
            value != null && value.length >= 6 ? null : getUILabel('password_min_length', lang), // Utilise i18n_service
          ),
          const SizedBox(height: 32),
          // Affichage du message d'erreur si _errorMessage n'est pas null
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20), // Espacement avant le bouton
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center, // Centrer le texte d'erreur
              ),
            ),
          // Bouton d'Inscription
          ElevatedButton.icon(
            // Désactiver le bouton et afficher un indicateur si _isLoading est vrai
            onPressed: _isLoading ? null : _register,
            icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.person_add), // Indicateur de chargement sur l'icône ou texte
            label: _isLoading ? Text(getUILabel('registering', lang)) : Text(getUILabel('register_button', lang)), // TODO: Add 'registering' key, texte du bouton
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48), // Bouton pleine largeur
            ),
          ),
          // TODO: Optionnel : Bouton pour revenir à l'écran de connexion si l'utilisateur a cliqué "Créer un compte" par erreur.
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : () { // Désactivé pendant l'inscription
              Navigator.pop(context); // Revenir à l'écran précédent (LoginScreen)
            },
            child: Text(getUILabel('back_to_login_button', lang)), // TODO: Add key for back to login
          ),
        ],
      ),
    ),
        ),
    );
  } // <-- Fin de la méthode build
} // <-- Fin de la classe _RegisterScreenState et de la classe RegisterScreen

// TODO: S'assurer que RegisterScreen n'est pas appelé avec un deviceId n'importe où.
