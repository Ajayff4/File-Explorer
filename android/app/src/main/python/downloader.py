"""yt-dlp download helper running inside the Chaquopy Python runtime.

Exposes three entry points used from MainActivity.kt:

  - resolve(url, media_type) - fetch title/thumbnail/duration without downloading
  - start(task_id, url, media_type, output_dir) - begin a download on a worker
    thread, streaming progress events into an in-memory queue
  - cancel(task_id) - abort an in-flight download
  - drain() - return and clear all queued events (polled by the EventChannel)

The Kotlin side polls `drain()` on a timer and forwards each queued map to the
Dart EventChannel, so no Java interop is required from Python threads.
"""

import json
import os
import threading
import urllib.error
import uuid

import yt_dlp

_events = []
_events_lock = threading.Lock()

_cancel_tokens = set()
_cancel_lock = threading.Lock()

_pause_events = {}
_pause_lock = threading.Lock()

_active = {}


def _post(payload):
    """Push a dict onto the event queue (safe from any thread)."""
    with _events_lock:
        _events.append(payload)


def drain():
    """Return and clear all queued events. Used by the Kotlin poller."""
    with _events_lock:
        drained = _events[:]
        del _events[:]
    return drained


class CancelledError(Exception):
    pass


def _format_for(media_type):
    # Prefer a single progressive file so no ffmpeg merge step is required.
    if media_type == "audio":
        return "bestaudio/best"
    return "best[ext=mp4]/best"


def _base_opts(task_id, url, media_type, output_dir):
    return {
        "quiet": True,
        "no_warnings": True,
        "noplaylist": True,
        "format": _format_for(media_type),
        "outtmpl": os.path.join(output_dir, "%(title).200B [%(id)s].%(ext)s"),
        "retries": 3,
        "fragment_retries": 3,
        "socket_timeout": 30,
        "progress_hooks": [_progress_hook(task_id)],
    }


def _progress_hook(task_id):
    def hook(data):
        with _cancel_lock:
            cancelled = task_id in _cancel_tokens
        if cancelled:
            raise CancelledError()

        # Block while the task is paused, keeping the download alive. On
        # resume the event is set and the download continues in place.
        with _pause_lock:
            pause_event = _pause_events.get(task_id)
        if pause_event is not None and not pause_event.is_set():
            pause_event.wait()
            with _cancel_lock:
                if task_id in _cancel_tokens:
                    raise CancelledError()

        status = data.get("status")
        if status == "started":
            info = data.get("info_dict") or {}
            title = info.get("title") or data.get("filename") or ""
            _post({
                "taskId": task_id,
                "kind": "resolved",
                "title": title,
            })
        elif status == "downloading":
            total = data.get("total_bytes")
            if total is None:
                total = data.get("total_bytes_estimate")
            _post({
                "taskId": task_id,
                "kind": "progress",
                "transferredBytes": data.get("downloaded_bytes") or 0,
                "totalBytes": total,
                "speedBytesPerSecond": data.get("speed") or 0,
            })

    return hook


def _final_filename(downloader, url, media_type, info):
    """Best-effort resolution of the on-disk filename after download."""
    requested = info.get("requested_downloads")
    if requested:
        filepath = requested[0].get("filepath")
        if filepath:
            return os.path.basename(filepath)
    try:
        prepared = downloader.prepare_filename(info)
        if prepared:
            return os.path.basename(prepared)
    except Exception:
        pass
    return info.get("title") or url


def _default_output_dir():
    """Public Downloads folder on Android, falling back to app HOME."""
    candidates = [
        os.path.join("/storage/emulated/0", "Download"),
        os.environ.get("HOME", ""),
        "/data/data/com.ajayff4.fileexplorer/files",
    ]
    for candidate in candidates:
        if candidate and os.path.isdir(candidate):
            return candidate
    return candidates[-1]


def _run_download(task_id, url, media_type, output_dir):
    try:
        if not output_dir or not os.path.isdir(output_dir):
            output_dir = _default_output_dir()
        os.makedirs(output_dir, exist_ok=True)

        opts = _base_opts(task_id, url, media_type, output_dir)
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True) or {}
            if info.get("_type") == "playlist":
                info = (info.get("entries") or [{}])[0] or {}

        _post({
            "taskId": task_id,
            "kind": "completed",
            "title": info.get("title") or url,
            "fileName": _final_filename(ydl, url, media_type, info),
            "totalBytes": info.get("filesize"),
        })
    except CancelledError:
        _post({"taskId": task_id, "kind": "cancelled"})
    except Exception as error:
        _post({
            "taskId": task_id,
            "kind": "failed",
            "message": _friendly_error(error, url),
        })
    finally:
        with _cancel_lock:
            _cancel_tokens.discard(task_id)
        with _pause_lock:
            _pause_events.pop(task_id, None)
        _active.pop(task_id, None)


def start(task_id, url, media_type, output_dir):
    if task_id in _active:
        return
    worker = threading.Thread(
        target=_run_download,
        args=(task_id, url, media_type, output_dir),
        daemon=True,
        name="ytdlp-%s" % (task_id[-8:] or task_id),
    )
    _active[task_id] = worker
    with _pause_lock:
        _pause_events[task_id] = threading.Event()
        _pause_events[task_id].set()
    worker.start()


def pause(task_id):
    """Pause an in-flight download in place; resume() continues it."""
    with _pause_lock:
        event = _pause_events.get(task_id)
    if event is not None:
        event.clear()


def resume(task_id):
    """Resume a previously paused download."""
    with _pause_lock:
        event = _pause_events.get(task_id)
    if event is not None:
        event.set()


def cancel(task_id):
    with _cancel_lock:
        _cancel_tokens.add(task_id)
    with _pause_lock:
        event = _pause_events.get(task_id)
    if event is not None:
        event.set()


def resolve(url, media_type):
    """Return metadata for a URL without downloading anything."""
    try:
        opts = {
            "quiet": True,
            "no_warnings": True,
            "noplaylist": True,
            "skip_download": True,
        }
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False) or {}
            if info.get("_type") == "playlist":
                info = (info.get("entries") or [{}])[0] or {}
            return {
                "title": info.get("title") or "",
                "thumbnail": info.get("thumbnail") or "",
                "durationSeconds": info.get("duration"),
                "isPlaylist": info.get("_type") == "playlist",
            }
    except Exception as error:
        return {
            "title": "",
            "thumbnail": "",
            "durationSeconds": None,
            "isPlaylist": False,
            "error": _friendly_error(error, url),
        }


def _friendly_error(error, url):
    import traceback
    try:
        tb = traceback.format_exc()
        with open(os.path.join(os.environ.get("HOME", "/data/data/com.ajayff4.fileexplorer/files"), "downloader_error.log"), "a") as _f:
            _f.write("=== %s ===\n%s\n" % (url, tb))
    except Exception:
        pass
    if isinstance(error, FileNotFoundError):
        return "Download folder does not exist or is not writable"
    if isinstance(error, PermissionError):
        return "No permission to write to the download folder"
    if isinstance(error, (urllib.error.URLError, urllib.error.HTTPError, TimeoutError)):
        return "Network error while reaching %s" % _host(url)
    if isinstance(error, OSError):
        return "Filesystem error while writing the download"
    text = str(error)
    if "Unsupported URL" in text:
        return "This link is not supported by yt-dlp: %s" % _host(url)
    if "Private video" in text:
        return "This video is private"
    if "inappropriate content" in text.lower():
        return "This video is age-restricted and cannot be downloaded"
    if len(text) > 180:
        text = text[:180] + "..."
    return text


def _host(url):
    try:
        from urllib.parse import urlparse
        return urlparse(url).netloc or url
    except Exception:
        return url