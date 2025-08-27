@echo off
echo Setting up SDL2 dependencies...

:: Create lib directory if it doesn't exist
if not exist "lib" mkdir lib

:: Check if SDL2.dll exists in bin
if not exist "bin\SDL2.dll" (
    echo Warning: SDL2.dll not found in bin\ directory.
    echo Please download SDL2 development libraries for Windows (32-bit) from:
    echo https://www.libsdl.org/download-2.0.php
    echo and place SDL2.dll in the bin\ directory
    pause
)

echo.
echo SDL2 setup complete.
echo Make sure to place all game data files in the data\ directory.

pause
