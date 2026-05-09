@echo off
chcp 65001 >nul
echo =============================================
echo  ND Fichas - Compressor para IA Narradora
echo  Converte fichas HTML em formato compacto
echo =============================================
echo.

:: Configuração - ajuste o caminho das fichas exportadas
set "FICHAS_DIR=%USERPROFILE%\Desktop\Fichas e BG"
set "FICHAS_DIR2=%USERPROFILE%\Desktop"
set "OUTPUT=%USERPROFILE%\Desktop\ND_FICHAS_JOGADORES_PARA_IA.txt"

:: Chamar o PowerShell para fazer o trabalho pesado
powershell -ExecutionPolicy Bypass -File "%~dp0comprimir_fichas.ps1" -FichasDir1 "%FICHAS_DIR%" -FichasDir2 "%FICHAS_DIR2%" -Output "%OUTPUT%"

echo.
echo Arquivo gerado: %OUTPUT%
echo Suba este arquivo como Knowledge no ChatGPT/Gemini/NotebookLM
echo.
pause
