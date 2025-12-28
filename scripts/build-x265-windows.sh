#!/bin/bash
set -e

echo "=== Building x265 for Windows x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Download x265
echo "Downloading x265..."
curl -L -o x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2
tar xjvf x265.tar.bz2

# Navigate to build directory
cd multicoreware*/build/linux

echo "Configuring x265..."
PATH="$PREFIX/bin:$PATH" cmake -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DENABLE_SHARED=off \
    -DCMAKE_C_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    -DCMAKE_CXX_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    ../../source

echo "Building x265 with $JOBS jobs..."
PATH="$PREFIX/bin:$PATH" make -j$JOBS

echo "Installing x265..."
make install

echo "=== x265 build complete ==="
ls -lh "$PREFIX/lib/"*x265* 2>/dev/null || true
echo "Checking for x265.pc..."
ls -lh "$PREFIX/lib/pkgconfig/x265.pc" 2>/dev/null || echo "WARNING: x265.pc not found!"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
pkg-config --modversion x265 || echo "WARNING: pkg-config cannot find x265"
