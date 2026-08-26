# Play Store Flavors — `universal` vs `standard` (adversarial / rejection-proof plan)

> **Persona for this document:** I am the Play Store reviewer whose job is to
> reject your app. I am looking for *any* trace that this is (or was) a media
> downloader — `yt-dlp`, Python, a `download_task_rows` table, a
> `…/downloader` `MethodChannel`, the words "Universal Downloader" / "yt-dlp" /
> "YouTube" in the binary, a hidden runtime switch, or a misleading listing.
> Every control below exists to survive **me**. If even one control is missing,
> I will find the trace and reject `standard`.

Flavors:

| Flavor | Contents | Target |
| ------ | -------- | ------ |
| `universal` | Everything, including the Universal Downloader | Sideload / F-Droid / GitHub |
| `standard` | Everything **minus** the downloader (must be 100% trace-free) | Google Play Store |

---

## 1. The reviewer's rejection checklist (threat model)

For each item, the **Probe** is what I (the invigilator) would run, the
**Hideout** is where a trace could survive, and the **Control** is the exact
fix that makes `standard` clean.

| # | What I'd reject for | Probe I run | Where a trace hides | Control |
| - | ------------------- | ----------- | ------------------- | ------- |
| 1 | Bundled `yt-dlp` / Python | `unzip -l app-standard-release.apk \| grep -i "yt_dlp\|python\|libpython\|libchaquopy"` | `src/main/python/`, chaquopy pip, native `.so` | Move Python + ffmpeg to `src/universal`; apply chaquopy **only** for `universal` (§2.1) |
| 2 | `…/downloader` channel strings | `strings classes.dex \| grep "com.ajayff4.fileexplorer/downloader"` | `MainActivity.kt` channel registration; `chaquopy_download_engine.dart` | Per-flavor no-op bridge: `src/standard` ships an empty `maybeSetupDownloaderBridge` (§2.4) |
| 3 | "Universal Downloader" / "yt-dlp" / "YouTube" copy | `strings` over the whole APK (DEX + resources) | `core_features_screen.dart`, `home_screen.dart`, `downloader_screen.dart` | Gate every reference behind `enableDownloader`; tree-shake removes the strings (§3) |
| 4 | Undeclared `download_task_rows` table | open the app's SQLite DB / grep generated drift code for `download_task_rows` | `AppDatabase` annotation + migration | Extract `DownloadTaskRows` into a feature-local `DownloaderDatabase`; prune `app_database.dart` (§3.3) |
| 5 | Hidden runtime re-enable switch | static analysis for remote config / `SharedPreferences` / `dart:io` env reads that flip the downloader on | a runtime `bool` flag instead of compile-time | **Compile-time only:** `bool.fromEnvironment('ENABLE_DOWNLOADER')`. No runtime path can re-enable it (§3.1). Forbidden. |
| 6 | Undeclared third-party native code | `unzip -l \| grep "\.so"` for python/chaquopy libs | chaquopy plugin applied unconditionally | chaquopy `apply plugin` is conditional on the `universal` task (§2.1) |
| 7 | Misleading store listing | read the Play Console description + screenshots | listing shows a downloader the APK lacks | Keep `standard`'s listing (text + screenshots) downloader-free (§4) |
| 8 | Data-safety mismatch | compare declared data vs actual tables | `download_task_rows` implies URL logging | `standard` has no such table; Data safety form omits download (§4) |

**Verified-clean facts (so we don't waste controls on non-issues):**
- `pubspec.yaml` has **no** downloader-only Flutter plugin — the Chaquopy bridge is hand-rolled over a `MethodChannel`, so there is no plugin whose native code leaks into every flavor. *Never add a downloader plugin; it would break this guarantee.*
- There is **no** `l10n` / `.arb` catalog — every user-facing string is a Dart literal, so tree-shaking removes them completely. *If i18n is ever added, the ARB files (resources, not tree-shaken) must also be flavor-gated, or strings survive.*
- `AndroidManifest.xml` declares only generic permissions (`INTERNET`, storage, camera, Wi-Fi/nearby). `INTERNET` is legitimately required by nearby sharing and remote media metadata — have this one-line justification ready; it is **not** a downloader tell.

---

## 2. Layer 1 — Android (the layer tree-shaking can't touch)

### 2.1 Apply Chaquopy **only** for `universal`

A reviewer scanning `standard` for `libpython3.12.so` / `libchaquopy.so` will
reject if the plugin is applied at all. Switch from the `plugins {}` block to a
conditional legacy `apply`, keyed off the invoked Gradle task:

```gradle
def isUniversal = gradle.startParameter.taskNames.any { it ==~ /(?i).*universal.*/ }
if (isUniversal) {
  apply plugin: 'com.chaquo.python'
}
if (isUniversal) {
  chaquopy {
    defaultConfig {
      version = "3.12"
      extractPackages("yt_dlp_plugins")
      pip { install "yt-dlp" }
    }
  }
}
```

Keep `id "com.chaquo.python" version "17.0.0" apply false` in
`android/settings.gradle` (unchanged). `gradle.properties` keeps
`disable-abi-filtering=true` (only matters when chaquopy is applied).

### 2.2 Move Python + ffmpeg out of `src/main`

| From | To |
| ---- | -- |
| `android/app/src/main/python/` | `android/app/src/universal/python/` |
| `android/app/src/main/assets/ffmpeg/` (binary + `LGPL-2.1.txt` + `PROVENANCE.md`) | `android/app/src/universal/assets/ffmpeg/` |

Chaquopy scans the flavor's `python/` dir, so `universal` bundles it and
`standard` has nothing. No `python/`, no `ffmpeg`, no `PROVENANCE.md`
mentioning ffmpeg ships in `standard`.

### 2.3 Flavor dimensions

```gradle
android {
  flavorDimensions "store"
  productFlavors {
    universal { dimension "store" }
    standard  { dimension "store" }
  }
}
```

Keep `minSdk = 24` for both (simpler; `standard` doesn't need Chaquopy's floor
but paying it costs nothing). Keep the same `applicationId` so `standard` is a
normal Play update of the listing.

### 2.4 Kotlin channel seam (no-op in `standard`)

`MainActivity.kt` (stays in `src/main/java`) must not contain the channel
strings. Move the registration into a per-flavor top-level function with the
**same signature** in each flavor source set:

- `src/universal/java/.../downloader_bridge.kt`
  → `fun maybeSetupDownloaderBridge(engine: FlutterEngine)` registers
  `MethodChannel com.ajayff4.fileexplorer/downloader`,
  `EventChannel com.ajayff4.fileexplorer/downloader/events`, and calls
  `extractFfmpeg()`.
- `src/standard/java/.../downloader_bridge.kt`
  → the **same** `fun maybeSetupDownloaderBridge(engine: FlutterEngine)` with an
  **empty body**.

`MainActivity.configureFlutterEngine` calls
`maybeSetupDownloaderBridge(flutterEngine)`. Each flavor compiles its own
implementation; `standard` emits **zero** channel strings and **zero** Python
glue. (A runtime `if (flavor == "standard") return;` guard is *insufficient* —
the strings would still be in the DEX. The no-op source set is the only safe
form.)

---

## 3. Layer 2 — Dart (compile-time flag + tree-shaking)

### 3.1 The flag — compile-time, never runtime

`lib/shared/config/flavor_config.dart`:

```dart
const bool enableDownloader =
    bool.fromEnvironment('ENABLE_DOWNLOADER', defaultValue: true);
```

`const bool.fromEnvironment` makes every `if (enableDownloader)` branch
compile-time dead under `--dart-define=ENABLE_DOWNLOADER=false`, so the compiler
discards the branch **and** any import only that branch used. **Hard rule: no
runtime switch** (no `dart:io` env read, no `SharedPreferences`, no remote
config). A runtime flag would keep the code in the binary and fail probe #5.

### 3.2 Gate every production reference

A single surviving reference keeps the **entire** downloader graph (and its
strings) linked. Gate all of:

| File | Gate |
| ---- | ---- |
| `lib/app/router/app_router.dart` | The two `GoRoute`s for `AppRoutes.downloader` / `AppRoutes.downloaderBrowse`; then delete the now-unused `AppRoutes` constants + the two downloader `import`s. |
| `lib/app/window/window_manager.dart` | The `if (path.startsWith(AppRoutes.downloader)) return Icons.download_rounded;` branch in `iconForLocation`. |
| `lib/features/home/presentation/home_screen.dart` | `ref.watch(downloaderControllerProvider)` (compute only `if (enableDownloader)`) and the `context.go/push(AppRoutes.downloader)` taps. |
| `lib/features/home/presentation/core_features_screen.dart` | The `Universal Downloader` `_CoreFeature` entry (description literally says "yt-dlp" + "YouTube/Instagram/Twitter"). Build the list conditionally so the entry — and its strings — are absent. |

Pattern:

```dart
if (enableDownloader) ...[
  GoRoute(path: AppRoutes.downloader, builder: (_ , _) => const DownloaderScreen()),
],
```

```dart
final downloaderState = enableDownloader ? ref.watch(downloaderControllerProvider) : null;
```

```dart
final _coreFeatures = <_CoreFeature>[
  // ...all non-downloader features...
  if (enableDownloader)
    _CoreFeature(
      icon: Icons.download_rounded,
      title: 'Universal Downloader',
      description: '...yt-dlp / YouTube / Instagram / Twitter...',
      color: Color(0xFFD81B60),
    ),
];
```

### 3.3 Extract the downloader database (defeats probe #4)

`DownloadTaskRows` currently lives in the **shared** `AppDatabase`
(`app_database.dart` + generated `app_database.g.dart`), referenced by the
`@DriftDatabase(tables: [...])` annotation and three migration steps
(`from < 8` createTable, `from < 9` quality, `from < 10` audioFormat/playlist).
A compile-time annotation list can't be conditionally shrunk, so the
`download_task_rows` table name + columns would otherwise survive in
`standard`.

1. Create `lib/features/downloader/data/downloader_database.dart` owning
   `@DriftDatabase(tables: [DownloadTaskRows])` and move the `DownloadTaskRows`
   table class here.
2. In `app_database.dart`: remove the table class, the
   `import '.../download_task.dart'`, the `DownloadTaskRows` entry in the
   `@DriftDatabase(tables: [...])` annotation, and the three migration steps
   referencing `downloadTaskRows`.
3. Point `drift_download_task_store.dart` /
   `drift_downloader_settings_store.dart` at `DownloaderDatabase`.
4. Regenerate: `flutter packages pub run build_runner build --delete-conflicting-outputs`
   — `app_database.g.dart` is regenerated **without** any `DownloadTaskRows` /
   `download_task_rows` symbol; `downloader_database.g.dart` lives inside the
   feature.
5. Because `DownloaderDatabase` is imported only by the (now gated) feature, it
   tree-shakes out of `standard` — no table, no column names, no strings.

> **Lingering user-data note (defense in depth, not an APK issue):** a device
> that ran `universal` then installs `standard` keeps an orphan
> `download_task_rows` table in its on-disk SQLite file. That is *user data*,
> invisible to an APK scan, but a paranoid privacy reviewer could dump it. Do
> **not** add a `DROP TABLE download_task_rows` in `standard` code — that would
> embed the string and fail probe #4. If cleanup is wanted, let `universal`
> drop the table on its own schema upgrade before the user migrates.

### 3.4 Auto-tree-shaken (no manual edit needed)

Once 3.2/3.3 land, these are referenced **only** from the gated feature and
vanish from `standard`: `download_engine_provider.dart`,
`chaquopy_download_engine.dart`, `download_engine_io.dart`,
`fake_download_engine.dart`, `downloader_controller.dart` + provider,
`downloader_screen.dart`, `download_browse_screen.dart`,
`download_entry_grid.dart`, `downloader_visuals.dart`, and the entire
`features/downloader/**` tree.

---

## 4. Store-listing & console hygiene (defeats probes #7, #8)

The APK is only half the review. The Play Console listing is read too:

- **Description & screenshots** for the `standard` track must not mention or
  depict the downloader. Keep a separate listing narrative from `universal`.
- **Data safety form** must not declare download/URL collection for `standard`
  (the `download_task_rows` table — which logs source URLs — does not exist
  there).
- **App title / icon**: identical is fine; just ensure no "downloader" wording
  sneaks into the `standard` title.

---

## 5. Build commands

```bash
# universal (sideload / F-Droid / GitHub) — downloader included
flutter build appbundle --flavor universal --dart-define=ENABLE_DOWNLOADER=true
flutter build apk         --flavor universal --dart-define=ENABLE_DOWNLOADER=true

# standard (Google Play) — must be trace-free
flutter build appbundle --flavor standard --dart-define=ENABLE_DOWNLOADER=false
flutter build apk         --flavor standard --dart-define=ENABLE_DOWNLOADER=false
```

Optional hardening for `standard`: add `--obfuscate --split-debug-info=build/symbols`
so any symbol that survives accidental retention is mangled (defense in depth;
tree-shaking is the real control).

---

## 6. Invigilator acceptance — final verification on the `standard` artifact

Run **all** of these against the `standard` build. The reviewer accepts only if
**every** command returns **nothing**.

```bash
APK=build/app/outputs/flutter-apk/app-standard-release.apk

# Probe 1 & 6: no Python / yt-dlp / chaquopy native libs
unzip -l "$APK" | grep -iE "yt_dlp|python|libpython|libchaquopy|ffmpeg"

# Probe 2: no downloader channel strings in the DEX
apkanalyzer dex packages "$APK" >/dev/null 2>&1
strings -a "$APK" | grep -E "com\.ajayff4\.fileexplorer/downloader"

# Probe 3: no downloader / site-name copy anywhere in the APK
strings -a "$APK" | grep -iE "Universal Downloader|yt-dlp|yt_dlp|YouTube|Instagram|Twitter"

# Probe 4: no download_task_rows symbol in generated code (source-side check)
grep -rn "download_task_rows\|DownloadTaskRows" lib/shared lib/features/home

# Probe 5: no runtime switch that could re-enable the downloader
grep -rn "fromEnvironment\|Platform.environment\|SharedPreferences" lib/features/downloader
```

Expected: all empty. Then:

```bash
flutter analyze          # clean
flutter test             # green (tests compile the feature directly; default flag = true)
```

And a device smoke test: `standard` shows **no** downloader entry in Home, Core
Features, or navigation; `universal` still downloads end-to-end via the Chaquopy
bridge.

---

## 7. Implementation checklist

- [ ] `android/app/build.gradle`: `flavorDimensions "store"` + `universal`/`standard`; conditional Chaquopy `apply` + `chaquopy {}` keyed on the `universal` task.
- [ ] `android/app/src/universal/python/` ← moved from `src/main/python/`.
- [ ] `android/app/src/universal/assets/ffmpeg/` ← moved from `src/main/assets/ffmpeg/`.
- [ ] `src/universal/java/.../downloader_bridge.kt` (real) + `src/standard/java/.../downloader_bridge.kt` (empty); `MainActivity` calls `maybeSetupDownloaderBridge`.
- [ ] `lib/shared/config/flavor_config.dart` added (`const bool.fromEnvironment`, compile-time only).
- [ ] Gate `app_router.dart`, `window_manager.dart`, `home_screen.dart`, `core_features_screen.dart`.
- [ ] Extract `DownloadTaskRows` → `features/downloader/data/downloader_database.dart`; prune `app_database.dart` + migration; regenerate drift.
- [ ] Build `universal` and `standard`; run §6 verification — **all empty**.
- [ ] Update the `standard` Play Console listing (description, screenshots) and Data safety form to be downloader-free.
- [ ] Update `README.md` feature list if `standard` is the advertised Play build (per `AGENTS.md`, audit-md also touches README).
