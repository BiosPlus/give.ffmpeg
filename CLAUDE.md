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
  - Encoding: libx264 (H.264), libaom (AV1)
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
│   └── build-aom-linux.sh          # AOM AV1 codec build script
├── CLAUDE.md                       # This file
└── README.md                       # User-facing documentation
```

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

## Future Enhancements

- Hardware acceleration (VAAPI, NVENC, QSV)
- Additional codecs (x265, svt-av1)
- Release automation
- Binary size optimization
- AppImage or container distribution
