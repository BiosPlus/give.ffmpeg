#!/bin/bash
# Main test runner - executes all test suites

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
export FFMPEG_BIN="${FFMPEG_BIN:-$PROJECT_ROOT/ffmpeg-build/bin/ffmpeg}"
export FFPROBE_BIN="${FFPROBE_BIN:-$PROJECT_ROOT/ffmpeg-build/bin/ffprobe}"
export SAMPLES_DIR="${SAMPLES_DIR:-$PROJECT_ROOT/test-samples}"
export TEMP_DIR="${TEMP_DIR:-$PROJECT_ROOT/test-output}"

# Colors for output (if terminal supports it)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

echo "=============================================="
echo "       FFmpeg Test Suite Runner"
echo "=============================================="
echo ""
echo "FFmpeg binary: $FFMPEG_BIN"
echo "FFprobe binary: $FFPROBE_BIN"
echo "Samples directory: $SAMPLES_DIR"
echo "Temp directory: $TEMP_DIR"
echo ""

# Check binaries exist
if [ ! -x "$FFMPEG_BIN" ]; then
    echo -e "${RED}ERROR: FFmpeg binary not found at $FFMPEG_BIN${NC}"
    exit 1
fi

if [ ! -x "$FFPROBE_BIN" ]; then
    echo -e "${RED}ERROR: FFprobe binary not found at $FFPROBE_BIN${NC}"
    exit 1
fi

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0
SUITES_RUN=0
FAILED_SUITES=()

# Run a test suite
run_suite() {
    local name="$1"
    local script="$2"

    echo ""
    echo "=============================================="
    echo "  Running: $name"
    echo "=============================================="

    ((SUITES_RUN++))

    if bash "$script"; then
        echo -e "${GREEN}✓ $name completed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ $name failed${NC}"
        FAILED_SUITES+=("$name")
        return 1
    fi
}

# Parse command line arguments
RUN_ALL=true
RUN_BUILD=false
RUN_CODECS=false
RUN_FORMATS=false
RUN_FILTERS=false
RUN_INTEGRATION=false
GENERATE_SAMPLES=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            RUN_ALL=false
            RUN_BUILD=true
            shift
            ;;
        --codecs)
            RUN_ALL=false
            RUN_CODECS=true
            shift
            ;;
        --formats)
            RUN_ALL=false
            RUN_FORMATS=true
            shift
            ;;
        --filters)
            RUN_ALL=false
            RUN_FILTERS=true
            shift
            ;;
        --integration)
            RUN_ALL=false
            RUN_INTEGRATION=true
            shift
            ;;
        --no-samples)
            GENERATE_SAMPLES=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --build        Run build configuration tests only"
            echo "  --codecs       Run codec tests only"
            echo "  --formats      Run format tests only"
            echo "  --filters      Run filter tests only"
            echo "  --integration  Run integration tests only"
            echo "  --no-samples   Skip sample generation"
            echo "  --help         Show this help message"
            echo ""
            echo "If no options specified, all tests are run."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Clean up old test output
if [ -d "$TEMP_DIR" ]; then
    echo "Cleaning up old test output..."
    rm -rf "$TEMP_DIR"
fi
mkdir -p "$TEMP_DIR"

# Generate samples if needed
if [ "$GENERATE_SAMPLES" = true ] && { [ "$RUN_ALL" = true ] || [ "$RUN_CODECS" = true ] || [ "$RUN_FORMATS" = true ]; }; then
    echo ""
    echo "=============================================="
    echo "  Generating Test Samples"
    echo "=============================================="

    if bash "$SCRIPT_DIR/generate-samples.sh"; then
        echo -e "${GREEN}✓ Sample generation completed${NC}"
    else
        echo -e "${RED}✗ Sample generation failed${NC}"
        exit 1
    fi
fi

# Run test suites
if [ "$RUN_ALL" = true ] || [ "$RUN_BUILD" = true ]; then
    run_suite "Build Configuration Tests" "$SCRIPT_DIR/test-build.sh" || true
fi

if [ "$RUN_ALL" = true ] || [ "$RUN_CODECS" = true ]; then
    run_suite "Codec Tests" "$SCRIPT_DIR/test-codecs.sh" || true
fi

if [ "$RUN_ALL" = true ] || [ "$RUN_FORMATS" = true ]; then
    run_suite "Format Tests" "$SCRIPT_DIR/test-formats.sh" || true
fi

if [ "$RUN_ALL" = true ] || [ "$RUN_FILTERS" = true ]; then
    run_suite "Filter Tests" "$SCRIPT_DIR/test-filters.sh" || true
fi

if [ "$RUN_ALL" = true ] || [ "$RUN_INTEGRATION" = true ]; then
    run_suite "Integration Tests" "$SCRIPT_DIR/test-integration.sh" || true
fi

# Print summary
echo ""
echo "=============================================="
echo "           Test Suite Summary"
echo "=============================================="
echo ""
echo "Test suites run: $SUITES_RUN"
echo "Test suites passed: $((SUITES_RUN - ${#FAILED_SUITES[@]}))"
echo "Test suites failed: ${#FAILED_SUITES[@]}"

if [ ${#FAILED_SUITES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed suites:${NC}"
    for suite in "${FAILED_SUITES[@]}"; do
        echo "  - $suite"
    done
    echo ""
    echo -e "${RED}=============================================="
    echo "              TESTS FAILED"
    echo "==============================================${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}=============================================="
    echo "           ALL TESTS PASSED"
    echo "==============================================${NC}"
    exit 0
fi
