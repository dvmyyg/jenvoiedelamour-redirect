// -------------------------------------------------------------
// 📄 FICHIER : lib/models/recipient.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Modèle de données pour représenter un destinataire (un autre utilisateur appairé).
// ✅ Contient les informations essentielles d'un destinataire (nom d'affichage, icône, relation, packs autorisés, état d'appairage, type de catalogue).
// ✅ Utilise l'UID Firebase de l'autre utilisateur comme identifiant unique principal ('id').
// ✅ Fournit des méthodes pour copier l'objet (copyWith).
// ✅ Inclut des factories et méthodes pour la conversion entre l'objet Dart et le format de données Firestore (Map<String, dynamic>).
// ✅ La conversion Firestore utilise l'ID du document (qui est l'UID du destinataire) pour remplir le champ 'id' du modèle.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V005 - Code examiné par Gemini. Modèle Recipient confirmé comme correctement refactorisé pour utiliser l'UID du destinataire comme ID principal ('id') et pour la conversion Firestore. Logique obsolète (deviceId) bien retirée. - 2025/05/31
// V004 - Remplacement du champ deviceId par l'UID du destinataire dans le modèle. L'ID du document Firestore (stocké dans le champ 'id') devient l'UID du destinataire. - 2025/05/29
// V003 - ajout de la méthode copyWith - 2025/05/27
// V002 - ajout du champ catalogType pour sélection du type de messages - 2025/05/28 10h26
// V001 - version initiale - 2025/05/21
// -------------------------------------------------------------

// GEM - code corrigé par Gémini le 2025/05/29

import 'package:cloud_firestore/cloud_firestore.dart';

class Recipient {
  // L'identifiant de ce destinataire. Après refactoring, c'est l'UID Firebase de l'autre utilisateur.
  final String id;

  final String displayName;
  final String icon;
  final String relation;
  final List<String> allowedPacks;
  final bool paired;
  final String catalogType;
  final Timestamp? createdAt; // ⭐️ AJOUTER LA DÉCLARATION DU CHAMP ICI

  Recipient({
    required this.id, // <-- ID (qui sera l'UID Firebase)
    required this.displayName,
    required this.icon,
    required this.relation,
    required this.allowedPacks,
    required this.paired,
    this.catalogType = 'partner',
    this.createdAt, // ⭐️ AJOUTER LE PARAMÈTRE AU CONSTRUCTEUR ICI
  });

  Recipient copyWith({
    String? id,
    String? displayName,
    String? icon,
    String? relation,
    List<String>? allowedPacks,
    bool? paired,
    String? catalogType,
  }) {
    return Recipient(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
      relation: relation ?? this.relation,
      allowedPacks: allowedPacks ?? this.allowedPacks,
      paired: paired ?? this.paired,
      catalogType: catalogType ?? this.catalogType,
    );
  }

  // Factory pour transformation Firestore → objet Recipient (adaptée pour lire l'UID comme ID principal)
  factory Recipient.fromMap(String id, Map<String, dynamic> data) {
    // 'id' vient de l'ID du document Firestore (qui sera l'UID du destinataire après refactoring)
    return Recipient(
      id: id,
      displayName: data['displayName'] ?? '',
      icon: data['icon'] ?? '',
      relation: data['relation'] ?? '',
      allowedPacks: List<String>.from(data['allowedPacks'] ?? []),
      paired: data['paired'] ?? false,
      catalogType: data['catalogType'] ?? 'partner',
    );
  }

  // Transformation objet Recipient → Firestore (adaptée pour ne pas écrire le champ deviceId)
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'icon': icon,
      'relation': relation,
      'allowedPacks': allowedPacks,
      'paired': paired,
      'catalogType': catalogType,
    };
  }
}
// 📄 FIN de lib/models/recipient.dart
