// lib/screens/chat_screen.dart

// Historique du fichier
// V003 - Refactoring : Remplacement de deviceId par l'UID Firebase de l'utilisateur actuel et du destinataire.
//      - Passage de l'UID de l'utilisateur actuel (obtenu dans build) et de l'UID du destinataire (via Recipient.id) au MessageService refactorisé.
//      - Utilisation de l'UID de l'utilisateur actuel pour identifier les messages envoyés.
//      - Suppression du paramètre deviceId. - 2025/05/29
// V002 - affichage du flux de messages avec correction de l’appel à Message.quick() - 2025/05/26 20h16 (Historique hérité)
// V001 - structure de base de l’écran de chat et affichage des messages - 2025/05/26 19h34 (Historique hérité)

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nécessaire pour obtenir l'UID de l'utilisateur actuel dans build
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé (contient l'UID du destinataire)
import '../models/message.dart'; // Utilise le modèle Message refactorisé (avec UID from/to)
import '../services/message_service.dart'; // Utilise le MessageService refactorisé
import 'package:intl/intl.dart'; // Pour le formatage de la date/heure // Ajouté car il était utilisé mais pas importé


class ChatScreen extends StatelessWidget {
  // Le deviceId n'est plus requis. L'identifiant de l'utilisateur actuel est son UID Firebase,
  // obtenu via FirebaseAuth.instance.currentUser dans la méthode build.
  // final String deviceId; // <-- SUPPRIMÉ
  final String deviceLang; // La langue reste pertinente
  // Le destinataire de la conversation. Son champ 'id' doit contenir l'UID Firebase de l'autre utilisateur.
  final Recipient recipient; // Cet objet Recipient doit avoir l'UID du destinataire dans son champ 'id'

  const ChatScreen({
    super.key,
    // required this.deviceId, // <-- SUPPRIMÉ du constructeur
    required this.deviceLang,
    required this.recipient,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenir l'utilisateur Firebase actuellement connecté dans la méthode build.
    // C'est la manière de faire dans un StatelessWidget pour accéder à l'état d'auth.
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté (ne devrait pas arriver si main.dart redirige correctement)
      // Afficher un message d'erreur ou un indicateur, car on ne peut pas initialiser le chat sans utilisateur connecté.
      return Scaffold(
        body: Center(
          child: Text("Erreur: Utilisateur non connecté pour accéder au chat.", style: TextStyle(color: Colors.red)), // TODO: Utiliser i18n_service
        ),
        appBar: AppBar( // Peut-être afficher une barre d'app vide ou avec un titre générique
          title: Text("Chat"), // TODO: i18n
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
      );
    }

    // L'UID de l'utilisateur actuel
    final String currentUserId = currentUser.uid;
    // L'UID du destinataire est stocké dans le champ 'id' du modèle Recipient refactorisé
    final String recipientUserId = recipient.id;

    // Initialiser le MessageService refactorisé avec les UID des deux utilisateurs
    // Dans un StatelessWidget, le service est généralement créé directement dans build si ses dépendances sont disponibles.
    final messageService = MessageService(
      currentUserId: currentUserId, // UID de l'utilisateur actuel
      recipientUserId: recipientUserId, // UID du destinataire
    );
    // debugLog n'est pas recommandé directement dans build pour éviter d'être appelé à chaque reconstruction.
    // Il était dans initState dans RecipientDetailsScreen, ce qui est plus adapté.
    // debugLog("✅ MessageService initialisé pour chat entre UID $currentUserId et UID $recipientUserId", level: 'INFO');


    // L'UI de l'écran de chat reste globalement la même, mais utilise maintenant
    // les identifiants basés sur l'UID et les services/modèles refactorisés.
    return Scaffold(
      appBar: AppBar(
        title: Text(recipient.displayName), // Affiche le nom du destinataire (du modèle Recipient)
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              // Le streamMessages() utilise le MessageService refactorisé (basé sur UID)
              stream: messageService.streamMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    // Déterminer si le message vient de l'utilisateur actuel en comparant 'msg.from' (qui contient maintenant l'UID) avec 'currentUserId'
                    final isMe = msg.from == currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.pink : Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content, // Contenu du message (du modèle Message refactorisé)
                              style: TextStyle(
                                fontSize: 20,
                                color: isMe ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Affichage de l'heure d'envoi
                            Text(
                              DateFormat.Hm().format(msg.sentAt.toDate()), // msg.sentAt est un Timestamp
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white38,
                              ),
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
          // Zone d'envoi rapide (bouton ❤️)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Utilise Message.quick refactorisé (qui attend les UID)
                  // Passe l'UID de l'utilisateur actuel et l'UID du destinataire
                  final msg = Message.quick(from: currentUserId, to: recipientUserId);
                  // Appelle sendMessage du MessageService refactorisé (qui gère l'écriture dans Firestore)
                  await messageService.sendMessage(msg);
                },
                icon: const Icon(Icons.favorite),
                label: const Text("Envoyer ❤️"), // TODO: Utiliser i18n_service
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
