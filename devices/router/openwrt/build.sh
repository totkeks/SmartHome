#!/usr/bin/env bash

set -eu

echo "Starting OpenWrt build process..."

cd imagebuilder

echo "Building OpenWrt..."
make -j$(nproc) image \
	PROFILE=bananapi_bpi-r4 \
	FILES=../files \
	#BIN_DIR="../firmware" \ # this is bugged currently and doesn't work
	PACKAGES=$(grep -v '^#' ../packages.txt | grep -v '^$' | tr '\n' ' ')

echo "Copying files to the firmware directory..."
prefix=$(basename $(find bin -type f -name '*.manifest') .manifest)
find bin -type f -exec bash -c 'fileName=$(basename "$0"); shortName=${fileName/$1/openwrt}; cp -v "$0" "../firmware/$shortName"' {} $prefix \;

echo "OpenWrt build process was successful."
