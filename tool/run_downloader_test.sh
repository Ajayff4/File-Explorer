#!/usr/bin/env bash
# Run the downloader integration test with the pinned venv.
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -x .venv/bin/python ]; then
    echo "No venv found. Setting up tool/.venv (first run)..."
    python3 -m venv .venv
    .venv/bin/pip install yt-dlp==2026.07.04
    # Threads has no upstream extractor; test harness uses the community plugin.
    .venv/bin/pip install git+https://github.com/tribixbite/yt-dlp-threads
    # Bundled ffmpeg (via imageio) enables merged 720p/1080p format tests.
    .venv/bin/pip install imageio-ffmpeg
fi

exec .venv/bin/python downloader_integration_test.py "$@"