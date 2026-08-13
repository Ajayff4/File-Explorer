package com.ajayff4.fileexplorer

import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
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
import com.chaquo.python.Python
import com.chaquo.python.PyObject
import com.chaquo.python.android.AndroidPlatform

class MainActivity: FlutterActivity() {
    private val ALL_FILES_ACCESS_REQUEST_CODE = 4700
    private val storageChannel = "com.ajayff4.fileexplorer/storage"
    private val apkIconChannel = "com.ajayff4.fileexplorer/apk_icon"
    private val wallpaperChannel = "com.ajayff4.fileexplorer/wallpaper"
    private val mediaActionsChannel = "com.ajayff4.fileexplorer/media_actions"
    private val mediaStoreChannel = "com.ajayff4.fileexplorer/media_store"
    private val wakelockChannel = "com.ajayff4.fileexplorer/wakelock"
    private val downloaderChannel = "com.ajayff4.fileexplorer/downloader"
    private val downloaderEventsChannel = "com.ajayff4.fileexplorer/downloader/events"

    private val downloaderEventsPollIntervalMs = 150L
    private var downloaderPollTimer: Handler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initChaquopy()

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

        setupDownloaderChannels(flutterEngine)
    }

    private fun setupDownloaderChannels(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloaderChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "resolve" -> {
                        val url = call.argument<String>("url")
                        val mediaType = call.argument<String>("mediaType") ?: "video"
                        if (url == null || url.isBlank()) {
                            result.error("missing_url", "URL is required", null)
                        } else {
                            handleDownloaderAsync({
                                val info = downloaderModule.callAttr("resolve", url, mediaType)
                                val resultMap = HashMap<String, Any?>()
                                for ((key, value) in info.asMap()) {
                                    resultMap[key.toString()] = unbox(value)
                                }
                                result.success(resultMap)
                            }) { error ->
                                result.error(
                                    "resolve_failed",
                                    error.message ?: "Failed to resolve URL",
                                    null,
                                )
                            }
                        }
                    }
                    "start" -> {
                        val taskId = call.argument<String>("taskId")
                        val url = call.argument<String>("url")
                        val mediaType = call.argument<String>("mediaType") ?: "video"
                        val outputDirectory = call.argument<String>("outputDirectory")
                        if (taskId == null || url == null || outputDirectory == null) {
                            result.error("missing_argument", "taskId, url, outputDirectory are required", null)
                        } else {
                            handleDownloaderAsync({
                                downloaderModule.callAttr(
                                    "start",
                                    taskId,
                                    url,
                                    mediaType,
                                    outputDirectory,
                                )
                                result.success(null)
                            }) { error ->
                                result.error(
                                    "start_failed",
                                    error.message ?: "Failed to start download",
                                    null,
                                )
                            }
                        }
                    }
                    "cancel" -> {
                        val taskId = call.argument<String>("taskId")
                        if (taskId == null) {
                            result.error("missing_task_id", "taskId is required", null)
                        } else {
                            try {
                                downloaderModule.callAttr("cancel", taskId)
                                result.success(null)
                            } catch (error: Exception) {
                                result.error(
                                    "cancel_failed",
                                    error.message ?: "Failed to cancel download",
                                    null,
                                )
                            }
                        }
                    }
                    "pause" -> {
                        val taskId = call.argument<String>("taskId")
                        if (taskId == null) {
                            result.error("missing_task_id", "taskId is required", null)
                        } else {
                            try {
                                downloaderModule.callAttr("pause", taskId)
                                result.success(null)
                            } catch (error: Exception) {
                                result.error(
                                    "pause_failed",
                                    error.message ?: "Failed to pause download",
                                    null,
                                )
                            }
                        }
                    }
                    "resume" -> {
                        val taskId = call.argument<String>("taskId")
                        if (taskId == null) {
                            result.error("missing_task_id", "taskId is required", null)
                        } else {
                            try {
                                downloaderModule.callAttr("resume", taskId)
                                result.success(null)
                            } catch (error: Exception) {
                                result.error(
                                    "resume_failed",
                                    error.message ?: "Failed to resume download",
                                    null,
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloaderEventsChannel,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    startDownloaderPolling(events)
                }

                override fun onCancel(arguments: Any?) {
                    stopDownloaderPolling()
                }
            },
        )
    }

    private val downloaderModule: PyObject
        get() = Python.getInstance().getModule("downloader")

    private fun initChaquopy() {
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }
    }

    private fun handleDownloaderAsync(
        onSuccess: () -> Unit,
        onError: (Exception) -> Unit,
    ) {
        Thread {
            try {
                onSuccess()
            } catch (error: Exception) {
                android.os.Handler(Looper.getMainLooper()).post {
                    onError(error)
                }
            }
        }.start()
    }

    private fun startDownloaderPolling(events: EventChannel.EventSink?) {
        stopDownloaderPolling()
        val handler = Handler(Looper.getMainLooper())
        downloaderPollTimer = handler
        handler.post(object : Runnable {
            override fun run() {
                if (events == null) {
                    return
                }
                try {
                    val drained = downloaderModule.callAttr("drain")
                    val list = drained.asList()
                    for (item in list) {
                        val map = item.asMap()
                        val payload = HashMap<String, Any?>()
                        for ((key, value) in map) {
                            payload[key.toString()] = unbox(value)
                        }
                        events.success(payload)
                    }
                } catch (_: Exception) {
                    // Python runtime not ready or module missing; ignore and retry.
                }
                handler.postDelayed(this, downloaderEventsPollIntervalMs)
            }
        })
    }

    /// Converts a Chaquopy PyObject (or plain JVM value) into a type the Flutter
    /// StandardMessageCodec can serialize. Chaquopy primitives are PyObjects
    /// that don't map directly to codec types.
    private fun unbox(value: Any?): Any? {
        if (value == null ||
            value is String ||
            value is Boolean ||
            value is Int ||
            value is Long ||
            value is Double ||
            value is Float
        ) {
            return value
        }
        val text = value.toString()
        if (text == "True") return true
        if (text == "False") return false
        if (text == "None") return null
        text.toLongOrNull()?.let { return it }
        text.toFloatOrNull()?.let { return it.toDouble() }
        return text
    }

    private fun stopDownloaderPolling() {
        downloaderPollTimer?.removeCallbacksAndMessages(null)
        downloaderPollTimer = null
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
        "image" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        "document", "archive", "app" ->
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        else -> null
    }

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
