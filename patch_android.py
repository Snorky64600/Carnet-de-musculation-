import glob

# 1. Mise à jour des versions Gradle
for path in glob.glob("clean_build/android/**/*.gradle", recursive=True) + ["clean_build/android/settings.gradle"]:
    try:
        with open(path, "r") as f: content = f.read()
        content = content.replace("1.7.10", "1.9.0").replace("1.8.10", "1.9.0")
        with open(path, "w") as f: f.write(content)
    except: pass

# 2. Mise à jour de app/build.gradle
path_app = "clean_build/android/app/build.gradle"
with open(path_app, "r") as f: content = f.read()
content = content.replace("minSdkVersion 19", "minSdkVersion 26").replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 26")
with open(path_app, "w") as f: f.write(content)

# 3. AndroidManifest.xml (Permissions + Service Health Connect)
manifest_path = "clean_build/android/app/src/main/AndroidManifest.xml"
with open(manifest_path, "r") as f: manifest_content = f.read()

inject = """
    <uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
    <uses-permission android:name="android.permission.health.READ_EXERCISE"/>
    <queries>
        <package android:name="com.google.android.apps.healthdata" />
    </queries>
    <application"""
manifest_content = manifest_content.replace("<application", inject)

service_entry = """
        <service
            android:name="androidx.health.connect.client.impl.converters.datatype.HealthConnectClientProvider"
            android:exported="true"
            android:permission="android.permission.BIND_HEALTH_CONNECT_SERVICE">
            <intent-filter>
                <action android:name="androidx.health.connect.client.action.HEALTH_CONNECT_SERVICE" />
            </intent-filter>
        </service>
"""
manifest_content = manifest_content.replace("</activity>", "</activity>" + service_entry)
with open(manifest_path, "w") as f: f.write(manifest_content)

# 4. MainActivity
for path in glob.glob("clean_build/android/app/src/main/kotlin/**/MainActivity.kt", recursive=True):
    with open(path, "w") as f:
        f.write("""package com.cyril.muscu.carnet_musculation;
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity() {}""")
        
