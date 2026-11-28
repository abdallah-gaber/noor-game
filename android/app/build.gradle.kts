import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStore = providers.environmentVariable("NOOR_RELEASE_STORE_FILE")
val releasePassword = providers.environmentVariable("NOOR_RELEASE_STORE_PASSWORD")
val releaseAlias = providers.environmentVariable("NOOR_RELEASE_KEY_ALIAS")

val adventurePlaytest = providers.gradleProperty("noorAdventurePlaytest").orNull == "true"
val adventureEntrypoint = providers.gradleProperty("target").orNull
    ?.replace('\\', '/')?.substringAfterLast('/') == "adventure_main.dart"
val adventureMarker = Base64.getEncoder().encodeToString("NOOR_ADVENTURE_PLAYTEST=true".toByteArray())
val defines = providers.gradleProperty("dart-defines").orNull?.split(",").orEmpty()
require(adventurePlaytest == adventureEntrypoint && adventurePlaytest == (adventureMarker in defines)) {
    "Build the separate Noor adventure with scripts/build_adventure_playtest.sh."
}

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
            if (adventurePlaytest) {
                applicationIdSuffix = ".adventure"
                manifestPlaceholders["noorAppLabel"] = "نور — المغامرة"
                signingConfig = signingConfigs.getByName("debug")
            } else {
                signingConfig = signingConfigs.getByName("noorRelease")
            }
            if (!adventurePlaytest && providers.gradleProperty("noorDeviceQa").orNull == "true") {
                applicationIdSuffix = ".deviceqa"
                manifestPlaceholders["noorAppLabel"] = "نور — اختبار الجهاز"
            }
        }
    }
}

val verifyNoorReleaseSigning = tasks.register("verifyNoorReleaseSigning") {
    doLast {
        require(
            adventurePlaytest || (!releaseStore.orNull.isNullOrBlank() &&
                !releasePassword.orNull.isNullOrBlank() &&
                !releaseAlias.orNull.isNullOrBlank()),
        ) {
            "Set NOOR_RELEASE_STORE_FILE, NOOR_RELEASE_STORE_PASSWORD and NOOR_RELEASE_KEY_ALIAS."
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild") dependsOn(verifyNoorReleaseSigning)
    if (adventurePlaytest && name in setOf("preDebugBuild", "preProfileBuild")) {
        doFirst { error("The Noor adventure playtest requires a release-mode APK.") }
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
