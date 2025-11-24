#!/bin/bash
set -e

echo "=== Building libopus for macOS ARM64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(sysctl -n hw.ncpu)

# Build libopus from source
echo "Cloning libopus..."
git clone --depth 1 https://github.com/xiph/opus.git opus-src
cd opus-src

echo "Preparing libopus..."
./autogen.sh

echo "Configuring libopus..."
./configure \
    --prefix="$PREFIX" \
    --disable-shared \
    --enable-static

echo "Building libopus with $JOBS jobs..."
make -j$JOBS

echo "Installing libopus..."
make install

echo "=== libopus build complete ==="
ls -lh "$PREFIX/lib/"*opus* 2>/dev/null || true
