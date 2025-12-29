#!/bin/bash
set -e

echo "=== Building FFmpeg for Linux x86_64 ==="

# Configuration
FFMPEG_VERSION="master"
PREFIX="$(pwd)/ffmpeg-build"
JOBS=$(nproc)

# Clone FFmpeg
echo "Cloning FFmpeg..."
git clone --depth 1 --branch $FFMPEG_VERSION https://github.com/FFmpeg/FFmpeg.git ffmpeg-src
cd ffmpeg-src

# Configure FFmpeg with minimal but optimized build
echo "Configuring FFmpeg..."
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

./configure \
    --prefix="$PREFIX" \
    --pkg-config-flags="--static" \
    --enable-gpl \
    --enable-nonfree \
    --enable-version3 \
    --disable-debug \
    --disable-doc \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --enable-lto \
    --enable-optimizations \
    --disable-shared \
    --enable-static \
    --enable-pic \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libopus \
    --enable-libaom \
    --enable-libvpx \
    --enable-libsvtav1 \
    --enable-libfdk-aac \
    --extra-cflags="-O3 -march=x86-64-v3 -mtune=generic -I$PREFIX/include" \
    --extra-ldflags="-static -L$PREFIX/lib" \
    --extra-libs=-lpthread \
    \
    --disable-everything \
    \
    --enable-ffmpeg \
    --enable-ffprobe \
    \
    --enable-protocol=file \
    --enable-protocol=pipe \
    \
    --enable-demuxer=mov \
    --enable-demuxer=matroska \
    --enable-demuxer=webm \
    --enable-demuxer=avi \
    --enable-demuxer=mp3 \
    --enable-demuxer=flac \
    --enable-demuxer=ogg \
    --enable-demuxer=wav \
    --enable-demuxer=image2 \
    --enable-demuxer=concat \
    \
    --enable-muxer=mp4 \
    --enable-muxer=matroska \
    --enable-muxer=webm \
    --enable-muxer=mov \
    --enable-muxer=mp3 \
    --enable-muxer=flac \
    --enable-muxer=ogg \
    --enable-muxer=wav \
    --enable-muxer=image2 \
    --enable-muxer=null \
    \
    --enable-decoder=h264 \
    --enable-decoder=hevc \
    --enable-decoder=vp8 \
    --enable-decoder=vp9 \
    --enable-decoder=av1 \
    --enable-decoder=mpeg4 \
    --enable-decoder=aac \
    --enable-decoder=mp3 \
    --enable-decoder=opus \
    --enable-decoder=flac \
    --enable-decoder=vorbis \
    --enable-decoder=pcm_s16le \
    --enable-decoder=pcm_s24le \
    --enable-decoder=png \
    --enable-decoder=mjpeg \
    \
    --enable-encoder=libx264 \
    --enable-encoder=libx265 \
    --enable-encoder=libopus \
    --enable-encoder=libaom_av1 \
    --enable-encoder=libvpx_vp8 \
    --enable-encoder=libvpx_vp9 \
    --enable-encoder=libsvtav1 \
    --enable-encoder=libfdk_aac \
    --enable-encoder=png \
    --enable-encoder=mjpeg \
    --enable-encoder=pcm_s16le \
    --enable-encoder=pcm_s24le \
    \
    --enable-parser=h264 \
    --enable-parser=hevc \
    --enable-parser=vp8 \
    --enable-parser=vp9 \
    --enable-parser=av1 \
    --enable-parser=mpeg4video \
    --enable-parser=aac \
    --enable-parser=mpegaudio \
    --enable-parser=opus \
    --enable-parser=flac \
    --enable-parser=vorbis \
    --enable-parser=png \
    --enable-parser=mjpeg \
    \
    --enable-bsf=h264_mp4toannexb \
    --enable-bsf=hevc_mp4toannexb \
    --enable-bsf=aac_adtstoasc \
    \
    --enable-filter=scale \
    --enable-filter=crop \
    --enable-filter=overlay \
    --enable-filter=trim \
    --enable-filter=setpts \
    --enable-filter=asetpts \
    --enable-filter=concat \
    --enable-filter=volume \
    --enable-filter=anull \
    --enable-filter=null \
    --enable-filter=format \
    --enable-filter=aformat \
    --enable-filter=fps

# Build
echo "Building FFmpeg with $JOBS jobs..."
make -j$JOBS

# Install
echo "Installing FFmpeg..."
make install

echo "=== Build complete ==="
echo "Binaries located at: $PREFIX/bin/"
ls -lh "$PREFIX/bin/"
