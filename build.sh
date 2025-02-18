#!/bin/bash
#
# Compile script for Cartel kernel
# Copyright (C) 2020-2021 Adithya R & johnmart19.

SECONDS=0 # builtin bash timer
ZIPNAME="Redline-onclite-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="$HOME/proton-clang-build/install"
DEFCONFIG="onclite-perf_defconfig"

export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
echo "Redline clang not found! Cloning to $TC_DIR..."
if ! git clone -q --depth=1 --single-branch https://github.com/johnmart19/Redline_clang $TC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

if [[ $1 == "-r" || $1 == "--regen" ]]; then
cp out/.config arch/arm64/configs/$DEFCONFIG
echo -e "\nRegened defconfig succesfully!"
exit 0
else
echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC="ccache clang" AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb
fi

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if ! [ -d "AnyKernel3" ]; then
echo "AnyKernel3 not found! Cloning..."
if ! git clone -q --depth=1 --single-branch https://github.com/johnmart19/AnyKernel3 -b redline_onclite AnyKernel3; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
rm -f *zip
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
if command -v gdrive &> /dev/null; then
gdrive upload --share $ZIPNAME
else
echo "Zip: $ZIPNAME"
fi
rm -rf out/arch/arm64/boot
else
echo -e "\nCompilation failed!"
fi
