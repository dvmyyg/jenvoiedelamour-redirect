## Choix techniques de l’application Jela (Flutter/Firebase)

### 🔧 Architecture et outils de base
- **Flutter** : Framework principal, avec support Material 3.
- **Dart 3.7.0** : Version spécifiée dans `pubspec.yaml`
- **Firebase** utilisé pour :
  - Authentification (firebase_auth)
  - Firestore (cloud_firestore)
  - Notifications push (firebase_messaging)
  - Stockage (firebase_storage)
  - Analytics (firebase_analytics)
  - App Check (firebase_app_check)
- **BoM Firebase** : utilisé via `build.gradle.kts` pour gérer les versions Firebase de façon centralisée.
- **App Check** : activé avec Play Integrity. Signature SHA-256 nécessaire.
- **Notifications locales** : plugin `flutter_local_notifications` intégré avec gestion spécifique sur Android.
- **UUID** : utilisé pour générer un identifiant unique d’appareil, stocké en local.
- **Partage natif** : plugin `share_plus` pour envoi de liens d’appairage.

---

### 📁 Structure des fichiers
- `main.dart` : point d’entrée, initialisation Firebase + App Check + lien entrant.
- `firebase_options.dart` : options Firebase générées automatiquement.
- `home_selector.dart` : écran de choix (connexion ou accueil)
- `auth_service.dart` : encapsulation logique Firebase Auth.
- `device_service.dart` : gestion de l’ID local de l’appareil.
- `firestore_service.dart` : enregistrement de l’appareil dans Firestore.
- `recipient_service.dart` : logique CRUD pour les destinataires.
- `i18n_service.dart` : multi-langue simplifiée (clé/langue).
- `screens/*` : écrans thématiques (register, login, love, recipients, etc.)
- `models/recipient.dart` : modèle Firestore pour les destinataires.

---

### 🔐 Authentification & Appairage
- **Création de compte** avec email/mot de passe.
- Vérification email envoyée.
- Sauvegarde du `deviceId` lié à l'utilisateur Firebase dans `users/{uid}`.
- Chaque appareil a un `deviceId` généré et persistant.
- Appairage via :
  - Un champ `pairingCode` dans `devices`
  - Un document dans la collection `pairings/{code}` qui contient `deviceA` et `deviceB`
  - Ajout d’une `deviceId` au destinataire dans `recipients/{id}`

---

### 🔔 Notifications et messagerie
- **FCM** activé avec réception de messages via `onBackgroundMessage` et `onMessage`.
- **messageType** utilisé comme champ temporaire dans Firestore pour indiquer l’émission d’un message.
- La réception déclenche une notification locale avec cœur affiché et vibration.

---

### 💾 Stockage Firestore
- `devices/{deviceId}` : données sur l’appareil (isReceiver, nom, foreground, lastSeen...)
- `devices/{deviceId}/recipients/{recipientId}` : les destinataires individuels.
- `users/{uid}` : informations sur l’utilisateur Firebase.
- `pairings/{code}` : appairage temporaire entre deux appareils.

---

### 🌐 Lien d'appairage
- Génération d’un lien d’appairage avec `?recipient={id}` pour appairer rapidement un destinataire.
- Lien redirige vers un GitHub Page avec redirection vers l’app mobile.

---

### 📱 UI / UX
- Fond noir, accent rose (`Colors.pink`), texte blanc => UI très lisible sur AMOLED.
- Utilisation de `PageView` vertical sur LoveScreen.
- Icônes emoji pour les destinataires.
- Affichage animé d’un cœur ou d’un message selon le type reçu.

---

### 📦 Plugins & packages
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_analytics`, `firebase_app_check`
- `flutter_local_notifications`, `share_plus`, `device_info_plus`, `shared_preferences`, `uuid`, `cupertino_icons`

---

### 🧪 Tests & Debug
- Page dédiée `FirebaseTestPage` pour tester rapidement les appels `Auth` (inscription et connexion).

