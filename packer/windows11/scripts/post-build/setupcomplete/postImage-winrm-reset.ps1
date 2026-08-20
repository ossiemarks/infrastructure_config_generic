<#
.SYNOPSIS
Resets WinRM to OS defaults and removes the build-time certificate before the image is sealed.

.DESCRIPTION
set-winrm-packer.ps1 configures WinRM permissively (HTTPS, basic auth,
unencrypted allowed) so Packer can connect during the build. This script
runs at the very end (via SetupComplete.cmd, so it executes even though
sysprep has already generalized the machine) and undoes that: restores
WinRM to OS defaults, removes listeners, sets the service to Manual/stopped,
and removes the "CN=packer" self-signed cert. A cloned VM's WinRM state
should never carry build-time credentials or permissive settings forward.

Logging location: C:\Windows\Logs\Packer\winrm-reset-defaults.log
#>

$ErrorActionPreference = "Stop"

$LogDir = "C:\Windows\Logs\Packer"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir "winrm-reset-defaults.log"

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

function Ensure-ServiceRunning {
    param(
        [Parameter(Mandatory = $true)][string]$ServiceName,
        [string]$DisplayName = $ServiceName,
        [ValidateSet("Automatic", "Manual")][string]$StartupType = "Manual"
    )
    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($svc.StartType -eq 'Disabled') {
            Write-Log ("{0} service is Disabled. Setting StartupType to {1}." -f $DisplayName, $StartupType) "WARN"
            Set-Service -Name $ServiceName -StartupType $StartupType -ErrorAction Stop
        }
        if ($svc.Status -ne 'Running') {
            Write-Log ("{0} service is {1}. Attempting to start..." -f $DisplayName, $svc.Status) "WARN"
            Start-Service -Name $ServiceName -ErrorAction Stop
            Start-Sleep -Seconds 1
            $svc = Get-Service -Name $ServiceName -ErrorAction Stop
            if ($svc.Status -eq 'Running') {
                Write-Log ("{0} service started successfully." -f $DisplayName)
            } else {
                Write-Log ("{0} service did not reach Running state (current: {1})." -f $DisplayName, $svc.Status) "WARN"
            }
        } else {
            Write-Log ("{0} service is already running." -f $DisplayName)
        }
    }
    catch {
        Write-Log ("Failed to verify/start {0} service: {1}" -f $DisplayName, $_.Exception.Message) "WARN"
    }
}

function Reset-WinRMToDefaults {
    Write-Log "Resetting WinRM to OS defaults..."

    Ensure-ServiceRunning -ServiceName "WinRM" -DisplayName "Windows Remote Management" -StartupType "Manual"

    try {
        & winrm invoke restore winrm/config '@{}' | Out-Null
        Write-Log "WinRM configuration restored to OS defaults."
    }
    catch {
        Write-Log ("WinRM restore failed: {0}" -f $_.Exception.Message) "WARN"
    }

    try {
        Get-ChildItem WSMan:\LocalHost\Listener -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Log "WinRM listeners removed."
    }
    catch {
        Write-Log ("Removing WinRM listeners failed: {0}" -f $_.Exception.Message) "WARN"
    }

    try {
        Set-Service -Name WinRM -StartupType Manual -ErrorAction SilentlyContinue
        Write-Log "WinRM service StartupType set to Manual."
    }
    catch {
        Write-Log ("Failed to set WinRM StartupType: {0}" -f $_.Exception.Message) "WARN"
    }

    try {
        Stop-Service -Name WinRM -Force -ErrorAction SilentlyContinue
        Write-Log "WinRM service stopped."
    }
    catch {
        Write-Log ("Failed to stop WinRM service: {0}" -f $_.Exception.Message) "WARN"
    }

    try {
        $packerCerts = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
            Where-Object { $_.Subject -eq 'CN=packer' }

        if ($packerCerts) {
            foreach ($cert in $packerCerts) {
                Write-Log ("Removing packer certificate {0}" -f $cert.Thumbprint)
                Remove-Item -Path $cert.PSPath -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Log "No CN=packer certificate found."
        }
    }
    catch {
        Write-Log ("Packer certificate cleanup failed: {0}" -f $_.Exception.Message) "WARN"
    }

    Write-Log "WinRM reset to defaults completed."
}

Write-Log "=== Post-image WinRM reset starting ==="
try {
    Ensure-ServiceRunning -ServiceName "Winmgmt" -DisplayName "Windows Management Instrumentation" -StartupType "Manual"
    Ensure-ServiceRunning -ServiceName "WinRM" -DisplayName "Windows Remote Management (WS-Management)" -StartupType "Manual"

    Reset-WinRMToDefaults

    Write-Log "=== Post-image WinRM reset completed ==="
    exit 0
}
catch {
    Write-Log ("Post-image script FAILED: {0}" -f $_.Exception.Message) "ERROR"
    exit 1
}
