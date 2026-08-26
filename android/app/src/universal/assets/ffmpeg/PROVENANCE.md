# Bundled ffmpeg provenance & license

The `ffmpeg` binary in this directory (`android/app/src/main/assets/ffmpeg/ffmpeg`)
is bundled so the Universal Downloader can merge/remux separate video+audio
streams downloaded by yt-dlp.

## License

**LGPL version 2.1** (full text in `LGPL-2.1.txt` alongside this file).

This is a **pure-LGPL build** — it contains no GPL-licensed component
(`--disable-gpl --disable-nonfree`). It does not link x264, x265, xvid,
vid.stab, frei0r, or any other GPL library. It is used only as a subprocess for
`-c copy` stream merging (no re-encoding), which requires only the codecs listed
in the build configuration below.

## Source

- FFmpeg 7.1 official release: https://ffmpeg.org/releases/ffmpeg-7.1.tar.xz
- Cross-compiled with Zig 0.13.0 (bundles a musl libc target):
  https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz

## Build configuration

```bash
CC="zig cc -target aarch64-linux-musl" \
AR="zig ar" RANLIB="zig ranlib" \
./configure \
  --prefix=/tmp/opencode/ffmpeg-lgpl-out \
  --cc="$CC" --ar="$AR" --ranlib="$RANLIB" \
  --arch=aarch64 --target-os=linux --enable-cross-compile \
  --disable-gpl --disable-nonfree --enable-static --disable-shared \
  --enable-small --disable-debug --disable-doc --disable-ffplay --disable-ffprobe \
  --enable-pthreads --disable-network \
  --enable-protocol=file --enable-protocol=pipe \
  --disable-hwaccels \
  --enable-decoder=h264,hevc,vp8,vp9,av1,mpeg4,aac,mp3,ac3,eac3,opus,vorbis,flac,pcm_s16le \
  --enable-parser=h264,hevc,vp8,vp9,av1,aac,mp3 \
  --enable-demuxer=mov,matroska,webm_dash_manifest,mp3,aac,ogg,flac,wav \
  --enable-muxer=mp4,matroska,webm,ogg,ipod,flac,wav
make -j$(nproc) STRIP=true
# copy fftools/ffmpeg_g (unstripped output) to bin, then:
zig objcopy --strip-all ffmpeg bin/ffmpeg
```

The `make STRIP=true` workaround is needed because the host `strip` cannot
process aarch64 binaries; `ffmpeg_g` (the unstripped build output) is the actual
binary, stripped afterward with `zig objcopy`.

## Verification

- `ffmpeg -version` runs on-device (Android, statically linked).
- `ffmpeg -i video.mp4 -i audio.m4a -c copy merged.mp4` produces a valid merged
  file on-device (verified 2026-08-19).
- License strings in the binary report `LGPL version 2.1 or later` for all
  libraries.