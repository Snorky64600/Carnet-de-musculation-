import glob

# 1. Mise à jour Kotlin / Gradle
for path in glob.glob("clean_build/android/**/*.gradle", recursive=True) + ["clean_build/android/settings.gradle"]:
    try:
        with open(path, "r") as f:
            content = f.read()
        content = content.replace("1.7.10", "1.9.0").replace("1.8.10", "1.9.0")
        with open(path, "w") as f:
            f.write(content)
    except Exception:
        pass

# 2. Configuration minSdkVersion = 26 & Signature release
path_app = "clean_build/android/app/build.gradle"
with open(path_app, "r") as f:
    content = f.read()

content = content.replace("minSdkVersion 19", "minSdkVersion 26")
content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 26")

signing_setup = """
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
"""

if "keystoreProperties" not in content:
    content = content.replace("android {", signing_setup + "\nandroid {")

signing_config_block = """
    signingConfigs {
        release {
            keyAlias keystoreProperties.getProperty('keyAlias')
            keyPassword keystoreProperties.getProperty('keyPassword')
            storeFile keystoreProperties.getProperty('storeFile') ? file(keystoreProperties.getProperty('storeFile')) : null
            storePassword keystoreProperties.getProperty('storePassword')
        }
    }
"""

if "signingConfigs" not in content:
    content = content.replace("buildTypes {", signing_config_block + "\n    buildTypes {")
    content = content.replace("signingConfig signingConfigs.debug", "signingConfig signingConfigs.release")

with open(path_app, "w") as f:
    f.write(content)

# 3. Injection AndroidManifest.xml pour Android 14 Santé Connect
manifest_path = "clean_build/android/app/src/main/AndroidManifest.xml"
try:
    with open(manifest_path, "r") as f:
        manifest_content = f.read()

    permissions = """
    <uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
    <uses-permission android:name="android.permission.health.READ_EXERCISE"/>
    <uses-permission android:name="android.permission.health.WRITE_EXERCISE"/>
    <queries>
        <package android:name="com.google.android.apps.healthdata" />
        <intent>
            <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
        </intent>
    </queries>
    <application"""

    if "READ_HEART_RATE" not in manifest_content:
        manifest_content = manifest_content.replace("<application", permissions)

    health_intent_filters = """
            <intent-filter>
                <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
                <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
            </intent-filter>
        </activity>
    """

    if "ACTION_SHOW_PERMISSIONS_RATIONALE" not in manifest_content:
        manifest_content = manifest_content.replace("</activity>", health_intent_filters)

    with open(manifest_path, "w") as f:
        f.write(manifest_content)
except Exception:
    pass

# 4. MainActivity
for path in glob.glob("clean_build/android/app/src/main/kotlin/**/MainActivity.kt", recursive=True):
    with open(path, "w") as f:
        f.write("""package com.cyril.muscu.carnet_musculation;

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
""")
        
