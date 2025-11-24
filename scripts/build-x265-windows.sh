#!/bin/bash
set -e

echo "=== Building x265 for Windows x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Build x265 from source
echo "Cloning x265..."
git clone --depth 1 https://bitbucket.org/multicoreware/x265_git.git x265-src
cd x265-src/build/msys

echo "Configuring x265..."
cmake \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF \
    -DENABLE_PIC=ON \
    -DCMAKE_C_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    -DCMAKE_CXX_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    ../../source

echo "Building x265 with $JOBS jobs..."
cmake --build . -j$JOBS

echo "Installing x265..."
cmake --install .

echo "=== x265 build complete ==="
ls -lh "$PREFIX/lib/"*x265* 2>/dev/null || true
