# GNUDIR CLEANER 
## File Organization Script
### By BioKeyPer's Multus Open Source Project

## Introduction

This script automates the process of organizing files in a specified directory into subdirectories based on their file types. It categorizes files into images, videos, documents, and archives.

## Features

- Automatically creates subdirectories for images, videos, documents, and archives.
- Moves files into their respective directories based on file extensions.
- Reuses existing subdirectories if they are already present, avoiding redundant directory creation.
- Ignores missing files gracefully.

## Prerequisites

- A Linux environment with Bash shell.
- Basic knowledge of using the terminal.

## Instructions to Use the Script

### 1. Clone this Repository
`git clone git@github.com:biokeyper/GNUDir-Cleaner.git`

## 2 Navigate to `GNUDir-Cleaner` Directory
`cd GNUDir-Cleaner`

### 3. Make the Script Executable

`chmod +x ./gnudir.sh`

### 4. Run the Script
You can now run the script by providing the target directory as an argument. For example, to organize files in the `Downloads` directory:

`./gnudir.sh ~/Downloads`

## Customization
You can modify the file types and directories in the script as needed based on your specific requirements.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Author
- BioKeyPer

## Anonymous Contributor. Credit to The Multus Community If Any.
# VERSION 0.0.0.2