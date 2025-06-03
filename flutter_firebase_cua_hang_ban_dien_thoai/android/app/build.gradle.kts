plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
        import java.io.File
        import java.io.FileInputStream

// Đọc file key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.example.cross_platform_mobile_app_development"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.cross_platform_mobile_app_development"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // Cấu hình signing
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { File(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    // Cấu hình build types
    buildTypes {
        getByName("release") {
            isMinifyEnabled = true // Bật loại bỏ mã không sử dụng
            isShrinkResources = true // Bật loại bỏ tài nguyên không sử dụng
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    // Các dependencies dưới đây có thể không cần thiết trong Flutter
    // implementation("androidx.appcompat:appcompat:1.6.1")
    // implementation("com.google.android.material:material:1.11.0")
    // implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}

flutter {
    source = "../.."
}