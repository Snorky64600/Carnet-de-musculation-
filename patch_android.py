import glob

# 1. Met à jour Kotlin dans tous les fichiers Gradle
for path in glob.glob("clean_build/android/**/*.gradle", recursive=True) + ["clean_build/android/settings.gradle"]:
    try:
        with open(path, "r") as f:
            content = f.read()
        content = content.replace("1.7.10", "1.9.0")
        content = content.replace("1.8.10", "1.9.0")
        with open(path, "w") as f:
            f.write(content)
    except Exception:
        pass

# 2. Force minSdkVersion à 26 pour Health Connect
path_app = "clean_build/android/app/build.gradle"
with open(path_app, "r") as f:
    content = f.read()
content = content.replace("minSdkVersion 19", "minSdkVersion 26")
content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 26")

# 3. Injecte la configuration de ta VRAIE signature (clé officielle)
signing_setup = """
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {"""

content = content.replace("android {", signing_setup)

signing_config_block = """
    signingConfigs {
        release {
            keyAlias keystoreProperties.getProperty('keyAlias')
            keyPassword keystoreProperties.getProperty('keyPassword')
            storeFile keystoreProperties.getProperty('storeFile') ? file(keystoreProperties.getProperty('storeFile')) : null
            storePassword keystoreProperties.getProperty('storePassword')
        }
    }

    buildTypes {"""

content = content.replace("buildTypes {", signing_config_block)
content = content.replace("signingConfig signingConfigs.debug", "signingConfig signingConfigs.release")

with open(path_app, "w") as f:
    f.write(content)

# 4. Remplace MainActivity par FlutterFragmentActivity pour Health Connect
for path in glob.glob("clean_build/android/app/src/main/kotlin/**/MainActivity.kt", recursive=True):
    with open(path, "w") as f:
        f.write("""package com.cyril.muscu.carnet_musculation;

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
""")
