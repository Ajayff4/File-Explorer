package com.ajayff4.fileexplorer

import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.content.ClipData
import android.content.ContentValues
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.Parcelable
import android.os.ParcelFileDescriptor
import android.util.Log
import android.os.StatFs
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

class MainActivity: FlutterActivity() {
    private val ALL_FILES_ACCESS_REQUEST_CODE = 4700
    private val storageChannel = "com.ajayff4.fileexplorer/storage"
    private val apkIconChannel = "com.ajayff4.fileexplorer/apk_icon"
    private val thumbnailChannel = "com.ajayff4.fileexplorer/thumbnail"
    private val wallpaperChannel = "com.ajayff4.fileexplorer/wallpaper"
    private val mediaActionsChannel = "com.ajayff4.fileexplorer/media_actions"
    private val mediaStoreChannel = "com.ajayff4.fileexplorer/media_store"
    private val wakelockChannel = "com.ajayff4.fileexplorer/wakelock"
    private val incomingChannel = "com.ajayff4.fileexplorer/incoming"
    private var incomingMethodChannel: MethodChannel? = null
    private var pendingIncomingPaths: List<String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Surface a file opened via "Open with" / a share-into before the
        // Flutter engine is ready; handled once the channel exists.
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    /// Routes ACTION_VIEW / ACTION_SEND / ACTION_SEND_MULTIPLE intents to Flutter
    /// so the built-in viewers can open the file(s) instead of a 3rd-party app.
    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val uris = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data?.let { listOf(it) } ?: emptyList()
            Intent.ACTION_SEND -> {
                val extra = intent.getParcelableExtra<Parcelable>(Intent.EXTRA_STREAM)
                (extra as? Uri)?.let { listOf(it) } ?: emptyList()
            }
            Intent.ACTION_SEND_MULTIPLE -> collectClipUris(intent)
            else -> emptyList()
        }
        val paths = uris.mapNotNull { resolvePath(it) }
        if (paths.isNotEmpty()) forwardIncomingFiles(paths)
    }

    private fun collectClipUris(intent: Intent): List<Uri> {
        val uris = mutableListOf<Uri>()
        intent.clipData?.let { clip ->
            for (i in 0 until clip.itemCount) uris.add(clip.getItemAt(i).uri)
        }
        if (uris.isEmpty()) {
            intent.getParcelableArrayListExtra<Parcelable>(Intent.EXTRA_STREAM)
                ?.forEach { (it as? Uri)?.let { u -> uris.add(u) } }
        }
        return uris
    }

    /// Resolves an incoming URI to a filesystem path. Content URIs are resolved
    /// via MediaStore when possible, otherwise copied into the app cache.
    private fun resolvePath(uri: Uri): String? {
        return try {
            when (uri.scheme) {
                "file" -> uri.path
                "content" -> resolveContentPath(uri)
                else -> null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveContentPath(uri: Uri): String? {
        // 1) MediaStore-backed URIs (image/video/audio/Downloads collections).
        try {
            val proj = arrayOf(MediaStore.MediaColumns.DATA)
            contentResolver.query(uri, proj, null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    val idx = c.getColumnIndex(MediaStore.MediaColumns.DATA)
                    if (idx >= 0) {
                        val p = c.getString(idx)
                        if (!p.isNullOrEmpty()) return p
                    }
                }
            }
        } catch (_: Exception) {
        }
        // 2) File-manager providers (e.g. ES File Explorer) often embed the real
        //    filesystem path in the URI, e.g.
        //    content://com.estrongs.files/storage/emulated/0/Download/x.jpg
        //    -> /storage/emulated/0/Download/x.jpg
        val rawPath = uri.path
        if (!rawPath.isNullOrEmpty() && rawPath.startsWith("/")) {
            val f = File(rawPath)
            if (f.canRead()) return rawPath
        }
        // 3) Fallback: copy the stream into our cache (needs the sending app to
        //    have granted read access to the URI).
        return try {
            val name = (uri.lastPathSegment?.substringAfterLast('/')
                ?.takeIf { it.isNotEmpty() } ?: "shared_${System.currentTimeMillis()}")
            val cacheFile = File(cacheDir, "incoming_$name")
            contentResolver.openInputStream(uri)?.use { input ->
                cacheFile.outputStream().use { out -> input.copyTo(out) }
            }
            if (cacheFile.length() > 0) cacheFile.absolutePath else null
        } catch (_: Exception) {
            null
        }
    }

    private fun forwardIncomingFiles(paths: List<String>) {
        if (incomingMethodChannel != null) {
            incomingMethodChannel?.invokeMethod("onFiles", paths)
        } else {
            pendingIncomingPaths = paths
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Incoming "Open with" / share intents are forwarded to Dart through
        // this channel. A cold-start intent is queued in `pendingIncomingPaths`;
        // instead of pushing it here (the Dart handler may not be registered
        // yet), we expose it via `getPending` so Dart can pull it once ready.
        incomingMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            incomingChannel,
        )
        incomingMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPending" -> {
                    result.success(pendingIncomingPaths)
                    pendingIncomingPaths = null
                }
                else -> result.notImplemented()
            }
        }

        // Downloader (Chaquopy/Python/yt-dlp) is wired only in the `universal`
        // flavor; the `standard` flavor compiles a no-op of this same function,
        // so nothing downloader-related is present in that build.
        maybeSetupDownloaderBridge(this, flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStorageVolumes" -> result.success(getStorageVolumes())
                    "getStorageStats" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("missing_path", "Path is required", null)
                        } else {
                            result.success(getStorageStats(path))
                        }
                    }
                    "isAllFilesAccessGranted" -> {
                        result.success(isAllFilesAccessGranted())
                    }
                    "requestAllFilesAccess" -> {
                        requestAllFilesAccess(result)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, apkIconChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getApkIcon" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("missing_path", "Path is required", null)
                        } else {
                            result.success(getApkIcon(path))
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wallpaperChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setWallpaper" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("missing_path", "Path is required", null)
                        } else if (setWallpaper(path)) {
                            result.success(null)
                        } else {
                            result.error(
                                "wallpaper_failed",
                                "Could not set wallpaper",
                                null,
                            )
                        }
                    }
                    "saveWallpaper" -> {
                        try {
                            val res = saveCurrentWallpapers()
                            Log.i(
                                "SaveWallpaper",
                                "result home=${res["home"]} lock=${res["lock"]} dir=${res["directory"]}",
                            )
                            result.success(res)
                        } catch (error: Exception) {
                            Log.e("SaveWallpaper", "saveCurrentWallpapers threw", error)
                            result.success(
                                mapOf(
                                    "directory" to null,
                                    "home" to null,
                                    "lock" to null,
                                ),
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaActionsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareFile" -> {
                        val path = call.argument<String>("path")
                        val mimeType = call.argument<String>("mimeType") ?: "*/*"
                        if (path == null) {
                            result.error("missing_path", "Path is required", null)
                        } else if (shareFile(path, mimeType)) {
                            result.success(null)
                        } else {
                            result.error("share_failed", "Could not share file", null)
                        }
                    }
                    "openFile" -> {
                        val path = call.argument<String>("path")
                        val mimeType = call.argument<String>("mimeType") ?: "*/*"
                        if (path == null) {
                            result.error("missing_path", "Path is required", null)
                        } else {
                            val outcome = openFileWithSystem(path, mimeType)
                            if (outcome.first) {
                                result.success(null)
                            } else {
                                result.error(
                                    "open_failed",
                                    outcome.second,
                                    null,
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaStoreChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "queryMedia" -> {
                        val type = call.argument<String>("type")
                        if (type == null) {
                            result.error("missing_type", "Media type is required", null)
                        } else {
                            Thread {
                                try {
                                    val items = queryMedia(type)
                                    Handler(Looper.getMainLooper()).post {
                                        result.success(items)
                                    }
                                } catch (error: Exception) {
                                    Handler(Looper.getMainLooper()).post {
                                        result.error(
                                            "query_failed",
                                            error.message ?: "MediaStore query failed",
                                            null,
                                        )
                                    }
                                }
                            }.start()
                        }
                    }
                    "queryFiles" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("missing_path", "Path is required", null)
                        } else {
                            Thread {
                                try {
                                    val items = queryFiles(path)
                                    Handler(Looper.getMainLooper()).post {
                                        result.success(items)
                                    }
                                } catch (error: Exception) {
                                    Handler(Looper.getMainLooper()).post {
                                        result.error(
                                            "query_failed",
                                            error.message ?: "MediaStore query failed",
                                            null,
                                        )
                                    }
                                }
                            }.start()
                        }
                    }
                    "countMedia" -> {
                        val type = call.argument<String>("type")
                        val path = call.argument<String>("path")
                        if (type == null || path == null) {
                            result.error(
                                "missing_argument",
                                "Media type and path are required",
                                null,
                            )
                        } else {
                            Thread {
                                try {
                                    val count = countMedia(type, path)
                                    Handler(Looper.getMainLooper()).post {
                                        result.success(count)
                                    }
                                } catch (error: Exception) {
                                    Handler(Looper.getMainLooper()).post {
                                        result.error(
                                            "count_failed",
                                            error.message ?: "MediaStore count failed",
                                            null,
                                        )
                                    }
                                }
                            }.start()
                        }
                    }
                    "scanFiles" -> {
                        val paths = call.argument<List<String>>("paths")
                        if (paths.isNullOrEmpty()) {
                            result.success(null)
                        } else {
                            try {
                                MediaScannerConnection.scanFile(
                                    this,
                                    paths.toTypedArray(),
                                    null,
                                    null,
                                )
                                result.success(null)
                            } catch (error: Exception) {
                                result.error(
                                    "scan_failed",
                                    error.message ?: "Media scan failed",
                                    null,
                                )
                            }
                        }
                    }
                    "saveQrToDownloads" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName =
                            call.argument<String>("fileName")
                                ?: "qr_${System.currentTimeMillis()}.png"
                        if (bytes == null) {
                            result.error("missing_bytes", "Image bytes are required", null)
                        } else {
                            Thread {
                                try {
                                    val savedPath = saveImageToDownloads(bytes, fileName)
                                    Handler(Looper.getMainLooper()).post {
                                        result.success(savedPath)
                                    }
                                } catch (error: Exception) {
                                    Handler(Looper.getMainLooper()).post {
                                        result.error(
                                            "save_failed",
                                            error.message ?: "Could not save QR image",
                                            null,
                                        )
                                    }
                                }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, thumbnailChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getThumbnail" -> {
                        val path = call.argument<String>("path")
                        val maxWidth = call.argument<Int>("maxWidth") ?: 256
                        if (path == null) {
                            result.error("missing_path", "Path is required", null)
                        } else {
                            Thread {
                                try {
                                    val bytes = getThumbnail(path, maxWidth)
                                    Handler(Looper.getMainLooper()).post {
                                        result.success(bytes)
                                    }
                                } catch (error: Exception) {
                                    Handler(Looper.getMainLooper()).post {
                                        result.error(
                                            "thumbnail_failed",
                                            error.message ?: "Thumbnail failed",
                                            null,
                                        )
                                    }
                                }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wakelockChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getStorageVolumes(): List<Map<String, Any?>> {
        val volumes = linkedMapOf<String, MutableMap<String, Any?>>()
        val primaryRoot = Environment.getExternalStorageDirectory()

        volumes[primaryRoot.absolutePath] = volumeMap(
            id = "primary",
            label = "Internal storage",
            root = primaryRoot,
            isPrimary = true,
            isRemovable = false,
        )

        externalMediaDirs
            .mapNotNull { it?.let(::extractStorageRoot) }
            .filter { it.exists() }
            .forEachIndexed { index, root ->
                volumes.putIfAbsent(
                    root.absolutePath,
                    volumeMap(
                        id = "external-$index",
                        label = if (root.absolutePath == primaryRoot.absolutePath) {
                            "Internal storage"
                        } else {
                            "Removable storage"
                        },
                        root = root,
                        isPrimary = root.absolutePath == primaryRoot.absolutePath,
                        isRemovable = root.absolutePath != primaryRoot.absolutePath,
                    ),
                )
            }

        return volumes.values.toList()
    }

    private fun volumeMap(
        id: String,
        label: String,
        root: File,
        isPrimary: Boolean,
        isRemovable: Boolean,
    ): MutableMap<String, Any?> {
        val stats = getStorageStats(root.absolutePath)

        return mutableMapOf(
            "id" to id,
            "label" to label,
            "path" to root.absolutePath,
            "isPrimary" to isPrimary,
            "isRemovable" to isRemovable,
            "totalBytes" to stats["totalBytes"],
            "freeBytes" to stats["freeBytes"],
            "usedBytes" to stats["usedBytes"],
        )
    }

    private fun getStorageStats(path: String): Map<String, Long> {
        return try {
            val stat = StatFs(path)
            val totalBytes = stat.blockCountLong * stat.blockSizeLong
            val freeBytes = stat.availableBlocksLong * stat.blockSizeLong
            mapOf(
                "totalBytes" to totalBytes.coerceAtLeast(1L),
                "freeBytes" to freeBytes.coerceAtLeast(0L),
                "usedBytes" to (totalBytes - freeBytes).coerceAtLeast(0L),
            )
        } catch (error: IllegalArgumentException) {
            mapOf(
                "totalBytes" to 1L,
                "freeBytes" to 0L,
                "usedBytes" to 0L,
            )
        }
    }

    private fun extractStorageRoot(directory: File): File? {
        val marker = "/Android/"
        val path = directory.absolutePath
        val markerIndex = path.indexOf(marker)

        return if (markerIndex > 0) {
            File(path.substring(0, markerIndex))
        } else {
            directory
        }
    }

    private fun isAllFilesAccessGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }
    }

    private var pendingAllFilesAccessResult: MethodChannel.Result? = null

    private fun requestAllFilesAccess(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.success(true)
            return
        }
        if (isAllFilesAccessGranted()) {
            result.success(true)
            return
        }
        if (pendingAllFilesAccessResult != null) {
            result.error("busy", "All files access request already in progress", null)
            return
        }
        pendingAllFilesAccessResult = result
        val intent = Intent(
            Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            Uri.parse("package:$packageName"),
        )
        try {
            startActivityForResult(intent, ALL_FILES_ACCESS_REQUEST_CODE)
        } catch (error: Exception) {
            pendingAllFilesAccessResult = null
            result.error("launch_failed", "Could not open All files access settings", null)
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        if (requestCode == ALL_FILES_ACCESS_REQUEST_CODE) {
            val pending = pendingAllFilesAccessResult
            pendingAllFilesAccessResult = null
            pending?.success(isAllFilesAccessGranted())
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    @Suppress("DEPRECATION")
    private fun queryMedia(type: String): List<Map<String, Any?>> {
        val uri = mediaStoreUriFor(type) ?: return emptyList()
        return queryMediaRows(uri, null, null, extensionFilterFor(type))
    }

    @Suppress("DEPRECATION")
    private fun queryFiles(path: String): List<Map<String, Any?>> {
        val uri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val dataColumn = MediaStore.MediaColumns.DATA
        val selection = "($dataColumn = ? OR $dataColumn LIKE ?) AND $dataColumn NOT LIKE ?"
        val selectionArgs = arrayOf(path, "$path/%", "%/.%")
        return queryMediaRows(uri, selection, selectionArgs)
    }

    @Suppress("DEPRECATION")
    private fun queryMediaRows(
        uri: Uri,
        selection: String?,
        selectionArgs: Array<String>?,
        extensionFilter: Set<String>? = null,
    ): List<Map<String, Any?>> {
        val projection = arrayOf(
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_MODIFIED,
        )

        val items = mutableListOf<Map<String, Any?>>()
        contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { cursor ->
            val pathColumn = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
            val nameColumn = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
            val sizeColumn = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
            val modifiedColumn = cursor.getColumnIndex(MediaStore.MediaColumns.DATE_MODIFIED)

            while (cursor.moveToNext()) {
                val path = if (pathColumn >= 0) cursor.getString(pathColumn) else null
                if (path.isNullOrEmpty() || hasHiddenSegment(path)) {
                    continue
                }

                val name = if (nameColumn >= 0) {
                    cursor.getString(nameColumn) ?: File(path).name
                } else {
                    File(path).name
                }
                if (extensionFilter != null && extensionOf(name) !in extensionFilter) {
                    continue
                }

                items.add(
                    mapOf(
                        "path" to path,
                        "name" to name,
                        "sizeBytes" to if (sizeColumn >= 0) cursor.getLong(sizeColumn) else 0L,
                        // DATE_MODIFIED is in seconds; expose milliseconds.
                        "modifiedAtMs" to if (modifiedColumn >= 0) {
                            cursor.getLong(modifiedColumn) * 1000
                        } else {
                            0L
                        },
                    )
                )
            }
        }
        return items
    }

    private fun extensionOf(name: String): String {
        val dotIndex = name.lastIndexOf('.')
        if (dotIndex <= 0 || dotIndex == name.length - 1) {
            return ""
        }
        return name.substring(dotIndex + 1).lowercase()
    }

    /// Lowercase extension groups for non-media kinds served from
    /// MediaStore.Files. Mirror the app's FileSystemEntryType mapping
    /// (local_storage_repository_io.dart / media_folder_screen.dart).
    private fun extensionFilterFor(type: String): Set<String>? = when (type) {
        "document" -> setOf(
            "pdf", "doc", "docx", "odt", "rtf", "txt", "md", "log",
            "xls", "xlsx", "ods", "csv", "ppt", "pptx", "odp",
        )
        "archive" -> setOf(
            "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "tgz",
        )
        "app" -> setOf(
            "apk", "apks", "xapk", "apkm", "aab", "app", "exe", "deb",
        )
        else -> null
    }

    private fun hasHiddenSegment(path: String): Boolean {
        return path.split('/').any { it.length > 1 && it.startsWith(".") }
    }

    @Suppress("DEPRECATION")
    private fun mediaStoreUriFor(type: String) = when (type) {
        "image" -> typeImageUri()
        "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        "document", "archive", "app" ->
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        else -> null
    }

    private fun typeImageUri() = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

    @Suppress("DEPRECATION")
    private fun countMedia(type: String, path: String): Long {
        val uri = mediaStoreUriFor(type) ?: return 0L

        val dataColumn = MediaStore.MediaColumns.DATA
        // Count rows inside the folder subtree, excluding hidden segments
        // (same parity as queryMedia's hasHiddenSegment filter).
        val selection = "($dataColumn = ? OR $dataColumn LIKE ?) AND $dataColumn NOT LIKE ?"
        val selectionArgs = arrayOf(path, "$path/%", "%/.%")

        val rows = queryMediaRows(uri, selection, selectionArgs, extensionFilterFor(type))
        return rows.size.toLong()
    }

    @Suppress("DEPRECATION")
    private fun getThumbnail(path: String, maxWidth: Int): ByteArray? {
        return try {
            if (isVideoExtension(extensionOf(path))) {
                // Videos still need MediaStore / the video thumbnail APIs.
                val uri = mediaStoreContentUriFor(path) ?: return null
                val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentResolver.loadThumbnail(
                        uri,
                        android.util.Size(maxWidth, maxWidth),
                        null,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    MediaStore.Video.Thumbnails.getThumbnail(
                        contentResolver,
                        ContentUris.parseId(uri),
                        MediaStore.Video.Thumbnails.MINI_KIND,
                        null,
                    )
                } ?: return null
                ByteArrayOutputStream().use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                    stream.toByteArray()
                }
            } else {
                // Decode the real file directly. Files written straight to disk
                // (e.g. saved wallpapers) are not re-indexed by MediaStore, so
                // its cached thumbnail can be stale/wrong. Reading the bytes
                // ourselves always reflects the current file content.
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(path, bounds)
                val rawW = bounds.outWidth
                val rawH = bounds.outHeight
                if (rawW <= 0 || rawH <= 0) return null
                val larger = if (rawW > rawH) rawW else rawH
                val scale = if (larger > maxWidth) larger / maxWidth else 1
                val decode = BitmapFactory.Options().apply { inSampleSize = scale }
                val bitmap = BitmapFactory.decodeFile(path, decode) ?: return null
                ByteArrayOutputStream().use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                    stream.toByteArray()
                }
            }
        } catch (error: Exception) {
            null
        }
    }

    /// Resolves a filesystem path to its MediaStore content URI (image or
    /// video collection) so the OS thumbnail APIs can read it. Returns null
    /// when the file is not indexed by MediaStore.
    @Suppress("DEPRECATION")
    private fun mediaStoreContentUriFor(path: String): Uri? {
        val collection = if (isVideoExtension(extensionOf(path))) {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection = "${MediaStore.MediaColumns.DATA} = ?"
        contentResolver.query(collection, projection, selection, arrayOf(path), null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val id = cursor.getLong(
                        cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID),
                    )
                    return ContentUris.withAppendedId(collection, id)
                }
            }
        return null
    }

    private fun isVideoExtension(ext: String): Boolean {
        return ext in setOf(
            "mp4", "avi", "mov", "mkv", "wmv", "flv", "webm", "m4v", "3gp",
        )
    }

    private fun getApkIcon(path: String): ByteArray? {
        return try {
            val packageInfo = getPackageArchiveInfo(path) ?: return null
            val appInfo = packageInfo.applicationInfo ?: return null
            appInfo.sourceDir = path
            appInfo.publicSourceDir = path
            val drawable = appInfo.loadIcon(packageManager)
            val bitmap = drawableToBitmap(drawable)
            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                stream.toByteArray()
            }
        } catch (error: Exception) {
            null
        }
    }

    private fun setWallpaper(path: String): Boolean {
        return try {
            val bitmap = BitmapFactory.decodeFile(path) ?: return false
            WallpaperManager.getInstance(this).setBitmap(bitmap)
            true
        } catch (error: Exception) {
            false
        }
    }

    /// Copies the current home and lock wallpapers into `File Explorer/Wallpaper`,
    /// preserving the original image bytes (no re-encoding). Returns a map with
    /// `directory`, `home`, and `lock` saved paths (null when unavailable).
    private fun saveCurrentWallpapers(): Map<String, Any?> {
        val wm = WallpaperManager.getInstance(this)
        val dir = File(Environment.getExternalStorageDirectory(), "File Explorer/Wallpaper")
        dir.mkdirs()
        val result = mutableMapOf<String, Any?>()
        result["directory"] = dir.absolutePath
        result["home"] = copyWallpaper(wm, WallpaperManager.FLAG_SYSTEM, dir, "home")
        result["lock"] = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            copyWallpaper(wm, WallpaperManager.FLAG_LOCK, dir, "lock")
        } else {
            null
        }
        return result
    }

    /// Saves the wallpaper for [which] (FLAG_SYSTEM / FLAG_LOCK) into [dir] as
    /// `<prefix>_wallpaper.<ext>`. On API 24+ it first tries to copy the real
    /// wallpaper file byte-for-byte (zero quality loss); if that is unavailable
    /// or blocked, the home screen falls back to the drawable encoded as a
    /// lossless PNG.
    private fun copyWallpaper(
        wm: WallpaperManager,
        which: Int,
        dir: File,
        prefix: String,
    ): String? {
        var path: String? = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val obj = try {
                wm.getWallpaperFile(which)
            } catch (error: Exception) {
                Log.e("SaveWallpaper", "getWallpaperFile threw which=$which", error)
                null
            }
            val input = when {
                obj is java.io.File -> try {
                    FileInputStream(obj)
                } catch (error: Exception) {
                    Log.e("SaveWallpaper", "open file failed which=$which", error)
                    null
                }
                obj is ParcelFileDescriptor -> try {
                    FileInputStream(obj.fileDescriptor)
                } catch (error: Exception) {
                    Log.e("SaveWallpaper", "open pfd failed which=$which", error)
                    null
                }
                else -> null
            }
            if (input != null) {
                try {
                    val header = ByteArray(8)
                    val n = input.read(header)
                    val ext = when {
                        n >= 3 && header[0] == 0xFF.toByte() && header[1] == 0xD8.toByte() && header[2] == 0xFF.toByte() -> "jpg"
                        n >= 4 && header[0] == 0x89.toByte() && header[1] == 0x50.toByte() && header[2] == 0x4E.toByte() && header[3] == 0x47.toByte() -> "png"
                        else -> "png"
                    }
                    val dest = File(dir, "${prefix}_wallpaper.$ext")
                    val output = FileOutputStream(dest)
                    try {
                        if (n > 0) output.write(header, 0, n)
                        val buffer = ByteArray(8192)
                        var read = input.read(buffer)
                        while (read >= 0) {
                            output.write(buffer, 0, read)
                            read = input.read(buffer)
                        }
                    } finally {
                        try {
                            input.close()
                        } catch (_: Exception) {
                        }
                        try {
                            output.close()
                        } catch (_: Exception) {
                        }
                    }
                    path = dest.absolutePath
                    Log.i("SaveWallpaper", "saved (file) which=$which -> $path")
                } catch (error: Exception) {
                    Log.e("SaveWallpaper", "copy failed which=$which", error)
                }
            } else {
                Log.d("SaveWallpaper", "getWallpaperFile null/unreadable which=$which")
            }
        }
        // Home fallback: drawable -> lossless PNG (works even when the file is blocked).
        if (path == null && which == WallpaperManager.FLAG_SYSTEM) {
            try {
                val drawable = wm.getDrawable() ?: run {
                    Log.d("SaveWallpaper", "getDrawable() returned null (likely live wallpaper)")
                    return null
                }
                val bitmap = (drawable as? BitmapDrawable)?.bitmap ?: run {
                    Log.d("SaveWallpaper", "drawable not a BitmapDrawable")
                    return null
                }
                val dest = File(dir, "${prefix}_wallpaper.png")
                val output = FileOutputStream(dest)
                try {
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                } finally {
                    try {
                        output.close()
                    } catch (_: Exception) {
                    }
                }
                path = dest.absolutePath
                Log.i("SaveWallpaper", "saved (drawable) which=$which -> $path")
            } catch (error: Exception) {
                Log.e("SaveWallpaper", "drawable fallback failed", error)
            }
        }
        return path
    }

    private fun shareFile(path: String, mimeType: String): Boolean {
        return try {
            val file = File(path)
            if (!file.isFile) {
                return false
            }

            val uri = contentUriFor(file)
            val sendIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(sendIntent, "Share image").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(chooser)
            true
        } catch (error: Exception) {
            false
        }
    }

    private fun openFileWithSystem(path: String, mimeType: String): Pair<Boolean, String> {
        return try {
            val file = File(path)
            if (!file.isFile) {
                return false to "File not found: $path"
            }

            val uri = contentUriFor(file)
            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(viewIntent, "Open with").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(chooser)
            true to ""
        } catch (error: ActivityNotFoundException) {
            false to "No app can open this file type"
        } catch (error: Exception) {
            false to (error.message ?: "Could not open file")
        }
    }

    /// Builds a shareable content URI for [file]. If the file lives outside the
    /// FileProvider's configured roots (e.g. `Directory.systemTemp` on some
    /// devices), copies it into the app cache dir and shares the copy so the
    /// recipient can read it.
    private fun contentUriFor(file: File): Uri {
        return try {
            FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file,
            )
        } catch (error: IllegalArgumentException) {
            val cacheCopy = File(
                cacheDir,
                "shared_${System.currentTimeMillis()}_${file.name}",
            )
            file.copyTo(cacheCopy, overwrite = true)
            FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                cacheCopy,
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun getPackageArchiveInfo(path: String): PackageInfo? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageArchiveInfo(
                path,
                PackageManager.PackageInfoFlags.of(0),
            )
        } else {
            packageManager.getPackageArchiveInfo(path, 0)
        }
    }

    /// Saves a PNG into the public Downloads/QRCodes collection so it is visible
    /// in the system Downloads app and gallery (MediaStore on API 29+, public
    /// Downloads directory on older versions).
    private fun saveImageToDownloads(bytes: ByteArray, fileName: String): String {
        val resolver = contentResolver
        val relativeDir = "Download/QRCodes"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativeDir)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            val uri = resolver.insert(collection, values)
                ?: throw IOException("Could not create MediaStore entry")
            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            } ?: throw IOException("Could not open output stream")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "${Environment.getExternalStorageDirectory().absolutePath}/$relativeDir/$fileName"
        } else {
            val dir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS,
            )
            val target = File(dir, "QRCodes")
            if (!target.exists()) target.mkdirs()
            val file = File(target, fileName)
            file.writeBytes(bytes)
            return file.absolutePath
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }

        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 144
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 144
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
