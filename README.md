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

## Instructions to Use the Script

### 1. Clone this Repository
```bash
git clone git@github.com:biokeyper/GNUDir-Cleaner.git`

## 2 Navigate to `GNUDir-Cleaner` Directory
`cd GNUDir-Cleaner`

### 3. Make the Script Executable

`chmod +x ./gnudir.sh`

### 4. Run the Script
You can now run the script by providing the target directory as an argument. For example, to organize files in the `Downloads` directory:

`./gnudir.sh ~/Downloads`

## Explanation of Changes:
* **Added `--recurse` Flag**:

- The script now accepts an optional `--recurse` flag as the second argument.
- If `--recurse` is provided, the script will traverse all subdirectories of the target directory.

* **Recursive File Search**:

Used the find command to locate files. If `--recurse` is set, it searches recursively; otherwise, it only searches the top-level directory (-maxdepth 1).

* **File Moving**:

Used find with `-exec mv` to move files based on their extensions.

## Usage:
To organize files in the top-level directory:
`./gnudir.sh <directory>`

To organize files recursively:
`./gnudir.sh <directory> --recurse`

This implementation ensures that the script can handle both flat and nested directory structures.


```bash
./gnudir.sh <directory>
```

### Sample Output
```bash
 ./gnudir.sh ~/Downloads --recurse
Moving images...
Images moved in 0 seconds.
Moving videos...
Videos moved in 1 seconds.
Moving documents...
Documents moved in 1 seconds.
Moving archives...
Archives moved in 1 seconds.
Moving audio files...
Audio files moved in 0 seconds.
Moving application packages...
Application packages moved in 0 seconds.
Organization complete in directory: /home/user/Downloads in 3 seconds.
```

## Customization
You can modify the file types and directories in the script as needed based on your specific requirements. For example:
- Add support for additional file extensions.
- Change the names of the subdirectories.

## Change LOG
- Added support for audio files and application packages
- Improved runtime display to show the total time taken for the script to execute.
- Refined the script to exclude already-organized files from being processed again.

## TODO:
- Confirm that files have been moved and delete any empty directories.
- Echo the data moved in that timeframe e.g `48GB in 7 seconds`.
- Add an animated or ASCII progress bar for better user experience

## License
This project is licensed under the GNU AFFERO GENERAL PUBLIC License Version 3 - see the LICENSE file for details.

## Author
- BioKeyPer

## Anonymous Contributor. Credit to The Multus Community If Any.
# VERSION 0.0.0.4