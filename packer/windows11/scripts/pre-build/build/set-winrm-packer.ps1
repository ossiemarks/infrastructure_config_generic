<#
.SYNOPSIS
Configures WinRM over HTTPS with a self-signed certificate so Packer can connect.

.DESCRIPTION
Removes any existing WinRM listeners, creates a self-signed certificate,
stands up a new HTTPS listener (5986), relaxes auth/encryption settings for
the build only, and opens the firewall to the local subnet. This is
intentionally permissive - it is undone by postImage-winrm-reset.ps1 before
the template is sealed with sysprep.

Logging location: C:\Build\Logs\winrm-packer.log
#>

$ErrorActionPreference = "Stop"

$LogDir = "C:\Build\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir "winrm-packer.log"

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

Write-Log "Running WinRM setup for Packer."

try {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Log "Script must be run as Administrator. Aborting." "ERROR"
        exit 1
    }
    Write-Log "Running with elevated privileges."
}
catch {
    Write-Log "Elevation check failed: $_" "ERROR"
    exit 1
}

try {
    Write-Log "Removing existing WinRM listeners..."
    $existingListeners = Get-ChildItem WSMan:\LocalHost\Listener -ErrorAction SilentlyContinue
    if ($existingListeners) {
        $existingListeners | Remove-Item -Recurse -Force
        Write-Log "Existing listeners removed."
    } else {
        Write-Log "No existing listeners found."
    }
}
catch {
    Write-Log "Failed to remove listeners: $_" "ERROR"
    exit 1
}

try {
    Write-Log "Creating new self-signed certificate for WinRM..."
    $cert = New-SelfSignedCertificate -DnsName "packer" -CertStoreLocation "Cert:\LocalMachine\My"
    Write-Log "Certificate created: $($cert.Thumbprint)"
}
catch {
    Write-Log "Failed to create certificate: $_" "ERROR"
    exit 1
}

try {
    Write-Log "Creating WinRM HTTPS listener..."
    New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * `
        -CertificateThumbprint $cert.Thumbprint -Force
    Write-Log "HTTPS listener created."
}
catch {
    Write-Log "Failed to create HTTPS listener: $_" "ERROR"
    exit 1
}

try {
    Write-Log "Configuring WinRM service..."
    if ((Get-Service WinRM).Status -ne "Running") {
        Set-Service -Name WinRM -StartupType Automatic
        Start-Service -Name WinRM
        Write-Log "WinRM started."
    } else {
        Write-Log "WinRM already running."
    }
}
catch {
    Write-Log "Failed to configure WinRM service: $_" "ERROR"
    exit 1
}

try {
    $build = [System.Environment]::OSVersion.Version.Build
    Write-Log "Detected OS build number: $build"

    Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
    Set-Item WSMan:\localhost\Client\AllowUnencrypted -Value $true
    Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
    Set-Item WSMan:\localhost\Client\Auth\Basic -Value $true
    Set-Item WSMan:\localhost\Service\Auth\CredSSP -Value $true
    Set-Item WSMan:\localhost\MaxTimeoutms -Value 1800000

    Write-Log "WinRM settings applied."
}
catch {
    Write-Log "Failed applying WinRM configuration: $_" "ERROR"
    exit 1
}

try {
    Write-Log "Checking firewall rule for WinRM 5986..."
    if (-not (Get-NetFirewallRule -DisplayName "WinRM HTTPS-In" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "WinRM HTTPS-In" -Direction Inbound -Action Allow `
            -Protocol TCP -LocalPort 5986 -Program "SYSTEM" -RemoteAddress "LocalSubnet"
        Write-Log "Firewall rule created."
    } else {
        Write-Log "Firewall rule already exists."
    }
}
catch {
    Write-Log "Failed to configure firewall: $_" "ERROR"
    exit 1
}

try {
    Write-Log "Restarting WinRM service..."
    Restart-Service WinRM -Force
    Write-Log "WinRM restarted successfully."
}
catch {
    Write-Log "Failed to restart WinRM: $_" "ERROR"
    exit 1
}

Write-Log "WinRM setup for Packer completed successfully."
