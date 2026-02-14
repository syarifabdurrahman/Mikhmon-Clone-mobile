@echo off
setlocal enabledelayedexpansion

echo Starting build at %time%...

cd android
call gradlew.bat assembleDebug

if errorlevel 1 (
  echo Build failed with error level %errorlevel%.
) else (
  echo Build completed successfully!
)

echo.
echo Press any key to continue...

pause >nul
