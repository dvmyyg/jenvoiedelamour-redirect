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
// ✅ Supporte le défilement infini (infinite looping).
// ✅ Correction du warning 'withOpacity' deprecated en utilisant 'withAlpha'.
// ✅ **Syntaxe du constructeur mise à jour (super parameters).** // <-- NOUVEAU
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V006 - Passage à la syntaxe super parameters pour le paramètre 'key' du constructeur. - 2025/06/06 20h25 // <-- NOUVELLE ENTRÉE
// V005 - Correction du warning 'withOpacity' en remplaçant par 'withAlpha(51)'. - 2025/06/06 20h15 (Historique conservé)
// V004 - Ajout du défilement infini (infinite looping) - 2025/06/06 20h00 (Historique conservé)
// V003 - ajout d’un léger zoom (1.08) sur la carte centrale - 2025/06/06 19h28 (Historique conservé)
// V002 - assombrissement automatique des cartes non centrées - 2025/06/06 19h10 (Historique conservé)
// V001 - ajout du carrousel vertical ContactsCarousel - 2025/06/06 18h48 (Historique conservé)
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/06/06 // Mise à jour le 06/06

import 'package:flutter/material.dart';

class ContactsCarousel extends StatefulWidget {
  final List<Widget> cards;

  // 🎯 CORRECTION ICI : Utilisation de super.key
  const ContactsCarousel({
    super.key, // Remplacement de 'Key? key,' et suppression de ': super(key: key)'
    required this.cards,
  });

  @override
  State<ContactsCarousel> createState() => _ContactsCarouselState();
}

class _ContactsCarouselState extends State<ContactsCarousel> {
  late FixedExtentScrollController _controller;
  // Stocke l'index réel (cyclique) de la carte sélectionnée pour les effets visuels
  int _realSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Si la liste n'est pas vide, initialise le contrôleur pour le défilement infini
    // et positionne au milieu d'une boucle.
    final initialIndex = widget.cards.isNotEmpty ? (widget.cards.length * 500) : 0;
    _controller = FixedExtentScrollController(initialItem: initialIndex);

    // Écoute les changements de sélection pour mettre à jour l'index réel central
    _controller.addListener(() {
      // Calcule l'index réel (cyclique)
      final newRealIndex = _controller.selectedItem % widget.cards.length;
      // Met à jour l'état si l'index réel a changé pour déclencher un rebuild et appliquer les effets
      if (_realSelectedIndex != newRealIndex) {
        setState(() {
          _realSelectedIndex = newRealIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si la liste est vide, on affiche un indicateur ou un message.
    if (widget.cards.isEmpty) {
      return const Center(
        // TODO: Utiliser getUILabel pour la traduction ici aussi
        child: Text(
          "Aucun destinataire à afficher.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Le nombre total d'éléments est très grand pour simuler l'infini.
    final int infiniteChildCount = widget.cards.length * 1000;

    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 220,
      perspective: 0.003,
      diameterRatio: 2.2,
      useMagnifier: true,
      magnification: 1.05,
      physics: const FixedExtentScrollPhysics(),
      // onSelectedItemChanged est retiré car la logique est gérée par le Listener du controller
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: infiniteChildCount,
        builder: (context, index) {
          // Calcule l'index réel dans ta liste d'origine
          final int realIndex = index % widget.cards.length;
          // Détermine si la carte actuelle (à l'index réel) est la carte sélectionnée réelle
          final isSelected = realIndex == _realSelectedIndex;

          return Transform.scale(
            scale: isSelected ? 1.08 : 1.0,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                // Correction : Remplacement de withOpacity(0.2) par withAlpha(51)
                isSelected ? Colors.transparent : Colors.black.withAlpha(51),
                BlendMode.darken,
              ),
              // Utilise l'index réel pour récupérer le bon widget
              child: widget.cards[realIndex],
            ),
          );
        },
      ),
    );
  }
}

// 📄 FIN de lib/widgets/contacts_carousel.dart
