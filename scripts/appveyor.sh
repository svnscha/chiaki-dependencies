#!/bin/bash

echo "APPVEYOR_BUILD_FOLDER=$APPVEYOR_BUILD_FOLDER"

mkdir ninja && cd ninja || exit 1
wget https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-win.zip && 7z x ninja-win.zip || exit 1
cd .. || exit 1

mkdir yasm && cd yasm || exit 1
wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0-win64.exe && mv yasm-1.3.0-win64.exe yasm.exe || exit 1
cd .. || exit 1

export PATH="$PWD/ninja:$PWD/yasm:/c/Qt/5.12.6/msvc2017_64/bin:$PATH"

scripts/build-ffmpeg.sh --target-os=win64 --arch=x86_64 --toolchain=msvc || exit 1

git clone https://github.com/xiph/opus.git && cd opus && git checkout ad8fe90db79b7d2a135e3dfd2ed6631b0c5662ab || exit 1
mkdir build && cd build || exit 1
cmake \
	-G Ninja \
	-DCMAKE_C_COMPILER=cl \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX="$APPVEYOR_BUILD_FOLDER/opus-prefix" \
	.. || exit 1
ninja || exit 1
ninja install || exit 1
cd ../.. || exit 1

wget https://mirror.firedaemon.com/OpenSSL/openssl-1.1.1d-dev.zip && 7z x openssl-1.1.1d-dev.zip || exit 1

wget https://www.libsdl.org/release/SDL2-devel-2.0.10-VC.zip && 7z x SDL2-devel-2.0.10-VC.zip || exit 1
export SDL_ROOT="$APPVEYOR_BUILD_FOLDER/SDL2-2.0.10" || exit 1
export SDL_ROOT=${SDL_ROOT//[\\]//} || exit 1
echo "set(SDL2_INCLUDE_DIRS \"$SDL_ROOT/include\")
set(SDL2_LIBRARIES \"$SDL_ROOT/lib/x64/SDL2.lib\")
set(SDL2_LIBDIR \"$SDL_ROOT/lib/x64\")" > "$SDL_ROOT/SDL2Config.cmake" || exit 1

COPY_DLLS="$PWD/openssl-1.1/x64/bin/libcrypto-1_1-x64.dll $PWD/openssl-1.1/x64/bin/libssl-1_1-x64.dll $SDL_ROOT/lib/x64/SDL2.dll"


# Deploy

mkdir -p chiaki-dependencies/libraries
mkdir -p chiaki-dependencies/libraries-dist
cp -r $APPVEYOR_BUILD_FOLDER/ffmpeg-prefix chiaki-dependencies/libraries || exit 1
cp -r $APPVEYOR_BUILD_FOLDER/opus-prefix chiaki-dependencies/libraries || exit 1
cp -r $APPVEYOR_BUILD_FOLDER/openssl-1.1 chiaki-dependencies/libraries || exit 1
cp -r $SDL_ROOT chiaki-dependencies/libraries || exit 1

cp -v $COPY_DLLS chiaki-dependencies/libraries-dist
