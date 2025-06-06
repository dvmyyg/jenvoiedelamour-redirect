// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/recipient_details_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Écran de conversation (chat) avec un destinataire spécifique.
// ✅ Affiche les messages échangés avec le destinataire en temps réel.
// ✅ Permet d'envoyer de nouveaux messages texte au destinataire.
// ✅ S'appuie sur FirebaseAuth.instance.currentUser pour l'UID de l'utilisateur actuel.
// ✅ Utilise l'UID du destinataire (via Recipient.id) pour identifier l'interlocuteur.
// ✅ Initialise et utilise MessageService avec les UID de l'utilisateur actuel et du destinataire.
// ✅ Identifie les messages "envoyés par moi" en comparant msg.from avec l'UID de l'utilisateur actuel.
// ✅ N'utilise plus deviceId pour l'identification ou la logique.
// ✅ Utilise le modèle Message refactorisé avec UID from/to.
// ✅ Affiche les messages sous forme de bulles avec indication d'heure.
// ✅ Implémente un scroll automatique intelligent : scroll vers le bas seulement si de nouveaux messages arrivent ET que l'utilisateur était déjà en bas de la liste.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V012 - Ajout de la logique de scroll conditionnel intelligent dans le StreamBuilder du chat, en utilisant ScrollController pour détecter la position de l'utilisateur et scroller si nécessaire à l'arrivée de nouveaux messages. - 2025/06/01
// V011 - Déclaration et libération du ScrollController dans la classe d'état et la méthode dispose. - 2025/06/01
// V010 - Ajout d'un ScrollController et de la logique dans le StreamBuilder pour implémenter le scroll automatique intelligent (scroll vers le bas si nouveaux messages et utilisateur en bas). - 2025/06/01 (Modifications partielles dans V011 et V012)
// V009 - Code examiné par Gemini. Logique de chat basée sur les UID Firebase (utilisateur actuel et destinataire) confirmée comme fonctionnelle et bien implémentée avec MessageService. - 2025/05/31
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
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/06/01 // Mise à jour le 01/06

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
  final String deviceLang; // La langue reste pertinente
  final Recipient recipient; // Cet objet Recipient doit avoir l'UID du destinataire dans son champ 'id'
  final bool isReceiver; // Rôle de l'utilisateur ACTUEL (celui qui est sur cet écran)

  const RecipientDetailsScreen({
    super.key,
    required this.deviceLang,
    required this.recipient,
    required this.isReceiver, // Ce paramètre est requis
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

  // Contrôleur pour gérer le défilement de la liste de messages
  final ScrollController _scrollController = ScrollController(); // <-- AJOUTEZ CETTE LIGNE

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
    _scrollController.dispose(); // <-- AJOUTEZ CETTE LIGNE
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
                // Code pour la logique de scroll automatique intelligent
                // Vérifie si le contrôleur de scroll est attaché à la ListView et s'il y a des messages.
                // S'il y a des messages ET que le contrôleur est attaché,
                // on vérifie si l'utilisateur était déjà en bas AVANT le rendu de la nouvelle liste.
                bool wasAtBottom = false;
                if (_scrollController.hasClients && messages.isNotEmpty) {
                  // Calcule la position actuelle et la position maximale de scroll.
                  final double currentScrollPosition = _scrollController.position.pixels;
                  final double maxScrollPosition = _scrollController.position.maxScrollExtent;

                  // Définit une petite tolérance. Être "en bas" signifie être proche de la position maximale.
                  // La tolérance est utile car parfois, la position exacte n'est pas égale au maxExtent
                  // en raison de la manière dont Flutter calcule les layouts.
                  final double tolerance = 50.0; // Tolérance en pixels (ajustez si nécessaire)

                  // Détermine si l'utilisateur était "en bas" avant que cette mise à jour n'arrive.
                  wasAtBottom = currentScrollPosition >= maxScrollPosition - tolerance;

                  // debugLog("Scroll check: current=$currentScrollPosition, max=$maxScrollPosition, wasAtBottom=$wasAtBottom", level: 'DEBUG');
                } else if (!_scrollController.hasClients) {
                  // Si la ListView n'a pas encore été rendue (premier build), on suppose qu'on doit scroller en bas.
                  // Cela couvre le cas où la conversation s'ouvre et il y a déjà des messages.
                  wasAtBottom = true;
                  // debugLog("Scroll check: no clients yet, assuming at bottom (initial build)");
                }


                // Si de nouveaux messages sont arrivés (on le sait car le StreamBuilder s'est mis à jour)
                // ET que l'utilisateur était en bas (ou si c'est le premier chargement),
                // on planifie le scroll vers le bas APRÈS que le nouveau rendu ait été effectué.
                // On utilise addPostFrameCallback pour s'assurer que la ListView est bien mise à jour
                // avec les nouveaux messages et que maxScrollExtent est correct AVANT de scroller.
                if (messages.isNotEmpty && wasAtBottom) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Vérifie à nouveau si le contrôleur a toujours des clients avant de tenter de scroller
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent, // Scroll jusqu'à la position maximale (tout en bas)
                        duration: const Duration(milliseconds: 300), // Durée de l'animation (300ms)
                        curve: Curves.easeOut, // Courbe d'animation (ralentit vers la fin)
                      );
                      // debugLog("Scrolling to bottom due to new messages and wasAtBottom");
                    }
                  });
                }
                // Fin du code pour la logique de scroll automatique intelligent

                // Build the ListView.builder
                return ListView.builder(
                  controller: _scrollController, // <-- AJOUTEZ CETTE LIGNE EXACTEMENT ICI
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
                ); // <-- End of ListView.builder
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
// 📄 FIN de lib/screens/recipient_details_screen.dart
