# Book Editor - עורך ספרים

A Streamlit-based tool for automatic word replacement in Word documents (.docx), designed for Hebrew book publishers. Each publisher maintains its own replacement dictionary, and the tool applies those rules to uploaded documents using Word's Track Changes feature so all edits remain visible and reviewable.

## Features

- **Document Processing** – Upload a `.docx` file, select a publisher, and automatically apply word replacements with Track Changes markup.
- **Publisher Management** – Create, rename, and delete publishers, each with its own dictionary.
- **Dictionary Management** – Add rules manually, edit inline via a data table, or bulk-import from a text file.
- **Deletion History** – Deleted dictionary entries are saved (up to 100) and can be restored.
- **Publisher Rules** – A large read-only text area at the bottom of Dictionary Management stores free-form editorial instructions separately for each publisher. Click Edit, then Save or Cancel; these notes do not alter automatic word replacement.
- **Export** – Download the processed Word file and export/import dictionary files.

## Project Structure

```
book-editor/
├── app.py                 # Main Streamlit application
├── requirements.txt       # Python dependencies
├── data/
│   └── publishers.json    # Publisher data and dictionaries
├── list_of_rules/         # Sample dictionary rule files
│   ├── booktic.txt
│   ├── matar.txt
│   └── מספרים.txt
├── setup.sh               # Automated setup & run script (Linux/macOS/WSL)
├── setup.bat              # Automated setup & run script (Windows)
├── update.py              # Safe automatic application updater (Windows)
├── Book-Editor.bat        # Windows shortcut - double-click to launch
├── .gitignore
└── README.md
```

## Prerequisites

- **Linux / macOS / WSL** -- No prerequisites. The setup script installs everything automatically.
- **Windows** -- Python is installed automatically via `winget` if it is missing. Git is not required for ZIP-based installations. (`winget` is built into Windows 10 1709+ and Windows 11.)

## Quick Start - Windows

1. **First time** -- Double-click `setup.bat`. It will automatically:
   - No Git required (updates download directly from GitHub)
   - Install Python 3.12 (via winget) if not already present
   - Create a Windows virtual environment
   - Install all dependencies
   - Open the app in your browser
2. **Every day after** -- Double-click `Book-Editor.bat` to launch the app. It automatically checks GitHub and updates application files before starting, even when installed from a ZIP. Existing publisher data in `data/` is retained.

That's it. No command line needed.

### Troubleshooting - Windows

| Problem | Solution |
|---------|----------|
| `setup.bat` cannot install Python (winget not available) | Install Python manually from [python.org/downloads](https://www.python.org/downloads/). Check **"Add python.exe to PATH"** during installation. |
| `setup.bat` finds Python but `venv` creation fails | Disable the Windows App Execution Aliases: **Settings → Apps → Advanced app settings → App execution aliases** → turn **off** both "python.exe" and "python3.exe". Then run `setup.bat` again. |
| App doesn't start after pulling new code | If the `venv` folder was created on another OS (Linux/macOS), `setup.bat` will detect it and recreate it automatically. If it persists, delete the `venv` folder manually and run `setup.bat` again. |

## Quick Start - Linux / macOS / WSL

```bash
# Make the script executable (first time only)
chmod +x setup.sh

# Run it
./setup.sh
```

The script will:
1. Detect your operating system
2. Install Python 3.10+ if not found (may ask for `sudo` password)
3. Create a virtual environment
4. Install all Python dependencies
5. Launch the app

The app will open in your default browser at **http://localhost:8501**.

## Manual Installation

1. **Clone the repository**

```bash
git clone <repository-url>
cd book-editor
```

2. **Create a virtual environment**

```bash
python3 -m venv venv
```

3. **Activate the virtual environment**

```bash
# Linux / macOS
source venv/bin/activate

# Windows (Command Prompt)
venv\Scripts\activate

# Windows (PowerShell)
venv\Scripts\Activate.ps1
```

4. **Install dependencies**

```bash
pip install -r requirements.txt
```

5. **Run the application**

```bash
streamlit run app.py
```

The app will be available at **http://localhost:8501**.

## Dictionary File Format

Dictionary text files use the following format (one rule per line):

```
"source word" "replacement word"
```

Example:

```
"אי אפשר" "אי־אפשר"
"הינה" "הנה"
```

## Usage

1. **Add a publisher** – Go to the "ניהול מילונים" tab, enter a publisher name, and click "הוסף הוצאה".
2. **Build a dictionary** – Add replacement rules manually or import from a `.txt` file.
3. **Process a document** – Go to the "עיבוד מסמך" tab, upload a `.docx` file, select a publisher, and click "בצע עיבוד".
4. **Download** – Review the change log and download the processed file with Track Changes applied.


## Windows ZIP auto-update behavior

Download the latest master ZIP once to install the new launcher. On each subsequent start, `Book-Editor.bat` downloads and compares the current application files with GitHub. Only `app.py`, `requirements.txt` and `update.py` are replaced. The `data/` directory, virtual environment, user-created files and launch scripts are never overwritten. If GitHub is temporarily unavailable, the existing version starts. Close any running Book Editor window before starting it again to activate an update.
