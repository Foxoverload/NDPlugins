@echo off
title Naruto Destiny - Script Extender Installer
color 0A

echo.
echo  ===================================================
echo  =   NARUTO DESTINY - SCRIPT EXTENDER v2.0.0      =
echo  =              Instalador Automatico              =
echo  ===================================================
echo.

REM Detectar pasta do Firecast automaticamente
set "FC=%LOCALAPPDATA%\Firecast"

if not exist "%FC%" (
    echo [ERRO] Pasta do Firecast nao encontrada em:
    echo        %FC%
    echo.
    echo Certifique-se de que o Firecast esta instalado.
    echo.
    pause
    exit /b 1
)

echo [INFO] Firecast encontrado em: %FC%
echo.

REM Verificar se Firecast esta rodando
tasklist /FI "IMAGENAME eq Firecast.exe" 2>NUL | find /I /N "Firecast.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [ERRO] O Firecast esta aberto! Feche-o antes de instalar.
    echo.
    pause
    exit /b 1
)

REM Verificar arquivos necessarios
if not exist "%~dp0lua54x64.dll" (
    echo [ERRO] Arquivo lua54x64.dll nao encontrado na pasta do instalador.
    pause
    exit /b 1
)
if not exist "%~dp0fcext_ficha_nd.lua" (
    echo [ERRO] Arquivo fcext_ficha_nd.lua nao encontrado na pasta do instalador.
    pause
    exit /b 1
)
if not exist "%~dp0fcext_ui.lua" (
    echo [ERRO] Arquivo fcext_ui.lua nao encontrado na pasta do instalador.
    pause
    exit /b 1
)

echo Arquivos do Script Extender encontrados. Iniciando instalacao...
echo.

REM Backup do DLL original (se ainda nao foi feito)
if not exist "%FC%\lua54x64_original.dll" (
    if exist "%FC%\lua54x64.dll" (
        echo [1/4] Fazendo backup do DLL original...
        copy /Y "%FC%\lua54x64.dll" "%FC%\lua54x64_original.dll" >nul
        echo       Backup salvo como: lua54x64_original.dll
    ) else (
        echo [1/4] DLL original nao encontrado, pulando backup...
    )
) else (
    echo [1/4] Backup ja existe, pulando...
)

REM Instalar Proxy DLL
echo [2/4] Instalando Proxy DLL...
copy /Y "%~dp0lua54x64.dll" "%FC%\lua54x64.dll" >nul
echo       lua54x64.dll instalado.

REM Instalar scripts Lua
echo [3/4] Instalando scripts Lua...
copy /Y "%~dp0fcext_ficha_nd.lua" "%FC%\fcext_ficha_nd.lua" >nul
echo       fcext_ficha_nd.lua instalado.

echo [4/4] Instalando biblioteca UI...
copy /Y "%~dp0fcext_ui.lua" "%FC%\fcext_ui.lua" >nul
echo       fcext_ui.lua instalado.

echo.
echo  ===================================================
echo  =       INSTALACAO CONCLUIDA COM SUCESSO!         =
echo  ===================================================
echo.
echo  1. Abra o Firecast normalmente
echo  2. Abra/crie uma ficha Naruto Destiny
echo  3. Os calculos automaticos estarao ativos!
echo.
echo  Para desinstalar, execute:
echo  desinstalar_script_extender.bat
echo.
pause
