// -------------------------------------------------------------
// 📄 FICHIER : lib/models/user_profile.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Modèle de données pour le profil utilisateur stocké dans Firestore (/users/{uid}).
// ✅ Inclut les champs de base du profil (prénom, rôle, langue préférée).
// ✅ Fournit des méthodes pour convertir les données entre le format Firestore (Map) et l'objet Dart (UserProfile).
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - Version initiale du modèle UserProfile. - 2025/06/13 23h05
// -------------------------------------------------------------

// TODO: Ajouter les imports nécessaires si d'autres types sont utilisés (ex: Timestamp si on ajoute un champ createdAt)
// import 'package:cloud_firestore/cloud_firestore.dart'; // Décommenter si besoin de Timestamp par exemple

class UserProfile {
  final String uid; // L'UID Firebase de l'utilisateur
  final String firstName;
  final bool isReceiver;
  final String deviceLang; // Langue préférée de l'utilisateur (peut être stockée ici ou seulement dans CurrentUserService)

  // TODO: Ajouter d'autres champs si nécessaire (ex: avatarUrl, createdAt, etc.)

  UserProfile({
    required this.uid,
    required this.firstName,
    required this.isReceiver,
    required this.deviceLang,
  });

  // Méthode pour créer un UserProfile à partir d'un document Firestore
  // Utilise Map<String, dynamic>? car le document peut ne pas exister ou être vide (bien que peu probable pour le profil courant)
  factory UserProfile.fromFirestore(String uid, Map<String, dynamic>? data) {
    // Gérer le cas où data est null ou incomplet en fournissant des valeurs par défaut
    data = data ?? {};
    return UserProfile(
      uid: uid,
      firstName: data['firstName'] ?? 'Utilisateur', // Fournir une valeur par défaut
      isReceiver: data['isReceiver'] ?? false, // Fournir une valeur par défaut
      deviceLang: data['deviceLang'] ?? 'en', // Fournir une valeur par défaut (ou utiliser PlatformDispatcher.instance.locale.languageCode si pas stocké)
    );
  }

  // Méthode pour convertir un UserProfile en Map pour l'écriture dans Firestore
  Map<String, dynamic> toFirestore() {
    return {
      // L'UID n'a pas besoin d'être stocké dans la map si c'est l'ID du document, mais cela peut aider à la cohérence
      // 'uid': uid,
      'firstName': firstName,
      'isReceiver': isReceiver,
      'deviceLang': deviceLang,
      // TODO: Inclure d'autres champs ici
    };
  }

  // Optionnel: méthode toString pour le debug
  @override
  String toString() {
    return 'UserProfile{uid: $uid, firstName: $firstName, isReceiver: $isReceiver, deviceLang: $deviceLang}';
  }

  // Optionnel: méthode copyWith pour créer une nouvelle instance modifiée
  UserProfile copyWith({
    String? uid,
    String? firstName,
    bool? isReceiver,
    String? deviceLang,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      isReceiver: isReceiver ?? this.isReceiver,
      deviceLang: deviceLang ?? this.deviceLang,
    );
  }
}

// 📄 FIN de lib/models/user_profile.dart
