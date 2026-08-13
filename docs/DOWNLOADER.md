# Universal Downloader

How URL-based media downloads work after the 2026-08-13 implementation (plus the
2026-08-14 pause/resume and UI polish), why it is bundled with yt-dlp via
Chaquopy, and how the Dart ↔ Python bridge stays in sync. The docs in this
folder are the implementation reference; the roadmap table lives in
`../ROADMAP.md`.

## Problem

Users wanted to paste a YouTube / Instagram / Twitter / other media link and
download it as a video or audio file directly inside the app, with queueing,
progress, and retry — the way ES File Explorer ships a downloader.

Doing this in Flutter means running a download engine that understands hundreds
of sites. The practical engine is `yt-dlp`, a Python program. Android has no
Python runtime by default, so the app embeds one via **Chaquopy** (a Gradle
plugin that bundles CPython + pip packages into the APK) and talks to it over
Flutter platform channels.

## Architecture

```
DownloaderScreen  (lib/features/downloader/presentation/downloader_screen.dart)
  └─ downloaderControllerProvider
       └─ DownloaderController (StateNotifier, lib/features/downloader/.../downloader_controller.dart)
            ├─ DownloadTaskStore   → Drift (DownloadTaskRows, app_database.dart schema v8)
            ├─ DownloaderSettingsStore → Drift SettingRows (max concurrent, output dir)
            └─ DownloadEngine      → createDownloadEngine()  (io/stub conditional import)
                 ├─ Android:  ChaquopyDownloadEngine  → MethodChannel / EventChannel
                 │                 └─ MainActivity.kt  → Chaquopy Python 3.12
                 │                       └─ src/main/python/downloader.py  → yt-dlp
                 └─ else:    FakeDownloadEngine  (dev/tests only)
```

- `DownloadTask` (domain entity) models one queued/running/paused/completed/
  failed/cancelled download with a `DownloadProgress` (transferred, total,
  speed).
- `DownloaderState` derives active/finished counts and stats from the task list.
- Settings persist the max-concurrent-downloads limit and the output directory.

## The Dart side

### Domain & repository seams

| File | Purpose |
| --- | --- |
| `domain/entities/download_task.dart` | `DownloadTask`, `DownloadProgress`, `DownloadMediaType` (video/audio), `DownloadTaskStatus` (+ label). |
| `domain/repositories/download_engine.dart` | `DownloadEngine` interface: `events()`, `resolve()`, `start()`, `pause()`, `resume()`, `cancel()`. `DownloaderEvent`/`MediaInfo` payloads. |
| `domain/repositories/download_task_store.dart` | `DownloadTaskStore` (load/save/delete). |
| `domain/repositories/downloader_settings_store.dart` | `DownloaderSettings` + `DownloaderSettingsStore`. |
| `data/repositories/chaquopy_download_engine.dart` | Android engine: MethodChannel `com.ajayff4.fileexplorer/downloader`, EventChannel `.../downloader/events`. |
| `data/repositories/fake_download_engine.dart` | Non-Android stand-in streaming synthetic progress (supports pause/resume). |
| `data/repositories/drift_download_task_store.dart` | Drift persistence of tasks. |
| `data/repositories/drift_downloader_settings_store.dart` | Drift persistence of settings (keys `downloader.*`). |
| `data/repositories/in_memory_*` | In-memory variants for tests. |
| `data/repositories/download_engine_io/stub.dart` | Platform check: Chaquopy on Android, Fake otherwise. |
| `data/repositories/*_provider.dart` | Riverpod providers wiring stores + engine. |
| `presentation/controllers/downloader_controller.dart` | `DownloaderController`/`DownloaderState`/provider. |
| `presentation/downloader_visuals.dart` | Shared icon/color/speed/datetime helpers for the UI. |
| `presentation/downloader_screen.dart` | The full downloader screen. |
| `presentation/download_browse_screen.dart` | The dedicated pushed browse view (`/downloader/browse`). |
| `presentation/download_entry_grid.dart` | Shared grid widget (thumbnails/icons, 4–8 responsive columns) used by the browse view and the change-folder picker. |

### Controller behavior

- `enqueue(url, mediaType)` creates a queued task, persists it, then starts it
  if concurrency allows (`maxConcurrentDownloads`, default 1, clamp 1–16).
- `_startIfReady` marks the task running and calls `engine.start(...)`; errors
  from the engine surface as a failed task.
- Events from `engine.events()` (`resolved`, `progress`, `completed`, `failed`,
  `cancelled`) update the matching task by `taskId`. Progress events also bump
  the status to running so a resumed download re-shows progress.
- `pause(taskId)` / `resume(taskId)` toggle an in-place blocking pause on the
  engine side (see below). Pausing a task that is already finished is ignored.
- `cancel(taskId)` calls `engine.cancel` for running **and** paused tasks
  (a paused task's blocked worker thread is woken and aborts) and marks
  cancelled.
- `retry(taskId)` re-queues a failed task (clears the failure message).
- `clearFinished()` drops completed/failed/cancelled tasks and their rows.
- Restored persisted tasks that were `running` or `paused` are normalized to
  failed with the message "Download interrupted before completion" (the engine
  process died with the app; resuming is not supported).
- Finished downloads expose `Move to` (queues a transfer `move` operation),
  `Open folder`, and `Browse` via a polished kebab menu on the card; finished
  tasks also show their completion datetime and a copy-error action on failure.
- `Open folder`/`Browse` push `DownloadBrowseScreen` (a grid of folder
  contents); the change-folder picker also renders folders as a grid. Both
  reuse `DownloadEntryGrid`.

## The Android side

### Gradle (Chaquopy)

- Plugin `com.chaquo.python` v17.0.0 applied in `android/settings.gradle`
  (`apply false`) and `android/app/build.gradle`.
- `chaquopy { defaultConfig { version = "3.12"; pip { install "yt-dlp" } } }`.
  Python 3.12 is used so the build host's local `python3.12` satisfies
  Chaquopy's build-Python requirement (3.13 has no host interpreter here).
- Only 64-bit ABIs are built (`arm64-v8a`, `x86_64`) because Chaquopy ships
  CPython for 64-bit ABIs only. `disable-abi-filtering=true` is set in
  `android/gradle.properties` so Flutter's ABI auto-config does not re-add
  `armeabi-v7a`, which would fail the variant with "Python 3.12 is not
  available for the ABI 'armeabi-v7a'".
- `minSdk` raised to 24 (Chaquopy requirement).

### Python module (`android/app/src/main/python/downloader.py`)

Pure-python wrapper around `yt-dlp`, imported by name `downloader`:

- `resolve(url, media_type)` — metadata (title/thumbnail/duration/isPlaylist)
  via `extract_info(download=False)`.
- `start(task_id, url, media_type, output_dir)` — spawns a daemon worker thread
  running `yt-dlp` with a progress hook. Video uses `best[ext=mp4]/best`;
  audio uses `bestaudio/best` (single-file formats, so no ffmpeg merge step is
  required — yt-dlp is installed as a pure-Python wheel and no binary ffmpeg
  is bundled).
- `pause(task_id)` / `resume(task_id)` — per-task `threading.Event` pause flags.
  The progress hook calls `event.wait()` while paused, stalling the worker
  thread **in place** so the yt-dlp connection stays alive; resume sets the
  event and the download continues seamlessly (no restart, no re-download).
- `cancel(task_id)` — sets a cancellation token **and** wakes any blocked pause
  event, so a paused download aborts immediately instead of hanging on the hook.
- Events (`resolved`/`progress`/`completed`/`failed`/`cancelled`) are appended
  to an in-process queue; `drain()` returns and clears it.

### Kotlin bridge (`MainActivity.kt`)

- MethodChannel `.../downloader`: `resolve`, `start`, `pause`, `resume`,
  `cancel`. Heavy work is off the main thread; results are marshalled back with
  `unbox()` so Chaquopy `PyObject` values become codec-safe primitives.
- EventChannel `.../downloader/events`: a `Handler` polls `drain()` every
  150 ms while listening and forwards each event map to Dart, converting
  values through `unbox()` (bool/int/float/string/None → codec types).

## Persistence

- `DownloadTaskRows` table (drift, `app_database.dart`), schema `8`; the
  migration creates the table when upgrading from any older schema.
- Task rows are written on every state change (`_replaceTask`), so restarting
  the app restores the full history.
- Settings live in the generic `SettingRows` table under `downloader.*` keys.

## Concurrency & queueing

- `maxConcurrentDownloads` gates how many tasks may be `running` at once.
- When a running task finishes/fails/cancels, `_tryStartNext()` starts the next
  queued task.
- One engine per app; the Chaquopy engine tracks active workers by task id so a
  duplicate `start` for an already-active task is a no-op.

## Tests

`test/features/downloader/downloader_controller_test.dart` covers:
- enqueue → running → completed with progress/filename/title,
- failure mapping + clear-finished,
- retry without stale failure message,
- cancel through the engine,
- pause, resume, ignore-pause-on-failed, cancel-paused,
- concurrency cap (2 of 4 start) and next-start-on-finish,
- persistence restore (completed) and interrupted-running/-paused → failed,
- settings update/persist and load on initialize.

Run with:

```bash
flutter test test/features/downloader/downloader_controller_test.dart
```

## Verification status

- `flutter analyze` — clean.
- Downloader controller tests — 15/15 pass.
- `flutter build apk --debug` — succeeds with yt-dlp bundled via Chaquopy.
- Live end-to-end verified on a real device (2026-08-14, wireless debug): a
  YouTube link was pasted in the downloader and progressed to completion
  through the Chaquopy ↔ Dart bridge.

## Limitations

The downloader depends entirely on what `yt-dlp` can resolve and download, so
support is not universal:

- **Site support varies** — sites such as Threads, and anything else without a
  working `yt-dlp` extractor, will not download (a failed task with a
  "Unsupported URL" style message is the expected result).
- **No playlist support** — only a single video/audio item per pasted link;
  playlist/`noplaylist` handling is not implemented yet.
- **No format conversion / merging** — the audio pick uses a single-file format
  and video picks `best[ext=mp4]/best`; there is no ffmpeg, so formats that
  require merging (separate audio+video streams) or conversion (e.g. audio →
  mp3) are not produced.
- **DRM / logged-in content** — DRM-protected or age/login-gated content that
  requires cookies or decryption keys will fail.
- **Rotation changes** — yt-dlp extractors can break when a site changes its
  API; fixes arrive by updating the bundled `yt-dlp` wheel.
- **Network & storage** — a download that stalls because the device's network
  drops is left to the app's retry, not a resumed byte-range download.

## Follow-ups (see `../ROADMAP.md`)

- Optional ffmpeg bundling for format conversion (e.g. audio → mp3) and
  video/audio merging beyond `best[ext=mp4]`/`bestaudio`.
- Playlist/`noplaylist` handling refinement.
