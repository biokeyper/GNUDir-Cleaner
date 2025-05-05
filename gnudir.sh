#!/bin/bash

# Check if a directory is provided as an argument
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <directory> [--recurse]"
    exit 1
fi

TARGET_DIR="$1"
RECURSE=false

# Check for the --recurse flag
if [ "$#" -eq 2 ] && [ "$2" == "--recurse" ]; then
    RECURSE=true
fi

# Start total runtime timer
TOTAL_START_TIME=$(date +%s)

# Create directories for organization
mkdir -p "$TARGET_DIR"/{img,vid,doc,arc,audio,apps}

# Find files (recursively if --recurse is set)
if [ "$RECURSE" = true ]; then
    FIND_CMD="find \"$TARGET_DIR\" -type f -not -path \"$TARGET_DIR/img/*\" -not -path \"$TARGET_DIR/vid/*\" -not -path \"$TARGET_DIR/doc/*\" -not -path \"$TARGET_DIR/arc/*\" -not -path \"$TARGET_DIR/audio/*\" -not -path \"$TARGET_DIR/apps/*\""
else
    FIND_CMD="find \"$TARGET_DIR\" -maxdepth 1 -type f"
fi

# Move files based on their extensions

# Move image files
echo "Moving images..."
START_TIME=$(date +%s)
eval "$FIND_CMD \( -iname \"*.png\" -o -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.gif\" -o -iname \"*.bmp\" -o -iname \"*.tiff\" -o -iname \"*.tif\" -o -iname \"*.webp\" -o -iname \"*.svg\" -o -iname \"*.ico\" -o -iname \"*.heic\" -o -iname \"*.heif\" -o -iname \"*.avif\" -o -iname \"*.arw\" -o -iname \"*.cr2\" -o -iname \"*.nef\" -o -iname \"*.orf\" -o -iname \"*.rw2\" -o -iname \"*.dng\" -o -iname \"*.3fr\" -o -iname \"*.crw\" -o -iname \"*.kdc\" -o -iname \"*.mef\" -o -iname \"*.pef\" -o -iname \"*.raf\" -o -iname \"*.rwz\" -o -iname \"*.srf\" -o -iname \"*.srw\" -o -iname \"*.x3f\" -o -iname \"*.dcr\" -o -iname \"*.erf\" -o -iname \"*.indd\" -o -iname \"*.aae\" -o -iname \"*.jxr\" -o -iname \"*.jpe\" -o -iname \"*.jif\" \) -exec mv {} \"$TARGET_DIR/img/\" \;"
END_TIME=$(date +%s)
echo "Images moved in $((END_TIME - START_TIME)) seconds."

# Move video files
echo "Moving videos..."
START_TIME=$(date +%s)
eval "$FIND_CMD \( -iname \"*.mp4\" -o -iname \"*.mkv\" -o -iname \"*.avi\" -o -iname \"*.mov\" -o -iname \"*.wmv\" -o -iname \"*.flv\" -o -iname \"*.webm\" -o -iname \"*.mpeg\" -o -iname \"*.mpg\" -o -iname \"*.3gp\" -o -iname \"*.3g2\" -o -iname \"*.m4v\" -o -iname \"*.rm\" -o -iname \"*.rmvb\" -o -iname \"*.m2ts\" \) -exec mv {} \"$TARGET_DIR/vid/\" \;"
END_TIME=$(date +%s)
echo "Videos moved in $((END_TIME - START_TIME)) seconds."

# Move document files
echo "Moving documents..."
START_TIME=$(date +%s)
eval "$FIND_CMD \( -iname \"*.pdf\" -o -iname \"*.txt\" -o -iname \"*.doc\" -o -iname \"*.docx\" -o -iname \"*.xls\" -o -iname \"*.xlsx\" -o -iname \"*.ppt\" -o -iname \"*.pptx\" -o -iname \"*.odt\" -o -iname \"*.ods\" -o -iname \"*.odp\" -o -iname \"*.csv\" -o -iname \"*.epub\" -o -iname \"*.mobi\" -o -iname \"*.azw\" -o -iname \"*.azw3\" -o -iname \"*.fb2\" -o -iname \"*.fbz\" -o -iname \"*.fbz2\" -o -iname \"*.fbz3\" \) -exec mv {} \"$TARGET_DIR/doc/\" \;"
END_TIME=$(date +%s)
echo "Documents moved in $((END_TIME - START_TIME)) seconds."

# Move archive files
echo "Moving archives..."
START_TIME=$(date +%s)
eval "$FIND_CMD \( -iname \"*.zip\" -o -iname \"*.iso\" -o -iname \"*.xz\" -o -iname \"*.gz\" -o -iname \"*.rar\" -o -iname \"*.bz2\" -o -iname \"*.tar\" -o -iname \"*.7z\" -o -iname \"*.tar.gz\" -o -iname \"*.tar.bz2\" -o -iname \"*.tar.xz\" -o -iname \"*.tar.lz\" -o -iname \"*.tar.lzo\" -o -iname \"*.tar.lzma\" -o -iname \"*.tar.lzop\" -o -iname \"*.tar.lz4\" -o -iname \"*.tar.lzip\" \) -exec mv {} \"$TARGET_DIR/arc/\" \;"
END_TIME=$(date +%s)
echo "Archives moved in $((END_TIME - START_TIME)) seconds."

# Move audio files
echo "Moving audio files..."
START_TIME=$(date +%s)
eval "$FIND_CMD \( -iname \"*.mp3\" -o -iname \"*.wav\" -o -iname \"*.flac\" -o -iname \"*.aac\" -o -iname \"*.ogg\" -o -iname \"*.m4a\" -o -iname \"*.wma\" \) -exec mv {} \"$TARGET_DIR/audio/\" \;"
END_TIME=$(date +%s)
echo "Audio files moved in $((END_TIME - START_TIME)) seconds."

# Move application package files
echo "Moving application packages..."
START_TIME=$(date +%s)
eval "$FIND_CMD \( -iname \"*.AppImage\" -o -iname \"*.deb\" -o -iname \"*.apk\" -o -iname \"*.ova\" -o -iname \"*.img\" -o -iname \"*.rpm\" \) -exec mv {} \"$TARGET_DIR/apps/\" \;"
END_TIME=$(date +%s)
echo "Application packages moved in $((END_TIME - START_TIME)) seconds."


# Calculate total runtime
TOTAL_END_TIME=$(date +%s)
TOTAL_RUNTIME=$((TOTAL_END_TIME - TOTAL_START_TIME))

echo "Organization complete in directory: $TARGET_DIR in $TOTAL_RUNTIME seconds."