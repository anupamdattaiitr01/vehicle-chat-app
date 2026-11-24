plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // ADDED: Apply Google Services plugin to parse android/app/google-services.json
    id("com.google.gms.google-services")
}

android {
    namespace = "com.yourcompany.vehicle_chat_app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ADDED: Required by flutter_local_notifications for scheduled/channel APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yourcompany.vehicle_chat_app"
        // Firebase Messaging requires minSdk 21 or higher
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // ADDED: Core library desugaring dependency for Android notification channels
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // ADDED: Expose FirebaseMessagingService & RemoteMessage to MiloFirebaseMessagingService.kt
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("com.google.firebase:firebase-messaging")
}

flutter {
    source = "../.."
}