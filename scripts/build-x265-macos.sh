#!/bin/bash
set -e

echo "=== Building x265 for macOS ARM64 ==="

# Configuration
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(sysctl -n hw.ncpu)

# Build x265 from source
echo "Cloning x265..."
git clone --depth 1 https://bitbucket.org/multicoreware/x265_git.git x265-src
cd x265-src

mkdir -p build
cd build

echo "Configuring x265..."
cmake \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF \
    -DENABLE_PIC=ON \
    -DCMAKE_C_FLAGS="-O3 -mcpu=apple-m1" \
    -DCMAKE_CXX_FLAGS="-O3 -mcpu=apple-m1" \
    ../source

echo "Building x265 with $JOBS jobs..."
cmake --build . -j$JOBS

echo "Installing x265..."
cmake --install .

echo "Creating pkg-config file for x265..."
mkdir -p "$PREFIX/lib/pkgconfig"
cat > "$PREFIX/lib/pkgconfig/x265.pc" << 'EOF'
prefix=__PREFIX__
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: x265
Description: H.265/HEVC encoder
Version: 1.0
Libs: -L${libdir} -lx265
Cflags: -I${includedir}
EOF

sed -i '' "s|__PREFIX__|$PREFIX|g" "$PREFIX/lib/pkgconfig/x265.pc"

echo "=== x265 build complete ==="
ls -lh "$PREFIX/lib/"*x265* 2>/dev/null || true
