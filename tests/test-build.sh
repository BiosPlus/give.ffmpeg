#!/bin/bash
# Test build configuration - verify build options and binary properties

set -e

FFMPEG="${FFMPEG_BIN:-./ffmpeg-build/bin/ffmpeg}"
FFPROBE="${FFPROBE_BIN:-./ffmpeg-build/bin/ffprobe}"

PASSED=0
FAILED=0
TESTS=()

echo "=== Build Configuration Tests ==="
echo "FFmpeg: $FFMPEG"
echo ""

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

echo "--- Binary Existence ---"

run_test "ffmpeg binary exists" "[ -x '$FFMPEG' ]"
run_test "ffprobe binary exists" "[ -x '$FFPROBE' ]"

echo ""
echo "--- Version Information ---"

run_test "ffmpeg version available" "$FFMPEG -version"
run_test "ffprobe version available" "$FFPROBE -version"

# Get version info
FFMPEG_VERSION=$($FFMPEG -version 2>&1 | head -n1)
echo "Version: $FFMPEG_VERSION"

echo ""
echo "--- Build Configuration Flags ---"

# Get build configuration
BUILDCONF=$($FFMPEG -buildconf 2>&1)

# Check for expected configuration options
run_test "Config: --enable-gpl" "echo '$BUILDCONF' | grep -q '\-\-enable-gpl'"
run_test "Config: --enable-nonfree" "echo '$BUILDCONF' | grep -q '\-\-enable-nonfree'"
run_test "Config: --enable-static" "echo '$BUILDCONF' | grep -q '\-\-enable-static'"
run_test "Config: --disable-shared" "echo '$BUILDCONF' | grep -q '\-\-disable-shared'"
run_test "Config: --enable-lto" "echo '$BUILDCONF' | grep -q '\-\-enable-lto'"
run_test "Config: --disable-debug" "echo '$BUILDCONF' | grep -q '\-\-disable-debug'"
run_test "Config: --disable-doc" "echo '$BUILDCONF' | grep -q '\-\-disable-doc'"
run_test "Config: --enable-optimizations" "echo '$BUILDCONF' | grep -q '\-\-enable-optimizations'"

echo ""
echo "--- Static Linking Verification ---"

# Platform-specific static linking checks
OS=$(uname -s)
case "$OS" in
    Linux)
        # Check if binary has minimal shared library dependencies
        if command -v ldd &> /dev/null; then
            # Get shared library count (excluding vDSO and ld-linux)
            LIB_COUNT=$(ldd "$FFMPEG" 2>/dev/null | grep -v 'linux-vdso\|ld-linux' | wc -l)
            # Expect minimal dependencies (libc, libm, libpthread, libdl at most)
            run_test "Minimal shared libs (Linux)" "[ $LIB_COUNT -le 6 ]"

            # Verify no libav* dependencies (should be static)
            run_test "No libavcodec.so dependency" "! ldd '$FFMPEG' 2>/dev/null | grep -q 'libavcodec'"
            run_test "No libavformat.so dependency" "! ldd '$FFMPEG' 2>/dev/null | grep -q 'libavformat'"
            run_test "No libavutil.so dependency" "! ldd '$FFMPEG' 2>/dev/null | grep -q 'libavutil'"
        fi
        ;;
    Darwin)
        # Check macOS binary dependencies
        if command -v otool &> /dev/null; then
            # Verify no external FFmpeg dylib dependencies
            run_test "No libavcodec.dylib dependency" "! otool -L '$FFMPEG' 2>/dev/null | grep -q 'libavcodec'"
            run_test "No libavformat.dylib dependency" "! otool -L '$FFMPEG' 2>/dev/null | grep -q 'libavformat'"
            run_test "No libavutil.dylib dependency" "! otool -L '$FFMPEG' 2>/dev/null | grep -q 'libavutil'"
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*)
        # Windows - check for DLL dependencies would require different tools
        echo "Note: Static linking verification limited on Windows"
        ;;
esac

echo ""
echo "--- Binary Size Check ---"

# Get binary size
FFMPEG_SIZE=$(stat -f%z "$FFMPEG" 2>/dev/null || stat -c%s "$FFMPEG" 2>/dev/null)
FFPROBE_SIZE=$(stat -f%z "$FFPROBE" 2>/dev/null || stat -c%s "$FFPROBE" 2>/dev/null)

echo "ffmpeg binary size: $(echo "$FFMPEG_SIZE" | awk '{printf "%.2f MB", $1/1024/1024}')"
echo "ffprobe binary size: $(echo "$FFPROBE_SIZE" | awk '{printf "%.2f MB", $1/1024/1024}')"

# Basic size sanity checks (binaries should be reasonable size)
# Too small might indicate missing components, too large might indicate issues
run_test "ffmpeg size > 1MB" "[ $FFMPEG_SIZE -gt 1000000 ]"
run_test "ffmpeg size < 100MB" "[ $FFMPEG_SIZE -lt 100000000 ]"
run_test "ffprobe size > 500KB" "[ $FFPROBE_SIZE -gt 500000 ]"
run_test "ffprobe size < 50MB" "[ $FFPROBE_SIZE -lt 50000000 ]"

echo ""
echo "--- Hardware/CPU Features ---"

# Get hardware capabilities
HWACCELS=$($FFMPEG -hwaccels 2>&1 | tail -n +2)
echo "Available hardware accelerators:"
echo "$HWACCELS" | sed 's/^/  /'

echo ""
echo "--- Protocol Support ---"

# Check for expected protocols
PROTOCOLS=$($FFMPEG -protocols 2>&1)

run_test "Protocol: file" "echo '$PROTOCOLS' | grep -q 'file'"
run_test "Protocol: pipe" "echo '$PROTOCOLS' | grep -q 'pipe'"

echo ""
echo "--- Parser Availability ---"

# Check for enabled parsers
test_parser_available() {
    local parser="$1"
    run_test "Parser available: $parser" \
        "$FFMPEG -hide_banner -parsers 2>/dev/null | grep -q ' $parser'"
}

test_parser_available "h264"
test_parser_available "hevc"
test_parser_available "vp8"
test_parser_available "vp9"
test_parser_available "av1"
test_parser_available "aac"
test_parser_available "flac"
test_parser_available "opus"
test_parser_available "png"
test_parser_available "mjpeg"

echo ""
echo "--- Bitstream Filter Availability ---"

# Check for enabled bitstream filters
test_bsf_available() {
    local bsf="$1"
    run_test "BSF available: $bsf" \
        "$FFMPEG -hide_banner -bsfs 2>/dev/null | grep -q '$bsf'"
}

test_bsf_available "h264_mp4toannexb"
test_bsf_available "hevc_mp4toannexb"
test_bsf_available "aac_adtstoasc"

echo ""
echo "=== Build Configuration Test Summary ==="
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
echo "All build configuration tests passed!"
