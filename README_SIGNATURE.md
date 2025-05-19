### 🔐 Gestion des clés de signature Android et compatibilité Firebase App Check

---

#### 🔍 Objectif

Ce document sert à clarifier le rôle et l'utilisation actuelle des clés de signature (notamment `keystore.jks`) dans le cadre du projet "J'envoie de l'amour", en lien avec Firebase, Google Play, et App Check.

---

#### 🔒 Clé `keystore.jks`

* Utilisée pour :

  * Signer **localement** les APK destinés à être uploadés dans la Play Console
  * Effectuer des tests locaux ou installations directes d’APK (hors store)
* N'est **pas utilisable pour Play Integrity / App Check**
* Doit être **conservée précieusement** car elle constitue la clé d'upload officielle

---

#### 🔐 Clé de signature d’application Google Play

* Gérée directement par Google Play
* Utilisée automatiquement pour re-signer les APK ou AAB après upload
* À utiliser pour :

  * Obtenir la **SHA-256 correcte** à enregistrer dans Firebase pour **App Check avec Play Integrity**
  * Garantir la validation des jetons Firebase

---

#### 📊 Statut actuel du projet

* ✅ `keystore.jks` en usage pour build et signature locale
* ✅ Compte Google Play Console créé
* ⏳ En attente de validation identité développeur pour accès à la SHA-256 de Google Play
* ❌ App Check non fonctionnel tant que cette clé Google n’est pas renseignée dans Firebase

---

#### 🔎 Résumé

Aucun élément actuel n’est superflu :

* `keystore.jks` reste **indispensable pour signer les APK à uploader**
* Mais **la SHA-256 à utiliser pour App Check est celle de la clé Google Play**, et non celle de `keystore.jks`

---

Mise à jour : **09/05/2025 – Briey**
