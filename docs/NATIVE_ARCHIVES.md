# Native RAR / 7z support (evaluation)

Working notes on adding read-only RAR and 7z browsing through a bundled native
engine layer, mirroring how the original ES File Explorer ships UnRAR +
7-Zip binaries in its APK. **Nothing here is committed to the codebase yet** —
this is an eval-only document.

## Why

- The `archive` package (pure Dart, 8.8M downloads/month, verified publisher)
  handles zip/tar/gz/bz2/xz and is the backbone of the current archive module.
- It cannot handle RAR (proprietary/patented algorithm) or the `.7z` container
  format. No maintained pure-Dart alternative exists.
- The two candidate pub/git packages are low-reliability:
  - `flutter_7zip` (FFI → 7-Zip): git-only dep, ~5 stars / 9 commits, LGPL,
    single maintainer, extract-only.
  - `unrar` (Dart FFI → RARLab UnRAR): brand-new, unverified uploader,
    ~38 downloads, extract-only.

## Proposed architecture

Keep `archive` as the base codec layer and add a thin native bridge only for
formats it can't decode:

```
LocalArchiveRepository (io)                     current seam
  ├─ ArchiveFormat.zip/tar/…   → archive package (unchanged)
  └─ ArchiveFormat.rar/7z      → ArchiveBridge (FFI)   ← new
        ├─ 7-Zip engine  (LGPL)
        └─ UnRAR engine  (RARLab)
```

- New `ArchiveFormat` values: `rar`, `sevenZip` (mapped from `.rar` / `.7z`).
- `ArchiveBridge` exposes `listDirectory(archivePath, dir)` and
  `readEntry(archivePath, entryPath)`, fed through `dart:ffi` to the `.so`
  bundled under `android/`.
- Archive listing, viewer, preview, and transfer code stay unchanged.

## Effort estimate

| Task | Effort |
| --- | --- |
| FFI plugin scaffold (CMake, pubspec, Dart bindings) | ~1 session |
| Compile 7-Zip/LZMA SDK for Android arm64 via NDK | 1–2 sessions |
| FFI wiring: list + read-entry, memory crossing, isolate off UI thread | ~1 session |
| Integration + re-add `.rar`/`.7z` as browsable + tests | ~1 session |
| Compile UnRAR for Android | ~1 session |
| RAR FFI wiring (second engine) | ~1 session |
| License compliance + encrypted-archive/password support | 1+ session |

**Total: roughly 6–9 focused sessions for both, ARM64 only.** Encrypted
archives and in-archive previews add more. Time is dominated by NDK/CMake
builds of the third-party C++ sources, not the Dart side.

## Open questions

- Which 7-Zip/LZMA SDK snapshot to vendor (current is 26.02).
- Password/AES handling for encrypted `.7z` and `.rar`.

## Licensing (RAR)

No "bypass" is needed — read-only extraction is explicitly permitted. The
UnRAR source (RARLab, SPDX id `UnRAR`, classified source-available, not OSI)
is free to embed for handling RAR archives. Chromium ships it unmodified the
same way.

Terms that must be honored:

| Clause | Requirement | Our compliance |
| --- | --- | --- |
| §2 — cannot build a RAR-compatible archiver | Do not create/write `.rar` files | RAR here is read-only (browse + extract) ✓ |
| §2 — cannot re-create proprietary RAR compression | No reverse-engineering of the algorithm | None planned ✓ |
| §2 — if source is modified | Full text of the license paragraph must be reproduced in docs/comments of the resulting package | Vendor **unmodified** source to avoid this entirely |
| §3 — free distribution allowed | — | Bundle `libunrar.so` inside the APK |

Compliance plan:

1. Vendor the **unmodified** `unrarsrc-<version>.tar.gz` (current 7.2.4) from
   rarlab.com into `project/third_party/unrar/`.
2. Ship RARLab's `license.txt` in the app (About / licenses screen).
3. Keep the engine extract-only to never touch the prohibited compression path.

## Status

- [ ] FFI plugin scaffold
- [ ] 7z engine
- [ ] RAR engine
- [ ] Repository integration + tests