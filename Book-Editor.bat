@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: =========================================================
::  Book-Editor.bat - Quick launcher (double-click to start)
::
::  On every launch this script will:
::   1. Pull the latest code from GitHub (if Git is available)
::   2. Reinstall dependencies if requirements.txt changed
::   3. Start the app
::
::  If this is a fresh install, it runs setup.bat automatically.
:: =========================================================

title Book Editor

cd /d "%~dp0"

:: --- Check if setup has been done ---
:: Also catches incompatible venv (e.g. created on Linux with bin/ instead of Scripts/)
if not exist "venv\Scripts\activate.bat" (
    echo.
    echo  First time? Running setup...
    echo.
    call setup.bat
    exit /b
)

:: ============================
::  STEP 1: Pull latest code
:: ============================

:: Check if Git is available (try common paths if not on PATH)
where git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    if exist "%PROGRAMFILES%\Git\cmd\git.exe" set "PATH=%PROGRAMFILES%\Git\cmd;!PATH!"
    if exist "%PROGRAMFILES(x86)%\Git\cmd\git.exe" set "PATH=%PROGRAMFILES(x86)%\Git\cmd;!PATH!"
    if exist "%LOCALAPPDATA%\Programs\Git\cmd\git.exe" set "PATH=%LOCALAPPDATA%\Programs\Git\cmd;!PATH!"
)

where git >nul 2>&1
if %ERRORLEVEL% neq 0 goto :skip_pull

:: Check if this is a git repository with a remote configured
if not exist ".git" goto :skip_pull
git remote -v >nul 2>&1
if %ERRORLEVEL% neq 0 goto :skip_pull

:: Save a hash of requirements.txt before pulling (to detect changes)
set "REQ_HASH_BEFORE="
if exist "requirements.txt" (
    for /f "tokens=*" %%h in ('certutil -hashfile requirements.txt MD5 2^>nul ^| findstr /v ":" 2^>nul') do (
        if not defined REQ_HASH_BEFORE set "REQ_HASH_BEFORE=%%h"
    )
)

echo Checking for updates...
git pull --ff-only 2>&1
if %ERRORLEVEL% neq 0 (
    echo WARNING: Could not pull updates. Continuing with current version.
    echo.
    goto :skip_pull
)

:: Check if requirements.txt changed after pull
set "REQ_HASH_AFTER="
if exist "requirements.txt" (
    for /f "tokens=*" %%h in ('certutil -hashfile requirements.txt MD5 2^>nul ^| findstr /v ":" 2^>nul') do (
        if not defined REQ_HASH_AFTER set "REQ_HASH_AFTER=%%h"
    )
)

if not "!REQ_HASH_BEFORE!"=="!REQ_HASH_AFTER!" (
    echo Dependencies changed. Reinstalling...
    call venv\Scripts\activate.bat
    pip install -r requirements.txt --quiet
    echo Dependencies updated.
    echo.
)

:skip_pull

:: ============================
::  STEP 2: Activate and check
:: ============================

:: --- Activate virtual environment ---
call venv\Scripts\activate.bat

:: --- Quick dependency check (install if missing) ---
pip show streamlit >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing dependencies...
    pip install -r requirements.txt --quiet
)

:: --- Create data directory if missing ---
if not exist "data" mkdir data

:: ============================
::  STEP 3: Launch
:: ============================
echo.
echo  =========================================
echo    Book Editor
echo    Opening http://localhost:8501 ...
echo    Press Ctrl+C to stop
echo  =========================================
echo.

start "" http://localhost:8501
streamlit run app.py --server.headless true

pause
