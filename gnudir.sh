#!/usr/bin/env bash

# GNUDIR Cleaner - safer, featureful version
# - safe find usage (no eval)
# - safe_mv with collision handling
# - CLI flags: --recurse, --dry-run, --verbose, --backup-mode, --exclude, --keep-empty

set -o pipefail

# Default settings
RECURSE=false
DRY_RUN=false
VERBOSE=false
KEEP_EMPTY=false
BACKUP_MODE="numbered" # numbered|timestamp|overwrite|skip
DOCS_BATCH_SIZE=0
EXCLUDES=()

usage() {
    cat <<'EOF'
Usage: gnudir.sh [options] <directory>

Options:
  --recurse            Recurse into subdirectories
  --dry-run            Show actions but do not move files
  --verbose            Print per-file operations
  --backup-mode MODE   Collision handling: numbered|timestamp|overwrite|skip (default: numbered)
  --exclude PATH       Exclude path (may be used multiple times)
  --keep-empty         Do not delete empty directories after organizing
  --help               Show this help

Example:
  gnudir.sh --recurse --dry-run ~/Downloads
EOF
}

# Parse arguments
ARGS=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --recurse) RECURSE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --log) LOGFILE="$2"; shift 2 ;;
        --yes|--force) FORCE=true; shift ;;
        --keep-empty) KEEP_EMPTY=true; shift ;;
        --backup-mode) BACKUP_MODE="$2"; shift 2 ;;
        --exclude) EXCLUDES+=("$2"); shift 2 ;;
        --docs-batch-size) DOCS_BATCH_SIZE=${2:-0}; shift 2 ;;
        --help) usage; exit 0 ;;
        --*) echo "Unknown option: $1"; usage; exit 1 ;;
        *) ARGS+=("$1"); shift ;;
    esac
done

if [ ${#ARGS[@]} -lt 1 ]; then
    echo "Error: target directory required"
    usage
    exit 1
fi

TARGET_DIR=${ARGS[0]}

# Safety checks
if [ "$TARGET_DIR" = "/" ] || [ -z "$TARGET_DIR" ]; then
    echo "Refusing to operate on root '/' or empty target. Provide a valid target directory."
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory does not exist: $TARGET_DIR"
    exit 1
fi

# canonicalize target dir
if command -v realpath >/dev/null 2>&1; then
    TARGET_DIR=$(realpath "$TARGET_DIR")
else
    TARGET_DIR=$(cd "$TARGET_DIR" && pwd -P)
fi

# Start total runtime timer
TOTAL_START_TIME=$(date +%s)

# Categories and directories
CATEGORIES=(img vid doc arc audio apps nany)
# create category dirs except 'nany' (lazy)
for d in "${CATEGORIES[@]}"; do
    [ "$d" = "nany" ] && continue
    mkdir -p "$TARGET_DIR/$d"
done

# Logging and force
LOGFILE=""
FORCE=false

log_entry() {
    # log format: ISO8601	STATUS	BYTES	SRC	DEST
    [ -z "$LOGFILE" ] && return 0
    local status="$1" bytes="$2" src="$3" dest="$4"
    printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$status" "$bytes" "$src" "$dest" >> "$LOGFILE"
}

# Utility: human-readable size
hr() {
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec --suffix=B --format="%.0f" "$1"
    else
        echo "$1 bytes"
    fi
}

# safe_mv: move file to destdir with collision handling and skip-same-file
safe_mv() {
    local src="$1" destdir="$2"
    local base dest src_real dest_real size
    base=$(basename -- "$src")
    dest="$destdir/$base"
    # canonical paths
    if command -v realpath >/dev/null 2>&1; then
        src_real=$(realpath "$src" 2>/dev/null || printf "%s" "$src")
        dest_real=$(realpath -m "$dest" 2>/dev/null || printf "%s" "$dest")
    else
        src_real=$(readlink -f "$src" 2>/dev/null || printf "%s" "$src")
        dest_real=$(readlink -f "$dest" 2>/dev/null || printf "%s" "$dest")
    fi

    # skip moving if same file
    if [ "$src_real" = "$dest_real" ]; then
        $VERBOSE && echo "Skipping (same file): $src"
        return 0
    fi

    # determine size
    if size=$(stat -c%s -- "$src" 2>/dev/null); then :; else size=$(wc -c <"$src" 2>/dev/null || echo 0); fi

    # Dry-run: print to stderr so callers don't capture non-numeric output
    if [ "$DRY_RUN" = true ]; then
        echo "DRY-RUN: mv '$src' -> '$destdir/'" >&2
        # also log planned action
        log_entry "DRY-RUN" "$size" "$src" "$destdir/"
        return 0
    fi

    # collision handling
    if [ -e "$dest" ]; then
        case "$BACKUP_MODE" in
            numbered)
                local n=1 name_noext extpart
                name_noext="${base%.*}"
                extpart="${base#${name_noext}}"
                if [ "$name_noext" = "$base" ]; then
                    name_noext="$base"; extpart=""
                fi
                while [ -e "$destdir/${name_noext}-$n$extpart" ]; do n=$((n+1)); done
                dest="$destdir/${name_noext}-$n$extpart"
                ;;
            timestamp)
                local ts
                ts=$(date +%Y%m%d%H%M%S)
                dest="$destdir/${base%.*}-$ts.${base##*.}"
                ;;
            overwrite)
                rm -f -- "$dest" || true
                ;;
            skip)
                $VERBOSE && echo "Skipping existing: $dest"
                return 0
                ;;
            *)
                echo "Unknown backup mode: $BACKUP_MODE"; return 1
                ;;
        esac
    fi

    # perform move
    if mv -- "$src" "$dest" 2>/dev/null; then
        $VERBOSE && echo "Moved: '$src' -> '$dest'" >&2
        log_entry "OK" "$size" "$src" "$dest"
        printf "%s\t%s\n" "$size" "$dest"
        return 0
    else
        # fallback to rsync for cross-filesystem moves
        if command -v rsync >/dev/null 2>&1; then
            $VERBOSE && echo "mv failed, trying rsync fallback for: '$src' -> '$destdir/'" >&2
            if rsync -a --remove-source-files -- "$src" "$destdir/" 2>/dev/null; then
                # rename if dest basename differs
                base=$(basename -- "$src")
                target="$destdir/$base"
                if [ "$target" != "$dest" ]; then
                    mv -- "$target" "$dest" 2>/dev/null || true
                fi
                $VERBOSE && echo "Rsync moved: '$src' -> '$dest'" >&2
                log_entry "OK-RSYNC" "$size" "$src" "$dest"
                printf "%s\t%s\n" "$size" "$dest"
                return 0
            else
                echo "Rsync fallback failed for: $src -> $destdir" >&2
                log_entry "ERROR" "$size" "$src" "$dest"
                return 1
            fi
        fi
        echo "Failed to move: $src -> $dest" >&2
        log_entry "ERROR" "$size" "$src" "$dest"
        return 1
    fi
}

# Build common find args
find_base=("$TARGET_DIR")
if [ "$RECURSE" != true ]; then
    find_base+=( -maxdepth 1 )
fi
find_base+=( -type f )

# exclude organizing dirs and user-specified excludes
for sub in "${CATEGORIES[@]}"; do
    find_base+=( -not -path "$TARGET_DIR/$sub" -not -path "$TARGET_DIR/$sub/*" )
done
for excl in "${EXCLUDES[@]}"; do
    if [ -n "$excl" ]; then
        find_base+=( -not -path "$excl" -not -path "$excl/*" )
    fi
done

# Category patterns (case-insensitive via -iname)
img_patterns=("*.png" "*.jpg" "*.jpeg" "*.webp" "*.gif" "*.bmp" "*.tiff" "*.tif" "*.svg" "*.ico" "*.heic" "*.heif" "*.avif")
vid_patterns=("*.mp4" "*.mkv" "*.avi" "*.mov" "*.wmv" "*.flv" "*.webm" "*.mpeg" "*.mpg" "*.3gp" "*.3g2" "*.m4v")
doc_patterns=("*.pdf" "*.txt" "*.doc" "*.docx" "*.xls" "*.xlsx" "*.ppt" "*.pptx" "*.odt" "*.ods" "*.odp" "*.csv" "*.epub" "*.mobi")
arc_patterns=("*.zip" "*.tar" "*.7z" "*.tar.gz" "*.tar.bz2" "*.tar.xz" "*.xz" "*.iso" "*.gz" "*.bz2")
audio_patterns=("*.mp3" "*.wav" "*.flac" "*.aac" "*.ogg" "*.m4a" "*.wma" "*.opus" "*.aiff" "*.aif" "*.amr" "*.alac" "*.mka" "*.au" "*.spx")
apps_patterns=("*.AppImage" "*.appimage" "*.run" "*.bin" "*.deb" "*.rpm" "*.pkg" "*.snap" "*.img" "*.ova")

# counters and sizes
declare -A count size_bytes
for c in "${CATEGORIES[@]}"; do count[$c]=0; size_bytes[$c]=0; done

# helper to run find for a category and move files
run_category() {
    local cat="$1"; shift
    local -n patterns=$1
    local destdir="$TARGET_DIR/$cat"
    $VERBOSE && echo "Moving ${cat}..."
    local start end elapsed
    start=$(date +%s)
    if [ ${#patterns[@]} -eq 0 ]; then return; fi
    # build pattern expression for find
    local expr=()
    expr+=(\( )
    local first=true
    for p in "${patterns[@]}"; do
        if [ "$first" = true ]; then
            expr+=( -iname "$p" )
            first=false
        else
            expr+=( -o -iname "$p" )
        fi
    done
    expr+=( \) )

    # run find safely
    while IFS= read -r -d '' f; do
        result=$(safe_mv "$f" "$destdir") || continue
        if [ -n "$result" ]; then
            s=$(printf '%s' "$result" | cut -f1)
            ((count[$cat]++))
            size_bytes[$cat]=$((size_bytes[$cat] + s))
        fi
    done < <(find "${find_base[@]}" "${expr[@]}" -print0 2>/dev/null)

    end=$(date +%s)
    elapsed=$((end - start))
    echo "${cat^} moved: ${count[$cat]} files, $(hr ${size_bytes[$cat]}) in ${elapsed} seconds."
}

# Run each category
run_category img img_patterns
run_category vid vid_patterns
run_category doc doc_patterns
run_category arc arc_patterns
run_category audio audio_patterns
run_category apps apps_patterns

# docs batching
if [ "$DOCS_BATCH_SIZE" -gt 0 ]; then
    echo "Batching documents into groups of $DOCS_BATCH_SIZE..."
    i=1; batch=1
    mkdir -p "$TARGET_DIR/doc/1"
    for f in "$TARGET_DIR"/doc/*; do
        [ -f "$f" ] || continue
        if [ $i -gt $DOCS_BATCH_SIZE ]; then
            batch=$((batch+1)); i=1; mkdir -p "$TARGET_DIR/doc/$batch"
        fi
        mv -- "$f" "$TARGET_DIR/doc/$batch/" 2>/dev/null || true
        i=$((i+1))
    done
    echo "Documents batched into $batch folders."
fi

# move leftover files (unknown) into nany
echo "Moving miscellaneous files..."
start_misc=$(date +%s)
while IFS= read -r -d '' f; do
    [ -f "$f" ] || continue
    parent=$(dirname -- "$f")
    # skip files already inside category dirs
    case "$parent" in
        "$TARGET_DIR"|"$TARGET_DIR/img"|"$TARGET_DIR/vid"|"$TARGET_DIR/doc"|"$TARGET_DIR/arc"|"$TARGET_DIR/audio"|"$TARGET_DIR/apps"|"$TARGET_DIR/nany")
            ;;
    esac
    result=$(safe_mv "$f" "$TARGET_DIR/nany") || continue
    if [ -n "$result" ]; then
        s=$(printf '%s' "$result" | cut -f1)
        ((count[nany]++))
        size_bytes[nany]=$((size_bytes[nany] + s))
    fi
done < <(find "${find_base[@]}" -print0 2>/dev/null)
end_misc=$(date +%s)
echo "Misc moved: ${count[nany]} files, $(hr ${size_bytes[nany]}) in $((end_misc - start_misc)) seconds."

# Delete empty directories (safely)
if [ "$KEEP_EMPTY" != true ]; then
    echo "Removing empty directories..."
    # confirm overwrite/cleanup if necessary
    if [ "$BACKUP_MODE" = "overwrite" ] && [ "$FORCE" != true ]; then
        read -r -p "Backup mode 'overwrite' is destructive. Continue? [y/N] " ans
        case "$ans" in [Yy]*) ;; *) echo "Aborting per user choice."; exit 1 ;; esac
    fi

    find "$TARGET_DIR" -depth -type d -empty \
        -not -path "$TARGET_DIR" \
        -not -path "$TARGET_DIR/img" -not -path "$TARGET_DIR/img/*" \
        -not -path "$TARGET_DIR/vid" -not -path "$TARGET_DIR/vid/*" \
        -not -path "$TARGET_DIR/doc" -not -path "$TARGET_DIR/doc/*" \
        -not -path "$TARGET_DIR/arc" -not -path "$TARGET_DIR/arc/*" \
        -not -path "$TARGET_DIR/audio" -not -path "$TARGET_DIR/audio/*" \
        -not -path "$TARGET_DIR/apps" -not -path "$TARGET_DIR/apps/*" \
        -not -path "$TARGET_DIR/nany" -not -path "$TARGET_DIR/nany/*" \
        -delete 2>/dev/null || true
fi

# Totals
TOTAL_END_TIME=$(date +%s)
TOTAL_RUNTIME=$((TOTAL_END_TIME - TOTAL_START_TIME))
total_files=0; total_bytes=0
for c in "${CATEGORIES[@]}"; do
    total_files=$((total_files + count[$c]))
    total_bytes=$((total_bytes + size_bytes[$c]))
done

echo "Organization complete in directory: $TARGET_DIR — ${total_files} files, $(hr $total_bytes) in $TOTAL_RUNTIME seconds."

exit 0
#!/bin/bash

# Check if a directory is provided as an argument
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <directory> [--recurse]"
    #!/usr/bin/env bash

    # GNUDIR Cleaner - safer, featureful version
    # - safe find usage (no eval)
    # - safe_mv with collision handling
    # - CLI flags: --recurse, --dry-run, --verbose, --backup-mode, --exclude, --keep-empty

    set -o pipefail

    # Default settings
    RECURSE=false
    DRY_RUN=false
    VERBOSE=false
    KEEP_EMPTY=false
    BACKUP_MODE="numbered" # numbered|timestamp|overwrite|skip
    DOCS_BATCH_SIZE=0
    EXCLUDES=()

    usage() {
        cat <<EOF
    Usage: $0 [options] <directory>

    Options:
      --recurse            Recurse into subdirectories
      --dry-run            Show actions but do not move files
      --verbose            Print per-file operations
      --backup-mode MODE   Collision handling: numbered|timestamp|overwrite|skip (default: numbered)
      --exclude PATH       Exclude path (may be used multiple times)
      --keep-empty         Do not delete empty directories after organizing
      --help               Show this help

    Example:
      $0 --recurse --dry-run ~/Downloads
    EOF
    }

    # Parse arguments
    ARGS=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --recurse) RECURSE=true; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --verbose) VERBOSE=true; shift ;;
            --keep-empty) KEEP_EMPTY=true; shift ;;
            --backup-mode) BACKUP_MODE="$2"; shift 2 ;;
            --exclude) EXCLUDES+=("$2"); shift 2 ;;
            --help) usage; exit 0 ;;
            --*) echo "Unknown option: $1"; usage; exit 1 ;;
            *) ARGS+=("$1"); shift ;;
        esac
    done

    if [ ${#ARGS[@]} -lt 1 ]; then
        echo "Error: target directory required"
        usage
        exit 1
    fi

    TARGET_DIR=${ARGS[0]}

    # Safety checks
    if [ "$TARGET_DIR" = "/" ] || [ -z "$TARGET_DIR" ]; then
        echo "Refusing to operate on root '/' or empty target. Provide a valid target directory."
        exit 1
    fi

    if [ ! -d "$TARGET_DIR" ]; then
        echo "Target directory does not exist: $TARGET_DIR"
        exit 1
    fi

    # canonicalize target dir
    if command -v realpath >/dev/null 2>&1; then
        TARGET_DIR=$(realpath "$TARGET_DIR")
    else
        TARGET_DIR=$(cd "$TARGET_DIR" && pwd -P)
    fi

    # Start total runtime timer
    TOTAL_START_TIME=$(date +%s)

    # Categories and directories
    CATEGORIES=(img vid doc arc audio apps nany)
    for d in "${CATEGORIES[@]}"; do
        mkdir -p "$TARGET_DIR/$d"
    done

    # Utility: human-readable size
    hr() {
        if command -v numfmt >/dev/null 2>&1; then
            numfmt --to=iec --suffix=B --format="%.0f" "$1"
        else
            echo "$1 bytes"
        fi
    }

    # safe_mv: move file to destdir with collision handling and skip-same-file
    safe_mv() {
        local src="$1" destdir="$2"
        local name base ext dest size src_real dest_real
        base=$(basename -- "$src")
        dest="$destdir/$base"
        # canonical paths
        if command -v realpath >/dev/null 2>&1; then
            src_real=$(realpath "$src") || src_real="$src"
            # realpath on non-existing target may fail; build dest_real accordingly
            dest_real=$(realpath -m "$dest" 2>/dev/null || printf "%s" "$dest")
        else
            src_real=$(readlink -f "$src") || src_real="$src"
            dest_real=$(readlink -f "$dest" 2>/dev/null || printf "%s" "$dest")
        fi

        # skip moving if same file
        if [ "$src_real" = "$dest_real" ]; then
            $VERBOSE && echo "Skipping (same file): $src"
            return 0
        fi

        # determine size
        if size=$(stat -c%s -- "$src" 2>/dev/null); then :; else size=$(wc -c <"$src" 2>/dev/null || echo 0); fi

        # Dry-run
        if [ "$DRY_RUN" = true ]; then
            echo "DRY-RUN: mv '$src' -> '$destdir/'"
            return 0
        fi

        # collision handling
        if [ -e "$dest" ]; then
            case "$BACKUP_MODE" in
                numbered)
                    local n=1 name_noext extpart
                    name_noext="${base%.*}"
                    extpart="${base#${name_noext}}"
                    # if base had no extension, extpart equals base; handle
                    if [ "$name_noext" = "$base" ]; then
                        name_noext="$base"; extpart=""
                    fi
                    while [ -e "$destdir/${name_noext}-$n$extpart" ]; do n=$((n+1)); done
                    dest="$destdir/${name_noext}-$n$extpart"
                    ;;
                timestamp)
                    local ts
                    ts=$(date +%Y%m%d%H%M%S)
                    dest="$destdir/${base%.*}-$ts.${base##*.}"
                    ;;
                overwrite)
                    rm -f -- "$dest" || true
                    ;;
                skip)
                    $VERBOSE && echo "Skipping existing: $dest"
                    return 0
                    ;;
                *)
                    echo "Unknown backup mode: $BACKUP_MODE"; return 1
                    ;;
            esac
        fi

        # perform move
        if mv -- "$src" "$dest" 2>/dev/null; then
            # report
            echo_op=""
            if [ "$VERBOSE" = true ]; then
                echo "Moved: '$src' -> '$dest'"
            fi
            # return size via global accumulate (caller handles)
            printf "%s\t%s\n" "$size" "$dest"
            return 0
        else
            echo "Failed to move: $src -> $dest" >&2
            return 1
        fi
    }

    # Build common find args
    find_base=("$TARGET_DIR")
    if [ "$RECURSE" != true ]; then
        find_base+=( -maxdepth 1 )
    fi
    find_base+=( -type f )

    # exclude organizing dirs and user-specified excludes
    for sub in "${CATEGORIES[@]}"; do
        # exclude both dir and its contents
        find_base+=( -not -path "$TARGET_DIR/$sub" -not -path "$TARGET_DIR/$sub/*" )
    done
    for excl in "${EXCLUDES[@]}"; do
        # allow user to pass either absolute or relative; canonicalize
        if [ -n "$excl" ]; then
            find_base+=( -not -path "$excl" -not -path "$excl/*" )
        fi
    done

    # Category patterns (case-insensitive via -iname)
    img_patterns=("*.png" "*.jpg" "*.jpeg" "*.webp" "*.gif" "*.bmp" "*.tiff" "*.tif" "*.svg" "*.ico" "*.heic" "*.heif" "*.avif")
    vid_patterns=("*.mp4" "*.mkv" "*.avi" "*.mov" "*.wmv" "*.flv" "*.webm" "*.mpeg" "*.mpg" "*.3gp" "*.3g2" "*.m4v")
    doc_patterns=("*.pdf" "*.txt" "*.doc" "*.docx" "*.xls" "*.xlsx" "*.ppt" "*.pptx" "*.odt" "*.ods" "*.odp" "*.csv" "*.epub" "*.mobi")
    arc_patterns=("*.zip" "*.tar" "*.7z" "*.tar.gz" "*.tar.bz2" "*.tar.xz" "*.xz" "*.iso" "*.gz" "*.bz2")
    audio_patterns=("*.mp3" "*.wav" "*.flac" "*.aac" "*.ogg" "*.m4a" "*.wma" "*.opus" "*.aiff" "*.aif" "*.amr" "*.alac" "*.mka" "*.au" "*.spx")
    apps_patterns=("*.AppImage" "*.appimage" "*.run" "*.bin" "*.deb" "*.rpm" "*.pkg" "*.snap" "*.img" "*.ova" )

    # counters and sizes
    declare -A count size_bytes
    for c in "${CATEGORIES[@]}"; do count[$c]=0; size_bytes[$c]=0; done

    # helper to run find for a category and move files
    run_category() {
        local cat="$1"; shift
        local -n patterns=$1
        local destdir="$TARGET_DIR/$cat"
        $VERBOSE && echo "Moving ${cat}..."
        local start end elapsed
        start=$(date +%s)
        # build find expression
        # use -print0 and while read -d ''
        if [ ${#patterns[@]} -eq 0 ]; then return; fi
        mapfile -t find_cmd < <(printf '%s\n' "${find_base[@]}")
        # run find with patterns
        # Construct args: find_base '(' -iname p1 -o -iname p2 ... ')'
        if printf '%s\n' "${patterns[@]}" | grep -q .; then
            # Use subshell to process null-delimited
            find "${find_base[@]}" \( $(for p in "${patterns[@]}"; do printf -- '-iname "%s" -o ' "$p"; done) -false \) -print0 2>/dev/null | \
                while IFS= read -r -d '' f; do
                    result=$(safe_mv "$f" "$destdir") || continue
                    # safe_mv prints a size\tpath on success
                    if [ -n "$result" ]; then
                        s=$(printf '%s' "$result" | cut -f1)
                        ((count[$cat]++))
                        size_bytes[$cat]=$((size_bytes[$cat] + s))
                    fi
                done
        fi
        end=$(date +%s)
        elapsed=$((end - start))
        echo "${cat^} moved: ${count[$cat]} files, $(hr ${size_bytes[$cat]}) in ${elapsed} seconds."
    }

    # Run each category
    run_category img img_patterns
    run_category vid vid_patterns
    run_category doc doc_patterns
    run_category arc arc_patterns
    run_category audio audio_patterns
    run_category apps apps_patterns

    # move leftover files (unknown) into nany
    echo "Moving miscellaneous files..."
    start_misc=$(date +%s)
    find "${find_base[@]}" -print0 2>/dev/null | while IFS= read -r -d '' f; do
        # ensure file still exists and is not in one of the dest dirs
        [ -f "$f" ] || continue
        # check if file was moved earlier by comparing parent dir
        parent=$(dirname -- "$f")
        case "$parent" in
            "$TARGET_DIR"|"$TARGET_DIR/img"|"$TARGET_DIR/vid"|"$TARGET_DIR/doc"|"$TARGET_DIR/arc"|"$TARGET_DIR/audio"|"$TARGET_DIR/apps"|"$TARGET_DIR/nany")
                # top-level files allowed; others skip
                ;;
        esac
        # ensure nany exists lazily
        mkdir -p "$TARGET_DIR/nany"
        result=$(safe_mv "$f" "$TARGET_DIR/nany") || continue
        if [ -n "$result" ]; then
            s=$(printf '%s' "$result" | cut -f1)
            ((count[nany]++))
            size_bytes[nany]=$((size_bytes[nany] + s))
        fi
    done
    end_misc=$(date +%s)
    echo "Misc moved: ${count[nany]} files, $(hr ${size_bytes[nany]}) in $((end_misc - start_misc)) seconds."

    # Delete empty directories (safely)
    if [ "$KEEP_EMPTY" != true ]; then
        # safety: do not delete outside TARGET_DIR; exclude organizing dirs
        echo "Removing empty directories..."
        find "$TARGET_DIR" -depth -type d -empty \
            -not -path "$TARGET_DIR" \
            -not -path "$TARGET_DIR/img" -not -path "$TARGET_DIR/img/*" \
            -not -path "$TARGET_DIR/vid" -not -path "$TARGET_DIR/vid/*" \
            -not -path "$TARGET_DIR/doc" -not -path "$TARGET_DIR/doc/*" \
            -not -path "$TARGET_DIR/arc" -not -path "$TARGET_DIR/arc/*" \
            -not -path "$TARGET_DIR/audio" -not -path "$TARGET_DIR/audio/*" \
            -not -path "$TARGET_DIR/apps" -not -path "$TARGET_DIR/apps/*" \
            -not -path "$TARGET_DIR/nany" -not -path "$TARGET_DIR/nany/*" \
            -delete 2>/dev/null || true
    fi

    # Totals
    TOTAL_END_TIME=$(date +%s)
    TOTAL_RUNTIME=$((TOTAL_END_TIME - TOTAL_START_TIME))
    total_files=0; total_bytes=0
    for c in "${CATEGORIES[@]}"; do
        total_files=$((total_files + count[$c]))
        total_bytes=$((total_bytes + size_bytes[$c]))
    done

    echo "Organization complete in directory: $TARGET_DIR — ${total_files} files, $(hr $total_bytes) in $TOTAL_RUNTIME seconds."

    exit 0
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



# Remove empty directories (excluding the main target and its main subfolders)
echo "Deleting empty directories..."
START_TIME=$(date +%s)
find "$TARGET_DIR" -type d -empty \
    -not -path "$TARGET_DIR" \
    -not -path "$TARGET_DIR/img" \
    -not -path "$TARGET_DIR/vid" \
    -not -path "$TARGET_DIR/doc" \
    -not -path "$TARGET_DIR/arc" \
    -not -path "$TARGET_DIR/audio" \
    -not -path "$TARGET_DIR/apps" \
    -delete
END_TIME=$(date +%s)
echo "Empty directories deleted in $((END_TIME - START_TIME)) seconds."

# echo "Organization complete in directory: $TARGET_DIR in $TOTAL_RUNTIME seconds."


# Calculate total runtime
TOTAL_END_TIME=$(date +%s)
TOTAL_RUNTIME=$((TOTAL_END_TIME - TOTAL_START_TIME))

echo "Organization complete in directory: $TARGET_DIR in $TOTAL_RUNTIME seconds."