@echo off
echo === FCEXT Uninstaller ===
echo.
set FC=C:\Users\aaron\AppData\Local\Firecast

REM Check Firecast not running
tasklist /FI "IMAGENAME eq Firecast.exe" 2>NUL | find /I /N "Firecast.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo ERROR: Feche o Firecast antes de desinstalar!
    pause
    exit /b 1
)

if not exist "%FC%\lua54x64_original.dll" (
    echo ERROR: Backup nao encontrado. Nada para restaurar.
    pause
    exit /b 1
)

echo Restaurando DLL original...
copy /Y "%FC%\lua54x64_original.dll" "%FC%\lua54x64.dll"

echo.
echo === DESINSTALADO COM SUCESSO ===
echo Firecast restaurado ao estado original.
pause
