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

echo "=== Building x264 for Linux $ARCH_NAME ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Build x264 from source
echo "Cloning x264..."
git clone --depth 1 https://code.videolan.org/videolan/x264.git x264-src
cd x264-src

echo "Configuring x264..."
./configure \
    --prefix="$PREFIX" \
    --enable-static \
    --disable-cli \
    --disable-opencl \
    --extra-cflags="$ARCH_FLAGS"

echo "Building x264 with $JOBS jobs..."
make -j$JOBS

echo "Installing x264..."
make install

echo "=== x264 build complete ==="
ls -lh "$PREFIX/lib/"*x264* 2>/dev/null || true
