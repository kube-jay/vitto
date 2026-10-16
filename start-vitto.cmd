@echo off
rem ---------------------------------------------------------------------------
rem  Starts Vitto on this computer for testing.
rem  Double-click this file (or run it from any folder). Keep the window open
rem  while you use the app; close it (or press Ctrl+C) to stop the website.
rem
rem    start-vitto.cmd           start everything
rem    start-vitto.cmd rebuild   also rebuild the app after pulling new code
rem    start-vitto.cmd reset     wipe all local data and recreate the demo data
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"
title Vitto (local)

echo.
echo  =============================
echo   Vitto - local test version
echo  =============================
echo.

docker info >nul 2>nul
if errorlevel 1 (
  echo  Docker Desktop is not running.
  echo  Open Docker Desktop, wait until it shows "Engine running", then run this again.
  echo.
  pause
  exit /b 1
)

set "PY=py"
where py >nul 2>nul || set "PY=python"

echo  [1/4] Starting the backend (the first time can take a few minutes^)...
call npx --yes supabase@2.121.0 start >nul 2>"%TEMP%\vitto-start.log"
if errorlevel 1 (
  echo  The backend could not start. Details:
  type "%TEMP%\vitto-start.log"
  echo.
  echo  If it says a port is already allocated, run stop-vitto.cmd and try again.
  pause
  exit /b 1
)

if /i "%~1"=="reset" (
  echo        Wiping local data...
  call npx --yes supabase@2.121.0 db reset >nul 2>&1
)

echo  [2/4] Adding demo Listings (skipped if they already exist^)...
%PY% scripts\seed_demo_listings.py
if errorlevel 1 (
  echo  Could not add demo data.
  pause
  exit /b 1
)

set "NEED_BUILD="
if not exist "apps\vitto_app\build\web\index.html" set "NEED_BUILD=1"
if /i "%~1"=="rebuild" set "NEED_BUILD=1"
if defined NEED_BUILD (
  echo  [3/4] Building the app (about 1 minute^)...
  pushd apps\vitto_app
  call flutter build web --release --pwa-strategy=none --no-wasm-dry-run --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH >nul
  if errorlevel 1 (
    popd
    echo  The app build failed. Run "flutter doctor" to check your Flutter setup.
    pause
    exit /b 1
  )
  popd
) else (
  echo  [3/4] App already built.
)

echo  [4/4] Opening http://localhost:5000
echo.
echo  Test accounts (password for all: VittoTest123!^)
echo    ada.ng@vitto.test     seller with demo Listings (Nigeria^)
echo    chidi.ng@vitto.test   buyer (Nigeria^)
echo    koffi.bj@vitto.test   Benin user (French^)
echo    admin@vitto.test      admin
echo.
echo  Emails sent by the app (sign-up, password reset^): http://127.0.0.1:54324
echo  Keep this window open. Close it to stop the website.
echo.
start "" http://localhost:5000
%PY% scripts\serve_web.py 5000
