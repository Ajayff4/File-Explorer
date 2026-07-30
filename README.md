# File Explorer

A Flutter file manager built with a feature-first architecture.

Package/application ID: `com.ajayff4.fileexplorer`

## Current Status

The project now has a usable early file-manager vertical slice:

- Mobile app shell with bottom navigation.
- Home dashboard with storage summary, shortcuts, favorites, and recent folders.
- Explorer screen with real local/Android storage browsing where permissions allow it.
- List/grid view toggle, breadcrumb, storage selector, refresh, and folder navigation.
- Android storage permission card and native Android storage volume discovery.
- Transfer queue for copy, move, rename, and delete.
- Copy/move destination picker with `Paste here`.
- Transfer conflict actions: `Skip`, `Replace`, and `Keep both`.
- Persistent transfer queue/history with Drift.
- Persistent favorite folders and recent folders.
- Search screen with current/storage scope, type filters, type-only discovery, and persisted search index.
- Media library screens for images, videos, audio, documents, and apps.
- Settings screen with persisted Explorer, Transfers, and Search toggles.
- Fake storage exists only for development/tests.

## Requirements

- Flutter `3.24.3` or compatible.
- Dart `3.5.3` or compatible.
- Android Studio / Android SDK for Android builds.

Check your setup:

```bash
flutter doctor
flutter devices
```

## Install Dependencies

From this folder:

```bash
flutter pub get
```

From repo root:

```bash
cd project
flutter pub get
```

## Run On Android

Start an emulator or connect a device, then run:

```bash
flutter run -d android
```

If multiple Android devices are connected:

```bash
flutter devices
flutter run -d <device-id>
```

For your connected phone, the command usually looks like:

```bash
flutter devices
flutter run -d HAL7EAPNFULJZPUG
```

Detach from the terminal while leaving the app running:

```text
d
```

Quit the running app session:

```text
q
```

Useful while running:

- Press `r` for hot reload.
- Press `R` for hot restart.
- Press `q` to quit.

Build and install a debug APK on a connected phone:

```bash
flutter build apk --debug
flutter install -d <device-id> --use-application-binary build/app/outputs/flutter-apk/app-debug.apk
```

Launch the installed app from terminal:

```bash
adb -s <device-id> shell monkey -p com.ajayff4.fileexplorer 1
```

If Android builds fail because SDK licenses are not accepted, run:

```bash
flutter doctor --android-licenses
```

On Linux Mint/Ubuntu, if the SDK is installed at `/usr/lib/android-sdk`, use the full `sdkmanager` path with `sudo` because that SDK folder is system-owned:

```bash
sudo /usr/lib/android-sdk/cmdline-tools/13.0/bin/sdkmanager \
  --sdk_root=/usr/lib/android-sdk \
  --licenses
```

This project compiles Android with SDK `35` because the Android plugins require it. If SDK 35 or the requested build tools are missing, install them from Android Studio SDK Manager or with `sdkmanager`:

```bash
sudo /usr/lib/android-sdk/cmdline-tools/13.0/bin/sdkmanager \
  --sdk_root=/usr/lib/android-sdk \
  "platforms;android-35" \
  "build-tools;33.0.1" \
  "platform-tools"
```

## Optional Dev Run Targets

The product target is Android phones. These commands are only for local
development/debugging when an Android device is not convenient.

Run in Chrome:

```bash
flutter run -d chrome
```

Run as a web server on a fixed local URL:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5174
```

Then open:

```text
http://127.0.0.1:5174
```

Run on Linux desktop:

```bash
flutter run -d linux
```

List all available targets:

```bash
flutter devices
```

## Build Commands

Android debug APK:

```bash
flutter build apk --debug
```

Android release APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle
```

Optional web dev build:

```bash
flutter build web
```

Optional Linux dev build:

```bash
flutter build linux
```

## Quality Checks

Format code:

```bash
dart format lib test
```

Analyze code:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run the normal local verification pass:

```bash
dart format lib test
flutter analyze
flutter test
```

## Code Generation

Drift and `build_runner` are used for the local metadata database.

Run generators after Drift schema/table changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode during active schema/model work:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Project Structure

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
    recents/
    search/
    settings/
    transfers/
  shared/
    database/
```

The codebase is organized feature-first so platform storage, transfer engine, search, settings, and future tools can grow without turning `lib/` into one large shared folder.
