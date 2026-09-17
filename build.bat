@echo off
setlocal
cd /d "%~dp0"

where cl >nul 2>&1
if errorlevel 1 (
  echo Run this from "x64 Native Tools Command Prompt for VS".
  exit /b 1
)

if not exist build mkdir build

rc /nologo /fo build\win.res win.rc
if errorlevel 1 exit /b 1

cl /nologo /EHsc /O2 /W3 /std:c++17 /DUNICODE /D_UNICODE /MT ^
   win.cpp build\win.res ^
   /Fo:build\ /Fe:build\therockware.exe ^
   /link /SUBSYSTEM:WINDOWS /ENTRY:wWinMainCRTStartup ^
   user32.lib gdi32.lib shell32.lib advapi32.lib ole32.lib uuid.lib ^
   shlwapi.lib windowscodecs.lib mfplat.lib mfreadwrite.lib mfuuid.lib xaudio2.lib
if errorlevel 1 exit /b 1

echo.
echo Built build\therockware.exe
echo Sign it:    powershell -ExecutionPolicy Bypass -File sign.ps1 -SelfSigned
echo Install it: build\therockware.exe --install
