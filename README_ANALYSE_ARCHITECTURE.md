ANALYSE DE L'ARCHITECTURE (Fichiers Flutter du projet "J'envoie de l'amour")

---

### lib/models/recipient.dart

✅ Représente un **destinataire** associé à un utilisateur (device).

Champs inclus :
- `id`: identifiant Firestore du document
- `displayName`: nom affiché (ex: Bini)
- `deviceId`: identifiant Firebase de l'appareil associé après appairage
- `relation`: clé i18n (ex: 'compagne', 'ami')
- `icon`: émoji personnalisé (💖)
- `paired`: booléen, indique si l’appairage est fait
- `allowedPacks`: liste des types de messages disponibles (ex: heart, hug, love_you...)

Utilisé dans :
- SendMessageScreen
- RecipientsScreen
- EditRecipientScreen

---

### lib/screens/send_message_screen.dart

✅ Permet d’envoyer un message à un destinataire appairé via Firestore.

- Affiche dynamiquement les types de messages autorisés par `allowedPacks`
- Utilise `getPreviewText()` pour afficher le texte localisé
- L’envoi met à jour le `messageType` et `senderName` dans le document Firestore du destinataire.

---

### lib/screens/recipient_details_screen.dart

✅ Page affichant les détails d’un destinataire.

- Présente les infos : nom, icône, relation, statut d’appairage
- Propose l’entrée d’un code d’appairage (à 4 chiffres)
- Gère Firestore pour compléter ou créer le lien avec un autre appareil
- Met à jour `paired` et `deviceId` dans Firestore après succès

---

### lib/screens/love_screen.dart

✅ Écran principal après connexion.

- Affiche la liste verticale des destinataires (avec `PageView`)
- Gère la réception des messages en écoutant Firestore
- Affiche une étoile en cas de message reçu (`showIcon`)
- Notification locale avec `flutter_local_notifications`
- Récupère et affiche le `senderName`

---

### lib/screens/register_screen.dart

✅ Gère la création d’un compte avec Firebase Auth.

- Vérifie email, mot de passe et confirmation
- Crée le compte via `AuthService.register()`
- Enregistre dans Firestore sous `/users/{uid}`
- Lance la vérification par mail

---

### lib/screens/login_screen.dart

✅ Permet de se connecter via Firebase Auth.

- Connecte un utilisateur avec email / mot de passe
- Redirige vers `LoveScreen`
- Propose un bouton vers `RegisterScreen`
- Accès à une page de test (`FirebaseTestPage`) intégrée

---

### lib/screens/home_selector.dart

✅ Choix initial en fonction de l’état de connexion Firebase.

- Si utilisateur connecté => LoveScreen
- Sinon => LoginScreen
- Gère `registerDevice` pour stocker `deviceId` et `isReceiver`

---

### lib/screens/settings_screen.dart

✅ Réglages utilisateur (nom affiché).

- Permet de modifier `displayName` lié au device
- Stocké dans `devices/{deviceId}/displayName`
- UI simple, 1 champ texte + bouton d’enregistrement

---

### lib/screens/edit_recipient_screen.dart

✅ Permet d’éditer un destinataire existant.

- Modifie nom, icône et relation
- Mise à jour Firestore sous `devices/{deviceId}/recipients/{id}`
- Propose un lien d’appairage à partager

---

### lib/screens/add_recipient_screen.dart

✅ Ajout d’un nouveau destinataire.

- Création d’un doc `Recipient` dans `devices/{deviceId}/recipients/{uuid}`
- Génération UUID et stockage initial sans deviceId
- Propose le partage du lien d’appairage via `Share`

---

### lib/services/recipient_service.dart

✅ Gestion CRUD des destinataires liés à un device.

- fetchRecipients, addRecipient, updateRecipient, deleteRecipient
- Cible la collection `devices/{deviceId}/recipients`

---

### lib/services/device_service.dart

✅ Génère ou récupère un `deviceId` local via SharedPreferences.

- Clé: 'deviceId' (UUID v4)

---

### lib/services/firestore_service.dart

✅ Enregistrement de l’appareil dans Firestore.

- Ajoute ou met à jour `deviceId`, `isReceiver`, `lastSeen`

---

### lib/services/auth_service.dart

✅ Centralise les fonctions Firebase Auth.

- register() : inscription + enregistrement Firestore
- login() : connexion utilisateur
- logout(), currentUser, isEmailVerified

---

### lib/services/i18n_service.dart

✅ Fournit les traductions multilingues pour les libellés, messages, prévisualisations.

- `getUILabel()`, `getMessageBody()`, `getPreviewText()`
- Langues supportées : fr, de, es, en

---

### lib/screens/firebase_test_page.dart

✅ Page de test pour inscription/connexion Firebase.

- Utilisée uniquement pour valider la configuration Auth à la main

---

✔️ Fin du document 1 – Analyse de l'architecture

