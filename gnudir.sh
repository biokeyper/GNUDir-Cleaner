#!/bin/bash

# Check if a directory is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

TARGET_DIR="$1"

# Create directories for organization if they don't already exist
[ ! -d "$TARGET_DIR/img" ] && mkdir -p "$TARGET_DIR/img"
[ ! -d "$TARGET_DIR/vid" ] && mkdir -p "$TARGET_DIR/vid"
[ ! -d "$TARGET_DIR/doc" ] && mkdir -p "$TARGET_DIR/doc"
[ ! -d "$TARGET_DIR/arc" ] && mkdir -p "$TARGET_DIR/arc"

# Move image files
mv "$TARGET_DIR"/*.png "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.PNG "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.jpg "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.JPG "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.jpeg "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.JPEG "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.gif "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.GIF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.bmp "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.BMP "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.tiff "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.TIFF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.tif "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.TIF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.webp "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.WEBP "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.svg "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.SVG "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.ico "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.ICO "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.heic "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.HEIC "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.heif "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.HEIF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.avif "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.AVIF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.arw "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.ARW "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.cr2 "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.CR2 "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.nef "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.NEF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.orf "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.ORF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.rw2 "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.RW2 "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.dng "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.DNG "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.3fr "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.3FR "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.arw "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.ARW "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.crw "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.CRW "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.kdc "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.KDC "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.mef "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.MEF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.pef "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.PEF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.raf "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.RAF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.rwz "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.RWZ "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.srf "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.SRF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.srw "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.SRW "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.x3f "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.X3F "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.dcr "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.DCR "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.dng "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.DNG "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.erf "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.ERF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.gif "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.GIF "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.indd "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.INDD "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.aae "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.AAE "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.jxr "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.JXR "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.jpe "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.JPE "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.jif "$TARGET_DIR/img/" 2>/dev/null
mv "$TARGET_DIR"/*.JIF "$TARGET_DIR/img/" 2>/dev/null

# Move video files
mv "$TARGET_DIR"/*.mp4 "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.MP4 "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.mkv "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.MKV "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.avi "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.AVI "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.mov "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.MOV "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.wmv "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.WMV "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.flv "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.FLV "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.webm "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.WEBM "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.mpeg "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.MPEG "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.mpg "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.MPG "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.3gp "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.3GP "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.3g2 "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.3G2 "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.m4v "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.M4V "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.rm "$TARGET_DIR/vid/" 2>/dev/null    
mv "$TARGET_DIR"/*.RM "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.rmvb "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.RMVB "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.m2ts "$TARGET_DIR/vid/" 2>/dev/null
mv "$TARGET_DIR"/*.M2TS "$TARGET_DIR/vid/" 2>/dev/null

# Move document files
mv "$TARGET_DIR"/*.pdf "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.PDF "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.txt "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.TXT "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.doc "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.DOC "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.docx "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.DOCX "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.xls "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.XLS "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.xlsx "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.XLSX "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.ppt "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.PPT "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.pptx "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.PPTX "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.odt "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.ODT "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.ods "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.ODS "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.odp "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.ODP "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.csv "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.CSV "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.epub "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.EPUB "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.mobi "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.MOBI "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.azw "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.AZW "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.azw3 "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.AZW3 "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.fb2 "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.FB2 "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.fbz "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.FBZ "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.fbz2 "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.FBZ2 "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.fbz3 "$TARGET_DIR/doc/" 2>/dev/null
mv "$TARGET_DIR"/*.FBZ3 "$TARGET_DIR/doc/" 2>/dev/null

# Move archive files
mv "$TARGET_DIR"/*.zip "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.iso "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.xz "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.deb "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.gz "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.rar "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.bz2 "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.7z "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.gz "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.bz2 "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.xz "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.lz "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.lzo "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.lzma "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.lzop "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.lz4 "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.lzip "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.lz4 "$TARGET_DIR/arc/" 2>/dev/null
mv "$TARGET_DIR"/*.tar.lzip "$TARGET_DIR/arc/" 2>/dev/null

echo "Organization complete in directory: $TARGET_DIR"