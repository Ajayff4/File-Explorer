package com.ajayff4.fileexplorer

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.chaquo.python.Python
import com.chaquo.python.PyObject
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

// Lives ONLY in the `universal` flavor source set. The `standard` (Play Store)
// flavor compiles a no-op version of this same function (see
// src/standard/java/.../DownloaderBridge.kt) so the downloader MethodChannel,
// EventChannel, and Chaquopy/Python glue are never present in the `standard`
// APK. Do not reference any of this from MainActivity directly.
private const val downloaderChannel = "com.ajayff4.fileexplorer/downloader"
private const val downloaderEventsChannel = "com.ajayff4.fileexplorer/downloader/events"
private const val downloaderEventsPollIntervalMs = 150L
private var downloaderPollTimer: Handler? = null

fun maybeSetupDownloaderBridge(activity: MainActivity, flutterEngine: FlutterEngine) {
    initChaquopy(activity)
    setupDownloaderChannels(activity, flutterEngine)
}

private fun setupDownloaderChannels(activity: MainActivity, flutterEngine: FlutterEngine) {
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
                            val info = downloaderModule().callAttr("resolve", url, mediaType)
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
                    val quality = call.argument<String>("quality") ?: "auto"
                    val audioFormat = call.argument<String>("audioFormat") ?: "original"
                    val playlist = call.argument<Boolean>("playlist") ?: false
                    if (taskId == null || url == null || outputDirectory == null) {
                        result.error("missing_argument", "taskId, url, outputDirectory are required", null)
                    } else {
                        handleDownloaderAsync({
                            android.util.Log.d("DownloaderDebug", "calling python start taskId=$taskId")
                            downloaderModule().callAttr(
                                "start",
                                taskId,
                                url,
                                mediaType,
                                outputDirectory,
                                quality,
                                audioFormat,
                                playlist,
                            )
                            android.util.Log.d("DownloaderDebug", "python start returned")
                            result.success(null)
                        }) { error ->
                            android.util.Log.e("DownloaderDebug", "start_failed", error)
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
                            downloaderModule().callAttr("cancel", taskId)
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
                            downloaderModule().callAttr("pause", taskId)
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
                            downloaderModule().callAttr("resume", taskId)
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
                "check_update" -> {
                    handleDownloaderAsync({
                        val info = downloaderModule().callAttr("check_update")
                        val resultMap = HashMap<String, Any?>()
                        for ((key, value) in info.asMap()) {
                            resultMap[key.toString()] = unbox(value)
                        }
                        result.success(resultMap)
                    }) { error ->
                        result.error(
                            "check_update_failed",
                            error.message ?: "Failed to check for updates",
                            null,
                        )
                    }
                }
                "apply_update" -> {
                    handleDownloaderAsync({
                        val info = downloaderModule().callAttr("apply_update")
                        val resultMap = HashMap<String, Any?>()
                        for ((key, value) in info.asMap()) {
                            resultMap[key.toString()] = unbox(value)
                        }
                        result.success(resultMap)
                    }) { error ->
                        result.error(
                            "apply_update_failed",
                            error.message ?: "Failed to apply update",
                            null,
                        )
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
                android.util.Log.d("DownloaderDebug", "EventChannel onListen called")
                startDownloaderPolling(events)
            }

            override fun onCancel(arguments: Any?) {
                android.util.Log.d("DownloaderDebug", "EventChannel onCancel called")
                stopDownloaderPolling()
            }
        },
    )
}

private fun downloaderModule(): PyObject =
    Python.getInstance().getModule("downloader")

private fun initChaquopy(activity: MainActivity) {
    if (!Python.isStarted()) {
        Python.start(AndroidPlatform(activity))
    }
    extractFfmpeg(activity)
}

/// Copies the bundled static ffmpeg binary from assets into app-private
/// storage (where it is executable) so yt-dlp can merge separate
/// video+audio streams for 720p/1080p downloads. No-op if already there.
private fun extractFfmpeg(activity: MainActivity) {
    try {
        val target = File(activity.filesDir, "ffmpeg")
        if (target.isFile && target.length() > 0) {
            return
        }
        activity.assets.open("ffmpeg/ffmpeg").use { input ->
            target.outputStream().use { output ->
                input.copyTo(output)
            }
        }
        target.setExecutable(true, false)
    } catch (_: Exception) {
        // Downloader still works without ffmpeg (progressive formats only).
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
                val drained = downloaderModule().callAttr("drain")
                val list = drained.asList()
                android.util.Log.d("DownloaderDebug", "drain returned ${list.size} events")
                for (item in list) {
                    val map = item.asMap()
                    val payload = HashMap<String, Any?>()
                    for ((key, value) in map) {
                        payload[key.toString()] = unbox(value)
                    }
                    android.util.Log.d("DownloaderDebug", "sending event $payload")
                    events.success(payload)
                }
            } catch (error: Exception) {
                android.util.Log.e("DownloaderDebug", "drain error", error)
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
