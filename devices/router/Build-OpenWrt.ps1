<#
.SYNOPSIS
	Builds the OpenWrt image for the Banana Pi BPI-R4.

.DESCRIPTION
	This script builds the router firmware for the Banana Pi BPI-R4 using Docker or Podman and the official OpenWrt Image Builder.

.PARAMETER Channel
	(Optional) Selects the source channel.
	Allowed values are 'snapshot' and 'release'.
	Defaults to 'snapshot'.

.PARAMETER ReleaseVersion
	(Optional) The OpenWrt release version, for example '25.12.4'.
	Only used when Channel is set to 'release'.
	If omitted, the latest release is resolved from GitHub.

.PARAMETER ImageBuilder
	(Optional) Specifies the URL to the OpenWrt Image Builder.
	If not provided, the URL is derived from Channel and ReleaseVersion.
#>

[CmdletBinding()]
param (
	[ValidateSet('snapshot', 'release')]
	[string]$Channel = 'snapshot',
	[string]$ReleaseVersion,
	[string]$ImageBuilder
)

$targetPath = 'mediatek/filogic'

if (-not $ImageBuilder) {
	if ($Channel -eq 'snapshot') {
		$ImageBuilder = "https://downloads.openwrt.org/snapshots/targets/$targetPath/openwrt-imagebuilder-mediatek-filogic.Linux-x86_64.tar.zst"
	}
	else {
		if (-not $ReleaseVersion) {
			try {
				$latestRelease = Invoke-RestMethod `
					-Uri 'https://api.github.com/repos/openwrt/openwrt/releases/latest' `
					-Headers @{ 'User-Agent' = 'SmartHome-Build-OpenWrt' }
				$ReleaseVersion = "$($latestRelease.tag_name)".TrimStart('v')
			}
			catch {
				throw "Could not resolve latest OpenWrt release from GitHub. Provide -ReleaseVersion or -ImageBuilder. Error: $_"
			}
		}

		$ImageBuilder = "https://downloads.openwrt.org/releases/$ReleaseVersion/targets/$targetPath/openwrt-imagebuilder-$ReleaseVersion-mediatek-filogic.Linux-x86_64.tar.zst"
	}
}

$uri = [System.Uri]$ImageBuilder
$baseUrl = $uri.GetLeftPart([System.UriPartial]::Path).TrimEnd($uri.Segments[-1])
$versionInfoUrl = "$baseUrl/version.buildinfo"

$revision = $null
$gitHash = $null

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

if (-not $revision) {
	if ($Channel -eq 'release' -and $ReleaseVersion) {
		# Keep release artifacts grouped by explicit version if buildinfo parsing changes.
		$revision = $ReleaseVersion
	}
	else {
		throw "Could not determine OpenWrt revision from $versionInfoUrl"
	}
}

if (-not $gitHash) {
	$gitHash = 'unknown'
}

Write-Output "Using Image Builder: $ImageBuilder"
Write-Output "Building OpenWrt revision: $revision"

$runtime = if (Get-Command podman -ErrorAction SilentlyContinue) { 'podman' } `
	elseif (Get-Command docker -ErrorAction SilentlyContinue) { 'docker' } `
	else { throw 'Neither podman nor docker could be found.' }

Set-Variable -Option Constant WorkDir (& $runtime image inspect router-firmware-builder --format '{{.Config.WorkingDir}}')
Set-Variable -Option Constant ImageName 'smart-home/openwrt-builder'
Set-Variable -Option Constant ContainerName 'smart-home-openwrt-builder'

$firmwareFolder = if ($Channel -eq 'release' -and $ReleaseVersion) { "$ReleaseVersion-$revision" } else { $revision }
$firmwareDir = Join-Path $PWD 'firmware' $firmwareFolder
New-Item -ItemType Directory -Force -Path $firmwareDir | Out-Null

& $runtime build `
	--build-arg IMAGE_BUILDER=$ImageBuilder `
	--build-arg OPENWRT_REVISION=$revision `
	--tag "${ImageName}:$revision" `
	--label "org.openwrt.commit=$gitHash" `
	--file 'openwrt/Dockerfile' `
	openwrt `
	|| $(throw 'Failed to build OpenWrt builder.')

& $runtime run `
	-v "${firmwareDir}:$WorkDir/firmware" `
	-v "${PWD}/.env:$WorkDir/.env:ro" `
	--rm `
	--name $ContainerName `
	"${ImageName}:$revision" `
	|| $(throw 'Failed to build OpenWrt.')

Write-Output 'Firmware built successfully.'
