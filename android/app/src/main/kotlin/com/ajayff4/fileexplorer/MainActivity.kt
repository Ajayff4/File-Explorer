package com.ajayff4.fileexplorer

import android.app.WallpaperManager
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity: FlutterActivity() {
    private val storageChannel = "com.ajayff4.fileexplorer/storage"
    private val apkIconChannel = "com.ajayff4.fileexplorer/apk_icon"
    private val wallpaperChannel = "com.ajayff4.fileexplorer/wallpaper"
    private val mediaActionsChannel = "com.ajayff4.fileexplorer/media_actions"
    private val wakelockChannel = "com.ajayff4.fileexplorer/wakelock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                        } else if (openFile(path, mimeType)) {
                            result.success(null)
                        } else {
                            result.error("open_failed", "Could not open file", null)
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

    private fun openFile(path: String, mimeType: String): Boolean {
        return try {
            val file = File(path)
            if (!file.isFile) {
                return false
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
            true
        } catch (error: Exception) {
            false
        }
    }

    private fun contentUriFor(file: File) = FileProvider.getUriForFile(
        this,
        "${applicationContext.packageName}.fileprovider",
        file,
    )

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
