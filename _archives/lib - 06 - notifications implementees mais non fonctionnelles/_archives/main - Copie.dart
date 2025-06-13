// -------------------------------------------------------------
// 📄 lib/main.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Point d'entrée principal de l'application Flutter.
// ✅ Initialise Firebase et gère l'état d'authentification initial.
// ✅ Détermine l'écran initial affiché à l'utilisateur (Login, Email Verification, HomeSelector).
// ✅ Gère les deep links d'appairage via app_links et déclenche la fonction d'appairage.
// ✅ Contient la logique de la fonction d'appairage bilatéral 'pairUsers' (basée sur UID).
// ✅ Gère la langue de l'appareil.
// ✅ Configure la gestion des messages FCM en arrière-plan.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V006 - Correction des appels internes à la fonction 'pairUsers' (anciennement _pairUsers) après son renommage et sa publicisation. - 2025/05/30
// V005 - Correction des avertissements 'unused_import' et 'local_variable_starts_with_underscore'. - 2025/05/30
// V004 - Refonte majeure : Remplacement de la logique basée sur deviceId par l'UID Firebase pour l'identification utilisateur globale et la navigation initiale.
//      - Suppression de getDeviceId, registerDevice.
//      - Suppression du paramètre deviceId partout où il n'est plus pertinent.
//      - Mise à jour des paramètres passés aux écrans (utilisation de userId/uid au lieu de deviceId).
//      - Adaptation de la gestion des deep links (_pairWith) pour extraire les UID et utiliser la nouvelle structure Firestore (users/{uid}/recipients).
//      - La logique _pairWith suppose maintenant que l'utilisateur RECEVANT le lien est déjà connecté pour obtenir son UID.
//      - Adaptation de PairSuccessScreen pour potentiellement afficher l'UID du destinataire appairé (via deep link).
//      - Simplification du flux d'initialisation en attendant l'état Firebase Auth avant de décider de l'écran initial. - 2025/05/29
// V003 - Remplacement de la logique basée sur deviceId par l'UID Firebase... (Description précédente incomplète)
// V002 - ajout import cloud_firestore pour FirebaseFirestore & SetOptions - 2025/05/24 10h31 (Historique hérité de LoginScreen / RegisterScreen)
// V001 - version initiale (Historique hérité)
// -------------------------------------------------------------

// GEM - Code corrigé par Gémini le 2025/05/30 // Mise à jour le 30/05

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Essentiel pour l'authentification basée sur l'utilisateur
import 'package:app_links/app_links.dart'; // Reste pour gérer les deep links
import 'dart:ui'; // Nécessaire pour PlatformDispatcher.instance.locale
import 'dart:async';

// On importe les écrans principaux. Ils devront maintenant gérer l'UID via FirebaseAuth.currentUser
// ou le recevoir en paramètre si l'action concerne un autre utilisateur.
import 'screens/home_selector.dart';
import 'screens/login_screen.dart'; // Écran de connexion pour les utilisateurs non connectés
import 'screens/email_verification_screen.dart'; // Écran de vérification pour les nouveaux comptes
// import 'screens/recipients_screen.dart'; // Pour potentiellement afficher le succès de l'appairage

// On supprime l'import de l'ancien device_service.dart car on n'utilise plus getDeviceId
// import 'services/device_service.dart'; // <-- SUPPRIMÉ
// On supprime l'import de firestore_service pour l'ancienne fonction registerDevice
// import 'services/firestore_service.dart'; // <-- SUPPRIMÉ (car registerDevice est supprimé ou déplacé)

import 'firebase_options.dart';
import 'utils/debug_log.dart'; // Votre utilitaire de log

// Gestion des messages FCM en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Assurer que Firebase est initialisé, car cette fonction peut s'exécuter en dehors du contexte principal
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugLog("🖙 [FCM-BG] Message reçu en arrière-plan : ${message.messageId}", level: 'INFO');
  // TODO: Ajouter ici la logique de gestion de la notification si nécessaire (ex: sauvegarder dans Firestore, afficher une notification locale, etc.)
}

// Capture et gestion des liens d'appairage via app_links.
// Cette fonction suppose maintenant que l'utilisateur est CONNECTÉ lorsqu'il clique sur un lien d'appairage.
// Le lien devrait contenir l'UID Firebase de l'inviteur ('recipient' est l'inviteur).
Future<String?> handleAppLinks() async {
  final AppLinks appLinks = AppLinks();

  // Écoute des liens d'appairage à chaud pendant que l'app est ouverte
  appLinks.uriLinkStream.listen((Uri? uri) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && uri != null && uri.queryParameters.containsKey('recipient')) {
      final String? recipientInviterUid = uri.queryParameters['recipient']; // C'est l'UID de l'inviteur
      if (recipientInviterUid != null && recipientInviterUid.isNotEmpty && currentUser.uid != recipientInviterUid) {
        debugLog("📨 AppLink (stream) → Inviteur UID=$recipientInviterUid", level: 'INFO');
        // Tente d'appairer cet utilisateur (currentUser.uid) avec l'inviteur (recipientInviterUid)
        final String? pairedWithUid = await pairUsers(recipientInviterUid, currentUser.uid);
        if (pairedWithUid != null) {
          debugLog("✅ Appairage stream réussi avec UID $pairedWithUid", level: 'SUCCESS');
          // TODO: Potentiellement naviguer vers l'écran de succès ou rafraîchir la liste des destinataires
        }
      } else {
        debugLog("⚠️ AppLink stream reçu mais utilisateur non connecté, ou lien invalide, ou auto-appairage.", level: 'WARNING');
      }
    }
  });

  // Vérification d'un lien d'appairage initial lors du démarrage de l'app
  final Uri? initialUri = await appLinks.getInitialAppLink();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && initialUri != null && initialUri.queryParameters.containsKey('recipient')) {
    final String? recipientInviterUid = initialUri.queryParameters['recipient']; // C'est l'UID de l'inviteur
    if (recipientInviterUid != null && recipientInviterUid.isNotEmpty && currentUser.uid != recipientInviterUid) {
      debugLog("📨 AppLink (initial) → Inviteur UID=$recipientInviterUid", level: 'INFO');
      // Tente d'appairer cet utilisateur (currentUser.uid) avec l'inviteur (recipientInviterUid)
      final String? pairedWithUid = await pairUsers(recipientInviterUid, currentUser.uid);
      if (pairedWithUid != null) {
        debugLog("✅ Appairage initial réussi avec UID $pairedWithUid", level: 'SUCCESS');
        return pairedWithUid; // Retourne l'UID du destinataire appairé pour affichage initial
      }
    } else {
      debugLog("⚠️ AppLink initial reçu mais utilisateur non connecté, ou lien invalide, ou auto-appairage.", level: 'WARNING');
    }
  }

  return null; // Aucun appairage initial via lien
}

// Fonction d'appairage bilatéral entre deux utilisateurs (identifiés par UID)
// Met à jour les collections 'recipients' sous les UID des deux utilisateurs dans Firestore.
// userAId est l'UID de l'utilisateur qui a partagé le lien (l'inviteur)
// userBId est l'UID de l'utilisateur qui a cliqué sur le lien (l'invité, l'utilisateur actuel)
Future<String?> pairUsers(String userAId, String userBId) async {
  if (userAId.isEmpty || userBId.isEmpty || userAId == userBId) {
    debugLog("⚠️ Appairage tenté avec UID(s) invalide(s) ou auto-appairage.", level: 'WARN');
    return null;
  }
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Récupérer les noms d'affichage des deux utilisateurs pour les mettre dans les objets Recipient
    final userASnap = await firestore.collection('users').doc(userAId).get();
    final userADisplayName = userASnap.data()?['firstName'] ?? 'Utilisateur A'; // Default name
    final userBSnap = await firestore.collection('users').doc(userBId).get();
    final userBDisplayName = userBSnap.data()?['firstName'] ?? 'Utilisateur B'; // Default name


    // 1. Ajouter l'utilisateur B comme destinataire chez l'utilisateur A
    // Chemin : users/{userAId}/recipients/{userBId}
    await firestore
        .collection('users')
        .doc(userAId)
        .collection('recipients')
        .doc(userBId) // ID du document est l'UID de l'autre utilisateur
        .set({
      'id': userBId, // Inclure l'UID aussi comme champ pour faciliter les requêtes futures si besoin
      'displayName': userBDisplayName, // Le nom de l'utilisateur B vu par A
      'icon': '💌', // Icône par défaut
      'relation': 'relation_partner', // Relation par défaut
      'allowedPacks': [], // Packs par défaut
      'paired': true, // Marqué comme appairé
      'catalogType': 'partner', // Type de catalogue par défaut
      'createdAt': FieldValue.serverTimestamp(), // Horodatage de création
    }, SetOptions(merge: true)); // Utilise merge pour ne pas écraser d'autres champs si le doc existe déjà

    // 2. Ajouter l'utilisateur A comme destinataire chez l'utilisateur B
    // Chemin : users/{userBId}/recipients/{userAId}
    await firestore
        .collection('users')
        .doc(userBId)
        .collection('recipients')
        .doc(userAId) // ID du document est l'UID de l'autre utilisateur
        .set({
      'id': userAId, // Inclure l'UID aussi comme champ
      'displayName': userADisplayName, // Le nom de l'utilisateur A vu par B
      'icon': '💌', // Icône par défaut
      'relation': 'relation_partner', // Relation par défaut
      'allowedPacks': [], // Packs par défaut
      'paired': true, // Marqué comme appairé
      'catalogType': 'partner', // Type de catalogue par défaut
      'createdAt': FieldValue.serverTimestamp(), // Horodatage de création
    }, SetOptions(merge: true));

    debugLog("✅ Appairage réussi entre UID $userAId et UID $userBId", level: 'SUCCESS');
    return userAId; // Retourne l'UID de l'inviteur pour confirmation
  } catch (e) {
    debugLog("❌ Erreur d’appairage Firestore entre $userAId et $userBId : $e", level: 'ERROR');
    // TODO: Gérer cette erreur (afficher message à l'utilisateur ?)
    return null;
  }
} // <-- Fin de la fonction _pairUsers

// TODO: Cette variable 'isReceiver' semble être une propriété de l'utilisateur plutôt que globale.
// Elle devrait probablement être stockée dans le document users/{uid} et gérée par une fonction dans firestore_service.
// Pour l'instant, on la laisse comme une constante locale mais il faudra la reconsidérer.
const bool isReceiver = true; // TODO: Cette variable est-elle toujours pertinente au niveau global ou devrait-elle être stockée par utilisateur ?

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase (important avant d'utiliser Firebase Auth ou Firestore)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugLog("✨ Firebase initialisé", level: 'INFO');

  // Attendre que Firebase Auth récupère l'état de connexion persistant
  // Cela évite d'afficher l'écran de connexion brièvement si l'utilisateur est déjà connecté.
  await FirebaseAuth.instance.authStateChanges().first;
  debugLog("👤 État d'auth Firebase synchronisé", level: 'INFO');

  // On ne génère PLUS de deviceId ici et on ne le passe PLUS à MyApp.
  // L'identifiant est l'UID de l'utilisateur Firebase, accessible via FirebaseAuth.instance.currentUser?.uid.
  // final deviceId = await getDeviceId(); // <-- SUPPRIMÉ

  // La langue du téléphone reste utile pour l'internationalisation et peut être récupérée indépendamment de l'identifiant utilisateur.
    final String deviceLang = PlatformDispatcher.instance.locale.languageCode; // La langue reste importante

  // On ne loggue PLUS le deviceId comme identifiant principal ici
  debugLog("🌐 Langue du téléphone : $deviceLang", level: 'INFO');
  // debugLog("🔖 Device ID : $deviceId", level: 'INFO'); // <-- SUPPRIMÉ

  // On n'appelle PLUS registerDevice ici car on utilise l'UID Firebase
  // await registerDevice(deviceId, isReceiver); // <-- SUPPRIMÉ

  // Configurer la gestion des messages FCM en arrière-plan dès que possible
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // TODO: Gérer la sauvegarde/mise à jour du token FCM. Le token est lié à l'installation de l'appli sur cet appareil,
  // mais il est généralement utile de l'associer à l'UID de l'utilisateur *connecté* pour pouvoir lui envoyer des notifications ciblées sur CET appareil.
  // Cela nécessiterait une fonction dans un service (ex: FirestoreService ou un nouveau service FCM)
  // qui prendrait l'UID de l'utilisateur actuel et le token FCM et l'enregistrerait dans Firestore
  // (par exemple, sous users/{uid}/fcmTokens/{thisDeviceToken}).
  // final token = await FirebaseMessaging.instance.getToken();
  // debugLog("🪪 FCM Token: $token", level: 'INFO');
  // Si l'utilisateur est connecté à ce point (après authStateChanges().first), on peut tenter de sauvegarder le token :
  // final User? currentUser = FirebaseAuth.instance.currentUser;
  // if (currentUser != null && token != null) {
  //   await saveFcmTokenForUser(currentUser.uid, token); // Cette fonction doit être créée.
  // }


  // Gérer les liens d'appairage initiaux (deep links) AVANT de lancer l'UI.
  // handleAppLinks suppose que l'utilisateur est déjà connecté. Si initialPairedRecipientUid n'est pas null,
  // cela signifie qu'un deep link d'appairage a été cliqué ET que l'utilisateur était déjà connecté (ou s'est connecté automatiquement).
  // initialPairedRecipientUid contiendra l'UID de l'inviteur si l'appairage via lien a réussi.
  final String? initialPairedRecipientUid = await handleAppLinks();


  // Lance l'application principale (le widget racine de l'UI).
  // MyApp n'a plus besoin de recevoir le deviceId. Il peut recevoir la langue et l'info sur l'appairage initial.
  runApp(MyApp(
    // deviceId: deviceId, // <-- SUPPRIMÉ du constructeur de MyApp
    deviceLang: deviceLang, // La langue reste pertinente
    // On passe l'UID de l'autre utilisateur si un appairage via deep link a réussi au démarrage
    initialPairSuccessRecipientUid: initialPairedRecipientUid,
  ));
}

// Le widget racine de l'application.
// Utilise StreamBuilder pour écouter l'état d'authentification Firebase et décider quel écran afficher.
class MyApp extends StatefulWidget {
  // Le deviceId n'est plus requis, car l'identité de l'utilisateur est gérée par Firebase Auth.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste un paramètre utile
  // Le paramètre initialPairSuccessRecipientId est maintenant l'UID de l'autre utilisateur
  final String? initialPairSuccessRecipientUid;


  const MyApp({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang,
    this.initialPairSuccessRecipientUid, // Optionnel, utilisé si un appairage initial via lien a eu lieu
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Indicateur pour afficher temporairement l'écran de succès d'appairage si déclenché par un lien au démarrage
  bool _showPairSuccess = false;

  @override
  void initState() {
    super.initState();
    // Si un appairage initial via deep link a réussi (UID de l'autre utilisateur reçu)
    if (widget.initialPairSuccessRecipientUid != null) {
      debugLog("🚀 Déclenchement de l'affichage de l'écran succès appairage pour UID ${widget.initialPairSuccessRecipientUid}", level: 'INFO');
      _showPairSuccess = true;
      // Afficher l'écran de succès pendant quelques secondes, puis masquer
      Timer(const Duration(seconds: 4), () { // Augmenté légèrement le délai pour une meilleure lecture
        if (mounted) {
          debugLog("⏳ Fin de l'affichage de l'écran succès", level: 'INFO');
          setState(() => _showPairSuccess = false);
          // TODO: Potentiellement, après l'écran de succès, naviguer vers l'écran des destinataires
          // ou rafraîchir la liste sur l'écran principal si on y retourne automatiquement.
          // Pour l'instant, masquer l'écran de succès ramène à l'écran déterminé par authStateChanges (HomeSelector si connecté).
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder écoute les changements de l'état d'authentification Firebase (connexion/déconnexion)
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jela', // TODO: Utiliser getUILabel pour le titre de l'app ?
      theme: ThemeData(useMaterial3: true), // TODO: Configurer le thème global ici
      // Utilise le StreamBuilder sur l'état d'authentification pour décider de l'écran de départ
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Le stream qui émet l'utilisateur actuel ou null
        builder: (context, snapshot) {
          // Afficher un indicateur de chargement pendant que l'état d'auth est déterminé
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugLog("⏳ Attente état d'authentification Firebase...", level: 'DEBUG');
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            );
          }

          // Récupérer l'utilisateur connecté (ou null s'il n'y en a pas)
          final User? user = snapshot.data;
          debugLog("👤 État actuel de l'utilisateur : ${user == null ? 'Déconnecté' : 'Connecté (UID: ${user.uid})'}", level: 'INFO');

          // Si un utilisateur est connecté...
          if (user != null) {
            // Vérifier si son email est vérifié
            if (!user.emailVerified) {
              debugLog("🔒 Email non vérifié — Redirection vers EmailVerificationScreen", level: 'WARNING');
              // Rediriger vers l'écran de vérification email.
              // Cet écran n'a plus besoin du deviceId, mais de la langue. L'UID est accessible via FirebaseAuth.currentUser.
              return EmailVerificationScreen(
                // deviceId: widget.deviceId, // <-- SUPPRIMÉ
                deviceLang: widget.deviceLang,
              );
            }

            // Si l'email est vérifié, vérifier si un appairage initial via deep link a eu lieu et a réussi.
            if (_showPairSuccess && widget.initialPairSuccessRecipientUid != null) {
              debugLog("🎉 Affichage temporaire de PairSuccessScreen", level: 'INFO');
              // Afficher l'écran de succès d'appairage.
              // On lui passe l'UID de l'autre utilisateur, pas l'ancien deviceId.
              return PairSuccessScreen(recipientUid: widget.initialPairSuccessRecipientUid!);
            }

            // Si l'utilisateur est connecté, email vérifié, et pas d'écran de succès temporaire :
            // Afficher l'écran principal (HomeSelector).
            // HomeSelector n'a plus besoin du deviceId. Il devra accéder à l'UID via FirebaseAuth.currentUser.
            debugLog("➡️ Redirection vers HomeSelector pour UID ${user.uid}", level: 'INFO');
            return HomeSelector(
              // deviceId: widget.deviceId, // <-- SUPPRIMÉ
              deviceLang: widget.deviceLang,
              // HomeSelector devra charger les données de l'utilisateur connecté (basé sur user.uid)
              // et ses destinataires (basé sur user.uid)
            );

          } else {
            // Si aucun utilisateur n'est connecté :
            // Rediriger vers l'écran de connexion.
            // LoginScreen n'a plus besoin du deviceId, juste de la langue.
            debugLog("➡️ Redirection vers LoginScreen (aucun utilisateur connecté)", level: 'INFO');
            return LoginScreen(
              deviceLang: widget.deviceLang,
              // deviceId: widget.deviceId, // <-- SUPPRIMÉ
              // LoginScreen gérera la connexion et l'inscription via Firebase Auth.
            );
          }
        },
      ),
    );
  } // <-- Fin de la méthode build de _MyAppState
} // <-- Fin de la classe _MyAppState

// Écran temporaire pour montrer le succès de l'appairage via deep link.
// Il affiche maintenant l'UID de l'autre utilisateur.
class PairSuccessScreen extends StatelessWidget {
  // Reçoit l'UID de l'autre utilisateur (l'inviteur) qui a été appairé.
  final String recipientUid; // Renommé de recipientId pour refléter qu'il s'agit de l'UID

  const PairSuccessScreen({super.key, required this.recipientUid});

  @override
  Widget build(BuildContext context) {
    // TODO: Afficher le prénom de l'autre utilisateur au lieu de son UID pour une meilleure expérience.
    // Cela nécessiterait de charger le profil de cet UID depuis Firestore dans ce widget.
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
            // Afficher l'UID de l'autre utilisateur (temporaire, afficher le nom serait mieux)
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

// 📄 FIN de lib/main.dart
