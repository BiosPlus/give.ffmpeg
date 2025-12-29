#!/bin/bash
set -e

echo "=== Building libx265 for Linux x86_64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
SOURCES_DIR="$(pwd)/ffmpeg_sources"
JOBS=$(nproc)

# Create directories
mkdir -p "$SOURCES_DIR"
mkdir -p "$PREFIX"

# Download and extract x265
cd "$SOURCES_DIR"
echo "Downloading x265..."
wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2

echo "Extracting x265..."
tar xjf x265.tar.bz2

# Find the extracted directory (it will be named multicoreware-x265_git-{hash})
X265_DIR=$(find . -maxdepth 1 -type d -name "multicoreware-x265_git-*" | head -n 1)

if [ -z "$X265_DIR" ]; then
    echo "Error: Could not find extracted x265 directory"
    exit 1
fi

echo "Found x265 directory: $X265_DIR"

# Build x265
cd "$X265_DIR/build/linux"

echo "Configuring libx265..."
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DENABLE_SHARED=off \
    -DCMAKE_C_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    -DCMAKE_CXX_FLAGS="-O3 -march=x86-64-v3 -mtune=generic" \
    ../../source

echo "Building libx265 with $JOBS jobs..."
PATH="$HOME/bin:$PATH" make -j$JOBS

echo "Installing libx265..."
make install

echo "=== libx265 build complete ==="
ls -lh "$PREFIX/lib/"*x265* 2>/dev/null || true
