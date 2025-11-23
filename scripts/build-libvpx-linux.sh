#!/bin/bash
set -e

echo "=== Building libvpx for Linux x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

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
    --extra-cflags="-O3 -march=x86-64-v3 -mtune=generic"

# Build
echo "Building libvpx with $JOBS jobs..."
make -j$JOBS

# Install
echo "Installing libvpx..."
make install

echo "=== libvpx build complete ==="
ls -lh "$PREFIX/lib/"
