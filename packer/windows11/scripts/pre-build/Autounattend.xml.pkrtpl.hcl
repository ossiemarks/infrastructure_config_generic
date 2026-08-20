<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <servicing></servicing>
    <!-- 1. windowsPE: disk layout, language, EULA, product key -->
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>${locale}</InputLocale>
            <SystemLocale>${locale}</SystemLocale>
            <UILanguage>${locale}</UILanguage>
            <UILanguageFallback>${locale}</UILanguageFallback>
            <UserLocale>${locale}</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <!-- UEFI disk layout, full wipe of disk 0 -->
            <ImageInstall>
                <OSImage>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/INDEX</Key>
                            <Value>${windows_image_index}</Value>
                        </MetaData>
                    </InstallFrom>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>3</PartitionID>
                    </InstallTo>
                    <WillShowUI>OnError</WillShowUI>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
                <FullName></FullName>
                <Organization></Organization>
                <ProductKey>
                    <Key>${product_key}</Key>
                    <WillShowUI>OnError</WillShowUI>
                </ProductKey>
            </UserData>
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Size>200</Size>
                            <Type>EFI</Type>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Size>16</Size>
                            <Type>MSR</Type>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>3</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Format>FAT32</Format>
                            <Label>SYSTEM</Label>
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Format>NTFS</Format>
                            <Label>Windows</Label>
                            <Letter>C</Letter>
                            <Order>2</Order>
                            <PartitionID>3</PartitionID>
                        </ModifyPartition>
                    </ModifyPartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
                <WillShowUI>OnError</WillShowUI>
            </DiskConfiguration>
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
                    <Path>powershell.exe -NoProfile -Command &quot;Copy-Item (Join-Path (Get-CimInstance Win32_Volume -Filter \&quot;Label=&apos;cidata&apos;\&quot;).DriveLetter \&quot;build\&quot;) C:\build -Recurse -Force -ErrorAction SilentlyContinue&quot;</Path>
                    <Order>7</Order>
                    <Description>Copy the build scripts to C:\build</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Path>cmd.exe /c reg add HKLM\SYSTEM\CurrentControlSet\Control\BitLocker /v PreventDeviceEncryption /t REG_DWORD /d 1 /f</Path>
                    <Order>8</Order>
                    <Description>Disable automatic device encryption</Description>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>${locale}</InputLocale>
            <SystemLocale>${locale}</SystemLocale>
            <UILanguage>${locale}</UILanguage>
            <UILanguageFallback>${locale}</UILanguageFallback>
            <UserLocale>${locale}</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <!--
              NOTE: PlainText is used here (instead of Microsoft's base64 "obfuscation")
              because it templates cleanly and offers no real secrecy either way - the
              base64 encoding is trivially reversible. This file only ever exists inside
              the generated build-time CD, which Packer uploads to Proxmox and unmounts
              once install completes.
            -->
            <AutoLogon>
                <Password>
                    <Value>${admin_password}</Value>
                    <PlainText>true</PlainText>
                </Password>
                <LogonCount>1</LogonCount>
                <Enabled>true</Enabled>
                <Username>administrator</Username>
            </AutoLogon>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <UnattendEnableRetailDemo>false</UnattendEnableRetailDemo>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>${admin_password}</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <RegisteredOrganization></RegisteredOrganization>
            <RegisteredOwner></RegisteredOwner>
            <TimeZone>${timezone}</TimeZone>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                    <CommandLine>powershell -ExecutionPolicy Bypass -File C:\build\lock-screen.ps1</CommandLine>
                    <Description>Lock the screen</Description>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <CommandLine>powershell -ExecutionPolicy Bypass -File C:\build\set-winrm-packer.ps1</CommandLine>
                    <Description>Configure WinRM for Packer</Description>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <CommandLine>powershell -ExecutionPolicy Bypass -File C:\build\start-virtio-install.ps1 -VolumeLabelPattern "${virtio_volume_label_pattern}"</CommandLine>
                    <Description>Install the VirtIO guest tools</Description>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
