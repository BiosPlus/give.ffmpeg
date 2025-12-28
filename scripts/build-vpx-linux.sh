#!/bin/bash
set -e

echo "=== Building libvpx for Linux x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
SOURCES_DIR="$(pwd)/ffmpeg_sources"
JOBS=$(nproc)

# Create directories
mkdir -p "$SOURCES_DIR"
mkdir -p "$PREFIX"

# Clone or update libvpx
cd "$SOURCES_DIR"
git -C libvpx pull 2> /dev/null || git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git

# Build libvpx
cd libvpx

echo "Configuring libvpx..."
PATH="$HOME/bin:$PATH" ./configure \
    --prefix="$PREFIX" \
    --disable-examples \
    --disable-unit-tests \
    --enable-vp9-highbitdepth \
    --as=yasm

echo "Building libvpx with $JOBS jobs..."
PATH="$HOME/bin:$PATH" make -j$JOBS

echo "Installing libvpx..."
make install

echo "=== libvpx build complete ==="
