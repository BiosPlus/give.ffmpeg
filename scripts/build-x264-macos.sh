#!/bin/bash
set -e

echo "=== Building x264 for macOS ARM64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(sysctl -n hw.ncpu)

# Build x264 from source
echo "Cloning x264..."
git clone --depth 1 https://code.videolan.org/videolan/x264.git x264-src
cd x264-src

echo "Configuring x264..."
./configure \
    --prefix="$PREFIX" \
    --enable-static \
    --disable-cli \
    --disable-opencl \
    --extra-cflags="-O3 -mcpu=apple-m1"

echo "Building x264 with $JOBS jobs..."
make -j$JOBS

echo "Installing x264..."
make install

echo "=== x264 build complete ==="
ls -lh "$PREFIX/lib/"*x264* 2>/dev/null || true
