#!/usr/bin/env bash

set -eu

# Build the U-Boot image
echo "Building U-Boot..."
cd u-boot

make mt7988a_bpir4_sd_defconfig
make -j$(nproc) CROSS_COMPILE=aarch64-linux-gnu-

cd ..
echo "U-Boot build was successful."

# Build the Firmware Image Package (FIP) containing the ARM Trusted Firmware (ATF) and U-Boot as BL33
echo "Building ATF/FIP..."
cd atf

make -j$(nproc) CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7988 DRAM_USE_COMB=1 BOOT_DEVICE=sdmmc BL33=../u-boot/u-boot.bin all fip

cd ..
echo "FIP build was successful."

echo "Copying files to the firmware directory..."
cp u-boot/u-boot.bin firmware
cp atf/build/mt7988/release/bl2.img firmware
cp atf/build/mt7988/release/fip.bin firmware

echo "Build process completed successfully."
