@echo off
chcp 65001 >nul

cd /d "%~dp0"
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] THIS SCRIPT WAS RUNNED AS ADMIN.
) else (
    echo [ERROR] RUN THIS SCRIPT AS ADMIN.
    pause
    exit
)
echo.

echo ==================================================
echo AUTOMATIC REGISTRY AND SYSTEM MAINTENANCE (SYSTEM)
echo ==================================================
echo [INFO] The script will run automatically in 10 seconds.
echo If you want to cancel the operation, press 'N'.
echo.

set "PRVNI_VOLBA=A"
timeout /t 10 /nobreak >nul
if exist "%temp%\choice_trick.txt" del "%temp%\choice_trick.txt"

set /p "PRVNI_VOLBA=Do you want to run system maintenance and an audit now? [Y/N] (Default: Y): "
if /i "%PRVNI_VOLBA%"=="N" (
    echo [INFO] The operation was cancelled by the user.
    timeout /t 2 >nul
    exit
)
echo.

echo ==================================================
echo   SELECT OPERATION MODE
echo ==================================================
echo [1] Security Audit Only (Recommended)
echo [2] Run Audit + Safe Surgical Recovery
echo ==================================================
echo [INFO] Waiting 10s for the choice.... (Default: 1)...
echo.

set "REZIM=1"
set /p "REZIM_INPUT=Enter the selection number. (1 or 2): "
if "%REZIM_INPUT%"=="2" set "REZIM=2"

set "LOGFILE=%USERPROFILE%\Desktop\Registry_Audit.txt"

echo ================================================== > "%LOGFILE%"
echo SECURITY AUDIT AND REGISTRY RECOVERY >> "%LOGFILE%"
echo Date and time: %DATE% %TIME% >> "%LOGFILE%"
if "%REZIM%"=="2" (echo MODE: SURGICAL RECOVERY MODE ENABLED >> "%LOGFILE%")
echo ================================================== >> "%LOGFILE%"
echo.

echo === 1/3 Running DISM RestoreHealth ===
dism /online /cleanup-image /restorehealth
echo.

echo === 2/3 Running SFC Scannow ===
sfc /scannow
echo.

echo === 3/3 Performing an audit of critical registers and systems (READ-ONLY). ===
echo. >> "%LOGFILE%"
echo "IMAGE FILE EXECUTION OPTIONS & SILENT PROCESS EXIT (64bit a 32bit)" >> "%LOGFILE%"
echo ------------------------------------------------------------------ >> "%LOGFILE%"
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" /s >> "%LOGFILE%" 2>&1
reg query "HKLM\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" /s >> "%LOGFILE%" 2>&1
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SilentProcessExit" /s >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"
echo WINLOGON (SHELL AND USERINIT - 64bit and 32bit) >> "%LOGFILE%"
echo ----------------------------------------------- >> "%LOGFILE%"
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell >> "%LOGFILE%" 2>&1
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Userinit >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"
echo Automatic Startup (Run and RunOnce Keys) >> "%LOGFILE%"
echo ------------------------------------- >> "%LOGFILE%"
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" >> "%LOGFILE%" 2>&1
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"
echo USER SHELL FOLDERS (STARTUP HIJACKING) >> "%LOGFILE%"
echo -------------------------------------- >> "%LOGFILE%"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /s >> "%LOGFILE%" 2>&1
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /s >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"
echo SYSTEM SERVICES (SERVICES - IMAGEPATH) >> "%LOGFILE%"
echo ------------------------------------------- >> "%LOGFILE%"
reg query "HKLM\System\CurrentControlSet\Services" /s /v ImagePath >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"
echo MODULE 1: SUSPICIOUS BEZICI PROCESSES FROM APPDATA >> "%LOGFILE%"
echo ------------------------------------------- >> "%LOGFILE%"
wmic process get Name,ExecutablePath 2>nul | findstr /i "AppData" | findstr /i /v "Temp" >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"
echo NEW MODULE: CRITICAL RISK - BEZIC PROCESSES FROM TEMPORARY COMPONENT TEMP >> "%LOGFILE%"
echo ------------------------------------------------------------------ >> "%LOGFILE%"
wmic process get Name,ExecutablePath 2>nul | findstr /i "AppData\Local\Temp" >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"
echo MODULE 2: CHECK NON-MICROSOFT SCHEDULED JOBS >> "%LOGFILE%"
echo ---------------------------------------------------- >> "%LOGFILE%"
schtasks /query /fo LIST /v 2>nul | findstr /i /v "Microsoft" | findstr /i "TaskName Author TaskToRun" >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"

echo MODULE 3: AUDITING NON-MICROSOFT DRIVERS (DRIVERQUERY) >> "%LOGFILE%"
echo -------------------------------------------------------- >> "%LOGFILE%"
driverquery /v /fo LIST 2>nul | findstr /i /v "Microsoft" | findstr /i "Module Display Name Name Link Date Driver Type" >> "%LOGFILE%" 2>&1
echo. >> "%LOGFILE%"

echo HOSTS File Integrity Check >> "%LOGFILE%"
echo -------------------------------- >> "%LOGFILE%"
type "%WinDir%\System32\drivers\etc\hosts" >> "%LOGFILE%" 2>&1

if "%REZIM%"=="2" (
    echo.
    echo === WINLOGON AND SYSTEM SAFE RECOVERY STARTED ===
    mkdir "%USERPROFILE%\Desktop\Registry_Backup" >nul 2>&1
    reg export "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" "%USERPROFILE%\Desktop\Registry_Backup\Winlogon_Backup.reg" /y >nul 2>&1
    reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" "%USERPROFILE%\Desktop\Registry_Backup\DefenderPolicies_Backup.reg" /y >nul 2>&1
    echo. >> "%LOGFILE%"
    echo ================================================== >> "%LOGFILE%"
    echo   SURGICAL RECOVERY LOG PROTOCOL                   >> "%LOGFILE%"
    echo ================================================== >> "%LOGFILE%"
    echo [*] Resetting Winlogon to factory defaults...
    reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe" /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Userinit /t REG_SZ /d "C:\Windows\system32\userinit.exe," /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe" /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Userinit /t REG_SZ /d "C:\Windows\system32\userinit.exe," /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d "0" /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoRestartShell /t REG_DWORD /d 1 /f >> "%LOGFILE%" 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DisableCAD /f >nul 2>&1
    echo [*] Repairing the low-level association of binaries (.exe, .com, .pif)...
    reg add "HKLM\SOFTWARE\Classes\.exe" /ve /t REG_SZ /d "exefile" /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\SOFTWARE\Classes\exefile\shell\open\command" /ve /t REG_SZ /d "\"%%1\" %%*" /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\SOFTWARE\Classes\exefile\shell\runas\command" /ve /t REG_SZ /d "\"%%1\" %%*" /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\SOFTWARE\Classes\comfile\shell\open\command" /ve /t REG_SZ /d "\"%%1\" %%*" /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\SOFTWARE\Classes\piffile\shell\open\command" /ve /t REG_SZ /d "\"%%1\" %%*" /f >> "%LOGFILE%" 2>&1
    echo [*] Removing hacker trolling (Scancode Map, SwapButtons)...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /t REG_SZ /d "" /f >> "%LOGFILE%" 2>&1
    reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /t REG_SZ /d "" /f >> "%LOGFILE%" 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v SwapMouseButtons /t REG_SZ /d "0" /f >> "%LOGFILE%" 2>&1
    reg add "HKCU\Control Panel\Desktop" /v AutoColorization /t REG_DWORD /d 1 /f >> "%LOGFILE%" 2>&1
    echo [*] Deleting the harmful IFEO transcript...
    reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\cmd.exe" /f >nul 2>&1
    reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\regedit.exe" /f >nul 2>&1
    reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /f >nul 2>&1
    reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\cmd.exe" /f >nul 2>&1
    reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\regedit.exe" /f >nul 2>&1
    reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /f >nul 2>&1
    echo [*] Enabling the display of file extensions and hidden data (SHOWALL)...
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL" /v CheckedValue /t REG_DWORD /d 1 /f >> "%LOGFILE%" 2>&1
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1

echo [] Resetting the Defender and Firewall policies to their default states...
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows Defender /v DisableAntiSpyware /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows Defender /v DisableRealtimeMonitoring /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection /v DisableRealtimeMonitoring /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection /v DisableBehaviorMonitoring /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection /v DisableOnAccessProtection /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection /v DisableIOAVProtection /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile /v EnableFirewall /t REG_DWORD /d 1 /f >> "%LOGFILE%" 2>&1
reg add HKLM\SYSTEM\CurrentControlSet\Services\WinDefend /v Start /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1

echo [] Resetting the Windows Firewall to factory settings and turning it on...
netsh advfirewall reset >> "%LOGFILE%" 2>&1
netsh advfirewall set allprofiles state on >> "%LOGFILE%" 2>&1

echo [] Reviving the Windows Update services and clearing the cache...
net stop wuauserv >> "%LOGFILE%" 2>&1
net stop bits >> "%LOGFILE%" 2>&1
rd /s /q %windir%\SoftwareDistribution\Download >> "%LOGFILE%" 2>&1
net start wuauserv >> "%LOGFILE%" 2>&1
net start bits >> "%LOGFILE%" 2>&1

sc config WinDefend start= auto >> "%LOGFILE%" 2>&1
sc start WinDefend >> "%LOGFILE%" 2>&1
sc config SecurityHealthService start= auto >> "%LOGFILE%" 2>&1
sc start SecurityHealthService >> "%LOGFILE%" 2>&1

RD /S /Q %WinDir%\System32\GroupPolicyUsers >> "%LOGFILE%" 2>&1
RD /S /Q %WinDir%\System32\GroupPolicy >> "%LOGFILE%" 2>&1
gpupdate /force >> "%LOGFILE%" 2>&1

reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer /v SmartScreenEnabled /t REG_SZ /d RequireAdmin /f
reg add HKLM\SYSTEM\CurrentControlSet\Services\wscsvc /v Start /t REG_DWORD /d 2 /f

echo [OK] Safe recovery, network restoration, and updates—including Defender—have been completed.

echo [] Resetting network providers to factory order (NetworkProvider)...
reg add HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order /v ProviderOrder /t REG_SZ /d RDPNP,LanmanWorkstation,webclient /f >> "%LOGFILE%" 2>&1

echo [] Cleaning up hidden persistence in the Internet Explorer registry and BHOs....
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\Browser Helper Objects /f >nul 2>&1
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\Browser Helper Objects /f >> "%LOGFILE%" 2>&1
reg delete HKLM\SOFTWARE\Microsoft\Internet Explorer\Extensions /f >nul 2>&1
reg add HKLM\SOFTWARE\Microsoft\Internet Explorer\Extensions /f >> "%LOGFILE%" 2>&1

echo [] Resetting LSA authentication and security packages to default (Lsa)...
reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Security Packages" /t REG_MULTI_SZ /d kerberos\0msv1_0\0schannel\0wdigest\0tspkg\0pku2u /f >> "%LOGFILE%" 2>&1
reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Notification Packages" /t REG_MULTI_SZ /d scecli /f >> "%LOGFILE%" 2>&1
reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" /t REG_MULTI_SZ /d msv1_0 /f >> "%LOGFILE%" 2>&1

echo [] Removing and cleaning Winlogon system notification modules...
reg delete HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify /f >nul 2>&1
reg add HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify /f >> "%LOGFILE%" 2>&1
reg delete HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon /v Taskman /f >nul 2>&1
reg delete HKCU\Software\Microsoft\Windows NT\CurrentVersion\Winlogon /v Shell /f >nul 2>&1

echo [] Removing hidden startup entries via Active Setup....
for /f "tokens=*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components" 2^>nul') do (
    echo %%A | findstr /i "{" >nul
    if errorlevel 1 (
        reg delete "%%A" /f >nul 2>&1
    )
)

echo [] Blocking the exploitation of FastProx COM hijacking...
reg add HKLM\SOFTWARE\Microsoft\COM3\FastProx /ve /t REG_SZ /d %%SystemRoot%%\system32\wbem\fastprox.dll /f >> "%LOGFILE%" 2>&1

echo [] Cleaning specific malware CLSID entries in the user profile...
reg delete HKCU\Software\Classes\CLSID\{42aedc87-2188-41fd-b9a3-0c966feabec1} /f >nul 2>&1
reg delete HKCU\Software\Classes\CLSID\{F04A1B42-8D39-4aa1-8591-9E2FA5466456} /f >nul 2>&1

echo [] Starting complete repair of boot (in case of a bootloader error/malicious change)(BCDBOOT)...
bcdboot %SystemRoot% /l cs-CZ /f ALL >> "%LOGFILE%" 2>&1

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableLockWorkstation /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoLogoff /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableChangePassword /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1

echo [] Restoring system policies and UAC settings, and unlocking program execution (NoRun, CMD, Regedit, TaskMgr)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v shutdownwithoutlogon /t REG_DWORD /d 1 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v UseDefaultTile /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v DisableLogonBackgroundImage /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v DisableCMD /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\System" /v DisableCMD /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg delete "HKCU\Software\Classes\ms-settings" /f >nul 2>&1
)

echo.
echo === (Almost) Done! ===
echo All repairs successfully finished. You can check the log file at:
echo %LOGFILE%
echo.

echo ====================================================================
echo EXTENDED TOOLBAR (you can pick multiple choices at once) 
echo ====================================================================
echo Example for running more repairs at once: 1 2 5 or 1,3
echo ====================================================================
echo [1] Complete repair of the internet connection (Reset internet connection)
echo [2] Repairing broken icons (Reset Icon Cache)
echo [3] Reregistering system dlls to fix dll errors
echo [4] Repairing the Start menu and Settings (UWP Apps)
echo [5] Scheduling disk repair on restart (Chkdsk)
echo [6] Do nothing (Terminate this process)
echo ====================================================================
set /p TOOLCHOICE=Choose 1 or more options (e.g. 1,3 or 1 2 5): 

set TOOLCHOICE=%TOOLCHOICE:,= %

setlocal enabledelayedexpansion
for %%G in (%TOOLCHOICE%) do (
    if "%%G"=="1" (
        echo [] Attempting to repair internet connection...
        ipconfig /flushdns >> "%LOGFILE%" 2>&1
        ipconfig /registerdns >> "%LOGFILE%" 2>&1
        ipconfig /release >> "%LOGFILE%" 2>&1
        ipconfig /renew >> "%LOGFILE%" 2>&1
        netsh int ip reset >> "%LOGFILE%" 2>&1
        netsh winsock reset >> "%LOGFILE%" 2>&1
    )
    if "%%G"=="2" (
        echo [] Reseting icon cache (iconcache.db and thumbcache.db).
        taskkill /f /im explorer.exe >nul 2>&1
        ie4uinit.exe -show >nul 2>&1
        del /f /q "%localappdata%\IconCache.db" >nul 2>&1
        del /f /q "%localappdata%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1
        del /f /q "%localappdata%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
        start explorer.exe
    )
    if "%%G"=="3" (
        echo [] Reregistering system dlls (this will probably take a while)...
        for %%i in (%windir%\system32\*.dll) do regsvr32.exe /s "%%i"
        for %%i in (%windir%\syswow64\*.dll) do regsvr32.exe /s "%%i"
    )
    if "%%G"=="4" (
        echo [] Reregistering system apps...
        PowerShell -ExecutionPolicy Bypass -Command "Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register '$($_.InstallLocation)\AppXManifest.xml'}" >> "%LOGFILE%" 2>&1
    )
    if "%%G"=="5" (
        echo [] Scheduling chkdsk on restart...
        echo Y | chkdsk C: /f /r /x >> "%LOGFILE%" 2>&1
    )
    if "%%G"=="6" (
        echo [INFO] Exit selected without further actions.
    )
)

echo.
echo [RECOMMENDATION] A SYSTEM REBOOT is highly recommended after completing these fixes.
echo Press any key to close this window...
pause >nul