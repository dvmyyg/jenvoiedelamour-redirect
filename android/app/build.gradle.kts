// -------------------------------------------------------------
// 📄 FICHIER : android/app/build.gradle.kts
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Configure la compilation de l’app Flutter et la signature APK release.
// ✅ Définit les versions SDK, le namespace, les options de compilation, et les toolchains Java/Kotlin.
// ✅ Gère la configuration de signature pour les builds release.
// ✅ Déclare les dépendances pour les bibliothèques essentielles, y compris Firebase via la BOM.
// ✅ **Configuration Gradle pour Firebase Cloud Messaging (application du plugin google-services et dépendance firebase-messaging) validée.**
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - Support intent://jela.app/open - 2025/05/24 15h20 (Historique hérité)
// V002 - Ajout support pour app://jela - 2025/05/25 19h42 (Historique hérité)
// V003 - Ajout/validation configuration Gradle pour FCM (plugin google-services et dépendance firebase-messaging). - 2025/06/04 // Mise à jour le 04/06
// -------------------------------------------------------------

// GEM - Code vérifié et historique mis à jour par Gémini le 2025/06/04 // Mise à jour le 04/06


plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "fr.jela.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "fr.jela.app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val store = project.property("storeFile") as String
            val storePass = project.property("storePassword") as String
            val keyAliasVal = project.property("keyAlias") as String
            val keyPass = project.property("keyPassword") as String

            println("🔐 CONFIG SIGNING RELEASE")
            println("🔐 storeFile     = $store")
            println("🔐 storePassword = $storePass")
            println("🔐 keyAlias      = $keyAliasVal")
            println("🔐 keyPassword   = $keyPass")
            println("📍 Chemin absolu keystore = ${file(store).absolutePath}")
            println("📍 Existe ? ${file(store).exists()}")

            storeFile     = file(store)
            storePassword = storePass
            keyAlias      = keyAliasVal
            keyPassword   = keyPass
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Importe le BoM Firebase pour gérer les versions
    implementation(platform("com.google.firebase:firebase-bom:33.13.0")) // Reste sur 33.13.0, c'est bon !

    // Déclare les dépendances des bibliothèques Firebase - utilise les modules principaux maintenant !
    // Les fonctionnalités KTX sont incluses dans les modules principaux depuis BoM 32.5.0+
    implementation("com.google.firebase:firebase-auth")       // PAS firebase-auth-ktx
    implementation("com.google.firebase:firebase-firestore")    // PAS firebase-firestore-ktx
    implementation("com.google.firebase:firebase-storage")    // PAS firebase-storage-ktx
    implementation("com.google.firebase:firebase-messaging")    // PAS firebase-messaging-ktx
    implementation("com.google.firebase:firebase-analytics")    // PAS firebase-analytics-ktx

    // Reste sur coreLibraryDesugaring si tu en as besoin
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

kotlin {
    jvmToolchain(21)
}

// 📄 FIN de android/app/build.gradle.kts
