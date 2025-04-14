// 📄 lib/screens/add_recipient_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

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
  bool _paired = false;
  List<String> _selectedPacks = [];

  final List<String> availablePacks = ['romantic', 'tender', 'funny'];

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Future<void> _saveRecipient() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = capitalize(_displayNameController.text.trim());
    final relation = capitalize(_relationController.text.trim());
    final icon = _iconController.text.trim();

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
      'paired': _paired,
      'allowedPacks': _selectedPacks,
      'deviceId': null, // sera rempli lors de l’appairage
    });

    Navigator.pop(context, true); // retour avec succès
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("➕ Nouveau destinataire"),
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
                onPressed: _saveRecipient,
                icon: const Icon(Icons.check),
                label: const Text("Créer"),
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
