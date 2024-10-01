<#
.SYNOPSIS
	Builds the router firmware for the Banana Pi BPI-R4.

.DESCRIPTION
	This script builds the router firmware for the Banana Pi BPI-R4 using Docker or Podman. It builds the U-Boot and ARM Trusted Firmware (ATF) binaries, and then packages the firmware image into a compressed archive.

.PARAMETER Target
	(Mandatory) The target to build. Must be one of "UBoot", "ATF".

.PARAMETER RefreshBuilder
	Refresh the base builder image, even if no changes have been made to the Dockerfile.

.PARAMETER UBootRepository
	(Optional) The URL or path to an alternate U-Boot repository. If not provided, the default repository as specified in the Dockerfile is used.

	If a URL is provided, the repository is cloned inside the container.
	If a path is provided, it is mounted inside the container and changes made during the build process are reflected back on the host.

.PARAMETER UBootBranch
	(Optional) The U-Boot branch to checkout. If not provided, the default of the respective repository is used.

.PARAMETER ATFRepository
	(Optional) The URL or path to an alternate ATF repository. If not provided, the default repository as specified in the Dockerfile is used.

	If a URL is provided, the repository is cloned inside the container.
	If a path is provided, it is mounted inside the container and changes made during the build process are reflected back on the host.

.PARAMETER ATFBranch
	(Optional) The ATF branch to checkout. If not provided, the default of the respective repository is used.
#>

param (
	[Parameter(Mandatory)]
	[ValidateSet("UBoot", "ATF")]
	[string]$Target,
	[switch]$RefreshBuilder,

	[string]$UBootRepository,
	[string]$UBootBranch,

	[string]$ATFRepository,
	[string]$ATFBranch
)

Set-Variable -Option Constant BuilderImageName "router-firmware-builder"
Set-Variable -Option Constant BuilderImageFile "Dockerfile.builder"
Set-Variable -Option Constant WorkDir "/workspace"

$runtime = if (Get-Command podman -ErrorAction SilentlyContinue) { "podman" } `
	elseif (Get-Command docker -ErrorAction SilentlyContinue) { "docker" } `
	else { throw "Neither podman nor docker could be found." }

# ----------------------------------------
# Base Container Image with Build Tools
# ----------------------------------------
if ($RefreshBuilder) {
	& $runtime rmi $BuilderImageName -f
}
& $runtime build --tag $BuilderImageName --file $BuilderImageFile . || $(throw "Failed to build container image for $BuilderImageName using $BuilderImageFile.")

# ----------------------------------------
# U-Boot Build
# ----------------------------------------
if ($Target -contains "UBoot" -or $Target -contains "ATF") {
	$buildArgs = @()
	$volumeArgs = @(
		"-v", "${PWD}/firmware:$WorkDir/firmware"
		"-v", "${PWD}/u-boot/bpi-r4.conf:$WorkDir/config"
		"-v", "${PWD}/u-boot/uEnv.txt:$WorkDir/uEnv.txt"
	)

	# Handle U-Boot repository override, if provided
	if ($UBootRepository) {
		if ($UBootRepository -match '^https?://.*\.git$') {
			$buildArgs += "--build-arg", "UBOOT_REPO=$UBootRepository"
			if ($UBootBranch) {
				$buildArgs += "--build-arg", "UBOOT_BRANCH=$UBootBranch"
			}
		}
		elseif (Test-Path -Path $UBootRepository -PathType Container) {
			$buildArgs += "--build-arg", "UBOOT_REPO="
			$volumeArgs += "-v", "${PWD}/${UBootRepository}:/$WorkDir/u-boot"
		}
		else {
			throw "The provided U-Boot repository path is not valid or does not exist."
		}
	}

	$uBootImageName = "$BuilderImageName-uboot"

	& $runtime build @buildArgs --tag $uBootImageName --file u-boot/Dockerfile u-boot || $(throw "Failed to build U-Boot builder using u-boot/Dockerfile.")

	& $runtime run --rm @volumeArgs --name $uBootImageName $uBootImageName || $(throw "Failed to build U-Boot.")
}

# ----------------------------------------
# ATF Build
# ----------------------------------------
if ($Target -contains "ATF") {
	$buildArgs = @()
	$volumeArgs = @(
		"-v", "${PWD}/firmware:$WorkDir/firmware"
		"-v", "${PWD}/atf/bpi-r4.conf:$WorkDir/makeflags"
	)

	# Handle ATF repository override, if provided
	if ($ATFRepository) {
		if ($ATFRepository -match '^https?://.*\.git$') {
			$buildArgs += "--build-arg", "ATF_REPO=$ATFRepository"
			if ($ATFBranch) {
				$buildArgs += "--build-arg", "ATF_BRANCH=$ATFBranch"
			}
		}
		elseif (Test-Path -Path $ATFRepository -PathType Container) {
			$buildArgs += "--build-arg", "ATF_REPO="
			$volumeArgs += "-v", "${PWD}/${ATFRepository}:/$WorkDir/atf"
		}
		else {
			throw "The provided ATF repository path is not valid or does not exist."
		}
	}

	$atfImageName = "$BuilderImageName-atf"

	& $runtime build @buildArgs --tag $atfImageName --file atf/Dockerfile atf || $(throw "Failed to build ATF builder using atf/Dockerfile.")

	& $runtime run --rm @volumeArgs --name $atfImageName $atfImageName || $(throw "Failed to build ATF.")
}

Write-Output "Firmware built successfully."