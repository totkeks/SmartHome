#!/usr/bin/env bash

set -eu

echo "Starting ATF/FIP build process..."

cd atf

echo "Building ATF/FIP..."
make -j$(nproc) CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7988 DRAM_USE_COMB=1 BOOT_DEVICE=sdmmc BL33=../firmware/u-boot.bin all fip

echo "Copying files to the firmware directory..."
cp -v build/mt7988/release/bl2.img ../firmware
cp -v build/mt7988/release/fip.bin ../firmware

echo "ATF/FIP build process was successful."
