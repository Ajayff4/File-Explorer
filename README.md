# File Explorer

A Flutter file manager built with a feature-first architecture.

Package/application ID: `com.ajayff4.fileexplorer`

## Current Status

The project currently contains the first app foundation:

- Responsive app shell with mobile bottom navigation and desktop/tablet navigation rail.
- Home dashboard.
- Explorer screen with list/grid toggle.
- Transfers screen placeholder.
- Settings screen placeholder.
- Fake storage data for UI development before native filesystem integration.

## Requirements

- Flutter `3.24.3` or compatible.
- Dart `3.5.3` or compatible.
- Chrome for web development.
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

## Run On Web

Run directly in Chrome:

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

Useful while running:

- Press `r` for hot reload.
- Press `R` for hot restart.
- Press `q` to quit.

## Run On Desktop

Linux:

```bash
flutter run -d linux
```

List all available targets:

```bash
flutter devices
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

## Build Commands

Web release build:

```bash
flutter build web
```

Android APK:

```bash
flutter build apk
```

Android App Bundle:

```bash
flutter build appbundle
```

Linux release build:

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

Drift and `build_runner` are already added for the upcoming local metadata database.

Run generators when generated files are introduced:

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
    home/
    settings/
    transfers/
```

The codebase is organized feature-first so platform storage, transfer engine, and settings work can grow without turning `lib/` into one large shared folder.
