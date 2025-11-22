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
```

Options:

- `--recurse`            Recurse into subdirectories
- `--dry-run`            Show actions but do not move files
- `--verbose`            Print per-file operations
- `--backup-mode MODE`   Collision strategy: `numbered`|`timestamp`|`overwrite`|`skip` (default `numbered`)
- `--exclude PATH`       Exclude path (may be used multiple times)
- `--keep-empty`         Do not delete empty directories after organizing
- `--help`               Show usage

Examples:

```bash
# top-level only
./gnudir.sh ~/Downloads

# recursive dry-run with verbose output
./gnudir.sh --recurse --dry-run --verbose ~/Downloads
```

## Categories & Notable Extensions

- Images: `png, jpg, jpeg, webp, gif, bmp, tif, tiff, svg, ico, heic, heif, avif`
- Videos: `mp4, mkv, avi, mov, wmv, flv, webm, mpeg, mpg, 3gp, m4v`
- Documents: `pdf, txt, doc, docx, xls, xlsx, ppt, pptx, odt, ods, odp, csv, epub, mobi`
- Archives: `zip, tar, 7z, tar.gz, tar.bz2, tar.xz, xz, iso, gz, bz2`
- Audio: `mp3, wav, flac, aac, ogg, m4a, wma, opus, aiff, aif, amr, alac, mka, au, spx`
- Apps: `AppImage, run, bin, deb, rpm, pkg, snap, img, ova`

Files that do not match a known category are moved to `nany`.

## Output

The script prints per-category summaries like:

```
img moved: 5 files, 12MB in 1 seconds.
vid moved: 2 files, 48MB in 1 seconds.
...
Organization complete in directory: /home/user/Downloads — 12 files, 60MB in 5 seconds.
```

## Testing

A simple test harness is provided under `tests/`:

```bash
bash tests/make_test_tree.sh    # creates a test tree and prints its path
bash tests/run_tests.sh         # runs basic non-recursive and recursive checks
```

## Change Log

- Added: safer find usage (no eval), `safe_mv` mover, per-category timing and size.
- Added: `--dry-run`, `--verbose`, `--backup-mode`, `--exclude`, `--keep-empty`.
- Added: audio and apps categories, miscellaneous `nany` folder.

## TODO / Future Improvements

- Add interactive menu and ASCII banner (optional).
- Add docs batching (`--docs-batch-size`) to split large doc folders.
- Add comprehensive unit tests and CI pipeline.

## License

This project is licensed under the GNU AFFERO GENERAL PUBLIC LICENSE Version 3 — see the `LICENSE` file.

## Author

- BioKeyPer

# VERSION 0.0.0.6