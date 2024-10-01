<#
.SYNOPSIS
	Builds the OpenWrt image for the Banana Pi BPI-R4.

.DESCRIPTION
	This script builds the router firmware for the Banana Pi BPI-R4 using Docker or Podman. It builds the OpenWrt image either from scratch or using an existing Image Builder.

.PARAMETER RefreshBuilder
	Refresh the base builder image, even if no changes have been made to the Dockerfile.

.PARAMETER Repository
	The URL of the repository to clone the OpenWrt source code from, or the local path to the repository.

.PARAMETER Branch
	The branch of the repository to use for building the OpenWrt image.

.PARAMETER UseImageBuilder
	(Optional) Switch to indicate that an existing OpenWrt Image Builder should be used instead of building from scratch.

.PARAMETER ImageBuilder
	(Optional) The URL or path to an alternate OpenWrt Image Builder. If not provided, the default as specified in the Dockerfile is used.
#>

[CmdletBinding(DefaultParameterSetName = "FromScratch")]
param (
	[switch]$RefreshBuilder,

	[Parameter(ParameterSetName = "FromScratch")]
	[string]$Repository,

	[Parameter(ParameterSetName = "FromScratch")]
	[string]$Branch,

	[Parameter(ParameterSetName = "ImageBuilder")]
	[switch]$UseImageBuilder,

	[Parameter(ParameterSetName = "ImageBuilder")]
	[string]$ImageBuilder
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
# OpenWrt Build
# ----------------------------------------
$buildArgs = @()
$volumeArgs = @(
	"-v", "${PWD}/firmware:$WorkDir/firmware",
	"-v", "${PWD}/.env:$WorkDir/.env:ro"
)

switch ($PSCmdlet.ParameterSetName) {
	"FromScratch" {
		$dockerFile = "openwrt/Dockerfile"
		$imageName = "$BuilderImageName-openwrt"

		if ($Repository) {
			if ($Repository -match '^https?://.*\.git$') {
				$buildArgs += "--build-arg", "REPO=$Repository"
				if ($Branch) {
					$buildArgs += "--build-arg", "BRANCH=$Branch"
				}
			}
			elseif (Test-Path -Path $Repository -PathType Container) {
				$buildArgs += "--build-arg", "REPO="
				$volumeArgs += "-v", "${Repository}:$WorkDir/openwrt"
			}
			else {
				throw "The provided OpenWrt repository path is not valid or does not exist."
			}
		}
	}

	"ImageBuilder" {
		$dockerFile = "openwrt/Dockerfile.imageBuilder"
		$imageName = "$BuilderImageName-openwrt-imagebuilder"

		if ($ImageBuilder) {
			$buildArgs += "--build-arg", "IMAGE_BUILDER=$ImageBuilder"
		}
	}
}

& $runtime build @buildArgs --tag $imageName --file $dockerFile openwrt || $(throw "Failed to build OpenWrt builder using $dockerFile.")

& $runtime run @volumeArgs --rm --name $imageName $imageName || $(throw "Failed to build OpenWrt.")

Write-Output "Firmware built successfully."
