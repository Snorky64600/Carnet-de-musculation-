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
with open(path_app, "w") as f:
    f.write(content)

# 3. Remplace MainActivity par FlutterFragmentActivity pour Health Connect
for path in glob.glob("clean_build/android/app/src/main/kotlin/**/MainActivity.kt", recursive=True):
    with open(path, "w") as f:
        f.write("""package com.cyril.muscu.carnet_musculation;

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
""")

# 4. Ajoute les permissions et activités Health Connect dans l'AndroidManifest.xml
manifest_path = "clean_build/android/app/src/main/AndroidManifest.xml"
with open(manifest_path, "r") as f:
    m_content = f.read()

permissions = """
    <uses-permission android:name="android.permission.health.READ_EXERCISE"/>
    <uses-permission android:name="android.permission.health.WRITE_EXERCISE"/>
    <uses-permission android:name="android.permission.health.READ_ACTIVE_ENERGY_BURNED"/>
    <uses-permission android:name="android.permission.health.WRITE_ACTIVE_ENERGY_BURNED"/>
    <queries>
        <package android:name="com.google.android.apps.healthdata" />
    </queries>
"""
if "<uses-permission" not in m_content:
    m_content = m_content.replace("<application", permissions + "\n    <application")

activity_perm = """
    <activity
        android:name="androidx.health.connect.client.PermissionController$Companion$RequestPermissionActivity"
        android:exported="true">
        <intent-filter>
            <action android:name="androidx.health.connect.client.action.REQUEST_PERMISSIONS" />
        </intent-filter>
    </activity>
"""
if "RequestPermissionActivity" not in m_content:
    m_content = m_content.replace("</application>", activity_perm + "\n    </application>")

with open(manifest_path, "w") as f:
    f.write(m_content)
  
