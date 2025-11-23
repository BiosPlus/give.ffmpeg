#!/bin/bash
# Test container format functionality - demuxers and muxers

set -e

FFMPEG="${FFMPEG_BIN:-./ffmpeg-build/bin/ffmpeg}"
FFPROBE="${FFPROBE_BIN:-./ffmpeg-build/bin/ffprobe}"
SAMPLES_DIR="${SAMPLES_DIR:-./test-samples}"
TEMP_DIR="${TEMP_DIR:-./test-output}"

PASSED=0
FAILED=0
TESTS=()

echo "=== Format Tests ==="
echo "FFmpeg: $FFMPEG"
echo ""

# Create temp directory
mkdir -p "$TEMP_DIR"

# Test function
run_test() {
    local name="$1"
    local cmd="$2"

    if eval "$cmd" > /dev/null 2>&1; then
        echo "PASS: $name"
        ((PASSED++))
    else
        echo "FAIL: $name"
        ((FAILED++))
        TESTS+=("$name")
    fi
}

# Test demuxer availability
test_demuxer_available() {
    local demuxer="$1"
    run_test "Demuxer available: $demuxer" \
        "$FFMPEG -hide_banner -demuxers 2>/dev/null | grep -q ' $demuxer '"
}

# Test muxer availability
test_muxer_available() {
    local muxer="$1"
    run_test "Muxer available: $muxer" \
        "$FFMPEG -hide_banner -muxers 2>/dev/null | grep -q ' $muxer '"
}

echo "--- Testing Demuxer Availability ---"
# Enabled demuxers per CLAUDE.md
test_demuxer_available "mov"
test_demuxer_available "matroska"
test_demuxer_available "avi"
test_demuxer_available "mp3"
test_demuxer_available "flac"
test_demuxer_available "ogg"
test_demuxer_available "wav"
test_demuxer_available "image2"
test_demuxer_available "concat"

echo ""
echo "--- Testing Muxer Availability ---"
# Enabled muxers per CLAUDE.md
test_muxer_available "mp4"
test_muxer_available "matroska"
test_muxer_available "webm"
test_muxer_available "mov"
test_muxer_available "mp3"
test_muxer_available "flac"
test_muxer_available "ogg"
test_muxer_available "wav"
test_muxer_available "image2"
test_muxer_available "null"

echo ""
echo "--- Testing Muxer Functionality ---"

# Test MP4 muxer
run_test "Mux: MP4" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 \
     -f lavfi -i sine=frequency=440:duration=0.5 \
     -c:v mjpeg -q:v 5 -c:a pcm_s16le \
     '$TEMP_DIR/mux_test.mp4'"

# Test Matroska muxer
run_test "Mux: Matroska (MKV)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 \
     -f lavfi -i sine=frequency=440:duration=0.5 \
     -c:v mjpeg -q:v 5 -c:a pcm_s16le \
     '$TEMP_DIR/mux_test.mkv'"

# Test MOV muxer
run_test "Mux: MOV" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 \
     -f lavfi -i sine=frequency=440:duration=0.5 \
     -c:v mjpeg -q:v 5 -c:a pcm_s16le \
     '$TEMP_DIR/mux_test.mov'"

# Test AVI muxer (via format)
run_test "Mux: AVI" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 \
     -f lavfi -i sine=frequency=440:duration=0.5 \
     -c:v mjpeg -q:v 5 -c:a pcm_s16le \
     '$TEMP_DIR/mux_test.avi'"

# Test WAV muxer
run_test "Mux: WAV" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -c:a pcm_s16le \
     '$TEMP_DIR/mux_test.wav'"

# Test FLAC muxer
run_test "Mux: FLAC" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -c:a flac \
     '$TEMP_DIR/mux_test.flac'"

# Test Ogg muxer
run_test "Mux: Ogg" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -c:a flac \
     '$TEMP_DIR/mux_test.ogg'"

# Test image2 muxer (image sequence)
run_test "Mux: Image sequence" \
    "mkdir -p '$TEMP_DIR/img_seq' && \
     $FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=10 \
     -c:v png \
     '$TEMP_DIR/img_seq/frame_%03d.png'"

# Test null muxer
run_test "Mux: Null (discard)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 \
     -f null -"

echo ""
echo "--- Testing Demuxer Functionality ---"

# Test demuxing generated files
if [ -f "$TEMP_DIR/mux_test.mp4" ]; then
    run_test "Demux: MP4" \
        "$FFPROBE -v error -show_format '$TEMP_DIR/mux_test.mp4'"
fi

if [ -f "$TEMP_DIR/mux_test.mkv" ]; then
    run_test "Demux: Matroska (MKV)" \
        "$FFPROBE -v error -show_format '$TEMP_DIR/mux_test.mkv'"
fi

if [ -f "$TEMP_DIR/mux_test.mov" ]; then
    run_test "Demux: MOV" \
        "$FFPROBE -v error -show_format '$TEMP_DIR/mux_test.mov'"
fi

if [ -f "$TEMP_DIR/mux_test.avi" ]; then
    run_test "Demux: AVI" \
        "$FFPROBE -v error -show_format '$TEMP_DIR/mux_test.avi'"
fi

if [ -f "$TEMP_DIR/mux_test.wav" ]; then
    run_test "Demux: WAV" \
        "$FFPROBE -v error -show_format '$TEMP_DIR/mux_test.wav'"
fi

if [ -f "$TEMP_DIR/mux_test.flac" ]; then
    run_test "Demux: FLAC" \
        "$FFPROBE -v error -show_format '$TEMP_DIR/mux_test.flac'"
fi

if [ -f "$TEMP_DIR/mux_test.ogg" ]; then
    run_test "Demux: Ogg" \
        "$FFPROBE -v error -show_format '$TEMP_DIR/mux_test.ogg'"
fi

# Test image sequence demuxing
if [ -f "$TEMP_DIR/img_seq/frame_001.png" ]; then
    run_test "Demux: Image sequence" \
        "$FFMPEG -y -framerate 10 -i '$TEMP_DIR/img_seq/frame_%03d.png' -f null -"
fi

echo ""
echo "--- Testing Container Remuxing ---"

# Test MKV to MP4 remux
if [ -f "$TEMP_DIR/mux_test.mkv" ]; then
    run_test "Remux: MKV to MP4" \
        "$FFMPEG -y -i '$TEMP_DIR/mux_test.mkv' -c copy '$TEMP_DIR/remux_test.mp4'"
fi

# Test MP4 to MOV remux
if [ -f "$TEMP_DIR/mux_test.mp4" ]; then
    run_test "Remux: MP4 to MOV" \
        "$FFMPEG -y -i '$TEMP_DIR/mux_test.mp4' -c copy '$TEMP_DIR/remux_test.mov'"
fi

# Test WAV to FLAC remux (audio only)
if [ -f "$TEMP_DIR/mux_test.wav" ]; then
    run_test "Transcode: WAV to FLAC" \
        "$FFMPEG -y -i '$TEMP_DIR/mux_test.wav' -c:a flac '$TEMP_DIR/remux_test.flac'"
fi

echo ""
echo "=== Format Test Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "Failed tests:"
    for test in "${TESTS[@]}"; do
        echo "  - $test"
    done
    exit 1
fi

echo ""
echo "All format tests passed!"
