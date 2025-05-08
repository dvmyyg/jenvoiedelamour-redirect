### 📛 Liste des bugs connus dans l'application "J'envoie de l'amour"

---

#### 🐞 1. Problème d'inscription Firebase (App Check)
- **Contexte :** L'inscription crée bien un compte dans Firebase Auth, mais le téléphone retourne une erreur.
- **Erreur détectée :** `No AppCheckProvider installed`
- **Cause probable :** App Check Firebase est activé mais mal configuré (signature SHA-256 manquante, AppCheck non activé côté console avec Play Integrity).
- **Conséquence :** Erreur bloquante sur certaines fonctionnalités dès l'inscription.
- **Correction prévue :** Générer et ajouter la SHA-256 dans Firebase Console + activer Play Integrity + configurer proprement `firebase_app_check`.

---

#### 🐞 2. messageType ne se réinitialise pas toujours
- **Contexte :** Lors de la réception d’un message, `messageType` est supprimé après affichage de la notification.
- **Bug observé :** Dans certains cas, `messageType` reste en base et provoque un double affichage.
- **Correction envisagée :** Ajouter une vérification lors de la réception ou utiliser un champ horodaté unique pour éviter les doublons.

---

#### 🐞 3. allowedPacks vide empêche l'envoi de messages
- **Contexte :** Lors de la création d’un destinataire, si `allowedPacks` n’est pas défini, la page d’envoi (SendMessageScreen) est vide.
- **Conséquence :** Aucun message n’est proposé à l’envoi, sans explication visuelle.
- **Correction proposée :** Ajouter une valeur par défaut à `allowedPacks` lors de la création (ex: `["heart"]`) + ajouter une alerte utilisateur si vide.

---

#### 🐞 4. Problème de redirection URI lors de l'appairage manuel
- **Contexte :** Le lien de pairing contient un paramètre `recipient`, mais certaines plateformes ne le déclenchent pas comme prévu.
- **Conséquence :** L'appairage manuel échoue silencieusement.
- **Correction envisagée :** Documenter un guide utilisateur ou modifier le lien pour qu'il force l’ouverture via un scheme personnalisé (ou Firebase Dynamic Links).

---

#### 🐞 5. Email non vérifié = navigation quand même autorisée
- **Contexte :** Après inscription, un utilisateur non vérifié est redirigé vers LoveScreen.
- **Comportement attendu :** Bloquer la navigation tant que l’email n’est pas confirmé.
- **Correction proposée :** Afficher une page dédiée avec un message d'attente de validation + bouton pour relancer l'envoi du lien de vérification.

---

#### 🐞 6. Problème de code pairing déjà utilisé
- **Contexte :** Un code de pairing peut être généré deux fois.
- **Conséquence :** Collision et statut incohérent entre deux appairages.
- **Correction proposée :** Forcer la suppression des pairings expirés ou déjà finalisés (nettoyage régulier ou TTL dans Firestore).

---

#### 🐞 7. Bug potentiel : SharedPreferences non clearé après logout
- **Contexte :** Le deviceId est conservé localement.
- **Risque :** En cas de changement d'utilisateur, les données sont croisées.
- **Correction proposée :** Ajouter une fonction de reset des SharedPreferences lors du logout.

---

#### 🐞 8. Absence de feedback UI lors d’un envoi réussi
- **Contexte :** Après appui sur un message, seul un `SnackBar` apparaît, sans feedback visuel fort.
- **Correction suggérée :** Ajouter une animation (💌 qui part ?) ou retour visuel temporaire plus marquant.
