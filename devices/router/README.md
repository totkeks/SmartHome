# Router - Banana Pi BPI-R4

This folder contains my personal configuration for the [Banana Pi BPI-R4](https://wiki.banana-pi.org/Banana_Pi_BPI-R4) using [OpenWrt](https://openwrt.org).

## EMMC Production System

OpenWrt-based system customized with my packages and configurations through the Image Builder and UCI defaults.

### First Installation

1. **Write Image to SD Card**:

   - Write the `openwrt-sdcard.img.gz` to an SD card using a tool like `dd` or `Etcher`.

2. **Install to NAND**:

   - Insert the SD card into the Banana Pi BPI-R4.
   - Boot from the SD card.
   - Select the option to install to NAND.

3. **Install to EMMC**:
   - Boot from NAND.
   - Select the option to install to EMMC.

### Upgrading

1. **Using LuCI**:

   - Navigate to `System` > `Backup/Flash Firmware`.
   - Upload the new firmware image `openwrt-squashfs-sysupgrade.itb`.
   - Click `Flash Image` to upgrade.

2. **Using Command Line**:

   - Upload the new firmware image `openwrt-squashfs-sysupgrade.itb` to the device (e.g., via SCP).
   - Run the following command to upgrade:

     ```sh
     sysupgrade -v /tmp/openwrt-squashfs-sysupgrade.itb
     ```

## Folder Structure

- `openwrt/` - OpenWrt Image Builder configuration
  - `build.sh` - Script to build the OpenWrt image
  - `Dockerfile` - Dockerfile for building the OpenWrt image
  - `files/` - Configuration files for UCI defaults and other customizations
  - `packages.txt` - List of packages to include in the build
- `firmware/` - Output folder for the built firmware files
- `services/` - Additional services configuration _(not implemented yet)_
- `.env` - Environment variables for sensitive data (not included in the repository)
- `.env.example` - Example environment variables file

## Building the Firmware

To build the firmware, follow these steps:

1. **Install Container Runtime**: Ensure [Podman](https://podman.io) or [Docker](https://www.docker.com) is installed on your system.

2. **Build the Builder Image**: Build the base builder image using the `Dockerfile.builder`:

   ```sh
   docker build -t router-firmware-builder -f Dockerfile.builder .
   ```

3. **Set Up Environment Variables**: Create a `.env` file based on the `.env.example` file and customize it for your needs.

4. **Run the Build Script**: Execute the `Build-OpenWrt.ps1` script to build the firmware:

   ```sh
   ./Build-OpenWrt.ps1
   ```
