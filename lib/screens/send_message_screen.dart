// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/send_message_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Permet à l'utilisateur actuel d'envoyer des messages rapides (type 'quick') à un destinataire spécifique.
// ✅ Affiche les types de messages rapides autorisés pour ce destinataire.
// ✅ Utilise les UID Firebase de l'utilisateur actuel et du destinataire pour créer et envoyer le message via MessageService.
// ✅ Gère le retour haptique lors de l'envoi.
// ✅ Affiche un message de succès ou d'erreur après l'envoi.
// ✅ N'utilise plus deviceId pour l'identification ou les opérations d'envoi.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V003 - Ajout de la gestion d'erreurs (try/catch) autour de l'envoi. Vérification de l'utilisateur connecté avant d'envoyer. Utilisation cohérente de debugLog et gestion des SnackBar avec 'mounted'. Ajout d'import uuid. - 2025/05/30
// V002 - Refactoring : Suppression de deviceId. Utilise l'UID du destinataire (via Recipient.id). Remplacement de l'ancienne logique d'envoi par mise à jour de devices/{recipient.deviceId}. Utilise le MessageService refactorisé pour envoyer un message de type rapide dans la sous-collection de messages. Suppression du paramètre deviceId. Obtention de l'UID de l'utilisateur actuel si nécessaire (mais sendMessage du service le gère). - 2025/05/29
// V001 - version initiale (envoi par mise à jour de champ dans devices/{deviceId} du destinataire) - 2025/05/21
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/30 // Mise à jour de la date au 30/05

import '../utils/debug_log.dart'; // Utilise le logger
import 'package:flutter/material.dart';
// On n'a plus besoin d'importer cloud_firestore directement ici car on utilise MessageService.
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- SUPPRIMÉ
import 'package:flutter/services.dart'; // Pour le retour haptique
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé (contient l'UID du destinataire dans .id)
import '../models/message.dart'; // Ajout de l'import du modèle Message
import '../services/i18n_service.dart'; // Pour les traductions (getMessageBody, getUILabel)
import '../services/message_service.dart'; // Utilise le MessageService refactorisé
//import 'package:uuid/uuid.dart'; // Ajout de l'import pour générer l'ID unique du message
//import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout de l'import pour Timestamp (utilisé dans le modèle Message)


class SendMessageScreen extends StatefulWidget {
  // Le deviceId n'est plus requis. L'identifiant de l'utilisateur actuel est son UID Firebase,
  // accessible via FirebaseAuth.instance.currentUser.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente
  // Le destinataire à qui envoyer le message. Son champ 'id' doit contenir l'UID Firebase de l'autre utilisateur.
  final Recipient recipient; // Cet objet Recipient doit avoir l'UID du destinataire dans son champ 'id'

  const SendMessageScreen({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang,
    required this.recipient,
  });

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  // MessageService sera initialisé DANS la méthode sendLove car ses dépendances (les UIDs)
  // sont obtenues au moment de l'envoi.
  // late MessageService _messageService; // <-- Pas d'initialisation ici si fait dans sendLove

  // Stocke l'UID de l'utilisateur actuel une fois obtenu.
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    debugLog("🔄 SendMessageScreen initialisé.", level: 'INFO');
    // Obtenir l'UID de l'utilisateur actuel dès que possible.
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Vérifier si l'utilisateur est connecté
    if (_currentUserId == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté.
      // Cela indique un problème de navigation/flux si on arrive ici sans utilisateur.
      debugLog("⚠️ SendMessageScreen : Utilisateur non connecté. Impossible d'envoyer de message.", level: 'ERROR');
      // L'UI dans build gérera l'affichage d'un message d'erreur.
      // TODO: Potentiellement, naviguer automatiquement vers la page de connexion si cela arrive ici.
    }
  }

  // Gère l'envoi d'un message de type rapide
  Future<void> sendLove(String type) async {
    // Vérification si l'UID de l'expéditeur est disponible.
    final user = FirebaseAuth.instance.currentUser; // Peut aussi utiliser _currentUserId si initialisé en initState
    if (user == null) {
      // Protection supplémentaire si l'UID de l'expéditeur n'est pas disponible
      debugLog("⚠️ [sendLove] Impossible d'envoyer le message : UID de l'utilisateur actuel est null.", level: 'ERROR');
      if (mounted) { // Vérifie si le widget est monté avant d'utiliser context
        ScaffoldMessenger.of(context).showSnackBar( // TODO: Utiliser i18n_service pour ce message
          SnackBar(content: Text("Erreur: Vous devez être connecté pour envoyer un message.")),
        );
      }
      return;
    }
    final String currentUserId = user.uid; // UID de l'expéditeur

    // L'UID du destinataire est stocké dans recipient.id (modèle Recipient refactorisé)
    final String recipientUserId = widget.recipient.id;

    // Vérifier si le destinataire est appairé (important avant d'envoyer)
    // Cette vérification est faite au niveau de l'UI/Business logic ici.
    // Vous pourriez aussi ajouter une vérification dans le MessageService,
    // ou vous appuyer sur les règles de sécurité Firestore (qui devraient empêcher l'écriture
    // si les destinataires ne sont pas appairés dans les collections respectives).
    if (!widget.recipient.paired) {
      debugLog("⚠️ [sendLove] Envoi annulé : destinataire '${widget.recipient.displayName}' (UID: $recipientUserId) non appairé", level: 'WARN');
      if (mounted) { // Vérifie si le widget est monté
        ScaffoldMessenger.of(context).showSnackBar( // TODO: Utiliser i18n_service pour ce message
          SnackBar(content: Text("Impossible d'envoyer un message: Destinataire non appairé.")),
        );
      }
      return;
    }


    // --- Nouvelle logique d'envoi utilisant MessageService refactorisé ---
    debugLog(
      "📤 [sendLove] Tentative d'envoi d'un message de type '$type' de UID $currentUserId vers UID $recipientUserId",
      level: 'INFO',
    );

    try {
      HapticFeedback.mediumImpact(); // retour haptique

      // Créer un objet Message en utilisant le modèle Message refactorisé
      // L'ID du message est généré localement (UUID).
      // Les champs 'from' et 'to' contiennent les UID Firebase.
      // Utilise getMessageBody pour le contenu basé sur le type.
      final msg = Message.quick( // Utilise la factory quick
        from: currentUserId,   // UID de l'expéditeur (utilisateur actuel)
        to: recipientUserId,   // UID du destinataire
        content: getMessageBody(type, widget.deviceLang), // Utilise i18n_service pour le contenu
        // La factory quick fixe le type à 'quick'. Si vous voulez utiliser le type 'type' passé en param,
        // vous devriez utiliser le constructeur Message(...) au lieu de la factory quick.
        // Ex:
        // final msg = Message(
        //   id: const Uuid().v4(),
        //   from: currentUserId,
        //   to: recipientUserId,
        //   type: type, // Utilise le type passé
        //   content: getMessageBody(type, widget.deviceLang),
        //   sentAt: Timestamp.now(),
        // );
      );

      // Initialiser MessageService AVEC les UIDs corrects pour CET envoi.
      // On le fait ici car il est utilisé seulement dans cette méthode.
      final messageService = MessageService(currentUserId: currentUserId, recipientUserId: recipientUserId);


      // Appelle la méthode sendMessage du MessageService refactorisé.
      // Ce service gère l'écriture bidirectionnelle atomique dans Firestore.
      await messageService.sendMessage(msg); // Attend la fin de l'envoi

      debugLog(
        "✅ [sendLove] Message de type '${msg.type}' envoyé avec succès à UID $recipientUserId", // Log le type réel du message envoyé (quick)
        level: 'SUCCESS',
      );

      // Afficher un message de succès à l'utilisateur SEULEMENT si l'envoi a réussi
      if (mounted) { // Vérifie si le widget est monté
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getUILabel('message_sent', widget.deviceLang))), // Utilise i18n_service
        );

        // Revenir à l'écran précédent après l'envoi réussi
        Navigator.pop(context);
      }


    } on FirebaseException catch (e) {
      // Gérer les erreurs spécifiques à Firebase
      debugLog("❌ [sendLove] Erreur Firebase lors de l'envoi : ${e.code} - ${e.message}", level: 'ERROR');
      if (mounted) { // Vérifie si le widget est monté
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${getUILabel('message_send_error', widget.deviceLang)} : ${e.message}"), // Utilise i18n_service et le message de l'erreur
          ),
        );
      }
      // Ne rethrow pas car l'erreur est gérée et affichée
    } catch (e) {
      // Gérer toute autre erreur inattendue
      debugLog("❌ [sendLove] Erreur inattendue lors de l'envoi : $e", level: 'ERROR');
      if (mounted) { // Vérifie si le widget est monté
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${getUILabel('message_send_error_unexpected', widget.deviceLang)} : $e"), // TODO: Add key for unexpected error
          ),
        );
      }
      // Ne rethrow pas
    }
  }

  @override
  Widget build(BuildContext context) {
    // L'UI affiche une liste de boutons (un par type de message rapide) pour le destinataire.
    // Elle utilise les données du modèle Recipient refactorisé (allowedPacks).
    final allowedMessages = widget.recipient.allowedPacks;

    // Afficher un message si l'utilisateur actuel n'est pas identifié (bien que main.dart le gère normalement)
    if (_currentUserId == null) {
      debugLog("⚠️ SendMessageScreen build : _currentUserId est null. Affichage de l'écran d'erreur.", level: 'ERROR');
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("💌 ${widget.recipient.displayName}"), // Peut-être un titre générique ici
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          // TODO: Utiliser i18n_service pour ce message
          child: Text("Erreur : Impossible de charger l'écran d'envoi sans utilisateur identifié.", style: TextStyle(color: Colors.red)),
        ),
      );
    }


    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("💌 ${widget.recipient.displayName}"), // Affiche le nom du destinataire (du modèle Recipient)
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: allowedMessages.isEmpty // Afficher un message s'il n'y a pas de types de messages autorisés
          ? Center(
        child: Text(
          getUILabel('no_message_packs_allowed', widget.deviceLang), // TODO: Add this key
          style: const TextStyle(color: Colors.white70, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.separated( // Affiche la liste des types de messages autorisés
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        itemCount: allowedMessages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final messageType = allowedMessages[index];
          // Utilise getPreviewText pour obtenir le texte du bouton (ex: l'émoticône ❤️)
          final previewText = getPreviewText(messageType, widget.deviceLang); // Utilise i18n_service


          return GestureDetector(
            // Désactiver le bouton si l'utilisateur n'est pas connecté
            onTap: _currentUserId == null ? null : () => sendLove(messageType), // Appelle la méthode d'envoi refactorisée
            child: Container(
              height: 90,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _currentUserId == null ? Colors.grey : Colors.pink, // Couleur du bouton désactivé/activé
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  previewText,
                  style: TextStyle(
                      fontSize: 22,
                      color: _currentUserId == null ? Colors.white70 : Colors.white // Couleur du texte désactivé/activé
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
// 📄 FIN de lib/screens/send_message_screen.dart
