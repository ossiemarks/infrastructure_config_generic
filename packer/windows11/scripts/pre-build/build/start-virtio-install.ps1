<#
.SYNOPSIS
Finds the attached VirtIO drivers CD by volume label pattern and runs the guest tools installer.

.DESCRIPTION
The VirtIO drivers ISO's volume label changes with every release (e.g.
"virtio-win-0.1.285"), so this matches by wildcard pattern instead of an
exact string - avoids the build silently failing every time you update the
ISO without also updating a hardcoded label.

.PARAMETER VolumeLabelPattern
Wildcard pattern (-like syntax) matched against the CD/DVD volume label.
Defaults to "virtio-win*".

.PARAMETER InstallerName
Installer filename at the root of the matched drive. Defaults to
"virtio-win-guest-tools.exe".

.PARAMETER InstallerArguments
Arguments passed to the installer. Defaults to "/passive /noreboot".

Logging location: C:\Build\Logs\virtio-installer.log
#>

param(
    [string]$VolumeLabelPattern = "virtio-win*",
    [string]$InstallerName = "virtio-win-guest-tools.exe",
    [string]$InstallerArguments = "/passive /noreboot"
)

$ErrorActionPreference = "Stop"

$LogDir = "C:\Build\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir "virtio-installer.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$timestamp] [$Level] $Message"
    switch ($Level) {
        "ERROR" { Write-Error $Message }
        "WARN"  { Write-Warning $Message }
        default { Write-Output $Message }
    }
}

Write-Log "Starting VirtIO installer helper script."
Write-Log "Parameters: VolumeLabelPattern='$VolumeLabelPattern', InstallerName='$InstallerName', InstallerArguments='$InstallerArguments'"

try {
    Write-Log "Searching for CD/DVD drives (DriveType = 5)..."
    $cdDrives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 5" -ErrorAction Stop

    if (-not $cdDrives) {
        Write-Log "No CD/DVD drives were detected on this machine." "ERROR"
        exit 1
    }

    Write-Log "Found CD/DVD drives: $(( $cdDrives | ForEach-Object { \"$($_.DeviceID) [$($_.VolumeName)]\" } ) -join ', ')"

    Write-Log "Looking for CD/DVD drive matching label pattern '$VolumeLabelPattern'..."
    $targetDrive = $cdDrives | Where-Object { $_.VolumeName -like $VolumeLabelPattern } | Select-Object -First 1

    if (-not $targetDrive) {
        Write-Log "No CD/DVD drive matching '$VolumeLabelPattern' was found." "ERROR"
        exit 1
    }

    $driveRoot = $targetDrive.DeviceID + "\"
    Write-Log "Match found. Drive: $($targetDrive.DeviceID), VolumeName: '$($targetDrive.VolumeName)'"

    $installerPath = Join-Path $driveRoot $InstallerName
    Write-Log "Looking for installer at: $installerPath"

    if (-not (Test-Path -Path $installerPath)) {
        Write-Log "Installer '$InstallerName' not found at '$installerPath'." "ERROR"
        exit 1
    }

    Write-Log "Installer found. Starting installation..."

    try {
        if ([string]::IsNullOrWhiteSpace($InstallerArguments)) {
            Write-Log "Launching installer without arguments."
            Start-Process -FilePath $installerPath -Wait
        } else {
            Write-Log "Launching installer with arguments: $InstallerArguments"
            Start-Process -FilePath $installerPath -ArgumentList $InstallerArguments -Wait
        }
        Write-Log "Installation process completed."
    }
    catch {
        Write-Log "Failed to launch installer: $($_.Exception.Message)" "ERROR"
        exit 1
    }

    Write-Log "VirtIO installer helper script completed successfully."
}
catch {
    Write-Log "Unexpected error in script: $($_.Exception.Message)" "ERROR"
    exit 1
}
