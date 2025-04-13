// 📄 lib/screens/add_recipient_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRecipientScreen extends StatefulWidget {
  final String deviceId;

  const AddRecipientScreen({super.key, required this.deviceId});

  @override
  State<AddRecipientScreen> createState() => _AddRecipientScreenState();
}

class _AddRecipientScreenState extends State<AddRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _relationController = TextEditingController();
  final _iconController = TextEditingController();
  List<String> _selectedPacks = [];
  bool _paired = false;

  final List<String> availablePacks = ['romantic', 'tender', 'funny'];

  @override
  void dispose() {
    _displayNameController.dispose();
    _relationController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipient() async {
    if (!_formKey.currentState!.validate()) return;

    final newDoc = FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .collection('recipients')
        .doc();

    await newDoc.set({
      'id': newDoc.id,
      'displayName': _displayNameController.text,
      'deviceId': '',
      'relation': _relationController.text,
      'icon': _iconController.text,
      'paired': _paired,
      'allowedPacks': _selectedPacks,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("➕ Ajouter un destinataire"),
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
              _buildTextField("Icône (ex: ❤️)", _iconController),
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
                onPressed: _saveRecipient,
                icon: const Icon(Icons.check),
                label: const Text("Ajouter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              )
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
