package com.ajayff4.fileexplorer

import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val storageChannel = "com.ajayff4.fileexplorer/storage"

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
}
