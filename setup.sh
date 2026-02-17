#!/usr/bin/env bash
#
# setup.sh - Set up and run the Book Editor application
#
# Works on Linux, macOS, and Windows (WSL / Git Bash).
# Automatically installs Python if not found, creates a virtual environment,
# installs dependencies, and starts the app.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

VENV_DIR="venv"
REQUIRED_PY_MAJOR=3
REQUIRED_PY_MINOR=10

# =========================================================
#  Helper functions
# =========================================================

detect_os() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)  echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*)  echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

detect_linux_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

python_version_ok() {
    local py_cmd="$1"
    local major minor
    major=$($py_cmd -c "import sys; print(sys.version_info.major)" 2>/dev/null) || return 1
    minor=$($py_cmd -c "import sys; print(sys.version_info.minor)" 2>/dev/null) || return 1
    if [ "$major" -gt "$REQUIRED_PY_MAJOR" ]; then
        return 0
    elif [ "$major" -eq "$REQUIRED_PY_MAJOR" ] && [ "$minor" -ge "$REQUIRED_PY_MINOR" ]; then
        return 0
    fi
    return 1
}

find_python() {
    for cmd in python3 python python3.12 python3.11 python3.10; do
        if command -v "$cmd" &>/dev/null && python_version_ok "$cmd"; then
            echo "$cmd"
            return 0
        fi
    done
    return 1
}

# =========================================================
#  Install Python per OS
# =========================================================

install_python_linux() {
    local pkg_mgr
    pkg_mgr=$(detect_linux_pkg_manager)

    echo "Detected Linux package manager: $pkg_mgr"

    case "$pkg_mgr" in
        apt)
            echo "Installing Python via apt..."
            sudo apt-get update -y
            sudo apt-get install -y python3 python3-venv python3-pip
            ;;
        dnf)
            echo "Installing Python via dnf..."
            sudo dnf install -y python3 python3-pip
            ;;
        yum)
            echo "Installing Python via yum..."
            sudo yum install -y python3 python3-pip
            ;;
        pacman)
            echo "Installing Python via pacman..."
            sudo pacman -Sy --noconfirm python python-pip
            ;;
        zypper)
            echo "Installing Python via zypper..."
            sudo zypper install -y python3 python3-pip
            ;;
        *)
            echo "Error: Could not detect a supported package manager."
            echo "Please install Python $REQUIRED_PY_MAJOR.$REQUIRED_PY_MINOR+ manually:"
            echo "  https://www.python.org/downloads/"
            exit 1
            ;;
    esac
}

install_python_macos() {
    if command -v brew &>/dev/null; then
        echo "Installing Python via Homebrew..."
        brew install python@3.12
    else
        echo "Homebrew not found. Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Make brew available in current session
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        echo "Installing Python via Homebrew..."
        brew install python@3.12
    fi
}

install_python() {
    local os_type="$1"

    echo ""
    echo "Python $REQUIRED_PY_MAJOR.$REQUIRED_PY_MINOR+ was not found on this system."
    echo "Attempting to install it automatically..."
    echo ""

    case "$os_type" in
        linux|wsl)
            install_python_linux
            ;;
        macos)
            install_python_macos
            ;;
        windows)
            echo "Error: Automatic Python install is not supported in Git Bash / MSYS."
            echo "Please download and install Python from: https://www.python.org/downloads/"
            echo "Make sure to check 'Add Python to PATH' during installation."
            exit 1
            ;;
        *)
            echo "Error: Unsupported operating system."
            echo "Please install Python $REQUIRED_PY_MAJOR.$REQUIRED_PY_MINOR+ manually:"
            echo "  https://www.python.org/downloads/"
            exit 1
            ;;
    esac

    # Re-hash so the shell finds the newly installed binary
    hash -r 2>/dev/null || true
}

# =========================================================
#  Main flow
# =========================================================

OS_TYPE=$(detect_os)
echo "Detected OS: $OS_TYPE"

# --- Find or install Python ---
PYTHON=""
if PYTHON=$(find_python); then
    echo "Found Python: $PYTHON"
else
    install_python "$OS_TYPE"

    # Try to find Python again after installation
    if PYTHON=$(find_python); then
        echo "Python installed successfully: $PYTHON"
    else
        echo "Error: Python installation finished but python$REQUIRED_PY_MAJOR.$REQUIRED_PY_MINOR+ was not found."
        echo "Please install Python manually: https://www.python.org/downloads/"
        exit 1
    fi
fi

PY_VERSION=$($PYTHON -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')")
echo "Using Python $PY_VERSION ($PYTHON)"

# --- Ensure venv module is available (some distros ship it separately) ---
if ! $PYTHON -m venv --help &>/dev/null; then
    echo "Python venv module not found. Installing..."
    if [ "$OS_TYPE" = "linux" ] || [ "$OS_TYPE" = "wsl" ]; then
        PY_SHORT=$($PYTHON -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        pkg_mgr=$(detect_linux_pkg_manager)
        if [ "$pkg_mgr" = "apt" ]; then
            sudo apt-get install -y "python${PY_SHORT}-venv" || sudo apt-get install -y python3-venv
        fi
    fi
fi

# --- Create virtual environment if needed ---
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    $PYTHON -m venv "$VENV_DIR"
    echo "Virtual environment created."
fi

# --- Activate virtual environment ---
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
elif [ -f "$VENV_DIR/Scripts/activate" ]; then
    source "$VENV_DIR/Scripts/activate"
else
    echo "Error: Could not find virtual environment activation script."
    exit 1
fi

# --- Install / update dependencies ---
echo "Installing dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo "Dependencies installed."

# --- Create data directory if missing ---
mkdir -p data

# --- Launch the app ---
echo ""
echo "========================================="
echo "  Starting Book Editor"
echo "  Open http://localhost:8501 in your browser"
echo "  Press Ctrl+C to stop"
echo "========================================="
echo ""

streamlit run app.py
