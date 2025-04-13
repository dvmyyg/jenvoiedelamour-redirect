// 📄 lib/models/recipient.dart

class Recipient {
  final String id;
  final String displayName;
  final String deviceId;
  final String relation;
  final String icon;
  final bool paired;
  final List<String> allowedPacks;

  Recipient({
    required this.id,
    required this.displayName,
    required this.deviceId,
    required this.relation,
    required this.icon,
    required this.paired,
    required this.allowedPacks,
  });

  factory Recipient.fromMap(String id, Map<String, dynamic> data) {
    return Recipient(
      id: id,
      displayName: data['displayName'] ?? '',
      deviceId: data['deviceId'] ?? '',
      relation: data['relation'] ?? '',
      icon: data['icon'] ?? '',
      paired: data['paired'] ?? false,
      allowedPacks: List<String>.from(data['allowedPacks'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'deviceId': deviceId,
      'relation': relation,
      'icon': icon,
      'paired': paired,
      'allowedPacks': allowedPacks,
    };
  }
}
