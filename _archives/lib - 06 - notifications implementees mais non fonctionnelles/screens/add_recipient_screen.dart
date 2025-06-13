// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/add_recipient_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Permet à l'utilisateur actuel de générer et partager son lien d'invitation (contenant son UID Firebase).
// ✅ S'appuie sur FirebaseAuth.instance.currentUser pour obtenir l'UID de l'utilisateur actuel.
// ✅ Utilise la librairie share_plus pour l'interface de partage système.
// ✅ UI simplifiée centrée sur le bouton de partage.
// ✅ N'utilise plus deviceId pour l'identification ou la logique.
// ✅ Logique obsolète de création locale de destinataire "en attente" retirée.
// ✅ Message partagé clarifié pour indiquer le processus de copier-coller de l'UID et inclure un lien de téléchargement de l'app (pointant vers l'APK hébergé sur GitHub Pages).
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V009 - Correction du placeholder "YOUR_APP_DOWNLOAD_LINK" dans la fonction _sharePairingLink avec l'URL spécifique de l'APK hébergé sur la page GitHub Pages du projet. - 2025/05/31
//        https://dvmyyg.github.io/jenvoiedelamour-redirect/apk/app-release.apk
// V008 - Nouvelle tentative de correction de la fonction _sharePairingLink pour résoudre l'erreur "named parameter 'placeholders' isn't defined" en utilisant replaceFirst pour l'interpolation des placeholders. Confirmation que le code précédent réintroduisait l'erreur. - 2025/05/31 (Remplacé par V009)
// V007 - Nouvelle tentative de correction de la fonction _sharePairingLink pour résoudre l'erreur "named parameter 'placeholders' isn't defined" en utilisant replaceFirst pour l'interpolation des placeholders. - 2025/05/31 (Remplacé par V008)
// V006 - Modification de la fonction _sharePairingLink pour améliorer le message partagé, en présentant l'UID comme un code à copier et en ajoutant potentiellement un lien de téléchargement de l'app. Code validé. - 2025/05/31 (Erreur de paramètre trouvée ensuite)
// V005 - Discussion sur la simplification du code d'appairage partagé (potentiellement n'envoyer que l'UID au lieu de l'URL complète pour le processus manuel de copier-coller). - 2025/05/31
// V004 - Correction du texte du message partagé pour indiquer le processus de copier-coller manuel, au lieu de cliquer sur le lien. - 2025/05/31
// V003 - Code examiné par Gemini. Logique de génération et partage de lien d'invitation basé sur l'UID Firebase confirmée comme fonctionnelle. Logique obsolète bien retirée. - 2025/05/31
// V002 - Refactoring : Suppression de la logique de création d'un destinataire "en attente" basée sur deviceId.
//      - L'écran se concentre désormais sur la génération et le partage d'un lien d'invitation contenant l'UID Firebase de l'utilisateur actuel.
//      - Suppression du paramètre deviceId. Accès à l'UID via FirebaseAuth.
//      - Utilisation de l'UID dans le lien d'invitation. - 2025/05/29
// V001 - version initiale (basée sur deviceId et création d'un destinataire en attente localement) - 2025/05/21
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/31 // Mise à jour le 31/05


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
  @override
  void initState() {
    super.initState();
    // Si le formulaire et les relations sont supprimés, cette initialisation l'est aussi
    // _selectedRelationKey = relationKeys.first; // <-- POTENTIELLEMENT SUPPRIMÉ
  }

  // Cette fonction génère et partage l'UID Firebase de l'utilisateur actuel.
  // Le message partagé guide l'ami pour copier/coller l'UID et inclut un lien de téléchargement de l'app.
  void _sharePairingLink() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("Erreur : Impossible de générer le lien d'appairage, utilisateur non connecté.");
      return;
    }

    // L'UID de l'utilisateur actuel à inclure dans le message comme code
    final String currentUserId = user.uid;

    // TODO: Obtenir le lien pour télécharger l'application (lien App Store, Google Play, App Distribution, etc.)
    // Cela pourrait être une constante globale, une valeur de config, etc.
    // Remplacez "YOUR_APP_DOWNLOAD_LINK" par le vrai lien !
    final String appDownloadLink = "https://dvmyyg.github.io/jenvoiedelamour-redirect/apk/app-release.apk";


    // Récupère le template de message traduit.
    // Assurez-vous que la clé 'pairing_invitation_message' existe dans vos traductions
    // et qu'elle utilise {uid} et {appLink} comme placeholders.
    final String messageTemplate = getUILabel(
        'pairing_invitation_message',
        widget.deviceLang
    );

    // Construit le message final en insérant l'UID et le lien de téléchargement
    // dans le template. Cette méthode assume que le template utilise '{uid}' et '{appLink}'.
    // Si tes placeholders sont différents (ex: '%1', '%2'), adapte les appels à replaceAll ici.
    String shareMessage = messageTemplate.replaceFirst('{uid}', currentUserId);
    shareMessage = shareMessage.replaceFirst('{appLink}', appDownloadLink);

    // Utilise getUILabel pour le sujet aussi, si ce n'est pas déjà fait
    final String shareSubject = getUILabel('pairing_link_subject', widget.deviceLang);

    Share.share(
      shareMessage, // Utilise le message construit dynamiquement
      subject: shareSubject, // Utilise le sujet traduit
    );

    // Après avoir partagé le lien, on peut sortir de cet écran.
    if (mounted) {
      Navigator.pop(context);
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
// fin du fichier add_recipients_screen.dart
