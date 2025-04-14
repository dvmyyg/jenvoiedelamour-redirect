// 📄 lib/screens/edit_recipient_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipient.dart';

class EditRecipientScreen extends StatefulWidget {
  final String deviceId;
  final String deviceLang; // ✅ Ajouté
  final Recipient recipient;

  const EditRecipientScreen({
    super.key,
    required this.deviceId,
    required this.deviceLang, // ✅ Ajouté
    required this.recipient,
  });

  @override
  State<EditRecipientScreen> createState() => _EditRecipientScreenState();
}

class _EditRecipientScreenState extends State<EditRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _relationController;
  late TextEditingController _iconController;
  late bool _paired;
  late List<String> _selectedPacks;

  final List<String> availablePacks = ['romantic', 'tender', 'funny'];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.recipient.displayName);
    _relationController = TextEditingController(text: widget.recipient.relation);
    _iconController = TextEditingController(text: widget.recipient.icon);
    _paired = widget.recipient.paired;
    _selectedPacks = List<String>.from(widget.recipient.allowedPacks);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final docRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .collection('recipients')
        .doc(widget.recipient.id);

    await docRef.update({
      'displayName': _displayNameController.text,
      'relation': _relationController.text,
      'icon': _iconController.text,
      'paired': _paired,
      'allowedPacks': _selectedPacks,
    });

    Navigator.pop(context, true); // retour avec signal de mise à jour
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("✏️ Modifier le destinataire"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Nom affiché", _displayNameController),
              _buildTextField("Relation", _relationController),
              _buildTextField("Icône (ex: 💖)", _iconController),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _paired,
                onChanged: (val) => setState(() => _paired = val),
                title: const Text("Appairé", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              const Text("Packs autorisés :", style: TextStyle(color: Colors.white)),
              Wrap(
                spacing: 8,
                children: availablePacks.map((pack) {
                  final selected = _selectedPacks.contains(pack);
                  return FilterChip(
                    label: Text(pack),
                    selected: selected,
                    selectedColor: Colors.pink,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedPacks.add(pack);
                        } else {
                          _selectedPacks.remove(pack);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.check),
                label: const Text("Enregistrer"),
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
      ),
    );
  }
}
