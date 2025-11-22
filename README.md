# GNUDIR CLEANER 
## File Organization Script
### By BioKeyPer's Multus Open Source Project

## Introduction

This script automates the process of organizing files in a specified directory into subdirectories based on their file types. It categorizes files into images, videos, documents, archives, audio files, and application packages.

## Features

- Automatically creates subdirectories for images, videos, documents, archives, audio files, and application packages.
- Moves files into their respective directories based on file extensions.
- Reuses existing subdirectories if they are already present, avoiding redundant directory creation.
- Ignores missing files gracefully.
- Supports recursive organization of files in subdirectories using the `--recurse` flag.
- Displays the total runtime of the script after completion.

## Prerequisites

- A Linux environment with Bash shell.
- Basic knowledge of using the terminal.

# GNUDIR CLEANER

File organization script to categorize files in a directory by file type.

## Introduction

This script automates organizing files in a specified directory into subdirectories by file type. Current categories: images, videos, documents, archives, audio, application packages, and a miscellaneous `nany` folder for unknown types.

## Features

- Creates/reuses subdirectories: `img`, `vid`, `doc`, `arc`, `audio`, `apps`, `nany`.
- Moves files into categories based on extensions (case-insensitive).
- Supports recursive traversal with `--recurse` and excludes the organizing subdirectories from processing.
- `--dry-run` to preview moves; `--verbose` for per-file logging.
- Collision handling via `--backup-mode` (default: `numbered`).
- Skips moving files that are already in their final location (no "same file" errors).
- Deletes empty directories after organizing (unless `--keep-empty` is used).
- Prints per-category counts and sizes and a total runtime/size summary.

## Prerequisites

- Linux environment with Bash.
- Common utilities: `find`, `mv`, `stat`, `numfmt` (optional, for human-readable sizes).

## Usage

Make the script executable and run:

```bash
git clone git@github.com:biokeyper/GNUDir-Cleaner.git
cd GNUDir-Cleaner
chmod +x ./gnudir.sh
./gnudir.sh [options] <directory>
# GNUDIR CLEANER

Simple file organizer for local directories. Categorizes files into folders by type (images, videos, documents, archives, audio, apps, and a misc `nany`).

**Goal:** keep your folders tidy by moving files to appropriate subfolders, avoid duplicating folders when empty, and provide safe defaults.

---

## Quick Start

```bash
git clone git@github.com:biokeyper/GNUDir-Cleaner.git
cd GNUDir-Cleaner
chmod +x ./gnudir.sh
./gnudir.sh [options] <directory>
```

Example — preview changes (no writes):

```bash
./gnudir.sh --recurse --dry-run --verbose ~/Downloads
```

Apply changes and batch documents into groups of 100:

```bash
./gnudir.sh --recurse --docs-batch-size 100 ~/Documents
```

---

## Key Behavior Notes

- Category folders (e.g. `img`, `doc`, `audio`) are created lazily only when a file is moved into them. The script removes empty directories after organizing, so you won't be left with empty category folders.
- The script skips moving files that are already in the correct folder (no "same file" errors).
- By default the script runs safely; use `--dry-run` to preview and `--verbose` to see per-file messages.

---

## Options

- `--recurse`            Recurse into subdirectories of the given target.
- `--dry-run`            Show actions but do not move files (safe preview).
- `--verbose`            Print per-file operations and helpful messages.
- `--backup-mode MODE`   Collision strategy when the destination exists: `numbered` | `timestamp` | `overwrite` | `skip` (default: `numbered`).
- `--exclude PATH`       Exclude a path from processing (can repeat).
- `--keep-empty`         Do not delete empty directories after organizing.
- `--docs-batch-size N`  When >0, split `doc/` into numbered subfolders with up to N files each (e.g. `doc/1`, `doc/2`). Default `0` (disabled).
- `--help`               Show this help and exit.

---

## Categories (file extensions)

- Images: png, jpg, jpeg, webp, gif, bmp, tif, tiff, svg, ico, heic, heif, avif
- Videos: mp4, mkv, avi, mov, wmv, flv, webm, mpeg, mpg, 3gp, m4v
- Documents: pdf, txt, doc, docx, xls, xlsx, ppt, pptx, odt, ods, odp, csv, epub, mobi
- Archives: zip, tar, 7z, tar.gz, tar.bz2, tar.xz, xz, iso, gz, bz2
- Audio: mp3, wav, flac, aac, ogg, m4a, wma, opus, aiff, aif, amr, alac, mka, au, spx
- Apps / installers: AppImage, .appimage, .run, .bin, .deb, .rpm, .pkg, .snap, .img, .ova

Files that do not match any known category are moved to `nany`.

---

## Examples

- Top-level only organize:
```bash
./gnudir.sh ~/Downloads
```

- Recursive dry-run with verbose output:
```bash
./gnudir.sh --recurse --dry-run --verbose ~/Downloads
```

- Batch documents into folders of 100 items each:
```bash
./gnudir.sh --recurse --docs-batch-size 100 ~/Documents
```

Sample output when batching is enabled:

```
Batching documents into groups of 100...
Documents batched into 3 folders.
Organization complete in directory: /home/user/Documents — 245 files, 360MB in 12 seconds.
```

---

## Testing

There is a test harness in `tests/`:

```bash
bash tests/make_test_tree.sh    # creates a deterministic test tree
bash tests/run_tests.sh         # runs basic checks
bash tests/test_docs_batch.sh   # tests docs batching behavior
```

CI: a GitHub Actions workflow is included in `.github/workflows/test.yml` that runs the test suite on push/PR.

---

## Development notes

- The script uses `find -print0` and a safe mover (`safe_mv`) to avoid shell quoting issues.
- Destination directories are created lazily inside `safe_mv` so the repo/user directories stay clean when no files match a category.
- The script uses `rsync` as a fallback for cross-filesystem moves when `mv` fails.

---

## License

This project is licensed under the GNU AFFERO GENERAL PUBLIC LICENSE Version 3 — see the `LICENSE` file.

## Author

- BioKeyPer

## VERSION

0.0.0.6
