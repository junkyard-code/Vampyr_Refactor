@echo off
setlocal

set FPC="C:\Program Files\Free Pascal\bin\i386-win32\fpc.exe"
set SDL2_PATH=C:\dev\sdl2

%FPC% -Mdelphi -Sd -Sh -O2 -v0 -Fu"%SDL2_PATH%" -o"test_sdl2.exe" test_sdl2.pas

if %ERRORLEVEL% EQU 0 (
    echo Compilation successful! Running the test...
    copy /Y "%SDL2_PATH%\lib\x86\SDL2.dll" .
    test_sdl2.exe
) else (
    echo Compilation failed with error code %ERRORLEVEL%
)

endlocal
