// -------------------------------------------------------------
// 📄 FICHIER : lib/widgets/contacts_carousel.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Widget réutilisable ContactsCarousel (effet carrousel vertical)
// ✅ Effet cylindre 3D simulé avec ListWheelScrollView
// ✅ Scroll vertical fluide avec zoom central (magnification)
// ✅ Aucune modification visuelle du contenu des cartes
// ✅ Mise en évidence de la carte centrale, assombrissement des cartes non sélectionnées
// ✅ Zoom léger sur la carte centrale via Transform.scale
// ✅ Intégrable directement dans HomeScreen ou autre écran
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - ajout du carrousel vertical ContactsCarousel - 2025/06/06 18h48
// V002 - assombrissement automatique des cartes non centrées - 2025/06/06 19h10
// V003 - ajout d’un léger zoom (1.08) sur la carte centrale - 2025/06/06 19h28
// -------------------------------------------------------------

import 'package:flutter/material.dart';

class ContactsCarousel extends StatefulWidget {
  final List<Widget> cards;

  const ContactsCarousel({
    Key? key,
    required this.cards,
  }) : super(key: key);

  @override
  State<ContactsCarousel> createState() => _ContactsCarouselState();
}

class _ContactsCarouselState extends State<ContactsCarousel> {
  late FixedExtentScrollController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 220,
      perspective: 0.003,
      diameterRatio: 2.2,
      useMagnifier: true,
      magnification: 1.05,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.cards.length,
        builder: (context, index) {
          final isSelected = index == _currentIndex;
          return Transform.scale(
            scale: isSelected ? 1.08 : 1.0,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.transparent : Colors.black.withOpacity(0.2),
                BlendMode.darken,
              ),
              child: widget.cards[index],
            ),
          );
        },
      ),
    );
  }
}

// 📄 FIN de lib/widgets/contacts_carousel.dart
