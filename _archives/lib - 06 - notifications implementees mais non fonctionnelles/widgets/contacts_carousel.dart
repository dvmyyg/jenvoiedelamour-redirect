// -------------------------------------------------------------
// 📄 FICHIER : lib/widgets/contacts_carousel.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Widget réutilisable ContactsCarousel (effet carrousel vertical)
// ✅ Effet cylindre 3D simulé avec ListWheelScrollView
// ✅ Scroll vertical fluide avec zoom central (magnification)
// ✅ Aucune modification visuelle du contenu des cartes
// ✅ Intégrable directement dans HomeScreen ou autre écran
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - ajout du carrousel vertical ContactsCarousel - 2025/06/06 18h48
// -------------------------------------------------------------

import 'package:flutter/material.dart';

class ContactsCarousel extends StatelessWidget {
  final List<Widget> cards;

  const ContactsCarousel({
    Key? key,
    required this.cards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 220,
      perspective: 0.003,
      diameterRatio: 2.2,
      useMagnifier: true,
      magnification: 1.05,
      physics: FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildListDelegate(
        children: cards,
      ),
    );
  }
}

// 📄 FIN de lib/widgets/contacts_carousel.dart
