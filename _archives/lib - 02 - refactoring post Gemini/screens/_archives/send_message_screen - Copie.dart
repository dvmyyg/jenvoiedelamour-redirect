//  lib/screens/send_message_screen.dart

// Historique du fichier
// V002 - Refactoring : Suppression de deviceId. Utilise l'UID du destinataire (via Recipient.id).
//      - Remplacement de l'ancienne logique d'envoi par mise à jour de devices/{recipient.deviceId}.
//      - Utilise le MessageService refactorisé pour envoyer un message de type rapide dans la sous-collection de messages.
//      - Suppression du paramètre deviceId. Obtention de l'UID de l'utilisateur actuel si nécessaire (mais sendMessage du service le gère). - 2025/05/29
// V001 - version initiale (envoi par mise à jour de champ dans devices/{deviceId} du destinataire) - 2025/05/21

// GEM - code corrigé par Gémini le 2025/05/29

import '../utils/debug_log.dart';
import 'package:flutter/material.dart';
// On n'a plus besoin de cloud_firestore pour l'écriture directe ici.
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- POTENTIELLEMENT SUPPRIMÉ
import 'package:flutter/services.dart'; // Pour le retour haptique
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé (contient l'UID du destinataire dans .id)
import '../services/i18n_service.dart'; // Pour les traductions
import '../services/message_service.dart'; // Utilise le MessageService refactorisé

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
  // MessageService sera initialisé dans sendLove avec les UID, pas au démarrage de l'écran.
  // Ou on pourrait l'initialiser ici dans initState si on préfère, comme dans RecipientDetailsScreen.
  // Choisissons de l'initialiser dans sendLove car c'est le seul endroit où il est utilisé.
  // late MessageService _messageService; // <-- Pas d'initialisation ici si fait dans sendLove

  // Stocke l'UID de l'utilisateur actuel une fois obtenu.
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Obtenir l'UID de l'utilisateur actuel dès que possible pour l'utiliser dans sendLove.
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (_currentUserId == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté (ne devrait pas arriver ici si main.dart redirige correctement)
      debugLog("⚠️ SendMessageScreen : Utilisateur non connecté. Ne peut pas envoyer de message.", level: 'ERROR');
      // TODO: Afficher un message d'erreur ou rediriger vers la page de connexion.
      // On ne peut pas envoyer de message sans UID d'expéditeur.
    }
  }

  // Gère l'envoi d'un message de type rapide
  Future<void> sendLove(String type) async {
    // L'UID du destinataire est stocké dans recipient.id (modèle Recipient refactorisé)
    final String recipientUserId = widget.recipient.id;

    // Obtenir l'UID de l'utilisateur actuel (expéditeur)
    final user = FirebaseAuth.instance.currentUser; // Peut aussi utiliser _currentUserId si initialisé en initState

    if (user == null) { // ou if (_currentUserId == null)
      // Protection supplémentaire si l'UID de l'expéditeur n'est pas disponible
      debugLog("⚠️ Impossible d'envoyer le message : UID de l'utilisateur actuel est null.", level: 'ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // TODO: Utiliser i18n_service pour ce message
          SnackBar(content: Text("Erreur: Vous devez être connecté pour envoyer un message.")),
        );
      }
      return;
    }
    final String currentUserId = user.uid; // UID de l'expéditeur


    // Vérifier si le destinataire est appairé (important avant d'envoyer)
    if (!widget.recipient.paired) {
      debugLog("⚠️ Envoi annulé : destinataire '${widget.recipient.displayName}' (UID: $recipientUserId) non appairé", level: 'WARN');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // TODO: Utiliser i18n_service pour ce message
          SnackBar(content: Text("Impossible d'envoyer un message: Destinataire non appairé.")),
        );
      }
      return;
    }

    // --- Ancienne logique d'envoi par mise à jour de champ obsolète ---
    /*
    final otherDeviceId = widget.recipient.deviceId; // Ancien deviceId du destinataire

    // Vérification appairage basée sur ancien champ
    if (!widget.recipient.paired) { // Utilise le champ 'paired' qui existe toujours dans le modèle Recipient refactorisé
      debugLog("⚠️ Envoi annulé : destinataire non appairé", level: 'WARN');
      return;
    }

    debugLog(
      "📤 Envoi (ancienne méthode) de type '$type' vers deviceId=$otherDeviceId", // Ancien log
      level: 'INFO',
    );

    try {
      HapticFeedback.mediumImpact(); // retour haptique

      // Écriture Firestore sur l'ancien chemin et anciens champs
      await FirebaseFirestore.instance
          .collection('devices') // Ancien chemin
          .doc(otherDeviceId) // Ancien ID
          .update({
        'messageType': type, // Ancien champ
        'senderName': widget.recipient.displayName, // Ancien champ (nom du destinataire? Semble incorrect, devrait être nom de l'expéditeur)
      });

      debugLog(
        "✅ Message envoyé (ancienne méthode) à $otherDeviceId : type=$type", // Ancien log
        level: 'SUCCESS',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getUILabel('message_sent', widget.deviceLang))),
      );

      Navigator.pop(context); // Sortir après envoi

    } catch (e) {
      debugLog("❌ Erreur lors de l'envoi (ancienne méthode) : $e", level: 'ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${getUILabel('send_failed', widget.deviceLang)} : $e"),
          ),
        );
      }
    }
    */ // --- Fin ancienne logique obsolète ---


    // --- Nouvelle logique d'envoi utilisant MessageService refactorisé ---
    debugLog(
      "📤 Envoi (nouvelle méthode) d'un message de type '$type' de UID $currentUserId vers UID $recipientUserId",
      level: 'INFO',
    );

    try {
      HapticFeedback.mediumImpact(); // retour haptique

      // Créer un objet Message en utilisant le modèle Message refactorisé
      // L'ID du message est généré localement (UUID) comme avant, ou peut être généré par Firestore.
      // Les champs 'from' et 'to' contiennent les UID Firebase.
      final msg = Message(
        id: const Uuid().v4(), // Génère un ID unique pour ce message (comme avant)
        from: currentUserId,   // UID de l'expéditeur (utilisateur actuel)
        to: recipientUserId,   // UID du destinataire
        type: type, // Type de message ('heart', etc.)
        content: getMessageBody(type, widget.deviceLang), // Utilise i18n_service pour le contenu basé sur le type
        sentAt: Timestamp.fromDate(DateTime.now()), // Timestamp de l'envoi
        seenAt: null, // Pas vu au moment de l'envoi
        receivedAt: null, // Pas encore reçu par l'autre appareil
      );

      // Initialiser MessageService DANS cette méthode si on ne l'a pas fait en initState.
      // Alternativement, l'initialiser en initState et l'utiliser ici est aussi possible.
      // Initialiser ici garantit que le service est créé avec les UID corrects pour CET envoi.
      final messageService = MessageService(currentUserId: currentUserId, recipientUserId: recipientUserId);


      // Appelle la méthode sendMessage du MessageService refactorisé.
      // Ce service gère l'écriture bidirectionnelle dans Firestore
      // (users/{uid_expéditeur}/recipients/{uid_destinataire}/messages et le miroir).
      await messageService.sendMessage(msg);

      debugLog(
        "✅ Message de type '$type' envoyé avec succès à UID $recipientUserId",
        level: 'SUCCESS',
      );

      if (!mounted) return;
      // Afficher un message de succès à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getUILabel('message_sent', widget.deviceLang))), // Utilise i18n_service
      );

      // Revenir à l'écran précédent (LoveScreen ou RecipientDetailsScreen) après l'envoi réussi
      Navigator.pop(context);

    } catch (e) {
      // Gérer les erreurs d'envoi
      debugLog("❌ Erreur lors de l'envoi de message (nouvelle méthode) : $e", level: 'ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${getUILabel('message_send_error', widget.deviceLang)} : $e"), // Utilise i18n_service
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // L'UI affiche une liste de boutons (un par type de message rapide) pour le destinataire.
    // Elle utilise les données du modèle Recipient refactorisé (allowedPacks).
    final allowedMessages = widget.recipient.allowedPacks;

    // Afficher un message si l'utilisateur actuel n'est pas identifié (bien que main.dart le gère)
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("💌 ${widget.recipient.displayName}"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text("Erreur: Impossible de charger l'écran d'envoi sans utilisateur identifié.", style: TextStyle(color: Colors.red)), // TODO: i18n_service
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
          // Utilise getPreviewText pour obtenir le texte du bouton
          final previewText = getPreviewText(messageType, widget.deviceLang); // Utilise i18n_service


          return GestureDetector(
            onTap: () => sendLove(messageType), // Appelle la méthode d'envoi refactorisée
            child: Container(
              height: 90,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink, // Couleur du bouton
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  previewText,
                  style: const TextStyle(fontSize: 22, color: Colors.white),
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
