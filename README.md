# GNUDIR CLEANER
## File Organization Script
### By BioKeyPer's Multus Open Source Project

Simple file organizer for local directories. Categorizes files into folders by type (images, videos, documents, archives, audio, apps, and a misc `nany`).

**Goal:** keep your folders tidy by moving files to appropriate subfolders, avoid duplicating folders when empty, and provide safe defaults.

---

## Features

- Creates/reuses subdirectories: `img`, `vid`, `doc`, `arc`, `audio`, `apps`, `nany`
- Moves files into categories based on extensions (case-insensitive)
- Supports recursive traversal and excludes the organizing subdirectories from processing
- `--dry-run` / `-DryRun` to preview moves; `--verbose` / `-ShowVerbose` for per-file logging
- Collision handling via `--backup-mode` / `-BackupMode` (default: `numbered`)
- Skips moving files that are already in their final location (no "same file" errors)
- Deletes empty directories after organizing (unless `--keep-empty` / `-KeepEmpty` is used)
- Prints per-category counts and sizes and a total runtime/size summary
- **Document batching**: Split large document folders into numbered subfolders (e.g., `doc/1`, `doc/2` with 100 files each)

---

## Platform Support

- **Linux/macOS**: `gnudir.sh` (Bash script)
- **Windows**: `gnudir.ps1` (PowerShell script)

---

## Quick Start

### Linux / macOS

```bash
git clone https://github.com/biokeyper/GNUDir-Cleaner.git
cd GNUDir-Cleaner
chmod +x ./gnudir.sh
./gnudir.sh [options] <directory>
```

**Example** — preview changes (no writes):
```bash
./gnudir.sh --recurse --dry-run --verbose ~/Downloads
```

**Example** — batch documents into groups of 100:
```bash
./gnudir.sh --recurse --docs-batch-size 100 ~/Documents
```

### Windows

```powershell
git clone https://github.com/biokeyper/GNUDir-Cleaner.git
cd GNUDir-Cleaner
.\gnudir.ps1 -TargetDir "C:\Users\YourName\Downloads"
```

**Example** — preview changes (no writes):
```powershell
.\gnudir.ps1 -TargetDir "C:\Users\YourName\Downloads" -Recurse -DryRun -ShowVerbose
```

**Example** — batch documents into groups of 100:
```powershell
.\gnudir.ps1 -TargetDir "C:\Users\YourName\Documents" -Recurse -DocsBatchSize 100
```

**Example** — with logging:
```powershell
.\gnudir.ps1 -TargetDir "C:\Users\YourName\Downloads" -Recurse -LogFile "C:\Logs\gnudir.csv"
```

> **Note**: If you see "running scripts is disabled" error, run:
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## Options

### Linux/macOS (Bash)

- `--recurse`            Recurse into subdirectories of the given target
- `--dry-run`            Show actions but do not move files (safe preview)
- `--verbose`            Print per-file operations and helpful messages
- `--backup-mode MODE`   Collision strategy: `numbered` | `timestamp` | `overwrite` | `skip` (default: `numbered`)
- `--exclude PATH`       Exclude a path from processing (can repeat)
- `--keep-empty`         Do not delete empty directories after organizing
- `--docs-batch-size N`  Split `doc/` into numbered subfolders with up to N files each (default: `0` = disabled)
- `--help`               Show this help and exit

### Windows (PowerShell)

- `-TargetDir <path>`    **Required**. Directory to organize
- `-Recurse`             Recurse into subdirectories
- `-DryRun`              Show actions but do not move files (safe preview)
- `-ShowVerbose`         Print per-file operations and helpful messages
- `-BackupMode <mode>`   Collision strategy: `numbered` | `timestamp` | `overwrite` | `skip` (default: `numbered`)
- `-Exclude <paths>`     Array of paths to exclude from processing
- `-KeepEmpty`           Do not delete empty directories after organizing
- `-DocsBatchSize <N>`   Split `doc/` into numbered subfolders with up to N files each (default: `0` = disabled)
- `-LogFile <path>`      Log operations to a CSV file

---

## Categories (file extensions)

- **Images**: png, jpg, jpeg, webp, gif, bmp, tif, tiff, svg, ico, heic, heif, avif
- **Videos**: mp4, mkv, avi, mov, wmv, flv, webm, mpeg, mpg, 3gp, m4v
- **Documents**: pdf, txt, doc, docx, xls, xlsx, ppt, pptx, odt, ods, odp, csv, epub, mobi, mht
- **Archives**: zip, tar, 7z, tar.gz, tar.bz2, tar.xz, xz, iso, gz, bz2
- **Audio**: mp3, wav, flac, aac, ogg, m4a, wma, opus, aiff, aif, amr, alac, mka, au, spx
- **Apps / installers**: AppImage, .appimage, .run, .bin, .deb, .rpm, .pkg, .snap, .img, .ova

Files that do not match any known category are moved to `nany`.

---

## Key Behavior Notes

- Category folders (e.g. `img`, `doc`, `audio`) are created lazily only when a file is moved into them
- The script removes empty directories after organizing, so you won't be left with empty category folders
- The script skips moving files that are already in the correct folder (no "same file" errors)
- By default the script runs safely; use dry-run to preview and verbose to see per-file messages
- Document batching only processes files directly in `doc/` root—existing batch folders (numbered directories) are preserved

---

## Testing

### Linux/macOS

```bash
cd tests
bash test_suite.sh       # runs basic checks
bash test_docs_batch.sh  # tests docs batching behavior
```

### Windows

```powershell
cd tests
.\test_suite.ps1
```

The test suite verifies:
- ✅ File categorization (images, videos, documents, archives, audio, apps, misc)
- ✅ Document batching functionality
- ✅ Dry-run mode (preview without making changes)

CI: GitHub Actions workflows are included that run tests on both Linux and Windows on push/PR.

---

## Development Notes

- **Bash script** uses `find -print0` and a safe mover (`safe_mv`) to avoid shell quoting issues
- Destination directories are created lazily inside `safe_mv` so directories stay clean when no files match a category
- The bash script uses `rsync` as a fallback for cross-filesystem moves when `mv` fails
- **PowerShell script** uses `Get-ChildItem` with proper exclusions to avoid re-processing files in category directories
- Both scripts preserve existing numbered batch folders and start new batches after the highest existing number

---

## License

This project is licensed under the GNU AFFERO GENERAL PUBLIC LICENSE Version 3 — see the `LICENSE` file.

## Author

- BioKeyPer

## VERSION

0.0.0.7
