//  lib/screens/edit_recipient_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipient.dart';
import '../services/i18n_service.dart';

class EditRecipientScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;
  final Recipient recipient;

  const EditRecipientScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
    required this.recipient,
  });

  @override
  State<EditRecipientScreen> createState() => _EditRecipientScreenState();
}

class _EditRecipientScreenState extends State<EditRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _iconController;
  late String _selectedRelationKey;

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
    _displayNameController = TextEditingController(
      text: widget.recipient.displayName,
    );
    _iconController = TextEditingController(text: widget.recipient.icon);
    _selectedRelationKey = widget.recipient.relation;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final docRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .collection('recipients')
        .doc(widget.recipient.id);

    await docRef.update({
      'displayName': _displayNameController.text.trim(),
      'relation': _selectedRelationKey,
      'icon': _iconController.text.trim(),
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _sharePairingLink() {
    final link =
        'https://dvmyyg.github.io/jenvoiedelamour-redirect/?recipient=${widget.recipient.id}';
    Share.share(
      '💌 Clique ici pour t’appairer avec moi dans l’app J’envoie de l’amour :\n$link',
      subject: 'Lien d’appairage',
    );
  }

  Widget _buildTextField(String labelKey, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: getUILabel(labelKey, widget.deviceLang),
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),
          ),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? getUILabel('required_field', widget.deviceLang) : null,
      ),
    );
  }

  Widget _buildRelationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedRelationKey,
        items: relationKeys.map((key) {
          return DropdownMenuItem(
            value: key,
            child: Text(getUILabel(key, widget.deviceLang)),
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
          labelText: getUILabel('relation_label', widget.deviceLang),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('edit_recipient_title', widget.deviceLang)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('display_name_label', _displayNameController),
              _buildRelationDropdown(),
              _buildTextField('icon_hint', _iconController),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.check),
                label: Text(getUILabel('save_changes_button', widget.deviceLang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _sharePairingLink,
                icon: const Icon(Icons.link),
                label: Text(getUILabel('share_pairing_link', widget.deviceLang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
