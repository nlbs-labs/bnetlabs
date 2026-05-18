param(
    [string]$Version = "v0.1.5",
    [string]$InstallDir = "${env:ProgramFiles}\BNetScale"
)

$Repo = "Labs/bnetscale"

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $args = "-Version `"$Version`" -InstallDir `"$InstallDir`""
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -Verb RunAs
    exit
}

$Current = "none"
if (Test-Path "$InstallDir\bnetscale.exe") {
    $Current = & "$InstallDir\bnetscale.exe" version 2>$null
    if (-not $Current) { $Current = "unknown" }
}

Write-Host "Current: $Current"
Write-Host "Target:  $Version"

if ($Current -eq $Version) {
    Write-Host "Already up to date."
    exit
}

$Arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "amd64" }
    "ARM64" { "arm64" }
    default { throw "Unsupported: $env:PROCESSOR_ARCHITECTURE" }
}

$Tarball = "bnetscale-$Version-windows-$Arch.tar.gz"
$Url = "https://git.nafi-labs.tech/$Repo/raw/main/releases/$Tarball"
$TmpDir = "$env:TEMP\bnetscale-update"

New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null

Write-Host "Downloading $Version..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $Url -OutFile "$TmpDir\$Tarball"

tar -xzf "$TmpDir\$Tarball" -C $TmpDir
Copy-Item "$TmpDir\bnetscale.exe" "$InstallDir\bnetscale.exe" -Force

Remove-Item -Recurse -Force $TmpDir
Write-Host "Updated to $Version"
