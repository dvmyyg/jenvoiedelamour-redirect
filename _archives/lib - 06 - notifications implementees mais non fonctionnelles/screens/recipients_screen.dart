// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/recipients_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Affiche la liste des destinataires liés à l’utilisateur authentifié (par UID)
// ✅ Bouton “Inviter quelqu’un” → navigue vers AddRecipientScreen (qui gère le partage de lien par UID)
// ✅ Bouton “Valider une invitation” → saisie manuelle du lien/UID, déclenche l'appairage pairUsers (basé sur UID). La boîte de dialogue accepte l'URL complète ou l'UID pur.
// ✅ Icône ✎ → navigation vers écran d’édition (passant l'UID du destinataire)
// ✅ Icône 🗑️ → suppression d’un destinataire (appelant RecipientService par UID, avec confirmation)
// ✅ Navigation → écran de chat/détail (RecipientDetailsScreen, passant l'UID du destinataire)
// ✅ Textes traduits dynamiquement via getUILabel (i18n_service)
// ✅ Chargement Firestore + appel à RecipientService (maintenant basés sur UID)
// ✅ **Reçoit le rôle isReceiver de l'utilisateur actuel en paramètre.**
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V021 - Ajout du paramètre isReceiver au constructeur de RecipientsScreen. - 2025/06/03
// V020 - Modification du bloc onPressed dans _showPasteLinkDialog pour accepter soit l'URL d'invitation (paramètre 'recipient'), soit l'UID Firebase pur, pour faciliter l'appairage manuel. Utilisation des nouvelles clés i18n pour les messages d'erreur. Code validé. - 2025/05/31
// V019 - Correction de l'erreur d'exportation de '_pairUsers' en renommant la fonction en 'pairUsers' dans main.dart et en mettant à jour l'import et l'appel ici. - 2025/05/30
// V018 - Correction de l'erreur Undefined name '_pairUsers' en décommentant l'import de main.dart. - 2025/05/30
// V017 - Correction de l'avertissement 'unnecessary_to_list'. Code refactorisé vers UID confirmé. - 2025/05/30
// V015 - Refactoring : Remplacement de deviceId par l'UID Firebase de l'utilisateur actuel.
//      - Suppression du paramètre deviceId. Accès à l'UID via FirebaseAuth.currentUser.
//      - Initialisation de RecipientService avec l'UID.
//      - Adaptation de la logique d'appairage manuel (_showPasteLinkDialog) pour utiliser les UID et appeler pairUsers (main.dart).
//      - Adaptation des appels à RecipientService (add/delete/update) pour utiliser les UID.
//      - Adaptation de la navigation vers les écrans détaillés/édition/envoi pour passer l'UID du destinataire. - 2025/05/29
// V014 - ajout du bloc descriptif des fonctionnalités principales - 2025/05/28 14h32 (Historique hérité)
// V013 - restauration des boutons d'invitation et de suppression - 2025/05/28 20h25 (Historique hérité)
// V012 - réintégration suppression recipient via menu contextuel - 2025/05/27 21h35 (Historique hérité)
// V011 - ajout menu édition du destinataire avec changement de catégorie - 2025/05/27 14h54 (Historique hérité)
// V010 - suppression de l’affichage du champ 'relation' dans la liste - 2025/05/26 15h13 (Historique hérité)
// V009 - vérification correcte du prénom miroir dans l’appairage - 2025/05/26 11h47 (Historique hérité)
// V008 - appairage bilatéral avec prénom miroir - 2025/05/26 11h08 (Historique hérité)
// V007 - ajout vérification doublon lors de l'appairage manuel - 2025/05/26 09:38 (Historique hérité)
// V006 - ajout des paramètres obligatoires 'allowedPacks' et 'paired' dans Recipient - 2025/05/26 09:18 (Historique hérité)
// V005 - ajout de la validation du champ de lien dans la boîte de dialogue - 2025/05/26 09h13 (Historique hérité)
// V004 - connexion du lien collé à la méthode d’appairage - 2025/05/26 08h55 (Historique hérité)
// V003 - ajout du bouton "Valider une invitation" avec champ de lien - 2025/05/26 08h52 (Historique hérité)
// V002 - bouton "Envoyer une invitation" + partage lien - 2025/05/25 22h40 (Historique hérité)
// V001 - version initiale - 2025/05/21 (Historique hérité)
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/31 // Mise à jour le 31/05

import 'package:flutter/material.dart';
import '../main.dart' show pairUsers; // Importe spécifiquement _pairUsers depuis main.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../services/recipient_service.dart'; // Utilise le RecipientService refactorisé
import '../models/recipient.dart'; // Utilise le modèle Recipient refactorisé (contient l'UID du destinataire dans .id)
import 'recipient_details_screen.dart';
import 'edit_recipient_screen.dart';
import 'add_recipient_screen.dart'; // Écran pour générer le lien d'invitation
import '../services/i18n_service.dart'; // Pour les traductions
import '../utils/debug_log.dart'; // Pour le logger


class RecipientsScreen extends StatefulWidget {
  final String deviceLang; // La langue reste pertinente
  final bool isReceiver; // Rôle de l'utilisateur ACTUEL (celui qui est sur cet écran)

  const RecipientsScreen({
    super.key,
    required this.deviceLang,
    required this.isReceiver, // Ce paramètre est requis
  });

  @override
  State<RecipientsScreen> createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends State<RecipientsScreen> {
  // RecipientService sera initialisé avec l'UID de l'utilisateur actuel.
  late RecipientService _recipientService;
  List<Recipient> _recipients = []; // Liste des destinataires

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Obtenir l'UID de l'utilisateur actuel dès que possible.
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (_currentUserId == null) {

      debugLog("⚠️ RecipientsScreen : Utilisateur non connecté. Ne peut pas charger les destinataires.", level: 'ERROR');
      // TODO: Afficher un message d'erreur ou rediriger vers la page de connexion.

      return; // Sortir si l'UID n'est pas disponible
    }

    _recipientService = RecipientService(_currentUserId!); // UID de l'utilisateur actuel (non null car vérifié au-dessus)

    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    if (_currentUserId == null) return; // Protection supplémentaire

    final recipients = await _recipientService.fetchRecipients();
    setState(() => _recipients = recipients); // Met à jour l'état avec la nouvelle liste
    debugLog("✅ ${_recipients.length} destinataires chargés pour l'UID $_currentUserId", level: 'INFO');
  }

  Future<void> _confirmDeleteRecipient(Recipient recipientToDelete) async { // Reçoit l'objet Recipient pour accéder à son ID/UID
    if (_currentUserId == null) return; // Protection supplémentaire

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(getUILabel('delete_contact_title', widget.deviceLang), style: const TextStyle(color: Colors.white)), // Utilise i18n_service
        content: Text(getUILabel('delete_contact_warning', widget.deviceLang), style: const TextStyle(color: Colors.white70)), // Utilise i18n_service
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(getUILabel('cancel_button', widget.deviceLang), style: const TextStyle(color: Colors.grey)), // Utilise i18n_service
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(getUILabel('delete_button', widget.deviceLang), style: const TextStyle(color: Colors.red)), // Utilise i18n_service
          ),
        ],
      ),
    );

    if (confirmed == true) {

      await _recipientService.deleteRecipient(recipientToDelete.id); // recipientToDelete.id contient maintenant l'UID de l'autre utilisateur
      // TODO: Optionnel : Supprimer aussi le destinataire miroir chez l'autre utilisateur si cette logique est souhaitée.

      _loadRecipients(); // Recharge la liste après suppression
    }
  }

  void _goToAddRecipientScreen() async {
    if (_currentUserId == null) return; // Protection supplémentaire

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecipientScreen(
          // deviceId: widget.deviceId, // <-- SUPPRIMÉ
          deviceLang: widget.deviceLang, // La langue est toujours passée
        ),
      ),
    );

    _loadRecipients();
  }

  void _showPasteLinkDialog() {
    if (_currentUserId == null) return; // Protection supplémentaire

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(getUILabel('validate_invite_button', widget.deviceLang), style: const TextStyle(color: Colors.white)), // Utilise i18n_service
        content: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: getUILabel('paste_invite_hint', widget.deviceLang), // Utilise i18n_service
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(getUILabel('cancel_button', widget.deviceLang), style: const TextStyle(color: Colors.grey)), // Utilise i18n_service
          ),
          TextButton(
            onPressed: () async {
              final input = controller.text.trim();
              String? recipientInviterUid;

              final uri = Uri.tryParse(input);
              // Tente d'abord de parser comme une URL avec le paramètre 'recipient'
              if (uri != null && uri.queryParameters.containsKey('recipient')) {
                recipientInviterUid = uri.queryParameters['recipient'];
                debugLog("➡️ [RecipientsScreen] Parsé comme URL d'invitation. UID: $recipientInviterUid", level: 'DEBUG');
              } else {

                if (input.length >= 20 && input.length <= 40) { // Assoupli la validation de longueur
                  recipientInviterUid = input;
                  debugLog("➡️ [RecipientsScreen] Parsé comme UID direct. UID: $recipientInviterUid", level: 'DEBUG');
                } else {

                  debugLog("⚠️ [RecipientsScreen] Entrée invalide : ne ressemble pas à une URL d'invitation ou un UID valide.", level: 'WARNING');
                }
              }

              if (recipientInviterUid != null && recipientInviterUid.isNotEmpty && _currentUserId != recipientInviterUid) {

                final alreadyPaired = _recipients.any((r) => r.id == recipientInviterUid); // r.id contient maintenant l'UID
                if (alreadyPaired) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUILabel('already_paired', widget.deviceLang)), // Utilise i18n_service
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.of(context).pop(); // Ferme la boîte de dialogue
                  return; // Sortir après le message "déjà appairé"
                }

                final String? pairedWithUid = await pairUsers(recipientInviterUid, _currentUserId!);
                if (mounted) { // Vérifier si le widget est toujours monté après l'opération asynchrone

                  if (pairedWithUid != null) {

                    _loadRecipients(); // Recharge la liste pour inclure le nouveau destinataire
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(getUILabel('pairing_success', widget.deviceLang)), // Utilise i18n_service
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop(); // Ferme la boîte de dialogue UNIQUEMENT en cas de succès
                  } else {

                    debugLog("⚠️ [RecipientsScreen] pairUsers a retourné null. Échec de l'appairage.", level: 'WARNING');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(getUILabel('pairing_failed', widget.deviceLang)), // Utilise i18n_service
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {

                final errorMessage = (_currentUserId == recipientInviterUid && recipientInviterUid != null && recipientInviterUid.isNotEmpty)
                    ? getUILabel('cannot_pair_with_self', widget.deviceLang) // Utilise i18n_service
                    : getUILabel('invalid_invite_code', widget.deviceLang); // Utilise i18n_service

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(getUILabel('validate_button', widget.deviceLang), style: const TextStyle(color: Colors.pink)), // Utilise i18n_service
          ),
        ],
      ),
    );
  }

  void _editRecipient(Recipient r) { // Prend l'objet Recipient en paramètre
    if (_currentUserId == null) return; // Protection supplémentaire

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRecipientScreen(
          deviceLang: widget.deviceLang, // La langue est toujours passée
          recipient: r, // Passe l'objet Recipient refactorisé
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadRecipients(); // Recharge la liste pour refléter les changements potentiels (nom, relation, icône)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(getUILabel('recipients_title', widget.deviceLang)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.pink), // Ou un message d'erreur
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(getUILabel('recipients_title', widget.deviceLang)), // Utilise i18n_service
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        children: [
          GestureDetector(
            onTap: _goToAddRecipientScreen, // Appelle la navigation refactorisée
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.add, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(getUILabel('invite_someone_button', widget.deviceLang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Utilise i18n_service
                ],
              ),
            ),
          ),
          // Bouton "Valider une invitation"
          GestureDetector(
            onTap: _showPasteLinkDialog, // Appelle la boîte de dialogue refactorisée pour appairage manuel
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.link, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(getUILabel('validate_invite_button', widget.deviceLang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Utilise i18n_service
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          // Liste des destinataires
          ..._recipients.map((r) { // _recipients contient des objets Recipient refactorisés (ID = UID)
            return ListTile(
              leading: Text(r.icon, style: const TextStyle(fontSize: 24)), // Utilise les données du modèle Recipient
              title: Text(r.displayName, style: const TextStyle(color: Colors.white)), // Utilise les données du modèle Recipient
              subtitle: Text(getUILabel(r.relation, widget.deviceLang), style: const TextStyle(color: Colors.white70)), // Utilise les données du modèle Recipient et i18n_service
              trailing: Wrap(
                spacing: 12,
                children: [
                  // Bouton d'édition
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () => _editRecipient(r), // Appelle la méthode d'édition refactorisée (passe l'objet Recipient)
                  ),
                  // Bouton de suppression
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteRecipient(r), // Appelle la méthode de suppression refactorisée (passe l'objet Recipient)
                  ),
                  // TODO: Optionnel : Bouton pour accéder directement au chat depuis la liste ?
                  IconButton(
                    icon: const Icon(Icons.chat, color: Colors.white70), // Icône de chat
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipientDetailsScreen(
                            deviceLang: widget.deviceLang, // La langue est toujours passée
                            recipient: r, // Passe l'objet Recipient refactorisé
                            isReceiver: widget.isReceiver, // Passe le rôle isReceiver de l'utilisateur ACTUEL (disponible via widget)
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // L'action onTap sur l'élément de liste pourrait aussi naviguer vers le chat
              // onTap: () { /* naviguer vers RecipientDetailsScreen(recipient: r, deviceLang: widget.deviceLang) */ },
            );
          }), // Suppression de .toList()
        ],
      ),
    );
  }
} // <-- Fin de la classe _RecipientsScreenState et de la classe RecipientsScreen

// 📄 FIN de lib/screens/recipients_screen.dart
