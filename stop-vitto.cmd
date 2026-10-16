@echo off
rem Stops the local Vitto backend. Your test data is kept for next time.
cd /d "%~dp0"
call npx --yes supabase@2.121.0 stop
echo.
echo Vitto backend stopped.
pause
