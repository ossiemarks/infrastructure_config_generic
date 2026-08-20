<#
.SYNOPSIS
Final cleanup pass before sysprep seals the image.

.DESCRIPTION
- Migrates build logs from C:\Build\Logs to C:\Windows\Logs\Packer (persistent)
- Removes C:\Build (build-time scripts/artifacts)
- Cleans Windows and user temp folders
- Clears the Windows Update download cache
- Runs DISM component store cleanup (/StartComponentCleanup /ResetBase)
- Clears all Windows event logs
- Removes C:\Windows.old if present

Logging location: C:\Windows\Logs\Packer\cleanup-for-image.log

Operational notes:
- Clearing event logs is appropriate for golden images/lab builds, not for
  systems you need audit history from.
- DISM /ResetBase reduces component rollback capability - this is
  intentional for a sealed base image.
#>

$ErrorActionPreference = "Stop"

$BuildRoot  = "C:\Build"
$OldLogRoot = "C:\Build\Logs"
$LogDir     = "C:\Windows\Logs\Packer"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir "cleanup-for-image.log"

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

Write-Log '===== Starting final image cleanup ====='

# 1. Migrate logs
Write-Log 'Migrating logs from C:\Build\Logs to C:\Windows\Logs\Packer...'
try {
    if (Test-Path $OldLogRoot) {
        Copy-Item -Path "$OldLogRoot\*" -Destination $LogDir -Recurse -Force
        Write-Log 'Log migration completed.'
    } else {
        Write-Log 'No logs found in C:\Build\Logs - nothing to migrate.'
    }
}
catch {
    Write-Log ("Log migration FAILED: {0}" -f $_.Exception.Message) 'ERROR'
}

# 2. Delete C:\Build
Write-Log 'Removing C:\Build...'
try {
    if (Test-Path $BuildRoot) {
        Remove-Item $BuildRoot -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log 'C:\Build removed.'
    } else {
        Write-Log 'C:\Build does not exist - skipping removal.'
    }
}
catch {
    Write-Log ("Removing C:\Build FAILED: {0}" -f $_.Exception.Message) 'ERROR'
}

# 3. Clean temp folders
Write-Log 'Cleaning Windows and user temp folders...'
try {
    if (Test-Path 'C:\Windows\Temp') {
        Get-ChildItem 'C:\Windows\Temp' -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike 'packer-ps-env-vars-*' } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($env:TEMP -and (Test-Path $env:TEMP)) {
        Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Log 'Temp folders cleaned (excluding packer-ps-env-vars-*).'
}
catch {
    Write-Log ("Cleaning temp folders FAILED: {0}" -f $_.Exception.Message) 'ERROR'
}

# 4. Clear Windows Update cache
Write-Log 'Clearing Windows Update download cache...'
try {
    net stop wuauserv /y | Out-Null
    net stop bits /y     | Out-Null

    if (Test-Path 'C:\Windows\SoftwareDistribution\Download') {
        Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -ErrorAction SilentlyContinue
    }

    net start wuauserv | Out-Null
    net start bits     | Out-Null

    Write-Log 'Windows Update cache cleared.'
}
catch {
    Write-Log ("Clearing Windows Update cache FAILED: {0}" -f $_.Exception.Message) 'ERROR'
}

# 5. WinSxS cleanup
Write-Log 'Running WinSxS cleanup (DISM) - this may take a while...'
try {
    Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase |
        ForEach-Object { Write-Log $_ }
    Write-Log 'WinSxS cleanup completed.'
}
catch {
    Write-Log ("WinSxS cleanup FAILED: {0}" -f $_.Exception.Message) 'ERROR'
}

# 6. Clear all Windows event logs
Write-Log 'Clearing all Windows event logs...'
try {
    $logs = wevtutil el
    foreach ($log in $logs) {
        try {
            Write-Log ("Clearing log: {0}" -f $log)
            wevtutil cl "$log"
        }
        catch {
            Write-Log ("Failed to clear {0}: {1}" -f $log, $_.Exception.Message) 'WARN'
        }
    }
    Write-Log 'Event log clearing completed.'
}
catch {
    Write-Log ("Clearing event logs FAILED: {0}" -f $_.Exception.Message) 'ERROR'
}

# 7. Remove C:\Windows.old if present
$windowsOldPath = "C:\Windows.old"

if (Test-Path -LiteralPath $windowsOldPath) {
    Write-Log "Found Windows.old. Removing..."
    try {
        & takeown.exe /F $windowsOldPath /R /D Y | Out-Null
        & icacls.exe $windowsOldPath /grant "Administrators:(OI)(CI)F" /T /C | Out-Null
        Remove-Item -LiteralPath $windowsOldPath -Recurse -Force -ErrorAction Stop
        Write-Log "Windows.old removed successfully."
    }
    catch {
        Write-Log "Direct delete failed: $($_.Exception.Message)" "WARN"
        Write-Log "Trying DISM cleanup as fallback..."
        try {
            & dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
            if (Test-Path -LiteralPath $windowsOldPath) {
                & takeown.exe /F $windowsOldPath /R /D Y | Out-Null
                & icacls.exe $windowsOldPath /grant "Administrators:(OI)(CI)F" /T /C | Out-Null
                Remove-Item -LiteralPath $windowsOldPath -Recurse -Force -ErrorAction Stop
            }
            if (-not (Test-Path -LiteralPath $windowsOldPath)) {
                Write-Log "Windows.old removed after DISM fallback."
            } else {
                Write-Log "Windows.old still exists. It may be locked; consider reboot + rerun." "WARN"
            }
        }
        catch {
            Write-Log "DISM fallback failed: $($_.Exception.Message)" "WARN"
        }
    }
} else {
    Write-Log "No Windows.old found. Skipping."
}

Write-Log '===== Final image cleanup completed successfully ====='
