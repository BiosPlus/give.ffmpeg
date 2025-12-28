#!/bin/bash
set -e

echo "=== Building libopus for Windows x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Build libopus from source
echo "Cloning libopus..."
git clone --depth 1 https://github.com/xiph/opus.git opus-src
cd opus-src

echo "Running autogen.sh..."
./autogen.sh

echo "Configuring libopus..."
CFLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
./configure \
    --prefix="$PREFIX" \
    --disable-shared \
    --enable-static \
    --disable-doc \
    --disable-extra-programs

echo "Building libopus with $JOBS jobs..."
make -j$JOBS

echo "Installing libopus..."
make install

echo "=== libopus build complete ==="
ls -lh "$PREFIX/lib/"*opus* 2>/dev/null || true
