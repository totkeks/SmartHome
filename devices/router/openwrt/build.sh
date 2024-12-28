#!/usr/bin/env bash

set -eu

echo "Starting OpenWrt build process..."

(
	echo "Replacing environment variables in configuration files"

	variable_names=()
	mapfile -t env_vars < <(grep -vE '^(#|$)' .env)

	for var in "${env_vars[@]}"; do
		export "$var"

		variable_name="${var%%=*}"
		variable_names+=("$variable_name")
	done

	export ROOT_PASSWORD_HASH=$(openssl passwd -5 "$ROOT_PASSWORD")
	variable_names+=("ROOT_PASSWORD_HASH")

	# Prevent envsubst from replacing local variables in the files
	echo "Variables to be replaced:"
	printf -- "- %s\n" "${variable_names[@]}"
	variables=$(printf '${%s} ' "${variable_names[@]}")

	for file in ./files/etc/uci-defaults/* ./files/root/* ./files/etc/hotplug.d/**/*; do
		envsubst "$variables" < "$file" | sponge "$file"
	done
)

cd imagebuilder

echo "Building OpenWrt..."
make -j$(nproc) image \
	PROFILE=bananapi_bpi-r4 \
	ROOTFS_PARTSIZE=1024 \
	PACKAGES="$(grep -vE '^(#|$)' ../packages.txt | tr '\n' ' ')" \
	FILES=../files
	#BIN_DIR="../firmware" # this is bugged currently and doesn't work

echo "Copying files to the firmware directory..."
prefix=$(basename $(find bin -type f -name '*.manifest') .manifest)
find bin -type f -exec bash -c 'fileName=$(basename "$0"); shortName=${fileName/$1/openwrt}; cp -v "$0" "../firmware/$shortName"' {} $prefix \;

echo "OpenWrt build process was successful."
