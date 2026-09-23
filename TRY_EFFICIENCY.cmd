@echo off
setlocal
cd /d "%~dp0"
if not exist "data" mkdir "data"
if errorlevel 1 goto failed
copy /y "_maps\efficiencystation.json" "data\next_map.json" >nul
if errorlevel 1 goto failed
echo Building and starting the EfficiencyStation test server.
echo BYOND 516.1667 must be installed. First build needs internet access.
echo When the server finishes loading, connect in BYOND to byond://127.0.0.1:1337
echo Leave this window open while playing. Press Ctrl+C to stop.
call RUN_SERVER.cmd
if errorlevel 1 goto failed
exit /b 0
:failed
echo The test server could not start. See the error above.
pause
exit /b 1
