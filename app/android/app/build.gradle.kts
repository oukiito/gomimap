import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// One define selects both Dart and native QA code; normal builds keep their ID.
val qaClock = (findProperty("dart-defines") as? String).orEmpty().split(',').any {
    runCatching { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        .getOrNull() == "GOMIMAP_QA=true"
}
check(!qaClock || gradle.startParameter.taskNames.none { it.contains("release", ignoreCase = true) }) {
    "The isolated QA clock is not a release target"
}
val appProject = project
gradle.taskGraph.whenReady {
    check(!qaClock || allTasks.none { it.project == appProject && it.name.contains("release", ignoreCase = true) }) {
        "The isolated QA clock is not a release target"
    }
}

android {
    namespace = "dev.gomimap.gomimap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = if (qaClock) "dev.gomimap.gomimap.qa" else "dev.gomimap.gomimap"
        manifestPlaceholders["appLabel"] = if (qaClock) "gomimap QA" else "gomimap"
        manifestPlaceholders["widgetTestTargetPackage"] = applicationId!!
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    sourceSets.named("main") {
        java.srcDir(if (qaClock) "src/qa/kotlin" else "src/standard/kotlin")
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

flutter {
    source = "../.."
}
