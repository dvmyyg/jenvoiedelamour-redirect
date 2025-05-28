// -------------------------------------------------------------
// 📄 FICHIER : lib/screens/recipients_screen.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Affiche la liste des destinataires liés à l’appareil
// ✅ Bouton “Inviter quelqu’un” → partage de lien d’invitation
// ✅ Bouton “Valider une invitation” → saisie manuelle du lien
// ✅ Icône ✎ → édition de la catégorie (partenaire, famille, ami)
// ✅ Icône 🗑️ → suppression d’un destinataire (avec confirmation)
// ✅ Navigation → écran de détail (RecipientDetailsScreen)
// ✅ Textes traduits dynamiquement via getUILabel (i18n_service)
// ✅ Chargement Firestore + appel à RecipientService
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V014 - ajout du bloc descriptif des fonctionnalités principales - 2025/05/28 14h32
// V013 - restauration des boutons d'invitation et de suppression - 2025/05/28 20h25
// V012 - réintégration suppression recipient via menu contextuel - 2025/05/27 21h35
// V011 - ajout menu édition du destinataire avec changement de catégorie - 2025/05/27 14h54
// V010 - suppression de l’affichage du champ 'relation' dans la liste - 2025/05/26 15h13
// V009 - vérification correcte du prénom miroir dans l’appairage - 2025/05/26 11h47
// V008 - appairage bilatéral avec prénom miroir - 2025/05/26 11h08
// V007 - ajout vérification doublon lors de l'appairage manuel - 2025/05/26 09h38
// V006 - ajout des paramètres obligatoires 'allowedPacks' et 'paired' dans Recipient - 2025/05/26 09h18
// V005 - ajout de la validation du champ de lien dans la boîte de dialogue - 2025/05/26 09h13
// V004 - connexion du lien collé à la méthode d’appairage - 2025/05/26 08h55
// V003 - ajout du bouton "Valider une invitation" avec champ de lien - 2025/05/26 08h52
// V002 - bouton "Envoyer une invitation" + partage lien - 2025/05/25 22h40
// V001 - version initiale - 2025/05/21

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/recipient_service.dart';
import '../models/recipient.dart';
import 'recipient_details_screen.dart';
import '../services/i18n_service.dart';

class RecipientsScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;

  const RecipientsScreen({super.key, required this.deviceId, required this.deviceLang});

  @override
  State<RecipientsScreen> createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends State<RecipientsScreen> {
  late RecipientService _recipientService;
  List<Recipient> _recipients = [];

  @override
  void initState() {
    super.initState();
    _recipientService = RecipientService(widget.deviceId);
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    final recipients = await _recipientService.fetchRecipients();
    setState(() => _recipients = recipients);
  }

  Future<void> _confirmDeleteRecipient(String recipientId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(getUILabel('delete_contact_title', widget.deviceLang), style: const TextStyle(color: Colors.white)),
        content: Text(getUILabel('delete_contact_warning', widget.deviceLang), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(getUILabel('cancel_button', widget.deviceLang), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(getUILabel('delete_button', widget.deviceLang), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _recipientService.deleteRecipient(recipientId);
      _loadRecipients();
    }
  }

  void _shareInviteLink() {
    final inviteLink = "https://dvmyyg.github.io/jenvoiedelamour-redirect/?recipient=${widget.deviceId}";
    Share.share(inviteLink);
  }

  void _showPasteLinkDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(getUILabel('validate_invite_button', widget.deviceLang), style: const TextStyle(color: Colors.white)),
        content: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: getUILabel('paste_invite_hint', widget.deviceLang),
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(getUILabel('cancel_button', widget.deviceLang), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final input = controller.text.trim();
              final uri = Uri.tryParse(input);
              final recipientId = uri?.queryParameters['recipient'];
              if (recipientId != null && recipientId.isNotEmpty) {
                final alreadyPaired = _recipients.any((r) => r.id == recipientId);
                if (alreadyPaired) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUILabel('already_paired', widget.deviceLang)),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final snapA = await FirebaseFirestore.instance.collection('devices').doc(recipientId).get();
                final displayNameA = snapA.data()?['displayName'] ?? getUILabel('default_pairing_name', widget.deviceLang);

                final snapB = await FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).get();
                final displayNameB = snapB.data()?['displayName'] ?? getUILabel('default_pairing_name', widget.deviceLang);

                await _recipientService.addRecipient(Recipient(
                  id: recipientId,
                  displayName: displayNameA,
                  icon: '💌',
                  relation: 'relation_partner',
                  deviceId: recipientId,
                  allowedPacks: [],
                  paired: true,
                ));

                await FirebaseFirestore.instance.collection('devices').doc(recipientId).collection('recipients').doc(widget.deviceId).set({
                  'id': widget.deviceId,
                  'displayName': displayNameB,
                  'icon': '💌',
                  'relation': 'relation_partner',
                  'deviceId': widget.deviceId,
                  'allowedPacks': [],
                  'paired': true,
                });

                if (mounted) {
                  Navigator.of(context).pop();
                  _loadRecipients();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUILabel('pairing_success', widget.deviceLang)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(getUILabel('invalid_invite_link', widget.deviceLang)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(getUILabel('validate_button', widget.deviceLang), style: const TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  void _editRecipient(Recipient r) {
    showDialog(
      context: context,
      builder: (_) {
        String selectedCategory = r.relation;
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(getUILabel('edit_contact_category', widget.deviceLang), style: const TextStyle(color: Colors.white)),
          content: DropdownButtonFormField<String>(
            value: selectedCategory,
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(value: 'relation_partner', child: Text(getUILabel('relation_partner', widget.deviceLang))),
              DropdownMenuItem(value: 'relation_family', child: Text(getUILabel('relation_family', widget.deviceLang))),
              DropdownMenuItem(value: 'relation_friend', child: Text(getUILabel('relation_friend', widget.deviceLang))),
            ],
            onChanged: (value) => selectedCategory = value!,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getUILabel('cancel_button', widget.deviceLang)),
            ),
            TextButton(
              onPressed: () async {
                final updated = r.copyWith(relation: selectedCategory);
                await _recipientService.updateRecipient(updated);
                if (mounted) {
                  Navigator.pop(context);
                  _loadRecipients();
                }
              },
              child: Text(getUILabel('save_button', widget.deviceLang), style: const TextStyle(color: Colors.pink)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getUILabel('recipients_title', widget.deviceLang)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        children: [
          GestureDetector(
            onTap: _shareInviteLink,
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
                  Text(getUILabel('invite_someone_button', widget.deviceLang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _showPasteLinkDialog,
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
                  Text(getUILabel('validate_invite_button', widget.deviceLang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          ..._recipients.map((r) {
            return ListTile(
              leading: Text(r.icon, style: const TextStyle(fontSize: 24)),
              title: Text(r.displayName, style: const TextStyle(color: Colors.white)),
              subtitle: Text(getUILabel(r.relation, widget.deviceLang), style: const TextStyle(color: Colors.white70)),
              trailing: Wrap(
                spacing: 12,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () => _editRecipient(r),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteRecipient(r.id),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipientDetailsScreen(
                      deviceId: widget.deviceId,
                      deviceLang: widget.deviceLang,
                      recipient: r,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
