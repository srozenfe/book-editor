"""Update the Windows ZIP installation from the public GitHub master branch.

Only application files are replaced; local data, virtual environments, and any
user-created files are never modified. Uses Python's standard library.
"""
from __future__ import annotations

import io
import os
import shutil
import sys
import tempfile
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ARCHIVE_URL = "https://github.com/srozenfe/book-editor/archive/refs/heads/master.zip"
# Do not update the currently running batch launcher or the setup script:
# Windows cmd.exe may still be reading those files.
UPDATE_FILES = ("app.py", "requirements.txt", "update.py")
TIMEOUT_SECONDS = 20
MAX_ZIP_BYTES = 15 * 1024 * 1024


def update() -> int:
    print("Checking GitHub for Book Editor updates...", flush=True)
    try:
        request = urllib.request.Request(
            ARCHIVE_URL, headers={"User-Agent": "Book-Editor-Windows-Updater"}
        )
        with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            payload = response.read(MAX_ZIP_BYTES + 1)
        if len(payload) > MAX_ZIP_BYTES:
            raise ValueError("Update archive is unexpectedly large")

        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            staged = {}
            for relative in UPDATE_FILES:
                matching = [name for name in archive.namelist()
                            if name.endswith("/" + relative)
                            and name.count("/") == 1]
                if len(matching) != 1:
                    raise ValueError("Missing or ambiguous update file: " + relative)
                staged[relative] = archive.read(matching[0])

        changes = {name: content for name, content in staged.items()
                   if not (ROOT / name).exists()
                   or (ROOT / name).read_bytes() != content}
        if not changes:
            print("Already up to date.")
            return 0

        # Stage and back up all replacements before modifying any live files.
        with tempfile.TemporaryDirectory(prefix="book-editor-update-") as temp:
            staging = Path(temp)
            for name, content in changes.items():
                (staging / name).write_bytes(content)
            backups = {}
            replaced = []
            try:
                for name in changes:
                    dest = ROOT / name
                    backups[name] = dest.read_bytes() if dest.exists() else None
                    os.replace(staging / name, dest)
                    replaced.append(name)
            except OSError:
                for name in reversed(replaced):
                    dest = ROOT / name
                    original = backups[name]
                    if original is None:
                        dest.unlink(missing_ok=True)
                    else:
                        backup = staging / (name + ".restore")
                        backup.write_bytes(original)
                        os.replace(backup, dest)
                raise

        print("Updated application files: " + ", ".join(changes))
        if "requirements.txt" in changes:
            print("Dependencies will be checked before launch.")
        print("Your publisher data in data/ was preserved.")
        return 0
    except (OSError, ValueError, zipfile.BadZipFile, urllib.error.URLError) as exc:
        print("WARNING: Update check failed: " + str(exc))
        print("Continuing with the existing application files.")
        return 1


if __name__ == "__main__":
    sys.exit(update())
