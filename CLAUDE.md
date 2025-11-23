# give.ffmpeg

## Project Overview

Build bleeding-edge FFmpeg binaries using GitHub Actions public runners for multiple platforms with maximum performance optimization.

## Target Platforms

- **Linux** (ubuntu-latest): x86_64
- **macOS** (macos-latest): ARM64 (Apple Silicon)
- **Windows** (windows-latest): x86_64

## Build Philosophy

1. **Bleeding Edge**: Build from FFmpeg master branch
2. **Performance First**: Enable all CPU-specific optimizations at compile time
3. **Minimal Build**: Start with essential codecs only, expand as needed
4. **Static Linking**: Produce self-contained binaries where possible

## Current Configuration (Minimal)

### Enabled Components
- Core FFmpeg tools (ffmpeg, ffprobe)
- Essential demuxers/muxers (mp4, mkv, webm, mov)
- Common video codecs (h264, hevc, vp8, vp9, av1 - decode only)
- Common audio codecs (aac, mp3, opus, flac, vorbis)
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
│       └── build.yml          # Main CI workflow
├── scripts/
│   ├── build-linux.sh         # Linux build script
│   ├── build-macos.sh         # macOS build script
│   └── build-windows.sh       # Windows build script
├── CLAUDE.md                  # This file
└── README.md                  # User-facing documentation
```

## Development Commands

```bash
# Test Linux build locally (requires Docker)
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash scripts/build-linux.sh

# Trigger CI build
git push origin <branch>
```

## Next Steps

1. Create GitHub Actions workflow
2. Implement platform-specific build scripts
3. Add artifact upload for built binaries
4. Verify builds complete successfully on all platforms

## Future Enhancements

- Hardware acceleration (NVENC, QSV, VideoToolbox, AMF)
- Additional codecs (x264, x265, svt-av1 encoding)
- Cross-compilation support
- Release automation
- Binary size optimization
