@echo off
setlocal

:: Set paths
set FPC=fpc
set SOURCE=src\main.pas
set BIN_DIR=bin
set SDL2_DLL=bin\SDL2.dll

:: Create bin directory if it doesn't exist
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: Check if SDL2.dll exists in bin directory
if not exist "%SDL2_DLL%" (
    echo Error: SDL2.dll not found in %BIN_DIR%
    echo Please copy SDL2.dll to the %BIN_DIR% directory
    pause
    exit /b 1
)

echo === Compiling Vampyr World ===

:: Compile the program
%FPC% -Mdelphi -Sd -Sh -O2 -v0 \
  -Fusrc \
  -FE%BIN_DIR% \
  -k"-L%CD%\bin -lSDL2" \
  %SOURCE%

if %ERRORLEVEL% NEQ 0 (
    echo Build failed with error %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo === Build successful! ===
echo Run %BIN_DIR%\vampyr_world_v7.exe to start the game.

endlocal
