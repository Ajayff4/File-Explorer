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
import shutil
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
import zipfile


def _app_files_dir():
    """App-private files dir (Chaquopy sets HOME to it)."""
    home = os.environ.get("HOME", "")
    if home:
        return home
    return "/data/data/com.ajayff4.fileexplorer/files"


_UPDATE_BASE = os.path.join(_app_files_dir(), "ytdlp_updates")

# If a runtime-updated yt-dlp exists in app-private storage, load it ahead of
# the copy bundled into the APK.
_update_pkg = os.path.join(_UPDATE_BASE, "yt_dlp")
if os.path.isdir(_update_pkg) and _UPDATE_BASE not in sys.path:
    sys.path.insert(0, _UPDATE_BASE)

def _load_threads_plugin():
    """Import the vendored Threads extractor and register it with yt-dlp.

    Must import the plugin module BEFORE yt-dlp's meta_path finder is
    consulted: yt-dlp installs a PluginFinder that hijacks any later
    `import yt_dlp_plugins` and raises ModuleNotFoundError (it only scans
    sys.path for real directories, which never exist under Chaquopy's in-APK
    virtual filesystem). Importing first puts the module in sys.modules, so the
    finder is never asked. Then the extractor class is registered directly in
    yt-dlp's registry, since yt-dlp's own plugin discovery cannot see
    Chaquopy-packaged modules.
    """
    try:
        from yt_dlp_plugins.extractor.threads import ThreadsIE
    except Exception:
        return
    try:
        import yt_dlp.extractor as _yt_extractor
        # Build the main extractor registry first, then append the plugin class.
        _yt_extractor.gen_extractor_classes()
        _yt_extractor._extractors_context.value[ThreadsIE.__name__] = ThreadsIE
        with open(os.path.join(_app_files_dir(), "downloader_debug.log"), "a") as _f:
            _f.write("ThreadsIE registered\n")
    except Exception:
        pass


_load_threads_plugin()
import yt_dlp

_events = []
_events_lock = threading.Lock()

_cancel_tokens = set()
_cancel_lock = threading.Lock()

_pause_events = {}
_pause_lock = threading.Lock()

_active = {}


def _debug(message):
    try:
        with open(os.path.join(_app_files_dir(), "downloader_debug.log"), "a") as _f:
            _f.write("%s: %s\n" % (time.time(), message))
    except Exception:
        pass


def _post(payload):
    """Push a dict onto the event queue (safe from any thread)."""
    _debug("post kind=%s" % payload.get("kind"))
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


def _format_for(media_type, quality):
    # Prefer a single progressive file so no ffmpeg merge step is required;
    # fall back to merged video+audio (needs ffmpeg) when the cap is only
    # available as separate streams.
    if media_type == "audio":
        return "bestaudio/best"
    height = {"480": 480, "720": 720, "1080": 1080}.get(quality)
    if height:
        return (
            "best[height<=%d][ext=mp4]/"
            "bestvideo[height<=%d]+bestaudio/"
            "best[height<=%d]/best" % (height, height, height)
        )
    if quality == "max":
        return "best[ext=mp4]/bestvideo+bestaudio/best"
    return "best[ext=mp4]/best"


def _ffmpeg_location():
    """Locate a usable ffmpeg binary for merging separate video+audio streams.

    Priority: IMAGEIO_FFMPEG_EXE (test harness), the binary bundled into app
    storage (copied from assets by MainActivity), the system PATH, then
    imageio-ffmpeg's bundled copy if present.
    """
    candidates = [os.environ.get("IMAGEIO_FFMPEG_EXE", "")]
    home = _app_files_dir()
    candidates.append(os.path.join(home, "ffmpeg"))
    candidates.append("/data/data/com.ajayff4.fileexplorer/files/ffmpeg")
    for candidate in candidates:
        if candidate and os.path.isfile(candidate):
            return candidate
    try:
        import shutil
        found = shutil.which("ffmpeg")
        if found:
            return found
    except Exception:
        pass
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        return None


def _base_opts(task_id, url, media_type, output_dir, quality="auto",
               audio_format="original", playlist=False):
    opts = {
        "quiet": True,
        "no_warnings": True,
        "noplaylist": not playlist,
        "format": _format_for(media_type, quality),
        "extractor_args": {"youtube": {"player_client": ["android"]}},
        "outtmpl": os.path.join(output_dir, "%(title).200B [%(id)s].%(ext)s"),
        "retries": 3,
        "fragment_retries": 3,
        "socket_timeout": 30,
        "progress_hooks": [_progress_hook(task_id)],
    }
    if media_type == "audio" and audio_format == "mp3":
        opts["postprocessors"] = [{
            "key": "FFmpegExtractAudio",
            "preferredcodec": "mp3",
            "preferredquality": "192",
        }]
    ffmpeg = _ffmpeg_location()
    if ffmpeg:
        opts["ffmpeg_location"] = ffmpeg
    return opts


def _progress_hook(task_id):
    def hook(data):
        _debug("hook task=%s status=%s" % (task_id, data.get("status")))
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


def _final_filename(downloader, url, media_type, info, audio_format="original"):
    """Best-effort resolution of the on-disk filename after download."""
    requested = info.get("requested_downloads")
    if requested:
        filepath = requested[0].get("filepath")
        if filepath:
            name = os.path.basename(filepath)
            if audio_format != "mp3" or name.lower().endswith(".mp3"):
                return name
    for entry in reversed(info.get("entries") or []):
        reqs = entry.get("requested_downloads") or []
        if reqs and reqs[0].get("filepath"):
            name = os.path.basename(reqs[0]["filepath"])
            if audio_format != "mp3" or name.lower().endswith(".mp3"):
                return name
    try:
        prepared = downloader.prepare_filename(info)
        if prepared:
            name = os.path.basename(prepared)
            if audio_format == "mp3":
                name = os.path.splitext(name)[0] + ".mp3"
            return name
    except Exception:
        pass
    name = info.get("title") or url
    if audio_format == "mp3":
        name = os.path.splitext(name)[0] + ".mp3"
    return name


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


def _run_download(task_id, url, media_type, output_dir, quality="auto",
                  audio_format="original", playlist=False):
    _debug("run_download task=%s url=%s type=%s quality=%s audio_format=%s playlist=%s"
           % (task_id, url, media_type, quality, audio_format, playlist))
    try:
        if not output_dir or not os.path.isdir(output_dir):
            output_dir = _default_output_dir()
        os.makedirs(output_dir, exist_ok=True)
        _debug("output_dir=%s" % output_dir)

        opts = _base_opts(task_id, url, media_type, output_dir, quality,
                          audio_format, playlist)
        _debug("format=%s noplaylist=%s ffmpeg=%s postprocessors=%s"
               % (opts.get("format"), opts.get("noplaylist"),
                  opts.get("ffmpeg_location"), opts.get("postprocessors")))
        with yt_dlp.YoutubeDL(opts) as ydl:
            _debug("YoutubeDL created, extract_info starting")
            info = ydl.extract_info(url, download=True) or {}
            _debug("extract_info done, type=%s" % info.get("_type"))
            if info.get("_type") == "playlist" and not playlist:
                info = (info.get("entries") or [{}])[0] or {}
                _debug("playlist unwrapped")

        _post({
            "taskId": task_id,
            "kind": "completed",
            "title": info.get("title") or url,
            "fileName": _final_filename(ydl, url, media_type, info, audio_format),
            "totalBytes": info.get("filesize"),
        })
    except CancelledError:
        _debug("cancelled")
        _post({"taskId": task_id, "kind": "cancelled"})
    except Exception as error:
        _debug("failed: %r" % (error,))
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


def start(task_id, url, media_type, output_dir, quality="auto",
          audio_format="original", playlist=False):
    _debug("start task=%s url=%s type=%s quality=%s audio_format=%s playlist=%s"
           % (task_id, url, media_type, quality, audio_format, playlist))
    if task_id in _active:
        _debug("start: already active")
        return
    worker = threading.Thread(
        target=_run_download,
        args=(task_id, url, media_type, output_dir, quality,
              audio_format, playlist),
        daemon=True,
        name="ytdlp-%s" % (task_id[-8:] or task_id),
    )
    _active[task_id] = worker
    with _pause_lock:
        _pause_events[task_id] = threading.Event()
        _pause_events[task_id].set()
    worker.start()
    _debug("start: worker spawned %s" % worker.name)


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
"extractor_args": {"youtube": {"player_client": ["android"]}},
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


def _version_tuple(version):
    parts = []
    for part in str(version).split("."):
        digits = ""
        for ch in part:
            if ch.isdigit():
                digits += ch
            else:
                break
        parts.append(int(digits) if digits else 0)
    return tuple(parts)


def _normalize_version(version):
    """Normalize a version for display (PEP 440 style).

    yt-dlp's own __version__ keeps leading zeros (e.g. 2026.07.04) while PyPI's
    JSON API returns the normalized form (2026.7.4). Normalizing both sides
    makes "Installed" and "Latest" render identically when they are equal.
    """
    parts = []
    for part in str(version).split("."):
        parts.append(str(int(part)) if part.isdigit() else part)
    return ".".join(parts)


def _current_version():
    try:
        return getattr(yt_dlp.version, "__version__", "") or ""
    except Exception:
        return ""


def check_update():
    """Check PyPI for a newer yt-dlp release. Returns a map for the Dart bridge."""
    try:
        with urllib.request.urlopen(
            "https://pypi.org/pypi/yt-dlp/json", timeout=20
        ) as resp:
            data = json.load(resp)
        latest = _normalize_version((data.get("info") or {}).get("version", ""))
        current = _normalize_version(_current_version())
        return {
            "currentVersion": current,
            "latestVersion": latest,
            "updateAvailable": bool(
                latest and _version_tuple(latest) > _version_tuple(current)
            ),
            "error": "",
        }
    except Exception as error:
        return {
            "currentVersion": _normalize_version(_current_version()),
            "latestVersion": "",
            "updateAvailable": False,
            "error": _friendly_error(error, "https://pypi.org/pypi/yt-dlp/json"),
        }


def _wheel_url_for(data):
    for item in data.get("urls") or []:
        filename = item.get("filename", "")
        if filename.endswith(".whl") and item.get("packagetype") == "bdist_wheel":
            return item.get("url"), filename
    return None, None


def apply_update():
    """Download the latest yt-dlp wheel into app storage and load it.

    Returns {"applied": bool, "version": str, "message": str}.
    """
    try:
        with urllib.request.urlopen(
            "https://pypi.org/pypi/yt-dlp/json", timeout=20
        ) as resp:
            data = json.load(resp)
        latest = (data.get("info") or {}).get("version", "")
        url, filename = _wheel_url_for(data)
        if not url:
            return {
                "applied": False,
                "version": _normalize_version(_current_version()),
                "message": "No wheel found for yt-dlp %s" % latest,
            }

        os.makedirs(_UPDATE_BASE, exist_ok=True)
        tmp_dir = os.path.join(_UPDATE_BASE, "tmp-download")
        if os.path.exists(tmp_dir):
            shutil.rmtree(tmp_dir, ignore_errors=True)
        os.makedirs(tmp_dir)
        wheel_path = os.path.join(tmp_dir, filename or "yt-dlp.whl")
        urllib.request.urlretrieve(url, wheel_path)

        target = os.path.join(_UPDATE_BASE, "yt_dlp")
        if os.path.exists(target):
            shutil.rmtree(target, ignore_errors=True)
        with zipfile.ZipFile(wheel_path) as archive:
            archive.extractall(_UPDATE_BASE)
        shutil.rmtree(tmp_dir, ignore_errors=True)

        if not os.path.isdir(target):
            return {
                "applied": False,
                "version": _normalize_version(_current_version()),
                "message": "Extracted wheel is missing the yt_dlp package",
            }

        global yt_dlp
        if _UPDATE_BASE not in sys.path:
            sys.path.insert(0, _UPDATE_BASE)
        for name in [
            n for n in list(sys.modules)
            if n == "yt_dlp" or n.startswith("yt_dlp.")
        ]:
            del sys.modules[name]
        import yt_dlp
        _load_threads_plugin()

        return {"applied": True, "version": _normalize_version(_current_version()), "message": ""}
    except Exception as error:
        return {
            "applied": False,
            "version": _normalize_version(_current_version()),
            "message": "Update failed: %s" % error,
        }