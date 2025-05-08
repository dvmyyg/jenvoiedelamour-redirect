// android/app/build.gradle.kts
// Ce fichier configure la compilation de l’app Flutter et la signature APK release

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
    implementation(platform("com.google.firebase:firebase-bom:33.2.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-storage-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
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
