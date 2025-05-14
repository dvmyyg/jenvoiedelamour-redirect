### 📛 Liste des bugs connus dans l'application "J'envoie de l'amour"

---

#### 🐞 1. Problème d'inscription Firebase (résolu)
- **Contexte :** L'inscription crée bien un compte dans Firebase Auth, mais le téléphone retournait une erreur.
- **Erreur détectée :** `No AppCheckProvider installed` ou échec silencieux après appel `register()`.
- **Cause réelle :** App Check Firebase était activé mais mal configuré (absence de signature SHA-256, Play Integrity non activé dans la console).
- **Conséquence :** L'inscription réussissait côté Auth, mais échouait à enregistrer l'utilisateur dans Firestore (`users/{uid}`).
- **Correction appliquée :**
✅ Création d’un compte Google Play
✅ Validation identité + téléphone
✅ Création de l’app fr.jela.app
✅ Ajout de la SHA-256 Google Play dans Firebase
✅ Téléchargement et remplacement du google-services.json
✅ Recompilation en release + test sur appareil réel
✅ Vérification Firebase : requêtes désormais validées (App Check actif)

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

---

#### 🐞 9. Inscription réussie dans Firebase Auth mais Firestore non alimenté
- **Contexte :** Lors de l'inscription via `AuthService.register()`, l'utilisateur est bien créé dans Firebase Auth, mais aucune entrée n'apparaît dans Firestore.
- **Symptôme :**  
  - Authentification OK (compte visible dans l’onglet Firebase Authentication)  
  - Collection `users` absente ou vide dans Firestore  
  - Aucun log `✅ [register] Utilisateur enregistré dans Firestore` visible en console
- **Causes possibles :**  
  - Échec silencieux de l'appel `set()` vers Firestore  
  - App Check toujours bloquant sur Firestore (même après correction côté Auth)  
  - Donnée transmise invalide (deviceId ou lang null)
- **Correction proposée :**  
  - Ajouter un log juste avant l'appel à Firestore pour vérifier les données transmises  
  - Vérifier les règles Firestore côté console (permissions `write`)  
  - Désactiver temporairement App Check sur Firestore pour tester  
  - Ajouter un retour visuel dans l'app si l'enregistrement échoue

---

#### 🐞 10. Aucune requête App Check validée malgré configuration correcte

- **Contexte :** App Check a été activé avec Play Integrity sur l'application `fr.jela.app`. La SHA-256 de la clé utilisée (`keystore.jks`) a bien été ajoutée dans Firebase Console. L'intégration App Check est en place dans le code (`main.dart`), et l'APK a été généré en release, signé, et installé manuellement sur les appareils A et B.
- **Symptôme :**
  - Firebase App Check indique que 100 % des requêtes Firestore sont "non validées"
  - Aucune requête validée n’apparaît, même après installation et exécution de l’APK signé
- **Vérifications effectuées :**
  - ✅ SHA-256 du certificat release extraite avec `./gradlew signingReport`
  - ✅ SHA-256 strictement identique à celle enregistrée dans Firebase
  - ✅ App Check activé avec Play Integrity
  - ✅ App installée manuellement sur A et B, version `release`, signée
  - ✅ Code Flutter avec `FirebaseAppCheck.instance.activate(...)` bien en place
- **Analyse finale grâce à Gemini (IA Firebase) :** Le véritable problème vient du fait que Play Integrity n’accepte que les APK signés via la clé de signature d'application gérée par Google Play. Tant que l'application n'est pas publiée (ou en test interne) via Google Play, la SHA-256 à utiliser est celle de Google, non celle du keystore.jks.
- **Action engagée :** 
  - Création d'un compte Google Play Console (Validation d'identité en cours)
  - Ajout prévu de la SHA-256 Google dans Firebase une fois accessible
  - Reconfiguration d'App Check à suivre une fois la clé valide obtenue
