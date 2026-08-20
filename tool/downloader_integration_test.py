#!/usr/bin/env python3
"""Integration test for the app's yt-dlp downloader against real social sites.

Imports the exact module the Android app runs
(android/app/src/main/python/downloader.py) and drives its public API
(`resolve`, `start`, `drain`) the same way MainActivity.kt does, then asserts
a real media file lands on disk. No APK rebuild required — iterate on
downloader.py and re-run this against a pinned yt-dlp.

Setup (first time only):
    python3 -m venv tool/.venv
    tool/.venv/bin/pip install yt-dlp==2026.07.04   # match bundled version
    tool/.venv/bin/pip install -r tool/requirements.txt

Usage:
    tool/.venv/bin/python tool/downloader_integration_test.py
    tool/.venv/bin/python tool/downloader_integration_test.py --sites youtube-short
    tool/.venv/bin/python tool/downloader_integration_test.py --keep --out /tmp/dl
    tool/.venv/bin/python tool/downloader_integration_test.py --url <any-url>
    tool/.venv/bin/python tool/downloader_integration_test.py --media-type audio --url <url>

Exit code: 0 = all selected sites downloaded OK, 1 = any failure.
"""

import argparse
import os
import shutil
import sys
import tempfile
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
_PROJECT = os.path.dirname(_HERE)
_DOWNLOADER = os.path.join(_PROJECT, "android", "app", "src", "main", "python")
sys.path.insert(0, _DOWNLOADER)

import yt_dlp  # noqa: E402  (fail fast if venv is not set up)

import downloader  # noqa: E402  the real module the app runs


SITES = {
    "youtube-video": {
        "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "media_type": "video",
        "note": "regular long-form YouTube video (11MB)",
    },
    "youtube-short": {
        "url": "https://youtube.com/shorts/fVLmyuCEEy8",
        "media_type": "video",
        "note": "YouTube Shorts, exercises the player_client=android fix",
    },
    "instagram-reel": {
        "url": "https://www.instagram.com/reel/DXOx98JDL1j/",
        "media_type": "video",
        "note": "public Instagram Reel (39MB)",
    },
    "twitter-video": {
        "url": "https://x.com/X/status/1697304622749086011",
        "media_type": "video",
        "note": "X/Twitter post with video",
    },
    "reddit-video": {
        "url": "https://www.reddit.com/r/videos/comments/1vrbo2j/",
        "media_type": "video",
        "note": "Reddit post hosting a native video (1.85MB)",
    },
    "threads-post": {
        "url": "https://www.threads.net/@gislainepasolini/post/DX7_p8iE1Eh",
        "media_type": "video",
        "note": "Threads video; requires the yt-dlp-threads plugin in the venv (same one vendored in the app under android/app/src/main/python/yt_dlp_plugins)",
    },
    "facebook-video": {
        "url": "https://www.facebook.com/watch/?v=3968344073475439",
        "media_type": "video",
        "note": "public Facebook video, 17s reel",
    },
}


def _task_id(url):
    suffix = "".join(c for c in url.split("/")[-1][-10:] if c.isalnum()) or "x"
    return "itest-%d-%s" % (time.time_ns(), suffix)


def run_one(url, media_type, output_dir, timeout=300, quality="auto"):
    """Start a download through downloader.start() and poll drain() for the
    terminal event, exactly like the Kotlin EventChannel poller does."""
    task_id = _task_id(url)

    start = time.monotonic()
    downloader.start(task_id, url, media_type, output_dir, quality)

    events = []
    while time.monotonic() - start < timeout:
        for event in downloader.drain():
            events.append(event)
            if event.get("taskId") == task_id and event.get("kind") in (
                "completed",
                "failed",
                "cancelled",
            ):
                return task_id, events
        time.sleep(0.5)

    downloader.cancel(task_id)
    return task_id, events


def check_artifact(output_dir, events, task_id):
    """Confirm the completed event points at a real file on disk."""
    terminal = next(
        (e for e in events if e.get("taskId") == task_id and e.get("kind") == "completed"),
        None,
    )
    if terminal is None:
        return False, "no 'completed' event"

    name = terminal.get("fileName")
    if name:
        path = os.path.join(output_dir, name)
        if os.path.isfile(path) and os.path.getsize(path) > 0:
            return True, "%s (%d bytes)" % (name, os.path.getsize(path))
        return False, "reported file missing: %s" % name

    files = [f for f in os.listdir(output_dir) if os.path.getsize(os.path.join(output_dir, f)) > 0]
    if files:
        return True, "%s (%d bytes)" % (files[0], os.path.getsize(os.path.join(output_dir, files[0])))
    return False, "no file written to output dir"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--sites",
        help="comma-separated site keys (default: all): " + ", ".join(SITES),
    )
    parser.add_argument("--url", help="test one arbitrary URL instead of the site list")
    parser.add_argument("--media-type", choices=["video", "audio"], default="video")
    parser.add_argument(
        "--quality",
        choices=["auto", "480", "720", "1080", "max"],
        default="auto",
        help="resolution cap to test (default: auto)",
    )
    parser.add_argument("--keep", action="store_true", help="keep downloaded files")
    parser.add_argument("--out", help="output directory (default: temp dir)")
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()

    print("yt-dlp: %s" % yt_dlp.version.__version__)
    print("module under test: %s" % downloader.__file__)
    print()

    if args.url:
        cases = [{"name": "custom", "url": args.url, "media_type": args.media_type, "note": "", "quality": args.quality}]
    elif args.sites:
        keys = [k.strip() for k in args.sites.split(",") if k.strip()]
        missing = [k for k in keys if k not in SITES]
        if missing:
            parser.error("unknown site(s): %s" % ", ".join(missing))
        cases = [dict(SITES[k], name=k, quality=args.quality) for k in keys]
    else:
        cases = [dict(v, name=k, quality=args.quality) for k, v in SITES.items()]

    tmp_root = args.out or tempfile.mkdtemp(prefix="dl-itest-")
    if not os.path.isdir(tmp_root):
        os.makedirs(tmp_root, exist_ok=True)
    print("output dir: %s\n" % tmp_root)

    results = []
    for case in cases:
        name = case["name"]
        url = case["url"]
        media_type = case["media_type"]
        quality = case.get("quality", "auto")
        note = case.get("note", "")

        meta = downloader.resolve(url, media_type)
        resolved_title = meta.get("title") or "(resolve failed: %s)" % (meta.get("error") or "?")

        print("[%s] %s" % (name, url))
        if note:
            print("      %s" % note)
        print("      resolve: %s" % resolved_title[:80])

        out_dir = os.path.join(tmp_root, name)
        os.makedirs(out_dir, exist_ok=True)
        task_id, events = run_one(url, media_type, out_dir, timeout=args.timeout, quality=quality)

        terminal = next(
            (e for e in events if e.get("taskId") == task_id and e.get("kind") in
             ("completed", "failed", "cancelled")),
            None,
        )
        if terminal is None:
            results.append((name, False, "timeout after %ds" % args.timeout))
            print("      FAIL: timed out\n")
            continue
        if terminal.get("kind") == "completed":
            ok, detail = check_artifact(out_dir, events, task_id)
            results.append((name, ok, detail))
            print("      %s: %s\n" % ("PASS" if ok else "FAIL", detail))
        else:
            message = terminal.get("message") or "download %s" % terminal.get("kind")
            results.append((name, False, message))
            print("      FAIL: %s\n" % message)

    print("=" * 60)
    all_ok = True
    for name, ok, detail in results:
        all_ok = all_ok and ok
        print("  %-18s %s  %s" % (name, "PASS" if ok else "FAIL", detail))
    print("=" * 60)
    print("RESULT: %s" % ("ALL PASS" if all_ok else "FAILURES PRESENT"))

    if not args.keep:
        try:
            shutil.rmtree(tmp_root)
        except OSError:
            pass

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
