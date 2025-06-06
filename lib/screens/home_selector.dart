// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/home_selector.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Sélectionne l'écran d'accueil approprié (probablement LoveScreen ici) après chargement des données utilisateur.
// ✅ Charge les propriétés essentielles de l'utilisateur actuel (isReceiver, displayName) depuis Firestore en utilisant son UID.
// ✅ Gère les états de chargement et d'erreur lors de la récupération des données utilisateur.
// ✅ S'appuie sur Firebase Authentication pour obtenir l'UID de l'utilisateur actuel.
// ✅ **Initialise le service FCM pour la gestion du token de l'appareil.**
// ✅ **Stocke les données de l'utilisateur actuel (isReceiver, displayName, deviceLang) dans CurrentUserService.**
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V006 - Stockage des données utilisateur (isReceiver, displayName, deviceLang) dans CurrentUserService après chargement. - 2025/06/03
// V005 - Converti en StatefulWidget pour initialiser le service FCM et gérer le token. - 2025/06/02
// V004 - Correction de l'accès à la propriété deviceLang dans le StatelessWidget. - 2025/05/30
// V003 - Refactoring : Remplacement de deviceId par l'UID Firebase de l'utilisateur actuel pour charger les données depuis Firestore (users/{userId}). - 2025/05/29
// V002 - ajout explicite du paramètre displayName (prénom) - 2025/05/24 08h20 (Historique hérité)
// V001 - version nécessitant une correction pour le prénom utilisateur - 2025/05/23 21h00 (Historique hérité)
// -------------------------------------------------------------

// GEM - Code corrigé et mis à jour par Gémini le 2025/06/03 // Mise à jour le 03/06

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
import '../utils/debug_log.dart';
import 'love_screen.dart'; // Écran vers lequel on navigue
import '../services/fcm_service.dart'; // Importe ton nouveau service FCM
// ⭐️ NOUVEAU : Importe ton nouveau service pour l'utilisateur actuel
import '../services/current_user_service.dart'; // Importe le service Singleton utilisateur actuel

// Converti de StatelessWidget à StatefulWidget
class HomeSelector extends StatefulWidget {
  // Le deviceId n'est plus requis. L'identifiant de l'utilisateur actuel est son UID Firebase,
  // accessible via FirebaseAuth.instance.currentUser.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente

  const HomeSelector({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang, // La langue est toujours passée
  });

  @override
  State<HomeSelector> createState() => _HomeSelectorState();
}

class _HomeSelectorState extends State<HomeSelector> {
  // Instancie ton service FCM
  final FcmService _fcmService = FcmService();

  @override
  void initState() {
    super.initState();
    debugLog("🏠 [HomeSelector] initState - Utilisateur authentifié et vérifié. Initialisation du service FCM...", level: 'INFO');
    _fcmService.initializeFcmHandlers(); // <-- APPEL CLÉ
  }

  Future<Map<String, dynamic>> _loadIsReceiverAndName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugLog("⚠️ HomeSelector : Utilisateur non connecté. Ne devrait pas arriver.", level: 'WARNING');
      return {
        'isReceiver': false,
        'displayName': '',
        'error': 'User not logged in', // Indicateur d'erreur interne
      };
    }

    final String currentUserId = user.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users') // Nouvelle collection de premier niveau basée sur l'UID
          .doc(currentUserId) // Document de l'utilisateur actuel (son UID)
          .get(); // Récupère le document

      final data = doc.data() ?? {};
      final isReceiver = data['isReceiver'] == true; // Lit le champ isReceiver si présent
      final displayName = data['firstName'] ?? data['displayName'] ?? ''; // Lit firstName ou displayName (firstName est préféré d'après ProfileScreen/RegisterScreen)

      debugLog("🏠 HomeSelector (UID: $currentUserId) : isReceiver=$isReceiver, name=$displayName", level: 'INFO');
      return {
        'isReceiver': isReceiver,
        'displayName': displayName, // Renvoie le prénom/nom affiché de l'utilisateur
      };
    } catch (e) {
      debugLog("❌ Erreur chargement HomeSelector pour UID $currentUserId : $e", level: 'ERROR');
      return {
        'isReceiver': false,
        'displayName': 'Erreur', // Indiquer visuellement une erreur
        'error': e.toString(), // Inclure l'erreur réelle
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadIsReceiverAndName(),
      builder: (context, snapshot) { // Utilise context ici
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          if (snapshot.hasError) {
            debugLog("❌ Erreur dans FutureBuilder HomeSelector: ${snapshot.error}", level: 'ERROR');
            return Scaffold(
              body: Center(
                child: Text("Erreur de chargement des données utilisateur: ${snapshot.error}", style: TextStyle(color: Colors.red)), // TODO: i18n
              ),
              backgroundColor: Colors.black,
            );
          }

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.pink),
            ),
            backgroundColor: Colors.black,
          );
        }

        final data = snapshot.data!;
        if (data.containsKey('error')) {
          debugLog("⚠️ Erreur interne chargée dans FutureBuilder: ${data['error']}", level: 'WARNING');
          return Scaffold(
            body: Center(
              child: Text("Impossible de charger le profil utilisateur. ${data['error']}", style: TextStyle(color: Colors.red)), // TODO: i18n
            ),
            backgroundColor: Colors.black,
          );
        }

        final isReceiver = data['isReceiver'] == true;
        final displayName = data['displayName'] ?? '';

        // ⭐️ CORRECTION ICI : Utiliser CurrentUserService() au lieu de CurrentUserService.instance ⭐️
        CurrentUserService().setUserData( // ⭐️ CORRECTION
          isReceiver: isReceiver,
          deviceLang: widget.deviceLang, // La langue est passée au widget HomeSelector
          displayName: displayName,
        );
        debugLog("✅ Données utilisateur stockées dans CurrentUserService : isReceiver=$isReceiver, displayName=$displayName", level: 'INFO'); // Optionnel: log utile


        return LoveScreen(
          deviceLang: widget.deviceLang,
          isReceiver: isReceiver,
          displayName: displayName,
        );
      },
    );
  } // <-- Fin de la méthode build
} // <-- Fin de la classe _HomeSelectorState

class PairSuccessScreen extends StatelessWidget {
  final String recipientUid; // Renommé de recipientId pour refléter qu'il s'agit de l'UID

  const PairSuccessScreen({super.key, required this.recipientUid});

  @override
  Widget build(BuildContext context) {
    // TODO: Afficher le prénom de l'autre utilisateur au lieu de son UID pour une meilleure expérience.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            const Text("✅ Appairage réussi !", // TODO: Utiliser getUILabel
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 10),
            Text(
              "Appairé avec (UID) : $recipientUid", // TODO: Afficher le nom réel de l'autre utilisateur
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text("Redirection vers l'application...", // TODO: Utiliser getUILabel
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
} // <-- Fin de la classe PairSuccessScreen

// 📄 FIN de lib/screens/home_selector.dart
