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
  - Encoding: libx264 (H.264), libx265 (H.265/HEVC), libvpx (VP8/VP9), libaom (AV1), SVT-AV1 (fast AV1)
- Common audio codecs:
  - Decoding: aac, mp3, opus, flac, vorbis
  - Encoding: libopus, libfdk-aac (AAC)
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
│   ├── build-x265-linux.sh         # x265 H.265/HEVC encoder build script
│   ├── build-opus-linux.sh         # Opus audio codec build script
│   ├── build-aom-linux.sh          # AOM AV1 codec build script
│   ├── build-vpx-linux.sh          # libvpx VP8/VP9 codec build script
│   ├── build-svtav1-linux.sh       # SVT-AV1 fast AV1 encoder build script
│   └── build-fdk-aac-linux.sh      # libfdk-aac AAC audio encoder build script
├── CLAUDE.md                       # This file
└── README.md                       # User-facing documentation
```

## Build Architecture

The build process uses **parallel GitHub Actions jobs** to maximize build performance:

### Parallel Library Builds (7 jobs)
Each codec library builds independently on its own runner:
- `build-x264`: H.264 encoder
- `build-x265`: H.265/HEVC encoder
- `build-opus`: Opus audio codec
- `build-aom`: AOM AV1 codec
- `build-vpx`: libvpx VP8/VP9 codec
- `build-svtav1`: SVT-AV1 fast AV1 encoder
- `build-fdk-aac`: libfdk-aac AAC audio encoder

Each job:
1. Installs only required dependencies
2. Builds library from latest upstream master/main branch
3. Uploads build artifacts for use by FFmpeg build
4. Artifacts retained for 1 day (only needed for current workflow run)

### Artifact Naming Convention
Artifacts use simple static names: `{library}-build`

Examples:
- `x264-build`
- `x265-build`
- `opus-build`
- `aom-build`

### Final FFmpeg Build (1 job)
The `build-ffmpeg` job:
1. Depends on all 7 library jobs (waits for completion)
2. Downloads all library artifacts
3. Merges artifacts into single `ffmpeg-build/` directory
4. Configures FFmpeg to use pre-built libraries via PKG_CONFIG_PATH
5. Builds and uploads final FFmpeg binaries
6. **On failure**: Deletes all library artifacts from current run

### Artifact Strategy
- **Successful library build**: Artifact uploaded with 1-day retention
- **Failed library build**: No artifact uploaded (build stops with error)
- **Failed FFmpeg build**: All library artifacts from current run are deleted
- **No cross-run caching**: Each workflow run builds fresh from upstream

**Benefits:**
- Libraries build concurrently instead of sequentially
- **~3x faster** (5-7 mins vs 15-20 mins) due to parallel builds
- Always uses latest upstream code (bleeding edge)
- Simple artifact management
- Each job has minimal dependencies
- Easy to add new codecs as additional parallel jobs
- Clean artifact storage (1-day retention)

## Development Commands

```bash
# Test Linux build locally (requires Docker)
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash scripts/build-linux.sh

# Trigger CI build
git push origin <branch>
```

## Built-from-Source Libraries

1. **libx264**: H.264 encoder (GPL)
2. **libx265**: H.265/HEVC encoder (GPL)
3. **libopus**: Opus audio codec
4. **libaom**: AV1 video codec for encoding and decoding
5. **libvpx**: VP8/VP9 video codec with high bitdepth support
6. **SVT-AV1**: High-performance AV1 encoder optimized for speed
7. **libfdk-aac**: High-quality AAC audio encoder (requires --enable-nonfree)

## Future Enhancements

- Hardware acceleration (VAAPI, NVENC, QSV)
- Additional codecs (libwebp)
- Release automation
- Binary size optimization
- AppImage or container distribution
