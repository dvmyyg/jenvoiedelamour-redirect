//  lib/screens/add_recipient_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../services/i18n_service.dart';

class AddRecipientScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang;

  const AddRecipientScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang,
  });

  @override
  State<AddRecipientScreen> createState() => _AddRecipientScreenState();
}

class _AddRecipientScreenState extends State<AddRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _iconController = TextEditingController();

  final List<String> relationKeys = [
    'compagne',
    'compagnon',
    'enfant',
    'maman',
    'papa',
    'ami',
    'autre',
  ];
  late String _selectedRelationKey;

  @override
  void initState() {
    super.initState();
    _selectedRelationKey = relationKeys.first;
  }

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Future<void> _saveRecipient() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = capitalize(_displayNameController.text.trim());
    final icon = _iconController.text.trim();
    final relation = _selectedRelationKey;

    final id = const Uuid().v4();

    final docRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .collection('recipients')
        .doc(id);

    await docRef.set({
      'id': id,
      'displayName': displayName,
      'relation': relation,
      'icon': icon,
      'deviceId': null,
    });

    if (!mounted) return;
    _sharePairingLink(id);
    Navigator.pop(context, true);
  }

  void _sharePairingLink(String recipientId) {
    final link =
        'https://dvmyyg.github.io/jenvoiedelamour-redirect/?recipient=$recipientId';
    Share.share(
      '💌 Clique ici pour t’appairer avec moi dans l’app J’envoie de l’amour :\n$link',
      subject: 'Lien d’appairage',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(getUILabel('add_recipient_title', widget.deviceLang)),
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
                onPressed: _saveRecipient,
                icon: const Icon(Icons.link),
                label: Text(getUILabel('share_pairing_link', widget.deviceLang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
        onChanged: (val) => setState(() => _selectedRelationKey = val ?? relationKeys.first),
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
}
