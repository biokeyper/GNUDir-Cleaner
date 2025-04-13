#!/bin/bash

# Check if a directory is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

TARGET_DIR="$1"

# Create directories for organization
mkdir -p "$TARGET_DIR/img"
mkdir -p "$TARGET_DIR/vid"
mkdir -p "$TARGET_DIR/doc"
mkdir -p "$TARGET_DIR/arc"

# Move image files
mv "$TARGET_DIR"/*.png "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.jpg "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.jpeg "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.webp "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.gif "$TARGET_DIR/img/" 2>/dev/null

# Move video files
mv "$TARGET_DIR"/*.mp4 "$TARGET_DIR/vid/" 2>/dev/null

# Move document files
mv "$TARGET_DIR"/*.pdf "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.txt "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.doc "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.docx "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.xlsx "$TARGET_DIR/doc/" 2>/dev/null

# Move archive files
mv "$TARGET_DIR"/*.zip "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.iso "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.xz "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.deb "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.gz "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.rar "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.bz2 "$TARGET_DIR/arc/" 2>/dev/null

echo "Organization complete in directory: $TARGET_DIR"
