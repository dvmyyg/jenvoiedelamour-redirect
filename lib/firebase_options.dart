// -------------------------------------------------------------
// 📄 FICHIER : lib/firebase_options.dart
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Contient les options de configuration (clés API, ID d'app, ID de projet, etc.) pour les applications Firebase de ce projet, générées par FlutterFire CLI.
// ✅ Permet l'initialisation correcte de Firebase dans l'application Flutter via Firebase.initializeApp.
// ✅ Inclut une configuration spécifique pour la plateforme Android.
// ⚠️ NOTE : Les configurations pour d'autres plateformes (Web, iOS, macOS, Windows, Linux) ne sont pas incluses dans cette version du fichier.
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V002 - Code examiné par Gemini. Le fichier est bien structuré pour Android, mais les configurations pour d'autres plateformes sont manquantes, indiquant qu'il a été généré ou modifié pour cibler uniquement Android. Explication ajoutée sur comment regénérer avec d'autres plateformes. - 2025/05/31
// V001 - Fichier généré initialement par FlutterFire CLI, contenant la configuration Firebase pour la plateforme Android. - 2025/05/XX (Date de génération approximative)
// -------------------------------------------------------------

// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNSbcMQwMIsECoz6riF0ybqCBDn50zbxI',
    appId: '1:1087981035524:android:1d58ca2ac6ef5c52fc5551',
    messagingSenderId: '1087981035524',
    projectId: 'jelamvp01',
    storageBucket: 'jelamvp01.appspot.com',
  );
}

// 📄 FIN de lib/firebase_options.dart
