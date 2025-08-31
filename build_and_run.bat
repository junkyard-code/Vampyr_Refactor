@echo off
setlocal enabledelayedexpansion

:: Configuration
set FPC=ppc386.exe
set SOURCE_DIR=src
set BIN_DIR=bin
set BUILD_DIR=build
set SDL2_DLL=SDL2.dll

:: Create directories if they don't exist
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

:: Check if Free Pascal is in PATH
where %FPC% >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo Free Pascal Compiler (fpc) not found in PATH.
    echo Please install Free Pascal or add it to your PATH.
    pause
    exit /b 1
)

echo === Building Vampyr World ===

:: Build command
%FPC% -B -Mobjfpc -Sd -Sh -O2 -v0 ^
  -Fu%SOURCE_DIR% ^
  -FE%BIN_DIR% ^
  -FU%BUILD_DIR% ^
  -k"-lSDL2" ^
  %SOURCE_DIR%\main.pas

if !ERRORLEVEL! NEQ 0 (
    echo Build failed with error !ERRORLEVEL!
    pause
    exit /b !ERRORLEVEL!
)

echo.
echo === Copying required files ===

:: Check if SDL2.dll exists in the project directory
if exist "%SDL2_DLL%" (
    copy /Y "%SDL2_DLL%" "%BIN_DIR%\" >nul
    echo Copied %SDL2_DLL% to %BIN_DIR%
) else (
    echo Warning: %SDL2_DLL% not found in project directory.
    echo Please ensure SDL2.dll is in your system PATH or in the %BIN_DIR% directory.
)

echo.
echo === Running Vampyr World ===

cd "%BIN_DIR%"
start "" "vampyr_world_v7.exe"

endlocal
