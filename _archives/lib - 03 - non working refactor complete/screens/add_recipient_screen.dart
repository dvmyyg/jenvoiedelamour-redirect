//  lib/screens/add_recipient_screen.dart

// Historique du fichier
// V002 - Refactoring : Suppression de la logique de création d'un destinataire "en attente" basée sur deviceId.
//      - L'écran se concentre désormais sur la génération et le partage d'un lien d'invitation contenant l'UID Firebase de l'utilisateur actuel.
//      - Suppression du paramètre deviceId. Accès à l'UID via FirebaseAuth.
//      - Utilisation de l'UID dans le lien d'invitation. - 2025/05/29
// V001 - version initiale (basée sur deviceId et création d'un destinataire en attente localement) - 2025/05/21

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
import 'package:share_plus/share_plus.dart';
import '../services/i18n_service.dart';

// On supprime les imports qui ne sont plus utilisés
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- SUPPRIMÉ
// import 'package:uuid/uuid.dart'; // <-- SUPPRIMÉ

class AddRecipientScreen extends StatefulWidget {
  // Le deviceId n'est plus pertinent ici. L'écran n'a pas besoin de l'ID de l'appareil.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente

  const AddRecipientScreen({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang,
  });

  @override
  State<AddRecipientScreen> createState() => _AddRecipientScreenState();
}

class _AddRecipientScreenState extends State<AddRecipientScreen> {
  // Les contrôleurs de texte ne sont plus nécessaires si on ne crée pas un destinataire localement ici
  // final _formKey = GlobalKey<FormState>(); // <-- POTENTIELLEMENT SUPPRIMÉ si le formulaire n'est plus utilisé
  // final _displayNameController = TextEditingController(); // <-- POTENTIELLEMENT SUPPRIMÉ
  // final _iconController = TextEditingController(); // <-- POTENTIELLEMENT SUPPRIMÉ

  // Les listes de relations et le champ sélectionné pourraient être supprimés si le formulaire est retiré
  /*
  final List<String> relationKeys = [ // <-- POTENTIELLEMENT SUPPRIMÉ
    'compagne',
    'compagnon',
    'enfant',
    'maman',
    'papa',
    'ami',
    'autre',
  ];
  late String _selectedRelationKey; // <-- POTENTIELLEMENT SUPPRIMÉ
  */


  @override
  void initState() {
    super.initState();
    // Si le formulaire et les relations sont supprimés, cette initialisation l'est aussi
    // _selectedRelationKey = relationKeys.first; // <-- POTENTIELLEMENT SUPPRIMÉ
  }

  // La méthode capitalize n'est plus nécessaire si on ne gère pas l'affichage du nom ici
  /*
  String capitalize(String input) { // <-- POTENTIELLEMENT SUPPRIMÉ
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
  */

  // La logique de sauvegarde d'un destinataire "en attente" est supprimée.
  // L'appairage crée le destinataire directement via _pairUsers dans main.dart.
  /*
  Future<void> _saveRecipient() async { // <-- SUPPRIMÉ
    if (!_formKey.currentState!.validate()) return;

    final displayName = capitalize(_displayNameController.text.trim());
    final icon = _iconController.text.trim();
    final relation = _selectedRelationKey;

    final id = const Uuid().v4(); // <-- ID local généré, obsolète

    // Chemin Firestore basé sur deviceId, obsolète
    final docRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId) // <-- deviceId obsolète
        .collection('recipients')
        .doc(id);

    // Écriture Firestore, obsolète
    await docRef.set({
      'id': id,
      'displayName': displayName,
      'relation': relation,
      'icon': icon,
      'deviceId': null, // Marqué comme non appairé
    });

    if (!mounted) return;
    _sharePairingLink(id); // Partage l'ID local, obsolète
    Navigator.pop(context, true);
  }
  */

  // Cette fonction est modifiée pour partager l'UID Firebase de l'utilisateur actuel.
  void _sharePairingLink() { // Ne prend plus d'ID local en paramètre
    // Obtenir l'UID de l'utilisateur actuellement connecté
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté (ne devrait pas arriver si main.dart redirige correctement)
      debugPrint("Erreur : Impossible de générer le lien d'appairage, utilisateur non connecté."); // Utilisation de debugPrint ou debugLog
      return;
    }

    // Utiliser l'UID de l'utilisateur actuel dans le lien
    // Le paramètre 'recipient' du lien contiendra maintenant l'UID de l'inviteur
    final inviteLink = "https://dvmyyg.github.io/jenvoiedelamour-redirect/?recipient=${user.uid}";

    Share.share(
      // TODO: Utiliser getUILabel pour le message du lien
      '💌 Clique ici pour t’appairer avec moi dans l’app J’envoie de l’amour :\n$inviteLink',
      subject: getUILabel('pairing_link_subject', widget.deviceLang), // Utilise i18n_service
    );

    // Après avoir partagé le lien, on peut sortir de cet écran.
    if (mounted) {
      Navigator.pop(context); // On sort après le partage
    }
  }


  @override
  Widget build(BuildContext context) {
    // L'UI est simplifiée pour se concentrer sur le partage du lien
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('add_recipient_title', widget.deviceLang)), // Utilise i18n_service
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center( // Centre le bouton de partage
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centre verticalement
            children: [
              // Le formulaire de nom/icône/relation est potentiellement supprimé.
              // On affiche juste un bouton pour partager le lien d'appairage.
              Text(
                getUILabel('share_pairing_link_explanation', widget.deviceLang), // TODO: Ajouter cette clé de traduction pour expliquer comment ça marche
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                // onPressed appelle maintenant la fonction _sharePairingLink modifiée
                onPressed: _sharePairingLink,
                icon: const Icon(Icons.share), // Icône de partage plus appropriée
                label: Text(getUILabel('share_pairing_link', widget.deviceLang)), // Utilise i18n_service
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Agrandir le bouton
                  textStyle: const TextStyle(fontSize: 18), // Augmenter la taille du texte
                ),
              ),

              // TODO: Ajouter ici potentiellement un bouton "Valider un code d'invitation"
              // qui ouvrirait la boîte de dialogue que nous avons vue dans RecipientsScreen.
              // Cette boîte de dialogue devrait être adaptée pour accepter un code temporaire
              // et utiliser _pairUsers avec l'UID de l'utilisateur actuel et l'UID lié au code.
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // TODO: Implémenter la saisie d'un code d'invitation
                  // _showPasteLinkDialog(); // L'ancienne boîte de dialogue doit être adaptée
                  debugPrint("TODO: Implémenter la saisie d'un code d'invitation");
                },
                child: Text(getUILabel('validate_invite_button', widget.deviceLang)), // Utilise i18n_service
              ),

              // TODO: Si vous gardez le formulaire nom/icône/relation, il faudrait l'ajouter ici.
              // Mais la logique de sauvegarde devra être réévaluée : enregistrer ces préférences
              // soit dans les préférences de l'utilisateur actuel pour les *futurs* appairages,
              // soit mettre à jour le document Recipient *après* l'appairage.
            ],
          ),
        ),
      ),
    );
  }
}
// Les méthodes _buildTextField et _buildRelationDropdown sont potentiellement supprimées
// si le formulaire de nom/icône/relation est retiré de cet écran.
