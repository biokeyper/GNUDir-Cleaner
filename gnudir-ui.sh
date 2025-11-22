#!/usr/bin/env bash
# Interactive wrapper for gnudir.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GNUDIR="$SCRIPT_DIR/gnudir.sh"

usage() {
  cat <<EOF
Usage: $0 [dir]

Starts a small interactive menu to run gnudir operations.
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

TARGET_DIR="${1:-.}"

while true; do
  echo "\nGNUDir Cleaner - Interactive Menu"
  echo "Target directory: $TARGET_DIR"
  echo "1) Quick organize (top-level)"
  echo "2) Recursive organize"
  echo "3) Dry-run recursive + verbose"
  echo "4) Run with custom flags"
  echo "5) Change target directory"
  echo "6) Exit"
  read -rp "Choose an option [1-6]: " opt
  case "$opt" in
    1)
      "$GNUDIR" "$TARGET_DIR"
      ;;
    2)
      "$GNUDIR" --recurse "$TARGET_DIR"
      ;;
    3)
      "$GNUDIR" --recurse --dry-run --verbose "$TARGET_DIR"
      ;;
    4)
      read -rp "Enter custom flags (e.g. --recurse --dry-run): " flags
      eval "\"$GNUDIR\" $flags \"$TARGET_DIR\""
      ;;
    5)
      read -rp "New target directory: " TARGET_DIR
      ;;
    6)
      echo "Goodbye"
      exit 0
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done
