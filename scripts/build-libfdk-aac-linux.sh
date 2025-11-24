#!/bin/bash
set -e

echo "=== Building libfdk-aac for Linux x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Build libfdk-aac from source
echo "Cloning libfdk-aac..."
git clone --depth 1 https://github.com/mstorsjo/fdk-aac.git fdk-aac-src
cd fdk-aac-src

echo "Preparing libfdk-aac..."
autoreconf -fiv

echo "Configuring libfdk-aac..."
./configure \
    --prefix="$PREFIX" \
    --disable-shared \
    --enable-static

echo "Building libfdk-aac with $JOBS jobs..."
make -j$JOBS

echo "Installing libfdk-aac..."
make install

echo "=== libfdk-aac build complete ==="
ls -lh "$PREFIX/lib/"*fdk* 2>/dev/null || true
