#!/usr/bin/env bash

set -eu

echo "Starting U-Boot build process..."

echo "Reading build configuration..."
mapfile -t config_lines < <(grep -vE '^(#|$)' config)
for line in "${config_lines[@]}"; do
    export "$line"
done

cd u-boot

echo "Generating make configuration..."
make ${BOARD_DEFCONFIG?"Error: BOARD_DEFCONFIG is not set"}

echo "Building U-Boot..."
make -j$(nproc)

echo "Copying binary to the firmware directory..."
cp -v u-boot.bin ../firmware

echo "U-Boot build process was successful."
