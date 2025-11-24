#!/bin/bash
set -e

echo "=== Building SVT-AV1 for Linux x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Build SVT-AV1 from source
echo "Cloning SVT-AV1..."
git clone --depth 1 https://gitlab.com/AOMediaCodec/SVT-AV1.git svt-av1-src
cd svt-av1-src

mkdir -p build
cd build

echo "Configuring SVT-AV1..."
cmake \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_AVX512=ON \
    -DENABLE_AVX2=ON \
    -DCMAKE_C_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    -DCMAKE_CXX_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    ..

echo "Building SVT-AV1 with $JOBS jobs..."
cmake --build . -j$JOBS

echo "Installing SVT-AV1..."
cmake --install .

echo "=== SVT-AV1 build complete ==="
ls -lh "$PREFIX/lib/"*SvtAv1* 2>/dev/null || true
