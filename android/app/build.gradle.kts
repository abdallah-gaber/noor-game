plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStore = providers.environmentVariable("NOOR_RELEASE_STORE_FILE")
val releasePassword = providers.environmentVariable("NOOR_RELEASE_STORE_PASSWORD")
val releaseAlias = providers.environmentVariable("NOOR_RELEASE_KEY_ALIAS")

android {
    namespace = "dev.noor.noor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.noor.noor"
        manifestPlaceholders["noorAppLabel"] = "نور"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("noorRelease") {
            storeFile = file(releaseStore.orElse("missing-noor-release-keystore").get())
            storeType = "PKCS12"
            storePassword = releasePassword.orNull
            keyAlias = releaseAlias.orNull
            keyPassword = releasePassword.orNull
        }
    }

    buildTypes {
        debug {
            if (providers.gradleProperty("noorAdultReview").orNull == "true") {
                applicationIdSuffix = ".adultreview"
                manifestPlaceholders["noorAppLabel"] = "نور — مراجعة البالغين"
            }
        }
        release {
            signingConfig = signingConfigs.getByName("noorRelease")
        }
    }
}

tasks.configureEach {
    if (name == "validateSigningRelease") {
        doFirst {
            require(releaseStore.isPresent && releasePassword.isPresent && releaseAlias.isPresent) {
                "Set NOOR_RELEASE_STORE_FILE, NOOR_RELEASE_STORE_PASSWORD and NOOR_RELEASE_KEY_ALIAS."
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
