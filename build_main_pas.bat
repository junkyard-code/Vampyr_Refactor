@echo off
setlocal ENABLEDELAYEDEXPANSION

:: Configuration
set FPC="C:\Program Files\Free Pascal\bin\i386-Win32\ppc386.exe"
if not exist %FPC% set FPC=ppc386.exe

set SOURCE_DIR=src
set BUILD_DIR=build
set BIN_DIR=bin
set SDL2_DIR=lib

:: Create directories
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

echo === Building Vampyr World Viewer ===

:: Build command
%FPC% -B -WC -S2 -O2 -Mobjfpc ^
  -Fu"%SOURCE_DIR%" ^
  -Fu"resources\SDL2-for-Pascal-2.3-stable\units" ^
  -FE"%BIN_DIR%" ^
  -FU"%BUILD_DIR%" ^
  -o"%BIN_DIR%\vampyr_world_viewer.exe" ^
  %SOURCE_DIR%\main.pas

if errorlevel 1 (
  echo Build FAILED
  exit /b 1
)

echo.
echo Build SUCCEEDED
echo.
echo Copy SDL2.dll to %BIN_DIR%\SDL2.dll
echo Place game data in %BIN_DIR%\data\

exit /b 0
