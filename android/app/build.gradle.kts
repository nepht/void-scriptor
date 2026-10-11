import java.util.Properties

// Release signing is driven by android/key.properties (gitignored). CI restores
// it from GitHub Secrets before building; local release builds use the keystore
// generated for this project. When the file is absent we keep the debug config
// so a fresh clone / keystore-less environment can still build and run.
val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = signingPropertiesFile.exists()
if (hasReleaseSigning) {
    signingPropertiesFile.inputStream().use { signingProperties.load(it) }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.voidscriptor.void_scriptor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.voidscriptor.void_scriptor"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = signingProperties["keyAlias"] as String
                keyPassword = signingProperties["keyPassword"] as String
                storeFile = rootProject.file(signingProperties["storeFile"] as String)
                storePassword = signingProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the production upload key when configured; otherwise fall back
            // to debug keys so `flutter run --release` still works in a clone
            // that has no keystore. Never ship a debug-signed build to a store.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
