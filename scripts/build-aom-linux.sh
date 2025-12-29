#!/bin/bash
set -e

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_NAME="x86_64"
        ;;
    aarch64|arm64)
        ARCH_NAME="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "=== Building libaom for Linux $ARCH_NAME ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
SOURCES_DIR="$(pwd)/ffmpeg_sources"
JOBS=$(nproc)

# Create directories
mkdir -p "$SOURCES_DIR"
mkdir -p "$PREFIX"

# Clone or update aom
cd "$SOURCES_DIR"
git -C aom pull 2> /dev/null || git clone --depth 1 https://aomedia.googlesource.com/aom

# Build aom
mkdir -p aom_build
cd aom_build

echo "Configuring libaom..."
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DENABLE_TESTS=OFF \
    -DENABLE_NASM=on \
    ../aom

echo "Building libaom with $JOBS jobs..."
PATH="$HOME/bin:$PATH" make -j$JOBS

echo "Installing libaom..."
make install

echo "=== libaom build complete ==="
