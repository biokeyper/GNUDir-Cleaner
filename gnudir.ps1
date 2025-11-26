param(
    [Parameter(Mandatory=$true)]
    [string]$TargetDir,

    [switch]$Recurse,
    [switch]$DryRun,
    [switch]$ShowVerbose,
    [switch]$KeepEmpty,

    [ValidateSet("numbered","timestamp","overwrite","skip")]
    [string]$BackupMode = "numbered",

    [int]$DocsBatchSize = 0,

    [string[]]$Exclude,

    [string]$LogFile
)

# Safety checks
if ([string]::IsNullOrWhiteSpace($TargetDir) -or $TargetDir -eq "\") {
    Write-Error "Refusing to operate on root or empty target."
    exit 1
}
if (-not (Test-Path $TargetDir -PathType Container)) {
    Write-Error "Target directory does not exist: $TargetDir"
    exit 1
}
$TargetDir = (Resolve-Path $TargetDir).Path

# Categories
$Categories = @("img","vid","doc","arc","audio","apps","nany")

# Patterns
$Patterns = @{
    img   = ".png",".jpg",".jpeg",".webp",".gif",".bmp",".tiff",".tif",".svg",".ico",".heic",".heif",".avif"
    vid   = ".mp4",".mkv",".avi",".mov",".wmv",".flv",".webm",".mpeg",".mpg",".3gp",".3g2",".m4v"
    doc   = ".pdf",".txt",".doc",".docx",".xls",".xlsx",".ppt",".pptx",".odt",".ods",".odp",".csv",".epub",".mobi",".mht"
    arc   = ".zip",".tar",".7z",".gz",".bz2",".xz",".iso"
    audio = ".mp3",".wav",".flac",".aac",".ogg",".m4a",".wma",".opus",".aiff",".aif",".amr",".alac",".mka",".au",".spx"
    apps  = ".appimage",".run",".bin",".deb",".rpm",".pkg",".snap",".img",".ova"
}

# Logging buffer
$LogBuffer = @()
function Write-Log {
    param([string]$Status,[long]$Bytes,[string]$Source,[string]$Dest)
    if (-not $LogFile) { return }
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $LogBuffer += "$timestamp,$Status,$Bytes,$Source,$Dest"
}

# Human-readable size formatter
function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    elseif ($Bytes -ge 1MB) { return ("{0:N2} MB" -f ($Bytes / 1MB)) }
    elseif ($Bytes -ge 1KB) { return ("{0:N2} KB" -f ($Bytes / 1KB)) }
    else { return "$Bytes bytes" }
}

# Safe move with collision handling
function Safe-Move {
    param([System.IO.FileInfo]$SourceFile,[string]$DestDir)
    $Source = $SourceFile.FullName
    $Base   = $SourceFile.Name
    $Dest   = Join-Path $DestDir $Base
    $size   = $SourceFile.Length

    if ($DryRun) {
        Write-Host "DRY-RUN: $Source -> $DestDir"
        Write-Log "DRY-RUN" $size $Source $DestDir
        return
    }

    if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Force -Path $DestDir | Out-Null }

    if (Test-Path $Dest) {
        switch ($BackupMode) {
            "numbered" {
                $n = 1
                $NameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($Base)
                $Ext = [System.IO.Path]::GetExtension($Base)
                while (Test-Path (Join-Path $DestDir "$NameNoExt-$n$Ext")) { $n++ }
                $Dest = Join-Path $DestDir "$NameNoExt-$n$Ext"
            }
            "timestamp" {
                $ts = Get-Date -Format "yyyyMMddHHmmss"
                $NameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($Base)
                $Ext = [System.IO.Path]::GetExtension($Base)
                $Dest = Join-Path $DestDir "$NameNoExt-$ts$Ext"
            }
            "overwrite" { Remove-Item $Dest -Force }
            "skip" { return }
        }
    }

    try {
        Move-Item -LiteralPath $Source -Destination $Dest -Force
        if ($ShowVerbose) { Write-Host "Moved: $Source -> $Dest" }
        Write-Log "OK" $size $Source $Dest
        return $SourceFile
    }
    catch {
        Write-Warning "Failed to move: $Source -> $Dest. Error: $($_.Exception.Message)"
        Write-Log "ERROR" $size $Source $Dest
    }
}

# Start timer
$startTime = Get-Date

# Collect files, excluding numbered batch folders in doc/ to prevent re-processing already batched files
$gciParams = @{ Path = $TargetDir; File = $true; ErrorAction = 'SilentlyContinue' }
if ($Recurse) { $gciParams.Recurse = $true }
$AllFiles = Get-ChildItem @gciParams | Where-Object { 
    $file = $_
    $relativePath = $file.FullName.Substring($TargetDir.Length + 1)
    $Exclude -notcontains $file.FullName -and
    # Exclude files in doc/{digit}/ batch folders only, not all of doc/
    -not ($relativePath -match '^doc\\(\d+)\\')
}

$Processed = @()
$CategoryStats = @{}

# Run categories
foreach ($c in $Categories) {
    if ($c -eq "nany") { continue }
    $Files = $AllFiles | Where-Object { $Patterns[$c] -contains $_.Extension.ToLower() }
    $count = 0; $bytes = 0
    foreach ($f in $Files) {
        $MovedFile = Safe-Move -SourceFile $f -DestDir (Join-Path $TargetDir $c)
        if ($MovedFile) { $Processed += $f; $count++; $bytes += $f.Length }
    }
    $CategoryStats[$c] = @{ Count = $count; Bytes = $bytes }
    Write-Host "$c moved: $count files"
}


# Docs batching
if ($DocsBatchSize -gt 0) {
    $docRoot = Join-Path $TargetDir "doc"
    if (Test-Path $docRoot) {
        # Get only files directly in doc root (not subdirectories)
        $Docs = Get-ChildItem $docRoot -File

        if ($Docs.Count -gt 0) {
            if ($ShowVerbose) {
                Write-Host "Batching $($Docs.Count) documents into groups of $DocsBatchSize ..."
                Write-Host "First file: $($Docs[0].FullName)"
                Write-Host "File exists: $(Test-Path $Docs[0].FullName)"
            } else {
                Write-Host "Batching $($Docs.Count) documents into groups of $DocsBatchSize ..."
            }
            
            # Find existing batch folders and calculate next batch number
            $existingBatchFolders = Get-ChildItem $docRoot -Directory | Where-Object { $_.Name -match '^\d+$' }
            $maxBatch = 0
            if ($existingBatchFolders.Count -gt 0) {
                $maxBatch = $existingBatchFolders.Name | ForEach-Object { [int]$_ } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
            }
            $batch = $maxBatch + 1
            $i = 1
            $movedCount = 0
            
            $BatchDir = Join-Path $docRoot "$batch"
            if (-not (Test-Path $BatchDir)) { New-Item -ItemType Directory -Force -Path $BatchDir | Out-Null }

            foreach ($f in $Docs) {
                if ($i -gt $DocsBatchSize) {
                    $batch++; $i = 1
                    $BatchDir = Join-Path $docRoot "$batch"
                    if (-not (Test-Path $BatchDir)) { New-Item -ItemType Directory -Force -Path $BatchDir | Out-Null }
                }
                try {
                    Move-Item -LiteralPath $f.FullName -Destination $BatchDir -Force -ErrorAction Stop
                    if ($ShowVerbose) { Write-Host "Batched: $($f.Name) -> $batch" }
                    $movedCount++
                } catch {
                    if ($ShowVerbose) { Write-Host "ERROR batching $($f.Name): $($_.Exception.Message)" }
                }
                $i++
            }
            Write-Host "Documents batched: $movedCount files into folders (highest folder: $batch, starting from $($maxBatch + 1))."
        } else {
            if ($ShowVerbose) { Write-Host "No new documents to batch." }
        }
    }
}



# Miscellaneous
$MiscFiles = $AllFiles | Where-Object { $Processed -notcontains $_ }
$count = 0; $bytes = 0
foreach ($f in $MiscFiles) {
    $MovedFile = Safe-Move -SourceFile $f -DestDir (Join-Path $TargetDir "nany")
    if ($MovedFile) { $Processed += $f; $count++; $bytes += $f.Length }
}
$CategoryStats["nany"] = @{ Count = $count; Bytes = $bytes }

# Remove empty directories deepest-first, including whole branches
if (-not $KeepEmpty) {
    Get-ChildItem -Path $TargetDir -Recurse -Directory |
        Sort-Object FullName -Descending |
        ForEach-Object {
            $hasChildren = (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
            if (-not $hasChildren) {
                Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                if ($ShowVerbose) { Write-Host "Removed empty directory: $($_.FullName)" }
            }
        }
}



# Totals
$TOTAL_END_TIME = Get-Date
$TOTAL_RUNTIME  = ($TOTAL_END_TIME - $startTime).TotalSeconds
$totalFiles     = $Processed.Count
$totalBytes     = ($Processed | Measure-Object Length -Sum).Sum
$hrSize         = Format-Size $totalBytes

Write-Host "Organization complete in directory: $TargetDir - $totalFiles files, $hrSize in $TOTAL_RUNTIME seconds."
Write-Host "Per-category totals:"
foreach ($c in $Categories) {
    $count = $CategoryStats[$c].Count
    $bytes = $CategoryStats[$c].Bytes
    $hr    = Format-Size $bytes
    Write-Host ("  {0,-6} {1,6} files, {2}" -f $c, $count, $hr)
}

# Flush logs with summary
if ($LogFile) {
    "Timestamp,Status,Bytes,Source,Destination" | Out-File -FilePath $LogFile -Encoding UTF8
    $LogBuffer | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "SUMMARY,OK,$totalBytes,$totalFiles,$TargetDir,$TOTAL_RUNTIME seconds" | Out-File -FilePath $LogFile -Append -Encoding UTF8

    foreach ($c in $Categories) {
        $count = $CategoryStats[$c].Count
        $bytes = $CategoryStats[$c].Bytes
        $hr    = Format-Size $bytes
        "CATEGORY,$c,$bytes,$count,$hr" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}
