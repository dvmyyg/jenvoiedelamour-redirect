// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/edit_recipient_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Permet d'éditer les détails (nom d'affichage, icône, relation) d'un destinataire spécifique.
// ✅ S'appuie sur FirebaseAuth.instance.currentUser pour l'UID de l'utilisateur actuel.
// ✅ Utilise l'UID du destinataire (via Recipient.id) pour accéder au document correct dans Firestore (users/{userId}/recipients/{recipient.id}).
// ✅ Sauvegarde les changements dans Firestore (mise à jour du document destinataire pour l'utilisateur actuel).
// ✅ Permet de partager le lien d'appairage (qui contient l'UID de l'utilisateur actuel).
// ✅ Utilise les contrôleurs de texte et un formulaire pour la saisie.
// ✅ Gère la navigation de retour vers RecipientsScreen avec indication de modification.
// ✅ Textes traduits dynamiquement via getUILabel (i18n_service).
// ✅ N'utilise plus deviceId pour l'identification ou la logique.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V006 - Code examiné par Gemini. Logique d'édition et de sauvegarde basée sur l'UID Firebase confirmée comme fonctionnelle. Partage du lien d'appairage (lien général de l'utilisateur actuel) confirmé. - 2025/05/31
// V005 - Refactoring : Remplacement de deviceId par l'UID Firebase de l'utilisateur actuel pour l'accès Firestore (users/{userId}/recipients/{recipient.id}).
//      - Utilisation de l'UID du destinataire (stocké dans recipient.id) comme ID de document.
//      - Suppression du paramètre deviceId. Accès à l'UID via FirebaseAuth.
//      - Adaptation de la fonction de partage de lien pour utiliser l'UID de l'utilisateur actuel et l'UID du destinataire. - 2025/05/29
// V004 - intégration AppBar + bouton d’envoi - 2025/05/24 16h00 (Historique hérité)
// V003 - suppression du bloc contact, refonte UI - 2025/05/23 18h20 (Historique hérité)
// V002 - ajout navigation depuis RecipientScreen - 2025/05/22 12h30 (Historique hérité)
// V001 - création écran fiche destinataire - 2025/05/21 (Historique hérité)
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/31 // Mise à jour le 31/05

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
import 'package:share_plus/share_plus.dart';
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé (avec UID)
import '../services/i18n_service.dart';

// On supprime les imports non utilisés ou non pertinents ici
// import 'package:uuid/uuid.dart'; // Non utilisé dans cet écran


class EditRecipientScreen extends StatefulWidget {
  // Le deviceId n'est plus requis. L'identifiant de l'utilisateur actuel est son UID.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente
  // Le destinataire contient maintenant l'UID de l'autre utilisateur dans son champ 'id'.
  final Recipient recipient;

  const EditRecipientScreen({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang,
    required this.recipient, // Assurez-vous que cet objet Recipient a l'UID correct dans son champ 'id'
  });

  @override
  State<EditRecipientScreen> createState() => _EditRecipientScreenState();
}

class _EditRecipientScreenState extends State<EditRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _iconController;
  late String _selectedRelationKey;

  // La liste des clés de relation semble correcte et indépendante des identifiants.
  final List<String> relationKeys = [
    'compagne',
    'compagnon',
    'enfant',
    'maman',
    'papa',
    'ami',
    'autre',
  ];

  @override
  void initState() {
    super.initState();
    // Initialise les contrôleurs avec les données actuelles du destinataire.
    // Le modèle Recipient refactorisé est utilisé ici.
    _displayNameController = TextEditingController(
      text: widget.recipient.displayName,
    );
    _iconController = TextEditingController(text: widget.recipient.icon);
    _selectedRelationKey = widget.recipient.relation;
  }

  // Libère les contrôleurs lorsqu'ils ne sont plus nécessaires.
  @override
  void dispose() {
    _displayNameController.dispose();
    _iconController.dispose();
    super.dispose();
  }


  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Obtenir l'UID de l'utilisateur actuellement connecté
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté (ne devrait pas arriver si main.dart redirige correctement)
      debugPrint("Erreur : Impossible de sauvegarder les changements, utilisateur non connecté."); // Utilisation de debugPrint ou debugLog
      // TODO: Afficher un message à l'utilisateur ?
      return;
    }

    // Construire la référence du document Destinataire en utilisant les UID
    // Chemin : users/{currentUserId}/recipients/{recipientUserId}
    final docRef = FirebaseFirestore.instance
        .collection('users') // Nouvelle collection de premier niveau basée sur l'utilisateur
        .doc(user.uid) // Document de l'utilisateur actuel (son UID)
        .collection('recipients') // Sous-collection des destinataires
        .doc(widget.recipient.id); // ID du document est l'UID du destinataire (stocké dans recipient.id)


    // Les données à mettre à jour utilisent les valeurs des contrôleurs.
    // Le modèle Recipient refactorisé n'a plus le champ deviceId dans son toMap(), ce qui est correct.
    // On peut utiliser update() car le document recipient doit déjà exister (créé lors de l'appairage).
    await docRef.update({
      'displayName': _displayNameController.text.trim(),
      'relation': _selectedRelationKey,
      'icon': _iconController.text.trim(),
      // On ne met PLUS à jour le champ 'deviceId' ici car il n'existe plus dans le modèle/Firestore
    });

    // TODO: Optionnel : Mettre à jour également le nom du destinataire dans la collection miroir
    // chez l'autre utilisateur, si vous voulez que le nom change pour les deux.
    // Cela nécessiterait un accès à l'UID de l'autre utilisateur (widget.recipient.id) et à son document 'recipients'
    // Chemin miroir : users/{recipient.id}/recipients/{user.uid}
    // await FirebaseFirestore.instance
    //     .collection('users').doc(widget.recipient.id)
    //     .collection('recipients').doc(user.uid)
    //     .update({'displayName': _displayNameController.text.trim()});
    // C'est une logique bidirectionnelle pour l'édition du nom qui peut être ajoutée si nécessaire.


    if (!mounted) return;
    // Revenir à l'écran précédent (RecipientsScreen)
    Navigator.pop(context, true); // Passer 'true' pour indiquer qu'une modification a eu lieu, pour potentiellement rafraîchir la liste
  }

  // Cette fonction pour partager le lien est similaire à AddRecipientScreen, mais on partage
  // potentiellement l'info sur cet appairage spécifique ? Ou juste un lien général d'invitation ?
  // L'implémentation actuelle semble partager un lien générique pour s'appairer avec *moi*.
  // Si l'objectif est de partager un lien pour cet appairage SPÉCIFIQUE, la logique devrait être différente.
  // Si c'est juste pour partager SON lien d'invitation (qui contient SON UID), alors c'est la même logique que AddRecipientScreen.
  // Supposons que c'est le lien général pour s'appairer avec l'utilisateur actuel (celui qui édite).
  void _sharePairingLink() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("Erreur : Impossible de générer le lien d'appairage (édition), utilisateur non connecté.");
      return;
    }

    // Le lien contient l'UID de l'utilisateur ACTUEL (celui qui utilise l'app)
    final inviteLink = "https://dvmyyg.github.io/jenvoiedelamour-redirect/?recipient=${user.uid}";

    Share.share(
      // TODO: Utiliser getUILabel pour le message du lien
      '${getUILabel('pairing_link_message', widget.deviceLang)}\n$inviteLink',
      subject: getUILabel('pairing_link_subject', widget.deviceLang),
    );



    // On ne sort PAS forcément de l'écran après avoir partagé depuis l'écran d'édition.
  }

  @override
  Widget build(BuildContext context) {
    // L'UI du formulaire d'édition reste similaire, mais les actions (sauvegarde, partage)
    // utilisent maintenant l'UID Firebase.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('edit_recipient_title', widget.deviceLang)), // Utilise i18n_service
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Utilise les méthodes de build locales (conservées car le formulaire d'édition est conservé)
              _buildTextField('display_name_label', _displayNameController), // Utilise i18n_service
              _buildRelationDropdown(), // Utilise i18n_service
              _buildTextField('icon_hint', _iconController), // Utilise i18n_service
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveChanges, // Appelle la logique de sauvegarde refactorisée
                icon: const Icon(Icons.check),
                label: Text(getUILabel('save_changes_button', widget.deviceLang)), // Utilise i18n_service
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _sharePairingLink, // Appelle la logique de partage refactorisée (lien général)
                icon: const Icon(Icons.link),
                label: Text(getUILabel('share_pairing_link', widget.deviceLang)), // Utilise i18n_service
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // Couleur différente pour distinguer de la sauvegarde
                  foregroundColor: Colors.white,
                ),
              ),
              // TODO: Potentiellement ajouter un bouton de suppression du destinataire ici aussi,
              // qui appellerait le deleteRecipient du RecipientService avec l'UID du destinataire.
            ],
          ),
        ),
      ),
    );
  }

  // Méthode locale pour construire un champ de texte (conservée car le formulaire est conservé)
  Widget _buildTextField(String labelKey, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: getUILabel(labelKey, widget.deviceLang), // Utilise i18n_service
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),
          ),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? getUILabel('required_field', widget.deviceLang) : null, // Utilise i18n_service
      ),
    );
  }

  // Méthode locale pour construire le Dropdown de relation (conservée car le formulaire est conservé)
  Widget _buildRelationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedRelationKey,
        items: relationKeys.map((key) {
          return DropdownMenuItem(
            value: key,
            child: Text(getUILabel(key, widget.deviceLang)), // Utilise i18n_service
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedRelationKey = val);
          }
        },
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: getUILabel('relation_label', widget.deviceLang), // Utilise i18n_service
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),
          ),
        ),
      ),
    );
  }
}
