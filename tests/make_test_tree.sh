#!/usr/bin/env bash
# Create a predictable test tree for gnudir tests
set -euo pipefail

T=${1:-$(mktemp -d /tmp/gnudir_test.XXXX)}
echo "Creating test tree at: $T" >&2
mkdir -p "$T"/a/sub1 "$T"/b/sub2 "$T"/already/img

# images
printf "img" > "$T"/picture.png
printf "img" > "$T"/a/sub1/picture.png

# videos
printf "vid" > "$T"/video.mp4

# documents
printf "doc" > "$T"/doc1.pdf

# archives
printf "arc" > "$T"/a/archive.zip

# audio
printf "audio" > "$T"/sound.opus

# app packages
printf "app" > "$T"/installer.AppImage
printf "app" > "$T"/installer.appimage
printf "run" > "$T"/installer.run

# duplicate names
printf "a" > "$T"/a/dup.txt
printf "b" > "$T"/b/dup.txt

# file already inside target subdir
printf "img" > "$T"/already/img/inside.png

# empty directories
mkdir -p "$T"/emptydir1 "$T"/a/emptydir2

printf '%s\n' "$T"
