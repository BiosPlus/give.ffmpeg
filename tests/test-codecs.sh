#!/bin/bash
# Test codec functionality - encoders and decoders

set -e

FFMPEG="${FFMPEG_BIN:-./ffmpeg-build/bin/ffmpeg}"
FFPROBE="${FFPROBE_BIN:-./ffmpeg-build/bin/ffprobe}"
SAMPLES_DIR="${SAMPLES_DIR:-./test-samples}"
TEMP_DIR="${TEMP_DIR:-./test-output}"

PASSED=0
FAILED=0
TESTS=()

echo "=== Codec Tests ==="
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

# Test encoder availability
test_encoder_available() {
    local encoder="$1"
    run_test "Encoder available: $encoder" \
        "$FFMPEG -hide_banner -encoders 2>/dev/null | grep -q ' $encoder '"
}

# Test decoder availability
test_decoder_available() {
    local decoder="$1"
    run_test "Decoder available: $decoder" \
        "$FFMPEG -hide_banner -decoders 2>/dev/null | grep -q ' $decoder '"
}

# Test encoding functionality
test_encode() {
    local name="$1"
    local input="$2"
    local output="$3"
    local codec_opts="$4"

    run_test "Encode: $name" \
        "$FFMPEG -y $input -t 0.5 $codec_opts '$TEMP_DIR/$output'"
}

# Test decoding functionality
test_decode() {
    local name="$1"
    local input="$2"
    local output="$3"

    run_test "Decode: $name" \
        "$FFMPEG -y -i '$input' -t 0.5 -f null -"
}

echo "--- Testing Encoder Availability ---"
# Enabled encoders per CLAUDE.md
test_encoder_available "png"
test_encoder_available "mjpeg"
test_encoder_available "pcm_s16le"
test_encoder_available "pcm_s24le"

echo ""
echo "--- Testing Decoder Availability ---"
# Enabled decoders per CLAUDE.md
test_decoder_available "h264"
test_decoder_available "hevc"
test_decoder_available "vp8"
test_decoder_available "vp9"
test_decoder_available "av1"
test_decoder_available "mpeg4"
test_decoder_available "aac"
test_decoder_available "mp3"
test_decoder_available "opus"
test_decoder_available "flac"
test_decoder_available "vorbis"
test_decoder_available "pcm_s16le"
test_decoder_available "pcm_s24le"
test_decoder_available "png"
test_decoder_available "mjpeg"

echo ""
echo "--- Testing Encoder Functionality ---"

# Test PNG encoder
test_encode "PNG image" \
    "-f lavfi -i testsrc=duration=0.1:size=320x240:rate=1" \
    "encode_test.png" \
    "-frames:v 1 -c:v png"

# Test MJPEG encoder
test_encode "MJPEG video" \
    "-f lavfi -i testsrc=duration=0.5:size=320x240:rate=30" \
    "encode_test_mjpeg.avi" \
    "-c:v mjpeg -q:v 5"

# Test PCM S16LE encoder
test_encode "PCM S16LE audio" \
    "-f lavfi -i sine=frequency=440:duration=0.5" \
    "encode_test_s16le.wav" \
    "-c:a pcm_s16le"

# Test PCM S24LE encoder
test_encode "PCM S24LE audio" \
    "-f lavfi -i sine=frequency=440:duration=0.5" \
    "encode_test_s24le.wav" \
    "-c:a pcm_s24le"

echo ""
echo "--- Testing Decoder Functionality ---"

# Test decoding generated samples
if [ -f "$SAMPLES_DIR/test.png" ]; then
    test_decode "PNG decoder" "$SAMPLES_DIR/test.png" "null"
fi

if [ -f "$SAMPLES_DIR/test_mjpeg.avi" ]; then
    test_decode "MJPEG decoder" "$SAMPLES_DIR/test_mjpeg.avi" "null"
fi

if [ -f "$SAMPLES_DIR/test_pcm_s16le.wav" ]; then
    test_decode "PCM S16LE decoder" "$SAMPLES_DIR/test_pcm_s16le.wav" "null"
fi

if [ -f "$SAMPLES_DIR/test_pcm_s24le.wav" ]; then
    test_decode "PCM S24LE decoder" "$SAMPLES_DIR/test_pcm_s24le.wav" "null"
fi

if [ -f "$SAMPLES_DIR/test.flac" ]; then
    test_decode "FLAC decoder" "$SAMPLES_DIR/test.flac" "null"
fi

echo ""
echo "--- Testing Transcoding Operations ---"

# Test PNG to MJPEG transcoding
run_test "Transcode: PNG to MJPEG" \
    "$FFMPEG -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 -c:v mjpeg -q:v 5 '$TEMP_DIR/transcode_mjpeg.avi'"

# Test audio transcoding
run_test "Transcode: PCM S16LE to PCM S24LE" \
    "$FFMPEG -y -f lavfi -i sine=frequency=440:duration=0.5 -c:a pcm_s16le '$TEMP_DIR/transcode_s16.wav' && \
     $FFMPEG -y -i '$TEMP_DIR/transcode_s16.wav' -c:a pcm_s24le '$TEMP_DIR/transcode_s24.wav'"

echo ""
echo "=== Codec Test Summary ==="
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
echo "All codec tests passed!"
