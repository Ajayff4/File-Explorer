package com.ajayff4.fileexplorer

import io.flutter.embedding.engine.FlutterEngine

// Compiled ONLY into the `standard` (Play Store) flavor. The downloader is
// excluded from this flavor, so this is intentionally a no-op: no
// MethodChannel, no EventChannel, no Chaquopy/Python glue, no ffmpeg. The
// matching real implementation lives in src/universal/java/.../DownloaderBridge.kt.
// MainActivity calls this same signature; here it does nothing, guaranteeing
// zero downloader traces in the `standard` APK.
fun maybeSetupDownloaderBridge(activity: MainActivity, flutterEngine: FlutterEngine) {
    // intentionally empty
}
