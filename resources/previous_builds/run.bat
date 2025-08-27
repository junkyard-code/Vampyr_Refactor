@echo off
setlocal
set BIN=%~dp0bin
if not exist "%BIN%\vampyr_world_viewer.exe" (
  echo Build first by running build.bat
  exit /b 1
)
set PATH=%BIN%;%PATH%
pushd "%BIN%"
vampyr_world_viewer.exe
popd
