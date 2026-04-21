@echo off
chcp 65001 >nul 2>&1
title Naruto Destiny - Script Extender Desinstalador
color 0C

echo.
echo  ╔══════════════════════════════════════════════════╗
echo  ║   🍥 NARUTO DESTINY - SCRIPT EXTENDER v2.0.0   ║
echo  ║            Desinstalador Automatico             ║
echo  ╚══════════════════════════════════════════════════╝
echo.

set "FC=%LOCALAPPDATA%\Firecast"

if not exist "%FC%" (
    echo [ERRO] Pasta do Firecast nao encontrada.
    pause
    exit /b 1
)

REM Verificar se Firecast esta rodando
tasklist /FI "IMAGENAME eq Firecast.exe" 2>NUL | find /I /N "Firecast.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [ERRO] O Firecast esta aberto! Feche-o antes de desinstalar.
    pause
    exit /b 1
)

echo [1/3] Removendo scripts Lua...
if exist "%FC%\fcext_ficha_nd.lua" del /F "%FC%\fcext_ficha_nd.lua"
if exist "%FC%\fcext_ui.lua" del /F "%FC%\fcext_ui.lua"
echo       Scripts removidos.

echo [2/3] Restaurando DLL original...
if exist "%FC%\lua54x64_original.dll" (
    copy /Y "%FC%\lua54x64_original.dll" "%FC%\lua54x64.dll" >nul
    del /F "%FC%\lua54x64_original.dll"
    echo       DLL original restaurado.
) else (
    echo       Backup nao encontrado. Remova lua54x64.dll manualmente se necessario.
)

echo [3/3] Limpando logs...
if exist "%FC%\fcext_log.txt" del /F "%FC%\fcext_log.txt"
echo       Limpo.

echo.
echo  ╔══════════════════════════════════════════════════╗
echo  ║      ✅ DESINSTALACAO CONCLUIDA COM SUCESSO!     ║
echo  ║                                                  ║
echo  ║  O Firecast voltou ao estado original.           ║
echo  ║  A ficha ND continuara funcionando sem FCEXT.    ║
echo  ╚══════════════════════════════════════════════════╝
echo.
pause
