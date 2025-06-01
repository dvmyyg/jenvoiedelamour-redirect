// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/login_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Permet aux utilisateurs existants de se connecter avec email et mot de passe via Firebase Auth.
// ✅ Gère la saisie de l'email et du mot de passe.
// ✅ Gère les erreurs spécifiques de connexion Firebase Auth.
// ✅ Affiche des indicateurs de chargement et des messages d'erreur.
// ✅ Fournit un bouton pour naviguer vers l'écran d'inscription (RegisterScreen).
// ✅ N'utilise plus deviceId pour l'identification ou les opérations Firebase.
// ✅ S'appuie sur le flux d'authentification centralisé (main.dart) pour la navigation post-connexion réussie.
// ✅ Utilise l'I18nService pour la traduction des textes de l'interface.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V004 - Correction de l'action onPressed du bouton 'Créer un compte' pour utiliser Navigator.push et naviguer
//        correctement vers RegisterScreen. Code refactorisé vers UID confirmé. - 2025/05/30
// V003 - Refactoring : Suppression du paramètre deviceId. L'écran s'appuie sur FirebaseAuth pour la connexion.
//        Suppression de l'écriture obsolète dans devices/{deviceId}.
//        S'appuie sur main.dart pour la navigation post-auth. - 2025/05/29
// V002 - Ajout import cloud_firestore pour FirebaseFirestore & SetOptions (historique hérité). - 2025/05/24 10h31
// V001 - Version initiale (historique hérité). - 2025/05/21
// -------------------------------------------------------------

// GEM - Code corrigé par Gémini le 2025/05/30 // Mise à jour le 30/05


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Essentiel pour la connexion
// L'import de cloud_firestore n'est plus nécessaire ici si on supprime l'écriture directe dans devices/{deviceId}
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- POTENTIELLEMENT SUPPRIMÉ
// On importe RegisterScreen pour la navigation vers la page d'inscription
import 'register_screen.dart';
import '../utils/debug_log.dart'; // Votre utilitaire de log
import '../services/i18n_service.dart'; // pour accès aux traductions UI
// L'import de firestore_service n'est plus nécessaire ici si on supprime la lecture directe du prénom après login.
// La navigation vers HomeSelector est gérée par main.dart après que l'état d'auth change.
// import '../services/firestore_service.dart'; // <-- POTENTIELLEMENT SUPPRIMÉ

// Optionnel : Importer AuthService si vous préférez centraliser la logique de connexion/inscription là-bas.
// import '../services/auth_service.dart'; // <-- Optionnel

class LoginScreen extends StatefulWidget {
  // Le deviceId n'est plus requis ici. L'écran gère la connexion via Firebase Auth.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente

  const LoginScreen({
    super.key,
    required this.deviceLang,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _isLoading = false; // Ajout d'un indicateur de chargement

  // Libère les contrôleurs lorsqu'ils ne sont plus nécessaires.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  // Gère le processus de connexion utilisateur
  Future<void> _login() async {
    // Basic form validation (optionnel si vous utilisez le validator du TextFormField)
    // if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
    //   setState(() => _error = getUILabel('empty_fields_error', widget.deviceLang)); // TODO: Add this key
    //   return;
    // }

    setState(() {
      _isLoading = true;
      _error = null; // Réinitialise l'erreur précédente
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text; // Ne pas trimmer le mot de passe

    try {
      // Appelle la méthode de connexion de Firebase Authentication
      // Alternativement, si vous utilisez AuthService:
      // final credential = await AuthService().login(email, password);
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si la connexion réussit, credential.user n'est pas null
      // Firebase Auth met à jour son état global.
      // main.dart (qui écoute authStateChanges()) détectera ce changement
      // et naviguera automatiquement vers EmailVerificationScreen ou HomeSelector.
      // Donc, cet écran n'a PAS besoin de naviguer ici !

      debugLog("👤 Connexion réussie pour ${credential.user?.email}", level: 'SUCCESS');

      // L'ancienne logique de lecture du prénom et d'écriture dans devices/{deviceId} est supprimée.
      // Le prénom est déjà stocké sous users/{uid} (sauvegardé lors de l'inscription/modification profil).
      // L'écriture dans devices/{deviceId} est obsolète.

      /*
      final uid = credential.user?.uid;
      if (uid == null) throw Exception("UID null après connexion"); // Cette vérification n'est pas strictement nécessaire car si credential.user est null, une exception est déjà lancée par signInWithEmailAndPassword.

      // 🔁 Lecture de users/{uid} pour récupérer prénom <-- Cette lecture n'est pas nécessaire pour la navigation
      // final userData = await getUserProfile(uid); // <-- SUPPRIMÉ
      // final firstName = userData?['firstName'] ?? ''; // <-- SUPPRIMÉ

      // debugLog("👤 Connexion réussie, prénom=$firstName"); // <-- Log adapté ci-dessus

      // 🔄 Mise à jour de devices/{deviceId} <-- OBSOLÈTE
      // await FirebaseFirestore.instance
      //     .collection('devices')
      //     .doc(widget.deviceId) // <-- deviceId obsolète
      //     .set({
      //   'displayName': firstName,
      // }, SetOptions(merge: true));
      */ // <-- Logique obsolète commentée/supprimée

      // Si on arrive ici sans exception, la connexion a réussi.
      // L'état d'auth global va changer, et main.dart gérera la navigation.
      // Il n'y a rien d'autre à faire dans _login() si la navigation est gérée par le widget parent (MyApp/main.dart).

    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs spécifiques de Firebase Auth (email incorrect, mot de passe incorrect, etc.)
      debugLog("❌ Login failed: ${e.code} - ${e.message}", level: 'ERROR');
      String errorMessage = getUILabel('login_error', widget.deviceLang); // Message d'erreur générique par défaut

      // TODO: Affiner le message d'erreur basé sur e.code si vous voulez être plus précis
      // switch (e.code) {
      //   case 'user-not-found':
      //     errorMessage = getUILabel('login_error_user_not_found', widget.deviceLang); // TODO: Add key
      //     break;
      //   case 'wrong-password':
      //     errorMessage = getUILabel('login_error_wrong_password', widget.deviceLang); // TODO: Add key
      //     break;
      //   // ... autres codes ...
      //   default:
      //     errorMessage = getUILabel('login_error_generic', widget.deviceLang); // TODO: Add key
      // }


      setState(() => _error = errorMessage); // Affiche le message d'erreur
    } catch (e) {
      // Gérer les autres types d'erreurs
      debugLog("❌ Login failed (other error): $e", level: 'ERROR');
      setState(() => _error = getUILabel('login_error_generic', widget.deviceLang)); // TODO: Add key
    } finally {
      // S'exécute après try/catch, que la connexion ait réussi ou échoué
      setState(() => _isLoading = false); // Désactive l'indicateur de chargement
    }
  }


  @override
  Widget build(BuildContext context) {
    final lang = widget.deviceLang;

    // L'UI reste globalement la même pour les champs email/password et les boutons.
    // La logique des boutons appelle la méthode _login refactorisée.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              getUILabel('login_title', lang), // Utilise i18n_service
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 32),
            // Champ Email (utilise _emailController)
            TextField(
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
              // Optional: add validator if using Form widget
            ),
            const SizedBox(height: 16),
            // Champ Mot de passe (utilise _passwordController)
            TextField(
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
              // Optional: add validator
            ),
            const SizedBox(height: 24),
            // Bouton de Connexion
            ElevatedButton(
              // Désactiver le bouton et afficher un indicateur si _isLoading est vrai
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48), // Bouton pleine largeur
              ),
              // Afficher un indicateur de chargement si _isLoading, sinon le texte du bouton
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(getUILabel('login_button', lang)), // Utilise i18n_service
            ),
            const SizedBox(height: 16),
            // Bouton pour naviguer vers la page d'inscription
            TextButton(
              onPressed: () {
                // => CORRECTION : Utilise Navigator.push pour naviguer vers RegisterScreen
                debugLog("➡️ [LoginScreen] Clic sur 'Créer un compte' - Navigation vers RegisterScreen", level: 'INFO'); // Ajout d'un log utile
                Navigator.push( // C'est CETTE méthode qui déclenche la navigation
                  context, // Le contexte du widget est nécessaire pour Navigator
                  MaterialPageRoute( // Crée une nouvelle route d'écran
                    builder: (context) => RegisterScreen( // Le builder construit l'écran de destination
                      deviceLang: widget.deviceLang, // On passe le paramètre nécessaire (la langue)
                    ),
                  ),
                );
              },
              child: Text(getUILabel('create_account_button', lang)), // Utilise i18n_service
            ),
            // Affichage du message d'erreur si _error n'est pas null
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center, // Centrer le texte d'erreur
                ),
              ),
          ],
        ),
      ),
    );
  }
}
