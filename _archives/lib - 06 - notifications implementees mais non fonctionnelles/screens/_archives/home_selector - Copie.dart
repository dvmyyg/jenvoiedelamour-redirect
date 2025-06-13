// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/home_selector.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Sélectionne l'écran d'accueil approprié (probablement LoveScreen ici) après chargement des données utilisateur.
// ✅ Charge les propriétés essentielles de l'utilisateur actuel (isReceiver, displayName) depuis Firestore en utilisant son UID.
// ✅ Gère les états de chargement et d'erreur lors de la récupération des données utilisateur.
// ✅ S'appuie sur Firebase Authentication pour obtenir l'UID de l'utilisateur actuel.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V004 - Correction de l'accès à la propriété deviceLang dans le StatelessWidget. - 2025/05/30
// V003 - Refactoring : Remplacement de deviceId par l'UID Firebase de l'utilisateur actuel pour charger les données depuis Firestore (users/{userId}).
//      - Suppression du paramètre deviceId. Accès à l'UID via FirebaseAuth.
//      - Mise à jour des paramètres passés à LoveScreen (suppression de deviceId, s'appuie sur l'UID accessible globalement). - 2025/05/29
// V002 - ajout explicite du paramètre displayName (prénom) - 2025/05/24 08h20 (Historique hérité)
// V001 - version nécessitant une correction pour le prénom utilisateur - 2025/05/23 21h00 (Historique hérité)
// -------------------------------------------------------------

// GEM - Code corrigé par Gémini le 2025/05/30 // Mise à jour le 30/05

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
import '../utils/debug_log.dart';
import 'love_screen.dart'; // Écran vers lequel on navigue

// On peut potentiellement ajouter l'import de firestore_service ici si on l'utilise pour d'autres lectures/écritures utilisateur.
// import '../services/firestore_service.dart';


class HomeSelector extends StatelessWidget {
  // Le deviceId n'est plus requis. L'identifiant de l'utilisateur actuel est son UID Firebase,
  // accessible via FirebaseAuth.instance.currentUser.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente

  const HomeSelector({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang, // La langue est toujours passée
  });

  // Modifié pour charger les données depuis le document users/{currentUserId}
  Future<Map<String, dynamic>> _loadIsReceiverAndName() async {
    // Obtenir l'utilisateur Firebase actuellement connecté pour son UID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Ce cas ne devrait pas arriver si main.dart gère correctement la navigation vers LoginScreen
      debugLog("⚠️ HomeSelector : Utilisateur non connecté. Ne devrait pas arriver.", level: 'WARNING');
      // Retourne des valeurs par défaut ou gère l'erreur comme nécessaire
      return {
        'isReceiver': false,
        'displayName': '',
        'error': 'User not logged in', // Indicateur d'erreur interne
      };
    }

    // L'UID de l'utilisateur actuel
    final String currentUserId = user.uid;

    try {
      // Lire le document de l'utilisateur depuis la collection 'users' en utilisant son UID
      final doc = await FirebaseFirestore.instance
          .collection('users') // Nouvelle collection de premier niveau basée sur l'UID
          .doc(currentUserId) // Document de l'utilisateur actuel (son UID)
          .get(); // Récupère le document

      // Extraire les données ( displayName / firstName et isReceiver )
      final data = doc.data() ?? {};
      // Note : le prénom (displayName/firstName) est stocké dans le document users/{uid}.
      // Le champ 'isReceiver' devrait idéalement être stocké ici aussi si c'est une propriété utilisateur.
      final isReceiver = data['isReceiver'] == true; // Lit le champ isReceiver si présent
      final displayName = data['firstName'] ?? data['displayName'] ?? ''; // Lit firstName ou displayName (firstName est préféré d'après ProfileScreen/RegisterScreen)

      debugLog("🏠 HomeSelector (UID: $currentUserId) : isReceiver=$isReceiver, name=$displayName", level: 'INFO');
      return {
        'isReceiver': isReceiver,
        'displayName': displayName, // Renvoie le prénom/nom affiché de l'utilisateur
      };
    } catch (e) {
      debugLog("❌ Erreur chargement HomeSelector pour UID $currentUserId : $e", level: 'ERROR');
      // Gérer l'erreur de lecture Firestore
      return {
        'isReceiver': false,
        'displayName': 'Erreur', // Indiquer visuellement une erreur
        'error': e.toString(), // Inclure l'erreur réelle
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder attend le résultat de _loadIsReceiverAndName (maintenant basé sur l'UID)
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadIsReceiverAndName(),
      builder: (context, snapshot) { // Utilise context ici
        // Afficher un indicateur de chargement pendant que les données utilisateur sont chargées
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          // Peut-être ajouter un message d'erreur si snapshot.hasError est vrai
          if (snapshot.hasError) {
            debugLog("❌ Erreur dans FutureBuilder HomeSelector: ${snapshot.error}", level: 'ERROR');
            // Afficher un écran d'erreur au lieu du simple indicateur
            return Scaffold(
              body: Center(
                child: Text("Erreur de chargement des données utilisateur: ${snapshot.error}", style: TextStyle(color: Colors.red)), // TODO: i18n
              ),
              backgroundColor: Colors.black,
            );
          }
          // Afficher l'indicateur de chargement standard
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.pink),
            ),
            backgroundColor: Colors.black,
          );
        }

        // Les données utilisateur sont chargées
        final data = snapshot.data!;
        // Vérifier s'il y a eu une erreur interne dans _loadIsReceiverAndName (cas utilisateur non connecté ou erreur Firestore)
        if (data.containsKey('error')) {
          // Gérer l'erreur (ex: rediriger vers Login si l'erreur est "User not logged in")
          // Ou afficher un message d'erreur persistant.
          debugLog("⚠️ Erreur interne chargée dans FutureBuilder: ${data['error']}", level: 'WARNING');
          // Si l'erreur indique que l'utilisateur n'est pas connecté, peut-être rediriger (nécessite un Future.delayed ou un PostFrameCallback pour ne pas naviguer pendant le build)
          // WidgetsBinding.instance.addPostFrameCallback((_) {
          //   if (data['error'] == 'User not logged in') {
          //     Navigator.of(context).pushReplacementNamed('/login'); // Exemple si vous utilisez les routes nommées
          //   }
          // });
          // En attendant, afficher un message d'erreur simple
          return Scaffold(
            body: Center(
              child: Text("Impossible de charger le profil utilisateur. ${data['error']}", style: TextStyle(color: Colors.red)), // TODO: i18n
            ),
            backgroundColor: Colors.black,
          );
        }

        final isReceiver = data['isReceiver'] == true;
        final displayName = data['displayName'] ?? ''; // Utilise le nom chargé

        // Navigue vers LoveScreen. On ne passe PLUS deviceId.
        // LoveScreen devra accéder à l'UID via FirebaseAuth.instance.currentUser.
        return LoveScreen(
          // deviceId: deviceId, // <-- SUPPRIMÉ
          deviceLang: deviceLang, // La langue est toujours passée
          isReceiver: isReceiver, // Passe la propriété chargée depuis Firestore
          displayName: displayName, // Passe le nom chargé depuis Firestore
        );
      },
    );
  }
}
// 📄 FIN de lib/screens/home_selector.dart
