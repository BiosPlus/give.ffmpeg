# give.ffmpeg

## Project Overview

Build bleeding-edge FFmpeg binaries using GitHub Actions public runners for Linux with maximum performance optimization.

## Target Platforms

- **Linux x86_64** (ubuntu-latest): Intel/AMD 64-bit processors
- **Linux ARM64** (ubuntu-24.04-arm): ARM 64-bit processors (aarch64)

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
- Architecture-specific optimizations:
  - x86_64: `-march=x86-64-v3` (SSE4.2, AVX2)
  - ARM64: `-march=armv8-a` (NEON, CRC)
- Link-time optimization (LTO) where supported
- Platform-specific SIMD automatically detected and enabled

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
│   ├── build-svtav1-linux.sh       # SVT-AV1 fast AV1 encoder build script
│   └── build-fdk-aac-linux.sh      # libfdk-aac AAC audio encoder build script
├── CLAUDE.md                       # This file
└── README.md                       # User-facing documentation
```

## Build Architecture

The build process uses **parallel GitHub Actions jobs** with **multi-architecture matrix builds** and **intelligent artifact caching** to minimize build time and resource usage:

### Parallel Library Builds (6 jobs × 2 architectures = 12 parallel builds)
Each codec library builds independently for both x86_64 and ARM64 on their respective runners:
- `build-x264`: H.264 encoder
- `build-opus`: Opus audio codec
- `build-aom`: AOM AV1 codec
- `build-vpx`: libvpx VP8/VP9 codec
- `build-svtav1`: SVT-AV1 fast AV1 encoder
- `build-fdk-aac`: libfdk-aac AAC audio encoder

Each job:
1. Installs only required dependencies
2. **Detects upstream commit hash** from the library's git repository
3. **Attempts to download cached artifact** from previous runs using checksum-based naming
4. **Builds library only if cache miss** (no matching artifact found)
5. **Uploads build artifacts** with checksum-based name (only on successful build)
6. Artifacts retained for 90 days (extended from 1 day due to caching value)

### Artifact Naming Convention
Artifacts use architecture-aware checksum-based naming: `{library}-build-{git-commit-hash}-{arch}`

Examples:
- `x264-build-a8b68ebfaa68621b5ac8907610d3335971839d52-x86_64`
- `x264-build-a8b68ebfaa68621b5ac8907610d3335971839d52-arm64`
- `opus-build-9e39d6f1f3ec87e5701f04ae9d8c58cec4a4f9d9-x86_64`
- `aom-build-3c6713d9e08c5f0e0b3d9c4e42d6e4c4e6f2a9b1-arm64`

This ensures that:
- **Builds are only triggered when upstream changes** (cache hit rate of ~95%+)
- **Multiple workflow runs can share artifacts** across branches, architectures, and time
- **Artifact names are deterministic** and traceable to upstream commits and target architecture
- **Each architecture maintains separate cache** preventing cross-contamination

### Final FFmpeg Build (2 jobs - one per architecture)
The `build-ffmpeg` job matrix:
1. Depends on all 6 library jobs (waits for completion of matching architecture)
2. Determines commit hashes for all upstream libraries
3. Downloads architecture-specific library artifacts
4. Merges artifacts into single `ffmpeg-build/` directory
5. Configures FFmpeg to use pre-built libraries via PKG_CONFIG_PATH
6. Builds and uploads final FFmpeg binaries as `ffmpeg-linux-{arch}`
7. **On failure**: Deletes architecture-specific library artifacts to force complete rebuild on next run

### Artifact Cleanup Strategy
- **Successful library build**: Artifact uploaded with 90-day retention
- **Failed library build**: No artifact uploaded (build stops with error)
- **Failed FFmpeg build**: All library artifacts are deleted (both cached and newly-built)

**Benefits:**
- Libraries build concurrently for both architectures instead of sequentially
- **~10x faster on cache hits** (30 seconds vs 5-7 mins) when upstream hasn't changed
- **~3x faster on cache misses** (5-7 mins vs 15-20 mins) due to parallel builds
- **Dual-architecture support** with no additional complexity
- **Significantly reduced runner minutes** and carbon footprint
- Each job has minimal dependencies
- Easy to add new codecs or architectures as additional parallel jobs
- Broken builds don't pollute artifact storage

## Development Commands

```bash
# Test x86_64 build locally (requires Docker)
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash scripts/build-linux.sh

# Test ARM64 build locally (requires Docker with ARM support or ARM host)
docker run --rm --platform linux/arm64 -v $(pwd):/work -w /work ubuntu:22.04 bash scripts/build-linux.sh

# Trigger CI build (builds both architectures)
git push origin <branch>
```

## Built-from-Source Libraries

1. **libx264**: H.264 encoder (GPL)
2. **libopus**: Opus audio codec
3. **libaom**: AV1 video codec for encoding and decoding
4. **libvpx**: VP8/VP9 video codec with high bitdepth support
5. **SVT-AV1**: High-performance AV1 encoder optimized for speed
6. **libfdk-aac**: High-quality AAC audio encoder (requires --enable-nonfree)

## Future Enhancements

- Hardware acceleration (VAAPI, NVENC, QSV)
- Additional codecs (x265, libwebp)
- Release automation
- Binary size optimization
- AppImage or container distribution
