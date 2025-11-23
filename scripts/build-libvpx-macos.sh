#!/bin/bash
set -e

echo "=== Building libvpx for macOS ARM64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(sysctl -n hw.ncpu)

# Create prefix directory
mkdir -p "$PREFIX"

# Clone libvpx
echo "Cloning libvpx..."
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git libvpx-src
cd libvpx-src

# Configure libvpx
echo "Configuring libvpx..."
./configure \
    --prefix="$PREFIX" \
    --disable-shared \
    --enable-static \
    --disable-examples \
    --disable-tools \
    --disable-docs \
    --disable-unit-tests \
    --enable-vp8 \
    --enable-vp9 \
    --enable-pic \
    --target=arm64-darwin-gcc

# Build
echo "Building libvpx with $JOBS jobs..."
make -j$JOBS

# Install
echo "Installing libvpx..."
make install

echo "=== libvpx build complete ==="
ls -lh "$PREFIX/lib/"
