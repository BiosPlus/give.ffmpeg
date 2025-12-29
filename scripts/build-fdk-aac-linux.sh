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

echo "Running autoreconf..."
autoreconf -fiv

echo "Configuring libfdk-aac..."
CFLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
./configure \
    --prefix="$PREFIX" \
    --disable-shared \
    --enable-static

echo "Building libfdk-aac with $JOBS jobs..."
make -j$JOBS

echo "Installing libfdk-aac..."
make install

echo "=== libfdk-aac build complete ==="
ls -lh "$PREFIX/lib/"*fdk-aac* 2>/dev/null || true
