# give.ffmpeg

## Project Overview

Build bleeding-edge FFmpeg binaries using GitHub Actions public runners for Linux with maximum performance optimization.

## Target Platform

- **Linux** (ubuntu-latest): x86_64

## Build Philosophy

1. **Bleeding Edge**: Build from FFmpeg master branch
2. **Performance First**: Enable all CPU-specific optimizations at compile time
3. **Minimal Build**: Start with essential codecs only, expand as needed
4. **Static Linking**: Produce self-contained binaries where possible

## Current Configuration (Minimal)

### Enabled Components
- Core FFmpeg tools (ffmpeg, ffprobe)
- Essential demuxers/muxers (mp4, mkv, webm, mov)
- Common video codecs:
  - Decoding: h264, hevc, vp8, vp9, av1
  - Encoding: libx264 (H.264), libvpx (VP8/VP9), libaom (AV1), SVT-AV1 (fast AV1)
- Common audio codecs:
  - Decoding: aac, mp3, opus, flac, vorbis
  - Encoding: libopus
- Essential filters (scale, crop, overlay)

### Disabled Components
- Hardware acceleration (future addition)
- Network protocols beyond file/pipe
- Uncommon formats
- Debug symbols in release

## Performance Optimizations

### Compiler Flags
- `-O3` optimization level
- `-march=native` equivalent per platform
- Link-time optimization (LTO) where supported
- Platform-specific SIMD: SSE4.2, AVX2 (x86), NEON (ARM)

### FFmpeg Configure Options
- `--enable-gpl` (for x264/x265)
- `--enable-nonfree` (for better codec support)
- `--disable-debug`
- `--disable-doc`
- `--enable-lto`

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── build.yml               # Main CI workflow
├── scripts/
│   ├── build-linux.sh              # FFmpeg build script
│   ├── build-x264-linux.sh         # x264 encoder build script
│   ├── build-opus-linux.sh         # Opus audio codec build script
│   ├── build-aom-linux.sh          # AOM AV1 codec build script
│   ├── build-vpx-linux.sh          # libvpx VP8/VP9 codec build script
│   └── build-svtav1-linux.sh       # SVT-AV1 fast AV1 encoder build script
├── CLAUDE.md                       # This file
└── README.md                       # User-facing documentation
```

## Build Architecture

The build process uses **parallel GitHub Actions jobs** to minimize total build time:

### Parallel Library Builds (5 jobs)
Each codec library builds independently on its own runner:
- `build-x264`: H.264 encoder
- `build-opus`: Opus audio codec
- `build-aom`: AOM AV1 codec
- `build-vpx`: libvpx VP8/VP9 codec
- `build-svtav1`: SVT-AV1 fast AV1 encoder

Each job:
1. Installs only required dependencies
2. Builds the library from source
3. Uploads the build artifacts (includes, libs, pkg-config)
4. Artifacts retained for 1 day

### Final FFmpeg Build (1 job)
The `build-ffmpeg` job:
1. Depends on all 5 library jobs (waits for completion)
2. Downloads all library artifacts
3. Merges artifacts into single `ffmpeg-build/` directory
4. Configures FFmpeg to use pre-built libraries via PKG_CONFIG_PATH
5. Builds and uploads final FFmpeg binaries

**Benefits:**
- Libraries build concurrently instead of sequentially
- ~3x faster total build time (5-7 mins vs 15-20 mins)
- Each job has minimal dependencies
- Easy to add new codecs as additional parallel jobs

## Development Commands

```bash
# Test Linux build locally (requires Docker)
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash scripts/build-linux.sh

# Trigger CI build
git push origin <branch>
```

## Built-from-Source Libraries

1. **libx264**: H.264 encoder (GPL)
2. **libopus**: Opus audio codec
3. **libaom**: AV1 video codec for encoding and decoding
4. **libvpx**: VP8/VP9 video codec with high bitdepth support
5. **SVT-AV1**: High-performance AV1 encoder optimized for speed

## Future Enhancements

- Hardware acceleration (VAAPI, NVENC, QSV)
- Additional codecs (x265, libwebp)
- Release automation
- Binary size optimization
- AppImage or container distribution
