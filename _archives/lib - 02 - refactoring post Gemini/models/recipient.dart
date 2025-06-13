// lib/models/recipient.dart

// Historique du fichier
// V004 - Remplacement du champ deviceId par l'UID du destinataire dans le modèle. L'ID du document Firestore (stocké dans le champ 'id') devient l'UID du destinataire. - 2025/05/29
// V003 - ajout de la méthode copyWith - 2025/05/27
// V002 - ajout du champ catalogType pour sélection du type de messages - 2025/05/28 10h26
// V001 - version initiale - 2025/05/21

// GEM - code corrigé par Gémini le 2025/05/29

class Recipient {
  // L'identifiant de ce destinataire. Après refactoring, c'est l'UID Firebase de l'autre utilisateur.
  final String id;

  final String displayName;
  final String icon;
  final String relation;
  // L'ancien champ 'deviceId' est supprimé car l'ID du document (stocké dans 'id') est maintenant l'UID Firebase
  // final String deviceId; // <-- ANCIEN CHAMP SUPPRIMÉ
  final List<String> allowedPacks;
  final bool paired;
  final String catalogType;

  Recipient({
    required this.id, // <-- ID (qui sera l'UID Firebase)
    required this.displayName,
    required this.icon,
    required this.relation,
    // required this.deviceId, // <-- SUPPRIMÉ DU CONSTRUCTEUR
    required this.allowedPacks,
    required this.paired,
    this.catalogType = 'partner',
  });

  // Méthode copyWith mise à jour (sans le champ deviceId)
  Recipient copyWith({
    String? id,
    String? displayName,
    String? icon,
    String? relation,
    // String? deviceId, // <-- SUPPRIMÉ DE copyWith
    List<String>? allowedPacks,
    bool? paired,
    String? catalogType,
  }) {
    return Recipient(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
      relation: relation ?? this.relation,
      // deviceId: deviceId ?? this.deviceId, // <-- SUPPRIMÉ DE copyWith
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
      // L'ancien champ 'deviceId' n'est plus lu depuis Firestore
      // deviceId: data['deviceId'] ?? '', // <-- SUPPRIMÉ DE fromMap
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
      // L'ancien champ 'deviceId' n'est plus écrit dans Firestore
      // 'deviceId': deviceId, // <-- SUPPRIMÉ DE toMap
      'allowedPacks': allowedPacks,
      'paired': paired,
      'catalogType': catalogType,
    };
  }
}
