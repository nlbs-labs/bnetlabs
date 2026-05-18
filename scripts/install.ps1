param(
    [string]$Version = "v0.1.5",
    [string]$InstallDir = "${env:ProgramFiles}\BNetScale",
    [string]$ConfigDir = "${env:ProgramData}\BNetScale"
)

$Host = "git.nafi-labs.tech"
$Repo = "Labs/bnetscale"

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $args = "-Version `"$Version`" -InstallDir `"$InstallDir`" -ConfigDir `"$ConfigDir`""
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -Verb RunAs
    exit
}

$Arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "amd64" }
    "ARM64" { "arm64" }
    default { throw "Unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
}

$Tarball = "bnetscale-$Version-windows-$Arch.tar.gz"
$Url = "https://$Host/$Repo/raw/main/releases/$Tarball"
$TmpDir = "$env:TEMP\bnetscale-install"
$ExePath = "$InstallDir\bnetscale.exe"

New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

Write-Host "Downloading bnetscale $Version for windows/$Arch..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $Url -OutFile "$TmpDir\$Tarball"

tar -xzf "$TmpDir\$Tarball" -C $TmpDir
Copy-Item "$TmpDir\bnetscale.exe" $ExePath -Force

$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($env:Path -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$env:Path;$InstallDir", "Machine")
}

Remove-Item -Recurse -Force $TmpDir

Write-Host "Installed bnetscale $Version to $ExePath"
Write-Host "Config directory: $ConfigDir"
Write-Host ""
Write-Host "Dependencies:"
Write-Host "  Install WireGuard from https://www.wireguard.com/install/"
