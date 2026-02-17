@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: =========================================================
::  setup.bat - Fully automated setup & run for Book Editor
::
::  No prerequisites needed. This script will:
::   1. Install Git automatically if not found
::   2. Install Python 3.12 automatically if not found
::   3. Remove incompatible venv (e.g. created on Linux)
::   4. Create a Windows virtual environment
::   5. Install all dependencies
::   6. Launch the app in the browser
:: =========================================================

title Book Editor - Setup

echo =========================================
echo   Book Editor - Setup
echo =========================================
echo.

:: --- Navigate to script directory ---
cd /d "%~dp0"

:: =====================
::  STEP 1: Find Git
:: =====================
call :find_git
if defined GIT goto :git_ready

echo.
echo Git was not found on this machine.
echo.

:: --- Check if winget is available ---
where winget >nul 2>&1
if %ERRORLEVEL% neq 0 goto :no_winget_git

:: --- Install Git via winget ---
echo Installing Git automatically via winget...
echo This may take a minute or two.
echo.
winget install Git.Git --accept-source-agreements --accept-package-agreements
if %ERRORLEVEL% neq 0 goto :git_install_failed

echo.
echo Git installed successfully. Refreshing environment...
echo.

:: --- Refresh PATH and search for newly installed Git ---
call :refresh_path
call :find_git_in_common_paths
call :find_git
if defined GIT goto :git_ready

echo.
echo WARNING: Git was installed but could not be found in the current session.
echo The app will still work, but auto-updates will not be available
echo until you restart your computer or reopen this script.
echo.

goto :git_ready

:no_winget_git
echo WARNING: winget is not available. Skipping Git installation.
echo The app will work without Git, but auto-updates will not be available.
echo You can install Git manually from: https://git-scm.com/download/win
echo.
goto :git_ready

:git_install_failed
echo.
echo WARNING: Automatic Git installation failed. Skipping.
echo The app will work without Git, but auto-updates will not be available.
echo You can install Git manually from: https://git-scm.com/download/win
echo.

:git_ready
if defined GIT (
    echo Found Git (%GIT%)
) else (
    echo Git not available - skipping auto-update features.
)

:: =====================
::  STEP 2: Find Python
:: =====================
call :find_python
if defined PYTHON goto :python_ready

echo.
echo Python 3.10+ was not found on this machine.
echo.

:: --- Check if winget is available ---
where winget >nul 2>&1
if %ERRORLEVEL% neq 0 goto :no_winget_python

:: --- Install Python via winget ---
echo Installing Python 3.12 automatically via winget...
echo This may take a minute or two.
echo.
winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements
if %ERRORLEVEL% neq 0 goto :python_install_failed

echo.
echo Python installed successfully. Refreshing environment...
echo.

:: --- Refresh PATH and search for the newly installed Python ---
call :refresh_path
call :find_python_in_common_paths
call :find_python
if defined PYTHON goto :python_ready

:: --- Still not found ---
echo.
echo ERROR: Python was installed but could not be found in the current session.
echo.
echo Please close this window and double-click setup.bat again.
echo.
pause
exit /b 1

:no_winget_python
echo winget is not available on this system.
echo.
call :show_manual_install_help
pause
exit /b 1

:python_install_failed
echo.
echo Automatic Python installation failed.
echo.
call :show_manual_install_help
pause
exit /b 1

:: =====================
::  Python is available
:: =====================
:python_ready
for /f "tokens=*" %%i in ('%PYTHON% -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"') do set "PY_FULL_VER=%%i"
echo Found Python %PY_FULL_VER% (%PYTHON%)

:: =============================================
::  STEP 3: Handle incompatible venv (Linux/macOS)
:: =============================================
if exist "venv" (
    if not exist "venv\Scripts\activate.bat" (
        echo.
        echo Detected incompatible virtual environment ^(created on another OS^).
        echo Removing it and creating a fresh one...
        rmdir /s /q venv
    )
)

:: =====================
::  STEP 4: Create venv
:: =====================
if exist "venv\Scripts\activate.bat" goto :venv_ready

echo.
echo Creating virtual environment...
%PYTHON% -m venv venv
if %ERRORLEVEL% neq 0 goto :venv_failed

echo Virtual environment created.
goto :venv_ready

:venv_failed
echo.
echo ERROR: Failed to create virtual environment.
echo.
echo If you see a permissions error, try disabling the Windows
echo App Execution Aliases:
echo   Settings ^> Apps ^> Advanced app settings ^> App execution aliases
echo   Turn OFF "App Installer - python.exe" and "App Installer - python3.exe"
echo.
pause
exit /b 1

:venv_ready
:: --- Activate virtual environment ---
call venv\Scripts\activate.bat

:: ============================
::  STEP 5: Install dependencies
:: ============================
echo.
echo Installing dependencies...
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo Dependencies installed.

:: --- Create data directory if missing ---
if not exist "data" mkdir data

:: ============================
::  STEP 6: Launch the app
:: ============================
echo.
echo =========================================
echo   Starting Book Editor
echo   The app will open in your browser at:
echo   http://localhost:8501
echo.
echo   Press Ctrl+C to stop the server
echo =========================================
echo.

start "" http://localhost:8501
streamlit run app.py --server.headless true

pause
exit /b 0


:: =========================================================
::  Subroutines
:: =========================================================

:find_git
:: Looks for git on PATH
set "GIT="
where git >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "GIT=git"
)
exit /b 0


:find_git_in_common_paths
:: Scan common Git install directories and add them to PATH
if exist "%PROGRAMFILES%\Git\cmd\git.exe" (
    set "PATH=%PROGRAMFILES%\Git\cmd;!PATH!"
)
if exist "%PROGRAMFILES(x86)%\Git\cmd\git.exe" (
    set "PATH=%PROGRAMFILES(x86)%\Git\cmd;!PATH!"
)
if exist "%LOCALAPPDATA%\Programs\Git\cmd\git.exe" (
    set "PATH=%LOCALAPPDATA%\Programs\Git\cmd;!PATH!"
)
exit /b 0


:find_python
:: Looks for python or python3 on PATH with version >= 3.10
set "PYTHON="

where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%i in ('python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2^>nul') do set "PY_VER=%%i"
    for /f "tokens=1,2 delims=." %%a in ("!PY_VER!") do (
        if %%a geq 3 if %%b geq 10 set "PYTHON=python"
    )
)

if not defined PYTHON (
    where python3 >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        for /f "tokens=*" %%i in ('python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2^>nul') do set "PY_VER=%%i"
        for /f "tokens=1,2 delims=." %%a in ("!PY_VER!") do (
            if %%a geq 3 if %%b geq 10 set "PYTHON=python3"
        )
    )
)
exit /b 0


:refresh_path
:: Re-read PATH from the Windows registry (picks up newly installed programs)
set "NEW_PATH="
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "NEW_PATH=%%b"
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "NEW_PATH=!NEW_PATH!;%%b"
if defined NEW_PATH set "PATH=!NEW_PATH!"
exit /b 0


:find_python_in_common_paths
:: Scan common Python install directories and add them to PATH
for /d %%d in ("%LOCALAPPDATA%\Programs\Python\Python3*") do (
    if exist "%%d\python.exe" (
        set "PATH=%%d;%%d\Scripts;!PATH!"
    )
)
for /d %%d in ("%PROGRAMFILES%\Python3*") do (
    if exist "%%d\python.exe" (
        set "PATH=%%d;%%d\Scripts;!PATH!"
    )
)
exit /b 0


:show_manual_install_help
echo =========================================
echo   Manual Python Installation Required
echo =========================================
echo.
echo 1. Go to: https://www.python.org/downloads/
echo 2. Download and run the Python 3.12 installer
echo 3. IMPORTANT: Check "Add python.exe to PATH" on the first screen
echo 4. After installing, disable the Windows App Execution Aliases:
echo      Settings ^> Apps ^> Advanced app settings ^> App execution aliases
echo      Turn OFF "App Installer - python.exe" and "App Installer - python3.exe"
echo 5. Close this window and double-click setup.bat again
echo.
exit /b 0
