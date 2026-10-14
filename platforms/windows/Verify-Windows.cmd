@echo off
cd /d "%~dp0"
start "" /wait "%~dp0ChirpOS.exe" --self-test
if exist "%LOCALAPPDATA%\ChirpOS\self-test.json" (
  type "%LOCALAPPDATA%\ChirpOS\self-test.json"
) else (
  echo No report was produced. Check errors.log in LocalAppData\ChirpOS.
)
echo.
pause
