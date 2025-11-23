#!/bin/bash
# Test filter functionality - video and audio filters

set -e

FFMPEG="${FFMPEG_BIN:-./ffmpeg-build/bin/ffmpeg}"
TEMP_DIR="${TEMP_DIR:-./test-output}"

PASSED=0
FAILED=0
TESTS=()

echo "=== Filter Tests ==="
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

# Test filter availability
test_filter_available() {
    local filter="$1"
    run_test "Filter available: $filter" \
        "$FFMPEG -hide_banner -filters 2>/dev/null | grep -q ' $filter '"
}

echo "--- Testing Video Filter Availability ---"
# Enabled video filters per CLAUDE.md
test_filter_available "scale"
test_filter_available "crop"
test_filter_available "overlay"
test_filter_available "trim"
test_filter_available "setpts"
test_filter_available "fps"
test_filter_available "format"
test_filter_available "null"

echo ""
echo "--- Testing Audio Filter Availability ---"
# Enabled audio filters per CLAUDE.md
test_filter_available "asetpts"
test_filter_available "volume"
test_filter_available "anull"
test_filter_available "aformat"
test_filter_available "concat"

echo ""
echo "--- Testing Video Filter Functionality ---"

# Test scale filter
run_test "Video filter: scale (1080p to 720p)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=1920x1080:rate=30 \
     -vf 'scale=1280:720' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_scale.avi'"

# Test scale with aspect ratio preservation
run_test "Video filter: scale (preserve aspect)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=1920x1080:rate=30 \
     -vf 'scale=640:-1' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_scale_aspect.avi'"

# Test crop filter
run_test "Video filter: crop (center crop)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=640x480:rate=30 \
     -vf 'crop=320:240:160:120' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_crop.avi'"

# Test trim filter
run_test "Video filter: trim" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=2:size=320x240:rate=30 \
     -vf 'trim=start=0.5:end=1.5,setpts=PTS-STARTPTS' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_trim.avi'"

# Test setpts filter (speed change)
run_test "Video filter: setpts (2x speed)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=1:size=320x240:rate=30 \
     -vf 'setpts=0.5*PTS' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_setpts.avi'"

# Test fps filter
run_test "Video filter: fps (30 to 15)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 \
     -vf 'fps=15' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_fps.avi'"

# Test format filter
run_test "Video filter: format (yuv420p)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 \
     -vf 'format=yuv420p' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_format.avi'"

# Test null filter
run_test "Video filter: null (passthrough)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 \
     -vf 'null' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_null.avi'"

# Test overlay filter (picture-in-picture)
run_test "Video filter: overlay (PiP)" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=640x480:rate=30 \
     -f lavfi -i testsrc=duration=0.5:size=160x120:rate=30 \
     -filter_complex '[0:v][1:v]overlay=10:10' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_overlay.avi'"

echo ""
echo "--- Testing Audio Filter Functionality ---"

# Test volume filter
run_test "Audio filter: volume (50%)" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -af 'volume=0.5' \
     -c:a pcm_s16le \
     '$TEMP_DIR/filter_volume.wav'"

# Test volume filter (increase)
run_test "Audio filter: volume (200%)" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -af 'volume=2.0' \
     -c:a pcm_s16le \
     '$TEMP_DIR/filter_volume_up.wav'"

# Test asetpts filter
run_test "Audio filter: asetpts" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -af 'asetpts=PTS-STARTPTS' \
     -c:a pcm_s16le \
     '$TEMP_DIR/filter_asetpts.wav'"

# Test aformat filter
run_test "Audio filter: aformat" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -af 'aformat=sample_rates=48000:channel_layouts=stereo' \
     -c:a pcm_s16le \
     '$TEMP_DIR/filter_aformat.wav'"

# Test anull filter
run_test "Audio filter: anull (passthrough)" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -af 'anull' \
     -c:a pcm_s16le \
     '$TEMP_DIR/filter_anull.wav'"

echo ""
echo "--- Testing Complex Filter Chains ---"

# Test chained video filters
run_test "Filter chain: scale + crop + fps" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=1920x1080:rate=60 \
     -vf 'scale=1280:720,crop=960:540:160:90,fps=30' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/filter_chain_video.avi'"

# Test chained audio filters
run_test "Filter chain: volume + aformat" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 \
     -af 'volume=0.8,aformat=sample_rates=48000' \
     -c:a pcm_s16le \
     '$TEMP_DIR/filter_chain_audio.wav'"

# Test combined video and audio filters
run_test "Filter chain: video + audio combined" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=640x480:rate=30 \
     -f lavfi -i sine=frequency=440:duration=0.5 \
     -vf 'scale=320:240' \
     -af 'volume=0.5' \
     -c:v mjpeg -q:v 5 -c:a pcm_s16le \
     '$TEMP_DIR/filter_combined.avi'"

# Test concat filter (requires pre-created files)
run_test "Filter: concat (2 audio files)" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.25 \
     -f lavfi -i sine=frequency=880:duration=0.25 \
     -filter_complex '[0:a][1:a]concat=n=2:v=0:a=1' \
     -c:a pcm_s16le \
     '$TEMP_DIR/filter_concat.wav'"

echo ""
echo "=== Filter Test Summary ==="
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
echo "All filter tests passed!"
