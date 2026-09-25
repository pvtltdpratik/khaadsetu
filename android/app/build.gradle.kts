import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.khaadsetu_version1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.khaadsetu_version1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Lets each flavor set its own app name with resValue (off by default in newer Android Gradle plugins).
    buildFeatures {
        resValues = true
    }

    // Four apps from one codebase (see lib/main_*.dart and build_all.bat / build_all.sh).
    // Each has its own applicationId, so they install side by side, and its own name and icon.
    flavorDimensions += "app"
    productFlavors {
        create("farmer") {
            dimension = "app"
            applicationId = "com.shetsamruddhi.farmer"
            resValue("string", "app_name", "farmer")
        }
        create("center") {
            dimension = "app"
            applicationId = "com.shetsamruddhi.center"
            resValue("string", "app_name", "center")
        }
        create("admin") {
            dimension = "app"
            applicationId = "com.shetsamruddhi.admin"
            resValue("string", "app_name", "admin")
        }
        create("dev") {
            dimension = "app"
            applicationId = "com.shetsamruddhi.dev"
            resValue("string", "app_name", "dev")
        }
    }

    // Release signing. android/key.properties (git-ignored) points at our own keystore, so
    // every release APK carries the same stable signature. Without that file the build
    // falls back to the debug key so `flutter run --release` still works on a fresh checkout.
    val keyProps = Properties().apply {
        val f = rootProject.file("key.properties")
        if (f.exists()) f.inputStream().use { load(it) }
    }
    signingConfigs {
        if (keyProps.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
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
