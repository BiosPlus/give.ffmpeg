#!/bin/bash
set -e

echo "=== Building x265 for Windows x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Create prefix directory
mkdir -p "$PREFIX"

# Clone x265
echo "Cloning x265..."
git clone --depth 1 https://bitbucket.org/multicoreware/x265_git.git x265-src
cd x265-src/build/linux

# Configure x265 with CMake
echo "Configuring x265..."
cmake -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF \
    -DCMAKE_C_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    -DCMAKE_CXX_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    ../../source

# Build
echo "Building x265 with $JOBS jobs..."
make -j$JOBS

# Install
echo "Installing x265..."
make install

echo "=== x265 build complete ==="
ls -lh "$PREFIX/lib/"
