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

echo "=== Building libopus for Linux $ARCH_NAME ==="

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
CFLAGS="$ARCH_FLAGS" \
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
