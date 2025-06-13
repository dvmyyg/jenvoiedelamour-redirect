// lib/screens/recipient_details_screen.dart

// Historique du fichier
// V008 - Refactoring : Remplacement de deviceId par l'UID Firebase de l'utilisateur actuel et du destinataire.
//      - Passage de l'UID de l'utilisateur actuel et de l'UID du destinataire (via Recipient.id) au MessageService refactorisé.
//      - Utilisation de l'UID de l'utilisateur actuel pour identifier les messages envoyés.
//      - Suppression du paramètre deviceId. Accès à l'UID de l'utilisateur actuel via FirebaseAuth.currentUser. - 2025/05/29
// V007 - Amélioration UI bulles de messages (taille, couleur, padding, arrondi) - 2025/05/29 17h43 (Historique hérité)
// V006 - correction type Timestamp / DateTime + import firestore - 2025/05/26 22h00 (Historique hérité)
// V005 - remplacement affichage par chat + messages - 2025/05/26 21h00 (Historique hérité)
// V004 - intégration AppBar + bouton d’envoi - 2025/05/24 16h00 (Historique hérité)
// V003 - suppression du bloc contact, refonte UI - 2025/05/23 18h20 (Historique hérité)
// V002 - ajout navigation depuis RecipientScreen - 2025/05/22 12h30 (Historique hérité)
// V001 - création écran fiche destinataire - 2025/05/21 (Historique hérité)

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé (contient l'UID du destinataire)
import '../models/message.dart'; // Utilise le modèle Message refactorisé (avec UID from/to)
import '../services/message_service.dart'; // Utilise le MessageService refactorisé
import '../utils/debug_log.dart'; // Utilise le logger
import 'package:uuid/uuid.dart'; // Toujours utilisé pour générer l'ID unique du message
import 'package:intl/intl.dart'; // Pour le formatage de la date/heure
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour Timestamp

class RecipientDetailsScreen extends StatefulWidget {
  // Le deviceId n'est plus requis. L'identifiant de l'utilisateur actuel est son UID Firebase,
  // obtenu via FirebaseAuth.instance.currentUser.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente
  // Le destinataire de la conversation. Son champ 'id' doit contenir l'UID Firebase de l'autre utilisateur.
  final Recipient recipient; // Cet objet Recipient doit avoir l'UID du destinataire dans son champ 'id'

  const RecipientDetailsScreen({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang,
    required this.recipient,
  });

  @override
  State<RecipientDetailsScreen> createState() => _RecipientDetailsScreenState();
}

class _RecipientDetailsScreenState extends State<RecipientDetailsScreen> {
  // MessageService sera initialisé avec les UID de l'utilisateur actuel et du destinataire.
  late MessageService _messageService;
  final TextEditingController _controller = TextEditingController();

  // Stocke l'UID de l'utilisateur actuel une fois obtenu.
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Obtenir l'UID de l'utilisateur actuel dès que possible.
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (_currentUserId == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté (ne devrait pas arriver ici si main.dart redirige correctement)
      debugLog("⚠️ RecipientDetailsScreen : Utilisateur non connecté. Ne devrait pas arriver.", level: 'ERROR');
      // TODO: Afficher un message d'erreur ou rediriger vers la page de connexion.
      // Si l'UID est null, on ne peut pas initialiser MessageService, donc le reste de l'écran ne fonctionnera pas.
      return; // Sortir si l'UID n'est pas disponible
    }

    // L'UID du destinataire est stocké dans le champ 'id' du modèle Recipient refactorisé
    final String recipientUserId = widget.recipient.id;

    // Initialiser le MessageService refactorisé avec les UID des deux utilisateurs
    _messageService = MessageService(
      currentUserId: _currentUserId!, // UID de l'utilisateur actuel (non null car vérifié au-dessus)
      recipientUserId: recipientUserId, // UID du destinataire
    );
    debugLog("✅ MessageService initialisé pour chat entre UID $_currentUserId et UID $recipientUserId", level: 'INFO');
  }

  // Libère le contrôleur de texte lorsqu'il n'est plus nécessaire.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  // Gère l'envoi d'un message texte
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_currentUserId == null) {
      // Protection supplémentaire si l'UID devient null de manière inattendue
      debugLog("⚠️ Impossible d'envoyer le message : UID de l'utilisateur actuel est null.", level: 'ERROR');
      // TODO: Afficher un message à l'utilisateur ?
      return;
    }

    // L'UID du destinataire est stocké dans recipient.id (modèle Recipient refactorisé)
    final String recipientUserId = widget.recipient.id;

    // Crée un objet Message.
    // L'ID du message est généré localement (UUID).
    // Les champs 'from' et 'to' contiennent les UID Firebase.
    final msg = Message(
      id: const Uuid().v4(), // Génère un ID unique pour ce message
      from: _currentUserId!, // UID de l'expéditeur (utilisateur actuel)
      to: recipientUserId,   // UID du destinataire
      type: 'text', // Type de message (texte)
      content: text, // Contenu du message
      sentAt: Timestamp.fromDate(DateTime.now()), // Timestamp de l'envoi
      seenAt: null, // Pas vu au moment de l'envoi
    );

    // Appelle la méthode sendMessage du MessageService refactorisé
    // Ce service gère l'écriture bidirectionnelle dans Firestore (users/{uid}/recipients/{otherUid}/messages)
    _messageService.sendMessage(msg);
    _controller.clear(); // Vide le champ de texte après envoi
  }

  @override
  Widget build(BuildContext context) {
    // Vérification si l'UID de l'utilisateur actuel est disponible.
    // Si non, on affiche un message d'erreur au lieu de construire l'écran de chat.
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.recipient.displayName),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text("Erreur de chargement du chat : Utilisateur non identifié.", style: TextStyle(color: Colors.red)), // TODO: Utiliser i18n_service
        ),
      );
    }


    // L'UI de l'écran de chat reste globalement la même.
    // Elle utilise le MessageService initialisé avec les UID et le modèle Message refactorisé.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipient.displayName), // Affiche le nom du destinataire (du modèle Recipient)
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              // Le streamMessages() utilise le MessageService refactorisé (basé sur UID)
              stream: _messageService.streamMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    // Déterminer si le message vient de l'utilisateur actuel en comparant 'msg.from' (qui contient maintenant l'UID) avec '_currentUserId'
                    final isMine = msg.from == _currentUserId;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.pink : const Color(0xFF2E2E2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content, // Contenu du message (du modèle Message refactorisé)
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            // Affichage de l'heure d'envoi
                            Text(
                              DateFormat.Hm().format(msg.sentAt.toDate()), // msg.sentAt est un Timestamp
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Zone de saisie du message en bas de page.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Message...', // TODO: Utiliser i18n_service
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Bouton d'envoi (appelle _sendMessage refactorisé)
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
