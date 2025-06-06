plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.learn_to_talk"
    compileSdk = 35 // Updated to Android 15 (API 35) to support all Flutter plugins
    
    // Disable lint checks for release builds
    lint {
        abortOnError = false
        checkReleaseBuilds = false
        disable.add("InvalidPackage")
        disable.add("NewApi")
    }
    
    // Disable resource shrinking and minification for release builds
    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
    
    // Configure AAPT options to avoid resource issues
    aaptOptions {
        noCompress("tflite") // For ML Kit models
        ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:.*:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~"
        additionalParameters.add("--no-version-vectors")
        additionalParameters.add("--no-version-transitions")
    }
    ndkVersion = "27.0.12077973" // Update to higher version required by plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.learn_to_talk"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24 // Updated from flutter.minSdkVersion to support flutter_sound
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

flutter {
    source = "../.."
}
