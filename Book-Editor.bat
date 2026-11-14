@echo off
chcp 65001 >nul 2>&1
setlocal
title Book Editor
cd /d "%~dp0"

:: First run: setup Python and dependencies, then start the app.
if not exist "venv\Scripts\python.exe" (
    echo First launch - running setup...
    call setup.bat
    exit /b %ERRORLEVEL%
)

:: ZIP installations have no .git directory. Use the Python updater instead.
if exist "update.py" (
    "venv\Scripts\python.exe" update.py
) else (
    echo Update helper missing. Continuing with local version.
)

:: Ensure updated requirements are installed (pip handles no-op installs).
echo Checking Python dependencies...
"venv\Scripts\python.exe" -m pip install -r requirements.txt --disable-pip-version-check --quiet
if errorlevel 1 (
    echo ERROR: Dependency installation failed. Verify network access.
    pause
    exit /b 1
)

if not exist "data" mkdir "data"
echo.
echo =========================================
echo Book Editor - http://localhost:8501
echo Press Ctrl+C to stop the server
echo =========================================
echo.
start "" "http://localhost:8501"
"venv\Scripts\python.exe" -m streamlit run app.py --server.headless true
if errorlevel 1 (
    echo Book Editor stopped with an error.
    pause
)
