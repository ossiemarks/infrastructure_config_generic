<#
.SYNOPSIS
Locks the current session immediately after first logon.

.DESCRIPTION
Windows Setup's FirstLogonCommands run in the Administrator's interactive
session. Locking the screen here prevents the autologon session from
sitting open and unattended while the remaining first-logon scripts
(WinRM setup, VirtIO install) finish in the background.

Logging location: C:\Build\Logs\lock-screen.log
#>

$ErrorActionPreference = "Stop"

$LogDir = "C:\Build\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir "lock-screen.log"

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

try {
    Write-Log "Attempting to lock the workstation."
    Start-Process "rundll32.exe" "user32.dll,LockWorkStation" -ErrorAction Stop
    Write-Log "Workstation locked successfully."
}
catch {
    Write-Log "Failed to lock workstation. Error: $($_.Exception.Message)" "ERROR"
}
