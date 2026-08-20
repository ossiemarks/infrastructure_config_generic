<?xml version="1.0" encoding="utf-8"?>
<!--
  Dropped into C:\Windows\System32\Sysprep\unattend.xml during the build.
  This is NOT used during the base-image build itself - it's the answer
  file sysprep leaves behind so that every VM cloned from the resulting
  template runs its own OOBE pass on first boot: random computer name,
  a temporary local account for interactive access, and a RunOnce cleanup
  (postoobecleanup.cmd) that removes the autologon and this file.
-->
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>${locale}</InputLocale>
            <SystemLocale>${locale}</SystemLocale>
            <UILanguage>${locale}</UILanguage>
            <UILanguageFallback>${locale}</UILanguageFallback>
            <UserLocale>${locale}</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <UnattendEnableRetailDemo>false</UnattendEnableRetailDemo>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>${admin_password}</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>${admin_password}</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Description>Temporary Account</Description>
                        <DisplayName>Temp</DisplayName>
                        <Group>Users</Group>
                        <Name>Temp</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <RegisteredOrganization></RegisteredOrganization>
            <RegisteredOwner></RegisteredOwner>
            <TimeZone>${timezone}</TimeZone>
            <AutoLogon>
                <Password>
                    <Value>${admin_password}</Value>
                    <PlainText>true</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <LogonCount>1</LogonCount>
                <Username>Administrator</Username>
            </AutoLogon>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Path>cmd.exe /c reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE /f</Path>
                    <Order>1</Order>
                    <Description>Create OOBE policy key</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Path>cmd.exe /c reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE /v DisablePrivacyExperience /t REG_DWORD /d 1 /f</Path>
                    <Order>2</Order>
                    <Description>Disable Privacy Experience (Policy)</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Path>cmd.exe /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /f</Path>
                    <Order>3</Order>
                    <Description>Create OOBE registry key</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Path>cmd.exe /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v DisablePrivacyExperience /t REG_DWORD /d 1 /f</Path>
                    <Order>4</Order>
                    <Description>Disable Privacy Experience</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Path>cmd.exe /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v PrivacyConsentStatus /t REG_DWORD /d 1 /f</Path>
                    <Order>5</Order>
                    <Description>Set Privacy Consent Status</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Path>cmd.exe /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v ProtectYourPC /t REG_DWORD /d 3 /f</Path>
                    <Order>6</Order>
                    <Description>Set ProtectYourPC level</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Path>cmd.exe /c net user Administrator /active:yes</Path>
                    <Order>7</Order>
                    <Description>Enable built-in Administrator</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Description>Run cleanup after OOBE completes</Description>
                    <Path>cmd.exe /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v PostOOBECleanup /t REG_SZ /d &quot;cmd.exe /c C:\Windows\Setup\Scripts\postoobecleanup.cmd&quot; /f</Path>
                    <Order>8</Order>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>*</ComputerName>
        </component>
    </settings>
</unattend>
