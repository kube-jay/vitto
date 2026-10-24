@echo off
rem ---------------------------------------------------------------------------
rem  Builds the Vitto website for hosting (Netlify), connected to a Supabase
rem  CLOUD project. Double-click it and paste the two values when asked.
rem  Both values are public by design (they ship inside every web page);
rem  never paste the "secret" or "service_role" key here.
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"
title Vitto - build for Netlify

echo.
echo  Supabase dashboard ^> your project ^> Project Settings ^> Data API / API Keys
echo.
set /p "SB_URL=  Project URL (https://xxxx.supabase.co): "
set /p "SB_KEY=  Publishable key (sb_publishable_...): "

echo %SB_URL% | findstr /r /c:"^https://.*\.supabase\.co" >nul || (
  echo  That does not look like a Supabase project URL.
  pause
  exit /b 1
)
echo %SB_KEY% | findstr /i "secret service_role" >nul && (
  echo  That is a SECRET key. Use the publishable key instead.
  pause
  exit /b 1
)

echo.
echo  Building (about 1 minute)...
pushd apps\vitto_app
call flutter build web --release --pwa-strategy=none --no-wasm-dry-run --output build\netlify --dart-define=SUPABASE_URL=%SB_URL% --dart-define=SUPABASE_PUBLISHABLE_KEY=%SB_KEY% >nul
if errorlevel 1 (
  popd
  echo  The build failed. Run "flutter doctor" to check your Flutter setup.
  pause
  exit /b 1
)
popd

echo.
echo  Done. The website is in:
echo    %CD%\apps\vitto_app\build\netlify
echo.
echo  Netlify: open your site ^> Deploys ^> drag this "netlify" folder onto the page.
echo  (New site: https://app.netlify.com/drop and drop the folder there.)
echo.
del /q "apps\vitto_app\build\web\.local-build" 2>nul
explorer "apps\vitto_app\build"
pause
