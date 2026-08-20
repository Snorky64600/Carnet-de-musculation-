import glob

# 1. Force minSdkVersion à 26 pour Health Connect
path_app = "clean_build/android/app/build.gradle"
with open(path_app, "r") as f:
    content = f.read()
content = content.replace("minSdkVersion 19", "minSdkVersion 26")
content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 26")
with open(path_app, "w") as f:
    f.write(content)

# 2. Remplace MainActivity par FlutterFragmentActivity pour Health Connect
for path in glob.glob("clean_build/android/app/src/main/kotlin/**/MainActivity.kt", recursive=True):
    with open(path, "w") as f:
        f.write("""package com.cyril.muscu.carnet_musculation;

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
""")
        
