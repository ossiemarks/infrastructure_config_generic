@echo off
setlocal

set LOG=C:\Windows\Logs\Packer\setupcomplete.log
if not exist C:\Windows\Logs\Packer mkdir C:\Windows\Logs\Packer

echo [%date% %time%] Starting SetupComplete.cmd >> %LOG%

echo [%date% %time%] Running postImage-winrm-reset.ps1 >> %LOG%
powershell.exe -ExecutionPolicy Bypass -File "C:\Windows\Setup\Scripts\postImage-winrm-reset.ps1"

if exist "C:\Windows\Setup\Scripts\postImage-winrm-reset.ps1" (
    echo [%date% %time%] Removing postImage-winrm-reset.ps1 >> %LOG%
    del /f /q "C:\Windows\Setup\Scripts\postImage-winrm-reset.ps1"
)

REM ---------------------------------------------------------------------
REM BitLocker prevention key is set during install (see Autounattend.xml)
REM so the build VM's disk never gets auto-encrypted mid-build. Uncomment
REM the line below if you want deployed VMs to allow BitLocker again.
REM ---------------------------------------------------------------------
REM reg delete "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /f

echo [%date% %time%] Removing SetupComplete.cmd >> %LOG%
del /f /q "%~f0"

endlocal
exit /b 0
