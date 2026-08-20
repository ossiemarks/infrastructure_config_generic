@echo off
setlocal
set LOG=C:\Windows\Logs\Packer\PostOOBECleanup.log
if not exist C:\Windows\Logs\Packer mkdir C:\Windows\Logs\Packer

echo [%date% %time%] Starting PostOOBECleanup.cmd >> %LOG%

echo [%date% %time%] Removing autologon registry keys >> %LOG%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v ForceAutoLogon /t REG_SZ /d 0 /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultDomainName /f

echo [%date% %time%] Removing the Temp user >> %LOG%
net user temp /delete
rmdir /s /q C:\Users\temp

echo [%date% %time%] Deleting unattend.xml >> %LOG%
if exist "C:\Windows\System32\Sysprep\unattend.xml" (
    del /f /q "C:\Windows\System32\Sysprep\unattend.xml"
)

REM ---------------------------------------------------------------------
REM Optional: disable the built-in Administrator once you have another
REM account to manage the machine with (e.g. after domain-joining).
REM ---------------------------------------------------------------------
REM net user Administrator /active:no

echo [%date% %time%] Rebooting in 5 seconds >> %LOG%
shutdown /r /t 5 /f

echo [%date% %time%] Removing PostOOBECleanup.cmd >> %LOG%
del "%~f0"

endlocal
exit /b 0
