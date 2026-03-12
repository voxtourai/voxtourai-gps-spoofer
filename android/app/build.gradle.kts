import org.gradle.api.GradleException
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val keystorePropsFile = rootProject.file("keystore.properties")
    if (keystorePropsFile.exists()) {
        keystorePropsFile.inputStream().use { load(it) }
    }
}

val platformSecretsProperties = Properties().apply {
    val platformSecretsFile = rootProject.file("platform-secrets.properties")
    if (platformSecretsFile.exists()) {
        platformSecretsFile.reader(Charsets.UTF_8).use { load(it) }
    }
}

fun signingProperty(name: String, envName: String): String? {
    val fromGradle = project.findProperty(name) as String?
    val fromKeystoreFile = keystoreProperties.getProperty(name)
    val fromEnv = System.getenv(envName)
    return fromGradle?.takeIf { it.isNotBlank() }
        ?: fromKeystoreFile?.takeIf { it.isNotBlank() }
        ?: fromEnv?.takeIf { it.isNotBlank() }
}

fun environmentProperty(name: String, envName: String = name): String? {
    val fromGradle = project.findProperty(name) as String?
    val fromEnv = System.getenv(envName)
    return fromGradle?.takeIf { it.isNotBlank() }
        ?: fromEnv?.takeIf { it.isNotBlank() }
}

fun platformSecret(name: String): String? =
    platformSecretsProperties.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }

val releaseStoreFile = signingProperty("storeFile", "ANDROID_KEYSTORE_FILE")
val releaseStorePassword =
    signingProperty("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingProperty("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword =
    signingProperty("keyPassword", "ANDROID_KEY_PASSWORD") ?: releaseStorePassword
val hasReleaseSigning =
    !releaseStoreFile.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        !releaseKeyAlias.isNullOrBlank()

android {
    namespace = "ai.voxtour.voxtourai_gps_spoofer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ai.voxtour.voxtourai_gps_spoofer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val mapsApiKey = environmentProperty("MAPS_API_KEY")
            ?: platformSecret("MAPS_API_KEY_ANDROID")
            ?: throw GradleException(
                "MAPS_API_KEY is required. Pass -PMAPS_API_KEY=..., set the MAPS_API_KEY " +
                    "environment variable, " +
                    "or run ./scripts/grab-platform-secrets.sh to generate android/platform-secrets.properties."
            )
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Keep local release builds working, but this output is not Play-uploadable.
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-location:21.3.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
