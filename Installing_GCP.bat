@echo off
setlocal

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Script requires administrator privileges. Restarting script with elevated permissions...
    powershell -Command "Start-Process '%~nx0' -Verb RunAs"
    exit /b
)

:: Check if the system is a member of a domain
wmic computersystem get domain | findstr /i /c:"WORKGROUP" >nul
if %errorlevel% equ 0 (
    echo The system is a member of a workgroup.
) else if %errorlevel% equ 1 (
    echo The system is a member of a domain.
    call :RemoveFromDomain
    if %errorlevel% equ 0 (
        echo The system has been removed from the domain.

        call :ChangeToWorkgroup
        if %errorlevel% equ 0 (
            echo The system has been moved to the new workgroup named WORKGROUP.
        ) else (
            echo An error occurred while changing the workgroup.
        )
    ) else (
        echo An error occurred while removing the system from the domain.
    )
) else (
    echo An error occurred while checking the domain/workgroup membership.
)


:: Give full path to the .exe file with time 120 seconds
call :RunInstaller "D:\jindal\BatchFile\gcpwstandaloneenterprise64(JSPL).exe" 120
if %errorlevel% equ 0 (
    echo The installation completed successfully.
    :: Proceed to the next step
    goto NextStep
) else if %errorlevel% equ 1 (
    echo The installation was aborted.
    goto NextStep
) else if %errorlevel% equ 2 (
    echo The installation timed out.
    goto NextStep
) else if %errorlevel% equ 3 (
    echo The installation was cancelled.
    goto NextStep
) else (
    echo An error occurred while running the installer.
    goto NextStep
)

exit /b

:NextStep
:: Starting the GoogleUpdate
echo Starting GoogleUpdate.exe...
start "" "C:\Program Files (x86)\Google\Update\GoogleUpdate.exe"
if %errorlevel% equ 0 (
    echo GoogleUpdate.exe started successfully.
    echo Restarting the computer...
    shutdown /r /t 0
) else (
    echo Failed to start GoogleUpdate.exe.
)

goto :eof

:IsDomainMember
exit /b

:RemoveFromDomain
wmic.exe /interactive:off ComputerSystem Where name="%computername%" call UnjoinDomainOrWorkgroup FUnjoinOptions=0
exit /b %errorlevel%

:ChangeToWorkgroup
set "username=abc"  :: Set the username as "abc"
set "password=abc"  :: Replace with desired "abc"
net user %username% %password% /add
net localgroup Administrators %username% /add
net config workstation /Workgroup:WORKGROUP
exit /b %errorlevel%

:RunInstaller
set "installerPath=%~1"vd
set "timeoutSeconds=%~2"

echo Starting %installerPath%...
echo set back for 3 minutes it will automatically do everything.
start "" "%installerPath%"
timeout /t %timeoutSeconds% >nul
tasklist /fi "IMAGENAME eq %installerPath:~3%" | findstr /i /c:"%installerPath:~3%" >nul
if %errorlevel% equ 0 (
    echo Timeout reached. Killing the process...
    taskkill /im "%installerPath:~3%" /f >nul
    exit /b 2
)

exit /b 0

:eof
