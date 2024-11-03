<#
.SYNOPSIS
	Builds the OpenWrt image for the Banana Pi BPI-R4 using the Image Builder.

.DESCRIPTION
	This script builds the router firmware for the Banana Pi BPI-R4 using Docker or Podman and the official OpenWrt Image Builder.

.PARAMETER ImageBuilder
	(Optional) The URL or path to an alternate OpenWrt Image Builder.
	If not provided, the default as specified in the Dockerfile is used.
#>

[CmdletBinding()]
param (
	[string]$ImageBuilder
)

Set-Variable -Option Constant BuilderImageName "router-firmware-builder"
Set-Variable -Option Constant BuilderImageFile "Dockerfile.builder"
Set-Variable -Option Constant WorkDir "/workspace"

$runtime = if (Get-Command podman -ErrorAction SilentlyContinue) { "podman" } `
	elseif (Get-Command docker -ErrorAction SilentlyContinue) { "docker" } `
	else { throw "Neither podman nor docker could be found." }

$buildArgs = @()
$volumeArgs = @(
	"-v", "${PWD}/firmware:$WorkDir/firmware",
	"-v", "${PWD}/.env:$WorkDir/.env:ro"
)

if ($ImageBuilder) {
	$buildArgs += "--build-arg", "IMAGE_BUILDER=$ImageBuilder"
}

$imageName = "$BuilderImageName-openwrt"
& $runtime build @buildArgs --tag $imageName --file "openwrt/Dockerfile" openwrt || $(throw "Failed to build OpenWrt builder.")
& $runtime run @volumeArgs --rm --name $imageName $imageName || $(throw "Failed to build OpenWrt.")

Write-Output "Firmware built successfully."
