[CmdletBinding()]
param (
	[string]$ImageName = "router-firmware-builder",
	[string]$UBootRepository,
	[string]$UBootBranch,
	[string]$ATFRepository,
	[string]$ATFBranch,
	[switch]$ForceRebuild = $false
)

$runtime = if (Get-Command podman -ErrorAction SilentlyContinue) { "podman" } `
	elseif (Get-Command docker -ErrorAction SilentlyContinue) { "docker" } `
	else { throw "Neither podman nor docker could be found." }

# Build container image
if ($ForceRebuild) {
	& $runtime rmi $ImageName -f
}

$UBootIsUrl = $UBootRepository -match '^https?://.*\.git$'
$ATFIsUrl = $ATFRepository -match '^https?://.*\.git$'

$buildArgs = @()
if ($UBootIsUrl) {
	$buildArgs += "--build-arg", "UBOOT_REPO=$UBootRepository"
	if ($UBootBranch) { $buildArgs += "--build-arg", "UBOOT_BRANCH=$UBootBranch" }
}
if ($ATFIsUrl) {
	$buildArgs += "--build-arg", "ATF_REPO=$ATFRepository"
	if ($ATFBranch) { $buildArgs += "--build-arg", "ATF_BRANCH=$ATFBranch" }
}

& $runtime build @buildArgs --tag $ImageName --file Dockerfile . || $(throw "Failed to build container image.")

# Run container and build firmware
$volumeArgs = @("-v", "${PWD}/firmware:/build/firmware")
if (-not $UBootIsUrl) { $volumeArgs += "-v", "${PWD}/${UBootRepository}:/u-boot" }
if (-not $ATFIsUrl) { $volumeArgs += "-v", "${PWD}/${ATFRepository}:/atf" }

& $runtime run --rm -it --name $imageName @volumeArgs $imageName || $(throw "Failed to build firmware.")

Write-Output "Firmware built successfully."
