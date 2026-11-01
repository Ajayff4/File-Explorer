# Website Plan

**Status:** Website moved, cleaned, QA-tested, and committed to its own local repo. Not published.
**Site source now:** top-level `website/` (outside the `project` git repository), versioned in a separate git repo.
**Website repo:** `main`, initial commit `be909e4`; no remote configured.
**Deployment target:** Undecided — leave GitHub Pages disabled until hosting is chosen.
**Next continuation:** Decide hosting, add a remote, and publish with explicit approval.

## Ground Rules

- Use **actual app screenshots only**. No generated app UI, fake screens, or invented filenames.
- Do **not** use `reference-screenshots/`; they are from a different app.
- Do **not** commit or push without explicit approval.
- Do **not** edit `CHANGELOG.md` or `ROADMAP.md` unless explicitly asked.
- Preserve the honest “Actual app screenshot” labelling on the site.

## Goal

Ship a credible marketing/download page for File Explorer `v1.1.0` that:

1. Shows the real Android app, not mockups.
2. Works cleanly on desktop and mobile.
3. Has working APK links, checksums, and GitHub links.
4. Is published from `website/` via the chosen hosting setup.

## Folder Move (Completed 2026-11-02)

The site now lives at the top level, next to `project/`:

```text
es-file-explorer/
├── project/                 # Flutter app + app Markdown docs only
│   └── docs/                # DOWNLOADER.md, ROUTING.md, etc. (no site code)
└── website/
    ├── index.html
    ├── styles.css
    ├── script.js
    ├── .nojekyll
    └── assets/
        ├── favicon.png
        ├── apple-touch-icon.png
        ├── logo-512.png
        ├── og.png
        └── screenshots/
            ├── home.png
            ├── explorer.png
            ├── analyzer.png
            └── transfers.png
```

Consequences:

- `website/` is **outside** the `project` git repo and now has its own git repo (`main`).
- GitHub Pages cannot publish it from the app repo’s `master /docs` source.
- Publishing requires one of: a separate website repo, a copy/publish step, or another host.
- Do not enable Pages until hosting is chosen.

## Current State

### Implemented

- Full responsive dark site in `website/index.html`, `website/styles.css`, `website/script.js`, `website/.nojekyll`.
- Header/nav, sticky state, mobile menu, scroll reveal, copy buttons, and footer year.
- Real screenshots from File Explorer v1.1.0 on the `Pixel_6` Android 14 AVD:
  - Hero home screenshot: `assets/screenshots/home.png`
  - Gallery: `assets/screenshots/explorer.png`, `assets/screenshots/analyzer.png`
  - Workflow Transfer Station screenshot: `assets/screenshots/transfers.png`
- `#screenshots` gallery between Features and Workflow.
- “Screenshots” links added to the header nav and footer App column.
- Hero caption says “Actual app screenshot · Android”; workflow caption says “Actual app screenshot · Transfer Station”.
- Hero screenshot is eager with `fetchpriority="high"` and `decoding="async"`; other screenshots use `loading="lazy"` and `decoding="async"`.
- All images keep explicit `width`/`height` to prevent layout shift.
- Dead mockup/queue CSS removed:
  - `.phone-screen`, status bar, app bar, storage card, chip row, fake file list, toast, fake bottom nav
  - `.queue-card` and progress/badge rules
  - responsive `.phone-screen` rules at 640px and 400px
- Mobile gallery phone frame enlarged from 244px to 280px max for legibility.
- Screenshot PNGs are 720×1600; total screenshot weight ~1.1 MB.

### Not yet done

- No remote configured and no push.
- No host chosen; GitHub Pages is not enabled.
- Optional: Lighthouse audit and WebP/AVIF conversion (PNGs intentionally kept for now).
- Optional: re-check the live site after publishing.

## Current Page Order

1. Hero (`#top`)
2. Features (`#features`)
3. Screenshots (`#screenshots`)
4. Workflow (`#workflow`)
5. Privacy (`#privacy`)
6. Builds (`#builds`)
7. Download (`#download`)
8. Roadmap
9. FAQ (`#faq`)
10. Footer

Header nav: Features, Screenshots, Workflow, Builds, Download, FAQ, GitHub.

## Files

| Path | Role |
| --- | --- |
| `website/index.html` | Landing page; real screenshots in hero, gallery, and workflow |
| `website/styles.css` | Responsive styling; dead mockup/queue rules removed |
| `website/script.js` | Nav, reveal, sticky header, copy buttons, footer year |
| `website/.nojekyll` | Required for GitHub Pages |
| `website/assets/favicon.png` | Brand favicon |
| `website/assets/apple-touch-icon.png` | Apple touch icon |
| `website/assets/logo-512.png` | Brand mark used in header and footer |
| `website/assets/og.png` | Open Graph / Twitter image |
| `website/assets/screenshots/home.png` | Actual home screenshot, 720×1600 |
| `website/assets/screenshots/explorer.png` | Actual Explorer screenshot, 720×1600 |
| `website/assets/screenshots/analyzer.png` | Actual Storage Analyzer screenshot, 720×1600 |
| `website/assets/screenshots/transfers.png` | Actual Transfer Station screenshot, 720×1600 |
| `project/WEBSITE_PLAN.md` | This plan; outside `website/` so it is not published |

## Screenshot Provenance

| Site asset | Source capture | Content |
| --- | --- | --- |
| `home.png` | `/tmp/es-home-check.png` | Home dashboard, 12:05, status bar visible |
| `explorer.png` | `/tmp/es-root-list.png` | Top-level Explorer folder list |
| `analyzer.png` | `/tmp/es-analyzer.png` | Storage Analyzer with 8.4 MB sample total |
| `transfers.png` | `/tmp/es-transfers-done.png` | Transfer Station, queue idle, 2 finished, 1 cancelled |

The older `/tmp/es-home-real4.png` had an invisible status bar; do not reuse it.
The `/tmp` copies are temporary; the live copies are under `website/assets/screenshots/`.

## QA Results (2026-11-02)

Local preview: `python3 -m http.server 8080` from `website/`.

- All local assets returned HTTP 200: HTML, CSS, JS, `.nojekyll`, brand images, and all four screenshots.
- Visual checks at `1440×1000`, `1366×900`, `1024×768`, `390×844`, and `360×800`.
- Hero screenshot sits correctly in the phone frame; no fake notch or distortion.
- Captions are readable and do not overlap the floating cards or phone.
- Floating AES/dual-window cards are hidden below 1365px and do not overlap at 1366px+.
- Gallery is two columns on desktop and one column at 640px and below; screenshots remain legible.
- Workflow screenshot fills its panel without clipping; caption fits on mobile.
- No horizontal overflow at widths `320`, `360`, `375`, `390`, `640`, `860`, `861`, `880`, `900`, `960`, `1024`, `1366`, or `1440`.
- All four screenshots loaded and decoded (`naturalWidth` 720); lazy images load on real scroll.
- No console errors, page exceptions, duplicate IDs, or broken internal anchors.
- Anchor navigation lands sections 96px below the sticky header.
- Mobile menu opens with solid background, `aria-expanded` toggles correctly, and closes on second click / link / Escape.
- FAQ and checksum `<details>` elements open; checksum copy button writes the exact hash and shows “Copied” (verified with focused clipboard permission).
- External GitHub repo, release, issues, roadmap, and both APK URLs returned HTTP 2xx.
- APK sizes on the site (110 MB / 62 MB) match the release assets (114,356,192 / 64,651,827 bytes).
- Footer year renders `2026`.

Full-page screenshots captured during QA can show the sticky header twice; that is a headless full-page capture artifact, not a page bug.

## Remaining Work

### 1. Publishing decision

- [ ] Choose the final hosting path:
  - separate `website` repo served by GitHub Pages, or
  - copy/publish step that places these files in the app repo’s Pages source, or
  - another host.
- [ ] Update this plan and, if the URL changes, the canonical/OG URLs in `index.html`.
- [x] Get explicit approval before committing (website repo initialized and committed).
- [x] Stage only intended website files.
- [x] Use the separate `website` repo instead of the `project` repo.
- [ ] Add a remote and push/get approval before pushing.
- [ ] Keep the existing uncommitted `ROADMAP.md` change separate.
- [ ] Configure the host, verify the live site returns 200, and verify CSS/JS/screenshots/APKs load.

### 2. Optional polish

- [ ] Run Lighthouse for accessibility/performance/SEO.
- [ ] Consider WebP/AVIF versions if load weight becomes a concern.
- [x] Version `website/` in git (separate local repo on `main`).

## Deployment Facts

- Repo: `https://github.com/Ajayff4/File-Explorer`
- Branch: `master`
- Release: `https://github.com/Ajayff4/File-Explorer/releases/tag/v1.1.0`
- Download URLs:
  - `https://github.com/Ajayff4/File-Explorer/releases/download/v1.1.0/app-universal-release.apk`
  - `https://github.com/Ajayff4/File-Explorer/releases/download/v1.1.0/app-standard-release.apk`
- SHA-256:
  - Universal: `1279a4f41ca33b1071b0b2ccbb618cef4357c65fe564f3da8d9950feac3c96d0`
  - Standard: `786b2721c958566bdecc71804af86f7468217c6151f2f87d37a7206c95d7b6d8`
- Website repo: local `website/.git`, branch `main`, initial commit `be909e4`, no remote.
- Canonical/OG URLs still point at `https://ajayff4.github.io/File-Explorer/`; update if hosting differs.
- GitHub Pages is not enabled.
- No `gh` CLI; use the GitHub web UI or authenticated API for hosting. Never print tokens.

## Decisions Made

- **Location:** top-level `website/`, outside the app repo.
- **Version control:** separate local git repo on `main`, initial commit `be909e4`.
- **Hosting:** decide later; no remote, push, or Pages until approval.
- **Screenshots nav link:** added to header and footer.
- **Image format:** keep PNG for now; conversion is optional.
- **Captions:** keep generic “Android” rather than naming the emulator.
- **Roadmap change:** keep separate from any website commit.
- **Live app UI:** real screenshots only; do not reintroduce mockups or invented filenames.

## Known Constraints

- App: `com.ajayff4.fileexplorer`, version `1.1.0+2`, `minSdk 24`.
- Standard APK excludes the Python/yt-dlp downloader; Universal includes it.
- Do not describe the repo as formally open source; there is no license file.
- Privacy claims checked: no ads/accounts/analytics SDKs found.
- Android 11+ still blocks `/Android/data` and `/Android/obb` without root/Shizuku.
- Android 17/targetSdk 37 LAN features will need `ACCESS_LOCAL_NETWORK`; current target is 36.
- Synthetic sample files were seeded only to make screenshots useful; they are not marketed as user data.
- The home screenshot is intentionally a full-screen capture including Android status and navigation bars.

## Environment Notes

- Emulator: `emulator-5554`, Android 14, 1080×2400, `Pixel_6` AVD.
- Installed app: Standard APK.
- Seed data: generic documents, archive, audio, and Linux Mint wallpapers.
- Local preview server was run on port `8080`; headless Chrome CDP on `9223` during QA.
- Emulator should be launched with `-gpu host`; swiftshader previously crashed.

Useful checks:

```bash
cd /media/ajay/DriveE/projects/flutter/es-file-explorer/website
python3 -m http.server 8080

curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/
curl -s -o /dev/null -w '%{http_code} %{size_download}\n' http://127.0.0.1:8080/assets/screenshots/home.png
grep -RInE 'queue-|phone-screen|phone-row|phone-appbar|storage-card|file-icon|Stylized preview|tax-2025|Camera →|84\.1 GB' index.html styles.css
```

Expected: server returns 200, image returns 200, grep returns no results.

## Resume Here

1. Ask for a hosting decision (separate repo vs copy/publish vs another host).
2. Add the chosen remote and get explicit approval before pushing.
3. Publish, then verify the live URL, assets, and both APK links.
4. Optionally run Lighthouse and consider WebP/AVIF.
