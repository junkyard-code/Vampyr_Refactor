@echo off
setlocal ENABLEDELAYEDEXPANSION
set FPC="C:\Program Files\Free Pascal\bin\i386-Win32\ppc386.exe"
if not exist %FPC% set FPC=ppc386.exe

echo === Building Vampyr World Viewer v7.6.3 ===
if not exist "build" mkdir "build"
%FPC% -B -WC -S2 -O2 -Mobjfpc -Fu"src" -Fu"SDL2-for-Pascal-2.3-stable\units" -FE"bin" -FU"build" -o"bin\vampyr_world_viewer.exe" src\main.pas
if errorlevel 1 (
  echo Build FAILED
  exit /b 1
)
echo Build SUCCEEDED
echo.
echo Put a 32-bit SDL2.dll into ".\bin\" and your data into ".\bin\data\"
exit /b 0
