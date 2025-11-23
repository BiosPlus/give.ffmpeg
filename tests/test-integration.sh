#!/bin/bash
# Integration tests - end-to-end transcoding workflows

set -e

FFMPEG="${FFMPEG_BIN:-./ffmpeg-build/bin/ffmpeg}"
FFPROBE="${FFPROBE_BIN:-./ffmpeg-build/bin/ffprobe}"
TEMP_DIR="${TEMP_DIR:-./test-output}"

PASSED=0
FAILED=0
TESTS=()

echo "=== Integration Tests ==="
echo "FFmpeg: $FFMPEG"
echo ""

# Create temp directory
mkdir -p "$TEMP_DIR/integration"

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

# Verify output file with ffprobe
verify_output() {
    local file="$1"
    local expected_streams="$2"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Check file is valid
    $FFPROBE -v error -show_format "$file" > /dev/null 2>&1
}

echo "--- End-to-End Transcoding Workflows ---"

# Workflow 1: Video processing pipeline
echo ""
echo "Workflow 1: Video processing pipeline"
run_test "E2E: Generate → Scale → Crop → Encode → Mux (MKV)" \
    "$FFMPEG -y \
     -f lavfi -i testsrc=duration=1:size=1920x1080:rate=30 \
     -vf 'scale=1280:720,crop=1200:600:40:60' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/integration/workflow1.mkv' && \
     verify_output '$TEMP_DIR/integration/workflow1.mkv'"

# Workflow 2: Audio processing pipeline
echo ""
echo "Workflow 2: Audio processing pipeline"
run_test "E2E: Generate → Volume → Resample → Encode → Mux (FLAC)" \
    "$FFMPEG -y \
     -f lavfi -i sine=frequency=440:duration=2 \
     -af 'volume=0.8,aformat=sample_rates=48000:channel_layouts=stereo' \
     -c:a flac \
     '$TEMP_DIR/integration/workflow2.flac' && \
     verify_output '$TEMP_DIR/integration/workflow2.flac'"

# Workflow 3: Combined A/V processing
echo ""
echo "Workflow 3: Combined audio/video processing"
run_test "E2E: A/V → Filters → Encode → Mux (MP4)" \
    "$FFMPEG -y \
     -f lavfi -i testsrc=duration=1:size=640x480:rate=30 \
     -f lavfi -i sine=frequency=440:duration=1 \
     -vf 'scale=320:240,fps=24' \
     -af 'volume=0.5' \
     -c:v mjpeg -q:v 5 -c:a pcm_s16le \
     '$TEMP_DIR/integration/workflow3.mp4' && \
     verify_output '$TEMP_DIR/integration/workflow3.mp4'"

# Workflow 4: Multiple input overlay
echo ""
echo "Workflow 4: Multiple input overlay"
run_test "E2E: Multi-input → Overlay → Encode (PiP effect)" \
    "$FFMPEG -y \
     -f lavfi -i testsrc=duration=1:size=640x480:rate=30 \
     -f lavfi -i testsrc2=duration=1:size=160x120:rate=30 \
     -filter_complex '[0:v][1:v]overlay=W-w-10:H-h-10' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/integration/workflow4.avi' && \
     verify_output '$TEMP_DIR/integration/workflow4.avi'"

# Workflow 5: Audio concatenation
echo ""
echo "Workflow 5: Audio concatenation"
run_test "E2E: Concatenate multiple audio streams" \
    "$FFMPEG -y \
     -f lavfi -i sine=frequency=440:duration=0.5 \
     -f lavfi -i sine=frequency=660:duration=0.5 \
     -f lavfi -i sine=frequency=880:duration=0.5 \
     -filter_complex '[0:a][1:a][2:a]concat=n=3:v=0:a=1' \
     -c:a pcm_s16le \
     '$TEMP_DIR/integration/workflow5.wav' && \
     verify_output '$TEMP_DIR/integration/workflow5.wav'"

# Workflow 6: Container remuxing
echo ""
echo "Workflow 6: Container remuxing chain"
run_test "E2E: Create MKV → Remux to MOV → Remux to MP4" \
    "$FFMPEG -y \
     -f lavfi -i testsrc=duration=1:size=320x240:rate=30 \
     -f lavfi -i sine=frequency=440:duration=1 \
     -c:v mjpeg -q:v 5 -c:a pcm_s16le \
     '$TEMP_DIR/integration/remux_source.mkv' && \
     $FFMPEG -y -i '$TEMP_DIR/integration/remux_source.mkv' -c copy '$TEMP_DIR/integration/remux_step1.mov' && \
     $FFMPEG -y -i '$TEMP_DIR/integration/remux_step1.mov' -c copy '$TEMP_DIR/integration/remux_final.mp4' && \
     verify_output '$TEMP_DIR/integration/remux_final.mp4'"

# Workflow 7: Image sequence workflow
echo ""
echo "Workflow 7: Image sequence workflow"
run_test "E2E: Video → PNG sequence → Video reconstruction" \
    "mkdir -p '$TEMP_DIR/integration/frames' && \
     $FFMPEG -y \
     -f lavfi -i testsrc=duration=0.5:size=320x240:rate=10 \
     -c:v png \
     '$TEMP_DIR/integration/frames/frame_%03d.png' && \
     $FFMPEG -y \
     -framerate 10 -i '$TEMP_DIR/integration/frames/frame_%03d.png' \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/integration/reconstructed.avi' && \
     verify_output '$TEMP_DIR/integration/reconstructed.avi'"

# Workflow 8: Speed manipulation
echo ""
echo "Workflow 8: Speed manipulation"
run_test "E2E: Speed up video 2x with audio" \
    "$FFMPEG -y \
     -f lavfi -i testsrc=duration=2:size=320x240:rate=30 \
     -f lavfi -i sine=frequency=440:duration=2 \
     -vf 'setpts=0.5*PTS' \
     -af 'atempo=2.0' \
     -c:v mjpeg -q:v 5 -c:a pcm_s16le \
     '$TEMP_DIR/integration/workflow8.avi' && \
     verify_output '$TEMP_DIR/integration/workflow8.avi'"

# Workflow 9: Extract and re-encode
echo ""
echo "Workflow 9: Extract segment and re-encode"
run_test "E2E: Create source → Extract segment → Re-encode" \
    "$FFMPEG -y \
     -f lavfi -i testsrc=duration=3:size=320x240:rate=30 \
     -c:v mjpeg -q:v 5 \
     '$TEMP_DIR/integration/source_long.avi' && \
     $FFMPEG -y \
     -ss 1 -t 1 -i '$TEMP_DIR/integration/source_long.avi' \
     -c:v mjpeg -q:v 3 \
     '$TEMP_DIR/integration/extracted.avi' && \
     verify_output '$TEMP_DIR/integration/extracted.avi'"

# Workflow 10: Format conversion chain
echo ""
echo "Workflow 10: Multi-format conversion"
run_test "E2E: WAV → FLAC → Ogg conversion chain" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=1 \
     -c:a pcm_s16le '$TEMP_DIR/integration/convert_source.wav' && \
     $FFMPEG -y -i '$TEMP_DIR/integration/convert_source.wav' \
     -c:a flac '$TEMP_DIR/integration/convert_mid.flac' && \
     $FFMPEG -y -i '$TEMP_DIR/integration/convert_mid.flac' \
     -c:a flac '$TEMP_DIR/integration/convert_final.ogg' && \
     verify_output '$TEMP_DIR/integration/convert_final.ogg'"

echo ""
echo "--- Output Verification ---"

# Verify output files have expected properties
if [ -f "$TEMP_DIR/integration/workflow3.mp4" ]; then
    echo ""
    echo "Checking workflow3.mp4 properties..."

    # Check video stream exists
    run_test "Output has video stream" \
        "$FFPROBE -v error -select_streams v -show_entries stream=codec_type '$TEMP_DIR/integration/workflow3.mp4' | grep -q video"

    # Check audio stream exists
    run_test "Output has audio stream" \
        "$FFPROBE -v error -select_streams a -show_entries stream=codec_type '$TEMP_DIR/integration/workflow3.mp4' | grep -q audio"

    # Check resolution
    run_test "Output resolution is 320x240" \
        "$FFPROBE -v error -select_streams v -show_entries stream=width,height '$TEMP_DIR/integration/workflow3.mp4' | grep -q 'width=320' && \
         $FFPROBE -v error -select_streams v -show_entries stream=width,height '$TEMP_DIR/integration/workflow3.mp4' | grep -q 'height=240'"
fi

echo ""
echo "=== Integration Test Summary ==="
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
echo "All integration tests passed!"
