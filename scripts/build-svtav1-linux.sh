#!/bin/bash
set -e

echo "=== Building SVT-AV1 for Linux x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
SOURCES_DIR="$(pwd)/ffmpeg_sources"
JOBS=$(nproc)

# Create directories
mkdir -p "$SOURCES_DIR"
mkdir -p "$PREFIX"

# Clone or update SVT-AV1
cd "$SOURCES_DIR"
git -C SVT-AV1 pull 2> /dev/null || git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git

# Build SVT-AV1
mkdir -p SVT-AV1/build
cd SVT-AV1/build

echo "Configuring SVT-AV1..."
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DEC=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    ..

echo "Building SVT-AV1 with $JOBS jobs..."
PATH="$HOME/bin:$PATH" make -j$JOBS

echo "Installing SVT-AV1..."
make install

echo "=== SVT-AV1 build complete ==="
