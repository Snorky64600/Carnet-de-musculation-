import glob

# 1. Mise à jour des versions Gradle
for path in glob.glob("clean_build/android/**/*.gradle", recursive=True) + ["clean_build/android/settings.gradle"]:
    try:
        with open(path, "r") as f: content = f.read()
        content = content.replace("1.7.10", "1.9.0").replace("1.8.10", "1.9.0")
        with open(path, "w") as f: f.write(content)
    except: pass

# 2. Configuration du minSdk à 26 (requis par Health Connect)
path_app = "clean_build/android/app/build.gradle"
with open(path_app, "r") as f: content = f.read()
content = content.replace("minSdkVersion 19", "minSdkVersion 26").replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 26")
with open(path_app, "w") as f: f.write(content)

# 3. Injection des permissions et déclaration Santé Connect
manifest_path = "clean_build/android/app/src/main/AndroidManifest.xml"
with open(manifest_path, "r") as f: manifest_content = f.read()

permissions_and_queries = """
    <uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
    <uses-permission android:name="android.permission.health.READ_EXERCISE"/>
    <queries>
        <package android:name="com.google.android.apps.healthdata" />
    </queries>
    <application"""

manifest_content = manifest_content.replace("<application", permissions_and_queries)

# Déclaration obligatoire pour l'affichage dans Santé Connect
health_alias = """
        <activity-alias
            android:name="ViewPermissionUsageActivity"
            android:exported="true"
            android:targetActivity=".MainActivity"
            android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
            <intent-filter>
                <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
                <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
            </intent-filter>
        </activity-alias>
"""
manifest_content = manifest_content.replace("</activity>", "</activity>\n" + health_alias)

with open(manifest_path, "w") as f: f.write(manifest_content)

# 4. Conversion MainActivity en FlutterFragmentActivity
for path in glob.glob("clean_build/android/app/src/main/kotlin/**/MainActivity.kt", recursive=True):
    with open(path, "w") as f:
        f.write("""package com.cyril.muscu.carnet_musculation;
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity() {}""")
        
