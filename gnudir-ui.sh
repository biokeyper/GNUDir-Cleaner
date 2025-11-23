#!/usr/bin/env bash
# Interactive wrapper for gnudir.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GNUDIR="$SCRIPT_DIR/gnudir.sh"

# Expand paths like ~ and variables, with a safe fallback
expand_path() {
  local p="$1"
  # replace leading ~ with $HOME
  if [[ "$p" == ~* ]]; then
    p="${p/#\~/$HOME}"
  fi
  # expand any environment vars
  eval "p=\"$p\""
  # canonicalize if possible
  if command -v realpath >/dev/null 2>&1; then
    realpath -m -- "$p" 2>/dev/null || printf "%s" "$p"
  else
    printf "%s" "$p"
  fi
}

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
TARGET_DIR_EXPANDED="$(expand_path "$TARGET_DIR")"
TARGET_DIR="$TARGET_DIR_EXPANDED"

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
      read -erp "New target directory: " INPUT_DIR
      # expand and normalize
      NEWDIR="$(expand_path "$INPUT_DIR")"
      if [ -z "$NEWDIR" ]; then
        echo "Empty path, keeping: $TARGET_DIR"
      elif [ -d "$NEWDIR" ]; then
        TARGET_DIR="$NEWDIR"
      else
        read -rp "Target directory does not exist: $NEWDIR. Create it? [y/N]: " createans
        if [[ "$createans" =~ ^[Yy]$ ]]; then
          mkdir -p -- "$NEWDIR" || { echo "Failed to create $NEWDIR"; }
          TARGET_DIR="$NEWDIR"
        else
          echo "Keeping current target: $TARGET_DIR"
        fi
      fi
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
