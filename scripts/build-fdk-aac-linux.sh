#!/bin/bash
set -e

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_NAME="x86_64"
        ARCH_FLAGS="-O3 -march=x86-64-v3 -mtune=generic"
        ;;
    aarch64|arm64)
        ARCH_NAME="arm64"
        ARCH_FLAGS="-O3 -march=armv8-a -mtune=generic"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "=== Building libfdk-aac for Linux $ARCH_NAME ==="

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
CFLAGS="$ARCH_FLAGS" \
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
