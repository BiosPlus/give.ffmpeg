#!/bin/bash
# Generate minimal test samples using FFmpeg's built-in sources
# This script creates small test files for codec/format/filter testing

set -e

FFMPEG="${FFMPEG_BIN:-./ffmpeg-build/bin/ffmpeg}"
SAMPLES_DIR="${SAMPLES_DIR:-./test-samples}"

echo "=== Generating Test Samples ==="
echo "Using FFmpeg: $FFMPEG"
echo "Output directory: $SAMPLES_DIR"

# Check FFmpeg exists
if [ ! -x "$FFMPEG" ]; then
    echo "ERROR: FFmpeg not found at $FFMPEG"
    exit 1
fi

# Create samples directory
mkdir -p "$SAMPLES_DIR"

# Generate video samples (1 second, small resolution for speed)
echo ""
echo "--- Generating video samples ---"

# Raw video for testing encoders
$FFMPEG -y -f lavfi -i "testsrc=duration=1:size=320x240:rate=30" \
    -c:v rawvideo -pix_fmt yuv420p \
    "$SAMPLES_DIR/test_raw.yuv"
echo "Created: test_raw.yuv"

# PNG image
$FFMPEG -y -f lavfi -i "testsrc=duration=0.1:size=320x240:rate=1" \
    -frames:v 1 -c:v png \
    "$SAMPLES_DIR/test.png"echo "Created: test.png"

# MJPEG
$FFMPEG -y -f lavfi -i "testsrc=duration=1:size=320x240:rate=30" \
    -c:v mjpeg -q:v 5 \
    "$SAMPLES_DIR/test_mjpeg.avi"echo "Created: test_mjpeg.avi"

# Generate audio samples
echo ""
echo "--- Generating audio samples ---"

# Raw PCM (s16le)
$FFMPEG -y -f lavfi -i "sine=frequency=440:duration=1" \
    -c:a pcm_s16le -ar 44100 \
    "$SAMPLES_DIR/test_pcm_s16le.wav"echo "Created: test_pcm_s16le.wav"

# Raw PCM (s24le)
$FFMPEG -y -f lavfi -i "sine=frequency=440:duration=1" \
    -c:a pcm_s24le -ar 44100 \
    "$SAMPLES_DIR/test_pcm_s24le.wav"echo "Created: test_pcm_s24le.wav"

# Generate container format samples with compatible codecs
echo ""
echo "--- Generating container samples ---"

# MP4 with MJPEG video and PCM audio (since we don't have h264 encoder)
$FFMPEG -y -f lavfi -i "testsrc=duration=1:size=320x240:rate=30" \
    -f lavfi -i "sine=frequency=440:duration=1" \
    -c:v mjpeg -q:v 5 -c:a pcm_s16le \
    "$SAMPLES_DIR/test.mov"echo "Created: test.mov"

# Matroska/MKV
$FFMPEG -y -f lavfi -i "testsrc=duration=1:size=320x240:rate=30" \
    -f lavfi -i "sine=frequency=440:duration=1" \
    -c:v mjpeg -q:v 5 -c:a pcm_s16le \
    "$SAMPLES_DIR/test.mkv"echo "Created: test.mkv"

# WebM (using MJPEG since we don't have VP8/VP9 encoder)
# Note: WebM typically requires VP8/VP9/AV1, but for testing demuxer we can use what we have
$FFMPEG -y -f lavfi -i "testsrc=duration=1:size=320x240:rate=30" \
    -f lavfi -i "sine=frequency=440:duration=1" \
    -c:v mjpeg -q:v 5 -c:a pcm_s16le \
    "$SAMPLES_DIR/test_mux.mkv"echo "Created: test_mux.mkv (for muxer testing)"

# AVI
$FFMPEG -y -f lavfi -i "testsrc=duration=1:size=320x240:rate=30" \
    -f lavfi -i "sine=frequency=440:duration=1" \
    -c:v mjpeg -q:v 5 -c:a pcm_s16le \
    "$SAMPLES_DIR/test.avi"echo "Created: test.avi"

# Ogg with PCM (will use FLAC since Ogg supports it)
$FFMPEG -y -f lavfi -i "sine=frequency=440:duration=1" \
    -c:a flac \
    "$SAMPLES_DIR/test.ogg"echo "Created: test.ogg"

# FLAC
$FFMPEG -y -f lavfi -i "sine=frequency=440:duration=1" \
    -c:a flac \
    "$SAMPLES_DIR/test.flac"echo "Created: test.flac"

# WAV
$FFMPEG -y -f lavfi -i "sine=frequency=440:duration=1" \
    -c:a pcm_s16le \
    "$SAMPLES_DIR/test.wav"echo "Created: test.wav"

# Image sequence
mkdir -p "$SAMPLES_DIR/image_seq"
$FFMPEG -y -f lavfi -i "testsrc=duration=0.5:size=320x240:rate=10" \
    -c:v png \
    "$SAMPLES_DIR/image_seq/frame_%03d.png"echo "Created: image_seq/frame_*.png"

echo ""
echo "=== Sample generation complete ==="
echo "Total samples created in: $SAMPLES_DIR"
ls -la "$SAMPLES_DIR"
