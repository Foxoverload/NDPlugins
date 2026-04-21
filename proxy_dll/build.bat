@echo off
echo === FCEXT Build Script ===
echo.

where zig >nul 2>&1
if errorlevel 1 (
    echo ERROR: zig not found. Install with: winget install zig.zig
    pause
    exit /b 1
)

echo Compiling proxy DLL...
zig cc -shared -target x86_64-windows-gnu -o lua54x64.dll lua54x64_proxy.c lua54x64.def -lkernel32 -luser32 -ladvapi32 -O2

if errorlevel 1 (
    echo.
    echo BUILD FAILED!
    pause
    exit /b 1
)

echo.
echo BUILD SUCCESS: lua54x64.dll created
echo Size: 
dir lua54x64.dll | findstr lua54x64
echo.
echo Run install.bat to install the proxy.
pause
