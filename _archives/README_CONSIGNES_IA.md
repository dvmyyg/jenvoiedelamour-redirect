# jelamvp01

Consignes pour ChatGPT. Tu dois les retenir et les appliquer à la lettre.

IDENTIFICATION DU PROJET
========================
projet MVP Flutter : jelamvp01
domaine utilisé : jenvoiedelamour.com
backend : Firebase Firestore (déjà intégré)
app en multilingue : textes en i18n, pas de hard-code
Firebase Dynamic Links obsolète
localisation projet : F:\development\jelamvp01
localisation Flutter 3.29.3 : F:\devtools\flutter
compte GitHub dvmyyg pour page de téléchargement app pour nouvel utilisateur

ENVIRONNEMENT DE DÉVELOPPEMENT
==============================
IDE : Visual Studio (pas Android Studio)
outils : Firebase, VSCode, Flutter, …
terminal PowerShell intégré VS Code :
- mode continuation automatique (>> pour retours multiples)
- ne supporte pas &&, retours à la ligne CMD (^) ou backticks hors bloc
- ne pas utiliser de scripts .ps1 ; tout faire en one-liner

TÉLÉPHONES CONNECTÉS
====================
Xiaomi Mi 10 Lite (72890b83) → A (arrondi)
Xiaomi Redmi 9 (001cb6320412) → B (WhatsApp Peugeot)
Xiaomi 11T Pro (port DATA HS, Wi-Fi) → C (WhatsApp perso)
mode développeur activé sur A, B, C (7× sur Version MIUI)
menu “Connexion USB” → “Transfert de fichiers (MTP)” indisponible
C ne passe pas en USB → téléchargement via GitHub

CONSIGNES DE TRAVAIL
====================
avant toute modif, ChatGPT doit me demander le fichier original
réponses courtes, préciser contexte (fichiers, chemins, arborescence, clés…)
toujours citer le chemin complet (android/app/main.dart, jamais main.dart seul)
interdiction de supprimer un code ou commentaire sans avertir

GESTION DES TÂCHES
==================
pour chaque nouveau groupe, lister étapes numérotées et état (fait/à faire)
pour chaque fichier modifié, afficher la version complète corrigée
pour chaque message, en-tête avec date et heure de Briey (https://www.time.is/fr GMT+2)
à la fin d’une étape : tester sur Flutter (puis commit si validé).

GESTION DES COMMITS
===================
fournir la commande complète git commit -m "…" (multi-ligne si besoin)
pushes/commits via Visual Studio Code, bien annoter
chemin du keystore : ajuster le nombre de ../ pour pointer sur <racine>/keystore.jks

SIGNATURE & KEYS
================
mdp : ne pas utiliser $
centraliser creds dans gradle.properties
key.properties pas utilisé
rapport de signature : lancer ./gradlew signingReport

PRÉREQUIS & VÉRIFICATIONS
=========================
plugin com.google.gms.google-services appliqué dans android/app/build.gradle.kts
compileSdkVersion et targetSdkVersion alignés sur la version Flutter utilisée
toolchains Java 17 et Kotlin 21 configurées pour Firebase & Flutter
utilisation du Firebase BoM (version 33.2.0) pour homogénéiser les dépendances
flutterfire_cli installé et mis à jour (v1.2.0 corrigée)

TRAITEMENT DES PROBLÈMES
========================
en cas de problème, être proactif :
- établir le constat rigoureux. Que devrait-il se passer ?
- comment jaloner le process pour valider étapes ?
- fichiers et bases impliqués
- proposer méthode investigation (avec logs ?)
- privilégier simplicité et pertinence.
- trace manuelle : ajouter de print Debug juste avant signingConfigs

COMMUNICATION
=============
tutoiement. Ne jamais passer à étape suivante sans confirmation explicite exécution tâche précédente.
