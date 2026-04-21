@echo off
echo === FCEXT Installer ===
echo.
set FC=C:\Users\aaron\AppData\Local\Firecast

REM Check Firecast not running
tasklist /FI "IMAGENAME eq Firecast.exe" 2>NUL | find /I /N "Firecast.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo ERROR: Feche o Firecast antes de instalar!
    pause
    exit /b 1
)

REM Check proxy DLL exists
if not exist "lua54x64.dll" (
    echo ERROR: lua54x64.dll proxy nao encontrada. Execute build.bat primeiro.
    pause
    exit /b 1
)

REM Backup original if not already done
if not exist "%FC%\lua54x64_original.dll" (
    echo Fazendo backup: lua54x64.dll -^> lua54x64_original.dll
    copy "%FC%\lua54x64.dll" "%FC%\lua54x64_original.dll"
) else (
    echo Backup ja existe: lua54x64_original.dll
)

REM Install proxy
echo Instalando proxy DLL...
copy /Y "lua54x64.dll" "%FC%\lua54x64.dll"

echo.
echo === INSTALADO COM SUCESSO ===
echo Abra o Firecast normalmente. O modulo fcext estara disponivel.
echo Verifique o log em: %FC%\fcext_log.txt
echo.
echo Para desinstalar, execute uninstall.bat
pause
