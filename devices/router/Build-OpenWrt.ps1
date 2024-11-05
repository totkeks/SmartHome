<#
.SYNOPSIS
	Builds the OpenWrt image for the Banana Pi BPI-R4.

.DESCRIPTION
	This script builds the router firmware for the Banana Pi BPI-R4 using Docker or Podman and the official OpenWrt Image Builder.

.PARAMETER ImageBuilder
	(Optional) Specifies the URL to the OpenWrt Image Builder.
	If not provided, it defaults to the latest snapshot.
#>

[CmdletBinding()]
param (
	[string]$ImageBuilder = "https://downloads.openwrt.org/snapshots/targets/mediatek/filogic/openwrt-imagebuilder-mediatek-filogic.Linux-x86_64.tar.zst"
)

$uri = [System.Uri]$ImageBuilder
$baseUrl = $uri.GetLeftPart([System.UriPartial]::Path).TrimEnd($uri.Segments[-1])
$versionInfoUrl = "$baseUrl/version.buildinfo"

try {
	$versionInfo = Invoke-WebRequest -Uri $versionInfoUrl -UseBasicParsing
	if ($versionInfo.Content -match '(r\d+)-([a-f0-9]+)') {
		$revision = $Matches[1]
		$gitHash = $Matches[2]
	}
}
catch {
	Write-Error "Could not fetch version info: $_"
}

$runtime = if (Get-Command podman -ErrorAction SilentlyContinue) { "podman" } `
	elseif (Get-Command docker -ErrorAction SilentlyContinue) { "docker" } `
	else { throw "Neither podman nor docker could be found." }

Set-Variable -Option Constant WorkDir (& $runtime image inspect router-firmware-builder --format '{{.Config.WorkingDir}}')
Set-Variable -Option Constant ImageName "smart-home/openwrt-builder"
Set-Variable -Option Constant ContainerName "smart-home-openwrt-builder"

$firmwareDir = Join-Path $PWD "firmware" $revision
New-Item -ItemType Directory -Force -Path $firmwareDir | Out-Null

& $runtime build `
	--build-arg IMAGE_BUILDER=$ImageBuilder `
	--tag "${ImageName}:$revision" `
	--label "org.openwrt.commit=$gitHash" `
	--file "openwrt/Dockerfile" `
	openwrt `
	|| $(throw "Failed to build OpenWrt builder.")

& $runtime run `
	-v "${firmwareDir}:$WorkDir/firmware" `
	-v "${PWD}/.env:$WorkDir/.env:ro" `
	--rm `
	--name $ContainerName `
	"${ImageName}:$revision" `
	|| $(throw "Failed to build OpenWrt.")

Write-Output "Firmware built successfully."
