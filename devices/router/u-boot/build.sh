#!/usr/bin/env bash

set -eu

echo "Starting U-Boot build process..."

echo "Reading additional makeflags..."
mapfile -t makeflags < <(grep -v '^#' ../makeflags.txt | grep -v '^$')

cd u-boot

echo "Generating configuration..."
make mt7988a_bpir4_sd_defconfig

echo "Building U-Boot..."
make -j$(nproc) CROSS_COMPILE=aarch64-linux-gnu- "${makeflags[@]}"

echo "Copying binary to the firmware directory..."
cp -v u-boot.bin ../firmware

echo "U-Boot build process was successful."
