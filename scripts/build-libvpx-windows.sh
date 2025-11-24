#!/bin/bash
set -e

echo "=== Building libvpx for Windows x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Build libvpx from source
echo "Cloning libvpx..."
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git libvpx-src
cd libvpx-src

echo "Configuring libvpx..."
./configure \
    --prefix="$PREFIX" \
    --enable-vp8 \
    --enable-vp9 \
    --enable-static \
    --disable-shared \
    --disable-examples \
    --disable-docs \
    --disable-unit-tests \
    --extra-cflags="-O3 -march=x86-64-v3 -mtune=generic"

echo "Building libvpx with $JOBS jobs..."
make -j$JOBS

echo "Installing libvpx..."
make install

echo "=== libvpx build complete ==="
ls -lh "$PREFIX/lib/"*vpx* 2>/dev/null || true
