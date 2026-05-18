param(
    [string]$InstallDir = "${env:ProgramFiles}\BNetScale",
    [string]$ConfigDir = "${env:ProgramData}\BNetScale"
)

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $args = "-InstallDir `"$InstallDir`" -ConfigDir `"$ConfigDir`""
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -Verb RunAs
    exit
}

Write-Host "Removing bnetscale..."

if (Test-Path "$InstallDir\bnetscale.exe") {
    Remove-Item "$InstallDir\bnetscale.exe" -Force
    Write-Host "  Removed $InstallDir\bnetscale.exe"
}

$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($env:Path -like "*$InstallDir*") {
    $newPath = ($env:Path.Split(';') | Where-Object { $_ -ne $InstallDir }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
}

if (Test-Path $ConfigDir) {
    $ans = Read-Host "Remove config directory ($ConfigDir)? [y/N]"
    if ($ans -eq 'y' -or $ans -eq 'Y') {
        Remove-Item -Recurse -Force $ConfigDir
        Write-Host "  Removed $ConfigDir"
    } else {
        Write-Host "  Preserved $ConfigDir"
    }
}

Write-Host "bnetscale uninstalled."
