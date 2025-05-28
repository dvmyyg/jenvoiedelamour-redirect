// lib/models/recipient.dart

// Historique du fichier
// V003 - ajout de la méthode copyWith - 2025/05/27
// V002 - ajout du champ catalogType pour sélection du type de messages - 2025/05/28 10h26
// V001 - version initiale - 2025/05/21

class Recipient {
  final String id;
  final String displayName;
  final String icon;
  final String relation;
  final String deviceId;
  final List<String> allowedPacks;
  final bool paired;
  final String catalogType;

  Recipient({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.relation,
    required this.deviceId,
    required this.allowedPacks,
    required this.paired,
    this.catalogType = 'partner',
  });

  Recipient copyWith({
    String? id,
    String? displayName,
    String? icon,
    String? relation,
    String? deviceId,
    List<String>? allowedPacks,
    bool? paired,
    String? catalogType,
  }) {
    return Recipient(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
      relation: relation ?? this.relation,
      deviceId: deviceId ?? this.deviceId,
      allowedPacks: allowedPacks ?? this.allowedPacks,
      paired: paired ?? this.paired,
      catalogType: catalogType ?? this.catalogType,
    );
  }

  factory Recipient.fromMap(String id, Map<String, dynamic> data) {
    return Recipient(
      id: id,
      displayName: data['displayName'] ?? '',
      icon: data['icon'] ?? '',
      relation: data['relation'] ?? '',
      deviceId: data['deviceId'] ?? '',
      allowedPacks: List<String>.from(data['allowedPacks'] ?? []),
      paired: data['paired'] ?? false,
      catalogType: data['catalogType'] ?? 'partner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'icon': icon,
      'relation': relation,
      'deviceId': deviceId,
      'allowedPacks': allowedPacks,
      'paired': paired,
      'catalogType': catalogType,
    };
  }
}
