[CmdletBinding()]
param (
	[string]$UBootRepository,
	[string]$UBootBranch,
	[string]$ATFRepository,
	[string]$ATFBranch,
	[switch]$RefreshBuilder = $false,
	[switch]$SkipATF = $false
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
$buildArgs = @()
$volumeArgs = @("-v", "${PWD}/firmware:$WorkDir/firmware")

# Handle U-Boot repository override, if provided
if ($UBootRepository) {
	if ($UBootRepository -match '^https?://.*\.git$') {
		$buildArgs += "--build-arg", "UBOOT_REPO=$UBootRepository"
		if ($UBootBranch) { $buildArgs += "--build-arg", "UBOOT_BRANCH=$UBootBranch" }
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
& $runtime run @volumeArgs --rm --name $uBootImageName $uBootImageName || $(throw "Failed to build U-Boot.")

# ----------------------------------------
# ATF Build
# ----------------------------------------
if (-not $SkipATF) {
	$buildArgs = @()
	$volumeArgs = @("-v", "${PWD}/firmware:$WorkDir/firmware")

	# Handle ATF repository override, if provided
	if ($ATFRepository) {
		if ($ATFRepository -match '^https?://.*\.git$') {
			$buildArgs += "--build-arg", "ATF_REPO=$ATFRepository"
			if ($ATFBranch) { $buildArgs += "--build-arg", "ATF_BRANCH=$ATFBranch" }
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
	& $runtime run @volumeArgs --rm --name $atfImageName $atfImageName || $(throw "Failed to build ATF.")
}

Write-Output "Firmware built successfully."
Get-ChildItem -Exclude .* firmware
