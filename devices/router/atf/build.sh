#!/usr/bin/env bash

set -eu

echo "Starting ATF/FIP build process..."

echo "Reading makeflags..."
mapfile -t makeflags < <(grep -vE '^(#|$)' makeflags)

cd atf

echo "Building ATF/FIP..."
make -j$(nproc) "${makeflags[@]}" all fip

echo "Copying files to the firmware directory..."
cp -v build/mt7988/release/bl2.img ../firmware
cp -v build/mt7988/release/fip.bin ../firmware

echo "ATF/FIP build process was successful."
