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

# Collect files
$gciParams = @{ Path = $TargetDir; File = $true; ErrorAction = 'SilentlyContinue' }
if ($Recurse) { $gciParams.Recurse = $true }
$AllFiles = Get-ChildItem @gciParams | Where-Object { $Exclude -notcontains $_.FullName }

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
    $Docs = Get-ChildItem (Join-Path $TargetDir "doc") -File
    $i = 1; $batch = 1
    foreach ($f in $Docs) {
        if ($i -gt $DocsBatchSize) { $batch++; $i = 1 }
        $BatchDir = Join-Path $TargetDir "doc\$batch"
        if (-not (Test-Path $BatchDir)) { New-Item -ItemType Directory -Force -Path $BatchDir | Out-Null }
        Move-Item $f.FullName -Destination $BatchDir -Force
        $i++
    }
    Write-Host "Documents batched into $batch folders."
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
# if (-not $KeepEmpty) {
#     Get-ChildItem -Path $TargetDir -Recurse -Directory |
#         Sort-Object FullName -Descending |
#         ForEach-Object {
#             # Count only real files (exclude directories)
#             $fileCount = (Get-ChildItem $_.FullName -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
#             if ($fileCount -eq 0) {
#                 # If no files remain, remove the directory (children already removed first)
#                 Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
#                 if ($ShowVerbose) { Write-Host "Removed empty directory: $($_.FullName)" }
#             }
#         }
# }

# Remove empty directories deepest-first, including whole branches
if (-not $KeepEmpty) {
    Get-ChildItem -Path $TargetDir -Recurse -Directory |
        Sort-Object FullName -Descending |
        ForEach-Object {
            $fileCount = (Get-ChildItem $_.FullName -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($fileCount -eq 0) {
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
