// lib/models/message.dart

// Historique du fichier
// V001 - modèle initial pour la messagerie bilatérale - 2025/05/26 19h12

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String from;
  final String to;
  final String catalog;
  final String type;
  final String simple;
  final String emoji;
  final String animation;
  final String sound;
  final String color;
  final Timestamp sentAt;
  final Timestamp? seenAt;

  Message({
    required this.id,
    required this.from,
    required this.to,
    required this.catalog,
    required this.type,
    required this.simple,
    required this.emoji,
    required this.animation,
    required this.sound,
    required this.color,
    required this.sentAt,
    this.seenAt,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    final rich = data['rich'] ?? {};
    return Message(
      id: id,
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      catalog: data['catalog'] ?? '',
      type: data['type'] ?? '',
      simple: data['simple'] ?? '',
      emoji: rich['emoji'] ?? '',
      animation: rich['animation'] ?? '',
      sound: rich['sound'] ?? '',
      color: rich['color'] ?? '',
      sentAt: data['sentAt'] ?? Timestamp.now(),
      seenAt: data['seenAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'catalog': catalog,
      'type': type,
      'simple': simple,
      'rich': {
        'emoji': emoji,
        'animation': animation,
        'sound': sound,
        'color': color,
      },
      'sentAt': sentAt,
      if (seenAt != null) 'seenAt': seenAt,
    };
  }
}
