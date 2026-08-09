# File Explorer

> A Flutter file manager built with a **feature-first architecture**.

[![Platform: Android](https://img.shields.io/badge/platform-Android-3ddc84)](#run-on-android)
[![Framework: Flutter](https://img.shields.io/badge/framework-Flutter-02569b)](https://flutter.dev)
[![Language: Dart](https://img.shields.io/badge/language-Dart-0175C2)](#requirements)

**Package/application ID:** `com.ajayff4.fileexplorer`

---

## Current Status

A usable file-manager vertical slice with native Android integration. Almost every
feature below works end to end on a real device over wireless ADB.

### 🧭 Platform & Shell

| Feature | Status |
| --- | --- |
| Mobile app shell with bottom navigation routing between screens. | ✅ |
| Feature-first `lib/features/*` architecture. | ✅ |
| Android storage permissions: legacy read/write, Android 13 media reads, Android 11+ all-files access. | ✅ |
| Predictive back gesture (`android:enableOnBackInvokedCallback`). | ✅ |

### 🏠 Home Dashboard

| Feature | Status |
| --- | --- |
| Storage summary, category shortcuts, recent folders, favorites, Recents entry. | ✅ |
| Live category counts on shortcuts (MediaStore-backed). | ✅ |
| Media library entry points via `AppRoutes.media`. | ✅ |
| Core Features listing page with expand/collapse cards. | ✅ |

### 📂 Explorer

| Feature | Status |
| --- | --- |
| Live local/Android browsing where permissions allow. | ✅ |
| List/grid toggle, breadcrumbs, storage selector, refresh, folder navigation. | ✅ |
| Sorting — Name (A–Z / Z–A), Modified, Size, Type. | ✅ |
| Multi-select action sheet (sort props…) with type filter, share, delete, rename, copy/move. | ✅ |
| "New Folder" / "New File" actions. | ✅ |
| Properties panel with folder-size computation + multi-select summary. | ✅ |
| Type-filter folder listings via MediaStore `countMedia`, walker fallback. | ✅ |
| Progressive loading — no fake storage in production. | ✅ |

### 🖼️ Media Libraries

| Feature | Status |
| --- | --- |
| 6 categories: Images, Videos, Audio, Documents, Apps, Archives. | ✅ |
| MediaStore-backed discovery — Images/Videos/Audio open in ~1–2s. | ✅ |
| Docs/Apps/Archives served from MediaStore.Files + per-folder `queryFiles`. | ✅ |
| Folder view grouped by parent folder with per-folder counts. | ✅ |
| Grid + list toggle, sort via `...` menu (Name/Modified/Size/Type). | ✅ |
| Thumbnails with APK icon extraction and typed icons. | ✅ |
| Shared `FileEntryListTile` + formatting helpers. | ✅ |

### 🎬 Viewers & Players

| Feature | Status |
| --- | --- |
| In-app preview for images, video, audio (Explorer + within ZIPs). | ✅ |
| Images: pinch/double-tap zoom, rotate, swipe, share, details, delete, rename, wallpaper. | ✅ |
| Video: auto-hiding controls, landscape, 10‑s double-tap seeking, speed, loop, shuffle, mute, wakelock. | ✅ |
| Audio: seek, speed, volume, mute, loop, shuffle, prev/next, details. | ✅ |
| Built-in text viewer (`.txt`, `.md`, `.json`, `.py`, `.dart`, …) — selectable, wrap, font size. | ✅ |
| `Open with` system chooser; `Open as` to force Text/Image/Video/Audio. | ✅ |

### 🗜️ Archives

| Feature | Status |
| --- | --- |
| In-app `.zip` browsing: folder viewer, back/refresh, breadcrumbs. | ✅ |
| Type badges + human-readable sizes; `Open with` via system chooser. | ✅ |
| "Extract here" workflow. | ✅ |

### 🔁 Transfers

| Feature | Status |
| --- | --- |
| Copy/move/rename/delete queue with `Paste here` picker. | ✅ |
| Conflict choices: `Skip`, `Replace`, `Keep both`. | ✅ |
| Persistent queue/history via Drift. | ✅ |
| Post-transfer MediaStore rescan so new files appear, moved sources update. | ✅ |

### 🔎 Search

| Feature | Status |
| --- | --- |
| Scope (folder/storage), type filters, type-only discovery. | ✅ |
| Persisted index (Drift), reindex, auto-invalidation on transfers. | ✅ |
| MediaStore-backed type browse + index seeding. | ✅ |
| Background pre-warm on permission; post-invalidation re-warm. | ✅ |

### 💾 Persistence & Settings

| Feature | Status |
| --- | --- |
| Persistent favorites, recents, transfer queue/history. | ✅ |
| Settings screen (Explorer, Transfers, Search toggles). | ✅ |
| Drift + build_runner codegen. | ✅ |

---

## 🧰 Requirements

| Tool | Version |
| --- | --- |
| Flutter | `3.24.3` or compatible |
| Dart | `3.5.3` or compatible |
| Android Studio / SDK | required for Android builds |

Check your setup:

```bash
flutter doctor
flutter devices
```

<details>
<summary>Install dependencies from repo root vs. project folder</summary>

Local Android SDK location referenced by docs assumes Linux Mint/Ubuntu
`/usr/lib/android-sdk`.

**From the project folder (`project/`):**

```bash
flutter pub get
```

**From repo root:**

```bash
cd project
flutter pub get
```

</details>

---

## 🚀 Run on Android

Start an emulator or connect a device, then:

```bash
flutter run -d android
```

If multiple Android devices are connected, target one explicitly:

```bash
flutter devices
flutter run -d <device-id>
```

Detach from the terminal while leaving the app running with <kbd>d</kbd>, or quit with
<kbd>q</kbd>. While running: <kbd>r</kbd> hot reload, <kbd>R</kbd> hot restart.

## 📡 Android Wireless Debugging

### First-time pairing (break USB once)

```bash
adb devices
adb tcpip 5555
adb connect $(adb shell ip route | awk '{print $9; exit}'):5555
flutter run
```

After `adb connect` succeeds, unplug USB. Hot reload still works with <kbd>r</kbd>.

If the phone already has wireless debugging paired from Developer options, later runs are
usually only:

```bash
adb connect <phone-ip>:<port>
flutter run -d <phone-ip>:<port>
```

<details>
<summary>Build and install a debug APK on a connected phone</summary>

**Remote debug build + install — use exactly this when asked for remote debugging:**

```bash
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

The `-r` reinstalls over the current build. Requires the phone to be reachable over
`adb` (see the USB `adb tcpip 5555` step above for wireless setup).

Launch the installed app from terminal:

```bash
adb -s <device-id> shell monkey -p com.ajayff4.fileexplorer 1
```

</details>

If Android builds fail because SDK licenses are not accepted:

```bash
flutter doctor --android-licenses
```

On Linux Mint/Ubuntu, if the SDK is installed at `/usr/lib/android-sdk`, use the full
`sdkmanager` path with `sudo` (system-owned folder):

```bash
sudo /usr/lib/android-sdk/cmdline-tools/13.0/bin/sdkmanager \
  --sdk_root=/usr/lib/android-sdk \
  --licenses
```

This project compiles Android with **SDK 35** because the plugins require it. If SDK 35
or the requested build tools are missing, install them:

```bash
sudo /usr/lib/android-sdk/cmdline-tools/13.0/bin/sdkmanager \
  --sdk_root=/usr/lib/android-sdk \
  "platforms;android-35" \
  "build-tools;33.0.1" \
  "platform-tools"
```

---

## 📱 Supported platforms

**The product target is Android phones.** The entire storage/media stack is native
Android — filesystem browsing, MediaStore queries, ZIP preview, and transfers are
built on `dart:io` and Android MethodChannels, so **web is not supported** (there is no
filesystem to explore, and the platform channels have no web implementation), and
desktop has no platform channel or HC support. Only Android builds should be
considered functional.

| Platform | Status | Notes |
| --- | --- | --- |
| Android | ✅ | The real target — everything works here. |
| iOS | ⚠️ | Scaffolded only; no iOS storage channel implementations. |
| Web | ❌ | Not supported — `dart:io`/Android channels have no web path. |
| Desktop (Linux/Windows/macOS) | ⚠️ | `dart:io` partial; storage channel implementations are Android-only. |

---

## 🔨 Build commands

| Artifact | Command |
| -- | -- |
| Android debug APK | `flutter build apk --debug` |
| Android release APK | `flutter build apk --release` |
| Android App Bundle | `flutter build appbundle` |
| Linux desktop build | `flutter build linux` — CLI history only; Linux support is planned for the future |

---

## ✅ Quality checks

```bash
dart format lib test
flutter analyze
flutter test
```
```text
- Run the full local verification pass above after changes.
- Do not add comments unless asked; do not touch CHANGES.md / ROADMAP.md unless asked.
```

---

## ⚙️ Code generation

Drift and `build_runner` power the local metadata DB. Run generators after schema/table
changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode during active schema/model work:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## 🏗️ Project Structure

```text
lib/
  app/
    app.dart
    router/
    theme/
  features/
    explorer/
    favorites/
    home/
    media/
    recents/
    search/
    settings/
    storage_permissions/
    transfers/
    zip/
  shared/
    database/
    formatters/
```

The codebase is organized feature-first so platform storage, transfer engine, search,
settings, and future tools can grow without turning `lib/` into one large shared folder.

---

## 📚 See also

- `CHANGES.md` — chronological progress log.
- `ROADMAP.md` — planned work and status per feature.
- `docs/ROUTING.md` — navigation model (added on real-device routing work).