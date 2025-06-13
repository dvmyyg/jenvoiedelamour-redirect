//  lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Toujours nécessaire pour interagir avec Firestore
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
  final FirestoreService _firestoreService = FirestoreService(); // Initialise le service

  // Variable pour stocker l'UID de l'utilisateur actuel.
  // On pourrait aussi l'obtenir directement dans les méthodes async.
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Obtenir l'UID de l'utilisateur actuel dès que l'écran s'initialise
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (_currentUserId == null) {
      debugLog("⚠️ SettingsScreen : Utilisateur non connecté. Impossible de charger/sauvegarder le profil.", level: 'ERROR');
      // TODO: Gérer ce cas (ex: afficher un message, désactiver les champs, rediriger)
      // Pour l'instant, on continue mais les opérations Firestore échoueront.
    } else {
      _loadDisplayName(); // Charger le nom si l'utilisateur est connecté
    }
  }

  // Charge le nom d'affichage NON PAS depuis le deviceId, mais depuis le document utilisateur via son UID
  Future<void> _loadDisplayName() async {
    if (_currentUserId == null) {
      debugLog("⚠️ _loadDisplayName : _currentUserId est null. Chargement annulé.", level: 'WARN');
      return; // Ne rien faire si l'UID n'est pas disponible
    }

    debugLog("🔄 Chargement du nom d'affichage pour UID: $_currentUserId", level: 'INFO');

    try {
      // Utilise le FirestoreService pour récupérer les données de l'utilisateur par son UID
      final userData = await _firestoreService.getUserProfile(_currentUserId!); // Assurez-vous que _currentUserId n'est pas null ici

      if (userData != null && userData['firstName'] != null) { // Vérifie si le document et le champ firstName existent
        final name = userData['firstName'];
        _nameController.text = name;
        debugLog("✅ Nom d'affichage chargé : $name", level: 'SUCCESS');
      } else {
        debugLog("🔍 Document utilisateur trouvé pour $_currentUserId, mais champ 'firstName' manquant ou vide.", level: 'INFO');
        // Le champ peut être manquant si c'est la première fois que l'utilisateur se connecte ou n'a pas encore défini de nom.
        // Laisse _nameController vide, ce qui est le comportement souhaité.
      }
    } catch (e) {
      debugLog("❌ Erreur lors du chargement du nom d'affichage pour UID $_currentUserId : $e", level: 'ERROR');
      // TODO: Afficher un message d'erreur à l'utilisateur
    }
  }

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Future<void> _saveDisplayName() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      // Optionnel: Afficher un message indiquant que le nom ne peut pas être vide
      debugLog("⚠️ Nom d'affichage vide. Sauvegarde annulée.", level: 'WARN');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUILabel('profile_name_cannot_be_empty', widget.currentLang)), // TODO: Add this key
          ),
        );
      }
      return;
    }

    final name = capitalize(rawName);

    // Obtenir l'UID de l'utilisateur actuel (protection supplémentaire)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugLog("⚠️ Impossible de sauvegarder le nom : Utilisateur non connecté.", level: 'ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // TODO: Use i18n_service
          SnackBar(content: Text("Erreur: Vous devez être connecté pour sauvegarder votre profil.")),
        );
      }
      return;
    }
    final String currentUserId = user.uid; // UID de l'expéditeur

    // --- Ancienne logique de mise à jour devices/{deviceId} ---
    /*
    // 🔁 Mise à jour devices/{deviceId}
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId) // Ancien ID basé sur le device
        .update({'displayName': name}); // Ancien champ dans le document device
    */ // --- Fin ancienne logique obsolète ---

    // 🧠 Nouvelle logique : Mise à jour UNIQUE du profil dans users/{uid} via le service
    debugLog("💾 Sauvegarde du nom d'affichage '$name' pour UID: $currentUserId", level: 'INFO');
    try {
      await _firestoreService.saveUserProfile(
        uid: currentUserId, // Utilise l'UID obtenu de FirebaseAuth
        // On n'a peut-être pas besoin de l'email ici si le service le récupère lui-même ou si firstName suffit
        // email: user.email ?? '', // Laisse ou supprime selon l'implémentation de saveUserProfile
        firstName: name, // Utilise firstName, cohérent avec le chargement
        // Si votre service attend un champ 'displayName' au lieu de 'firstName', ajustez ici.
        // La cohérence est clé entre lecture et écriture. Si Recipient utilise 'displayName', il est
        // probablement préférable d'utiliser 'displayName' dans users/{uid} aussi.
        // Pour l'exemple, je vais utiliser 'firstName' comme dans l'appel original.
        // Assurez-vous que saveUserProfile gère bien ce champ et que getUserProfile lit le même.
      );

      debugLog("✅ Nom d'affichage sauvegardé avec succès.", level: 'SUCCESS');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getUILabel('profile_saved', widget.currentLang)),
        ),
      );

      // Optionnel: Revenir en arrière après la sauvegarde
      // Navigator.pop(context);


    } catch (e) {
      debugLog("❌ Erreur lors de la sauvegarde du nom d'affichage pour UID $currentUserId : $e", level: 'ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${getUILabel('profile_save_error', widget.currentLang)} : $e"), // TODO: Add this key
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Afficher un message ou un indicateur de chargement si _currentUserId n'est pas encore défini
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(getUILabel('profile_title', widget.currentLang)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          // TODO: Use i18n_service for this message
          child: Text("Veuillez vous connecter pour gérer votre profil.", style: TextStyle(color: Colors.red)),
        ),
      );
    }


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
              ),
              style: const TextStyle(color: Colors.white),
              // Optionnel: Désactiver le champ si l'utilisateur n'est pas connecté
              // enabled: _currentUserId != null,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _currentUserId == null ? null : _saveDisplayName, // Désactive le bouton si non connecté
              child: Text(getUILabel('profile_save_button', widget.currentLang)),
            ),
          ],
        ),
      ),
    );
  }
}
