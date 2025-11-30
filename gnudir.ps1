<#
.SYNOPSIS
    Organizes files in a directory into category-specific subdirectories.

.DESCRIPTION
    GNUDir Cleaner automatically categorizes and organizes files in a target directory based on their file extensions.
    Files are moved into subdirectories: img (images), vid (videos), doc (documents), arc (archives), 
    audio (audio files), apps (applications), and nany (miscellaneous/unknown types).
    
    The script supports recursive operation, dry-run preview, collision handling, document batching into
    numbered subfolders, and comprehensive logging.

.PARAMETER TargetDir
    The directory to organize. This is a required parameter.
    Example: "C:\Users\YourName\Downloads"

.PARAMETER Recurse
    Recurse into subdirectories of the target directory. Files already in category folders are excluded
    to prevent re-processing.

.PARAMETER DryRun
    Preview actions without actually moving files. Shows what would be done without making changes.

.PARAMETER ShowVerbose
    Print detailed per-file operations and helpful messages during execution.

.PARAMETER KeepEmpty
    Do not delete empty directories after organizing. By default, empty directories are removed.

.PARAMETER BackupMode
    Strategy for handling filename collisions. Valid values:
    - 'numbered' (default): Append numbers to duplicate filenames (file-1.txt, file-2.txt)
    - 'timestamp': Append timestamp to filename (file-20250127103045.txt)
    - 'overwrite': Replace existing files
    - 'skip': Skip files that already exist

.PARAMETER DocsBatchSize
    Split the doc/ folder into numbered subfolders with this many files each.
    For example, with -DocsBatchSize 100, files are organized into doc/1/, doc/2/, etc.
    Set to 0 (default) to disable batching.

.PARAMETER Exclude
    Array of file paths to exclude from processing. Can specify multiple paths.

.PARAMETER LogFile
    Path to a CSV log file. Operations will be logged with timestamp, status, bytes, source, and destination.

.EXAMPLE
    .\gnudir.ps1 -TargetDir "C:\Users\YourName\Downloads"
    
    Organize files in the Downloads folder into category subdirectories.

.EXAMPLE
    .\gnudir.ps1 -TargetDir "C:\Users\YourName\Downloads" -Recurse -DryRun -ShowVerbose
    
    Preview what would happen when organizing Downloads recursively, with detailed output.

.EXAMPLE
    .\gnudir.ps1 -TargetDir "C:\Users\YourName\Documents" -Recurse -DocsBatchSize 100
    
    Organize Documents recursively and batch document files into groups of 100 per subfolder.

.EXAMPLE
    .\gnudir.ps1 -TargetDir "D:\ProjectFiles" -Recurse -LogFile "C:\Logs\organize.csv" -BackupMode timestamp
    
    Organize ProjectFiles recursively, log all operations to CSV, and use timestamp-based collision handling.

.NOTES
    Author: BioKeyPer
    Version: 0.0.0.8
    License: GNU AGPL v3
    
    SAFETY FEATURES:
    The script automatically blocks execution on protected directories to prevent system damage:
    - System directories: C:\Windows, C:\Program Files, C:\ root
    - Application installations: Python*, Ruby*, Node*, Go*, SQL*, Oracle*, MongoDB*
    - Heuristic detection: 2+ file types (.exe, .dll, .msi, .sys, .bat, .cmd, .ps1) OR 1+ .msi OR 3+ .exe OR 5+ .dll
    
    Category folders are created only when files are moved into them. Files already in the correct
    category folder are not moved. Document batching preserves existing numbered batch folders
    and starts new batches after the highest existing number.


.LINK
    https://github.com/biokeyper/GNUDir-Cleaner
#>

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

# Helper function for user-friendly error messages
function Show-FriendlyError {
    param(
        [string]$ErrorType,
        [string]$Details,
        [int]$ExitCode = 1
    )
    
    $message = switch ($ErrorType) {
        "InvalidTarget" { 
            "Invalid target directory: $Details`n" +
            "Please provide a valid directory path. Example: -TargetDir 'C:\Users\YourName\Downloads'"
        }
        "RootDir" {
            "Safety check failed: Cannot operate on system root directory.`n" +
            "Please specify a subdirectory to organize."
        }
        "NotFound" {
            "Directory not found: $Details`n" +
            "Please verify the path exists and you have permission to access it."
        }
        "PermissionDenied" {
            "Permission denied: $Details`n" +
            "Try running PowerShell as Administrator, or check folder permissions."
        }
        "FileLocked" {
            "File is in use: $Details`n" +
            "Close any programs using this file and try again."
        }
        "PathTooLong" {
            "Path exceeds Windows limit (260 characters): $Details`n" +
            "Consider enabling long paths in Windows or use shorter folder names."
        }
        "SystemDir" {
            "Safety check failed: Protected system directory detected.`n" +
            "Cannot operate on: $Details`n" +
            "To protect your system, this script cannot run on Windows, Program Files, or the system drive root."
        }
        "ApplicationDir" {
            "Safety check failed: Application installation directory detected.`n" +
            "Cannot operate on: $Details`n" +
            "Running this script would break the installed application (Python, Node, databases, etc.).`n" +
            "This directory appears to contain application executables or libraries."
        }
        default {
            "Error: $Details"
        }
    }
    
    Write-Host "ERROR: $message" -ForegroundColor Red
    exit $ExitCode
}

# Helper function to check path length
function Test-PathLength {
    param([string]$Path)
    
    # Windows default MAX_PATH is 260 characters
    $MAX_PATH = 260
    
    if ($Path.Length -ge $MAX_PATH) {
        Write-Warning "Path may be too long ($($Path.Length) chars): $Path"
        Write-Warning "To enable long paths: Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1"
        return $false
    }
    return $true
}

# Safety checks with enhanced error messages
if ([string]::IsNullOrWhiteSpace($TargetDir) -or $TargetDir -eq "\") {
    Show-FriendlyError -ErrorType "RootDir" -Details $TargetDir
}

if (-not (Test-Path $TargetDir -PathType Container)) {
    Show-FriendlyError -ErrorType "NotFound" -Details $TargetDir
}

try {
    $TargetDir = (Resolve-Path $TargetDir).Path
} catch {
    Show-FriendlyError -ErrorType "PermissionDenied" -Details "$TargetDir - $($_.Exception.Message)"
}

# Critical Safety Checks: Block system directories
$SystemPaths = @(
    $env:SystemRoot,
    $env:ProgramFiles,
    ${env:ProgramFiles(x86)}
)

# Block system folders and their subdirectories
foreach ($path in $SystemPaths) {
    if ($path -and ($TargetDir -eq $path -or $TargetDir.StartsWith("$path\", [System.StringComparison]::OrdinalIgnoreCase))) {
        Show-FriendlyError -ErrorType "SystemDir" -Details $TargetDir
    }
}

# Block system drive root explicitly
$SystemDrive = [System.IO.Path]::GetPathRoot($env:SystemRoot)
try {
    $tItem = Get-Item $TargetDir
    $sItem = Get-Item $SystemDrive
    if ($tItem.FullName.TrimEnd('\') -eq $sItem.FullName.TrimEnd('\')) {
         Show-FriendlyError -ErrorType "SystemDir" -Details $TargetDir
    }
} catch {
    # Ignore errors here, if we can't get item we can't check it
}

# Block known application installation directories (only on system drive)
$SystemDriveLetter = $SystemDrive.TrimEnd('\')
if ($TargetDir.StartsWith($SystemDriveLetter, [System.StringComparison]::OrdinalIgnoreCase)) {
    # Pattern matching for common application installations
    $appPatterns = @(
        '^C:\\Python',           # Python installations
        '^C:\\Ruby',            # Ruby installations
        '^C:\\Node',            # Node.js
        '^C:\\Go',              # Go language
        '^C:\\PerfLogs',        # Windows performance logs
        '^C:\\ProgramData',     # Application data
        '^C:\\Windows\.old',    # Old Windows installation
        'SQL',                  # Any SQL variant (MySQL, PostgreSQL, MSSQL)
        '^C:\\Oracle',          # Oracle database
        '^C:\\MongoDB'          # MongoDB
    )
    
    foreach ($pattern in $appPatterns) {
        if ($TargetDir -match $pattern) {
            Show-FriendlyError -ErrorType "ApplicationDir" -Details $TargetDir
        }
    }
}

# Heuristic detection: Check for application installations by file analysis
# If directory has many executables, libraries, or installers, it's likely an app
try {
    $fileTypes = @{
        'exe' = @(Get-ChildItem $TargetDir -Filter *.exe -File -ErrorAction SilentlyContinue)
        'dll' = @(Get-ChildItem $TargetDir -Filter *.dll -File -ErrorAction SilentlyContinue)
        'msi' = @(Get-ChildItem $TargetDir -Filter *.msi -File -ErrorAction SilentlyContinue)
        'sys' = @(Get-ChildItem $TargetDir -Filter *.sys -File -ErrorAction SilentlyContinue)
        'bat' = @(Get-ChildItem $TargetDir -Filter *.bat -File -ErrorAction SilentlyContinue)
        'cmd' = @(Get-ChildItem $TargetDir -Filter *.cmd -File -ErrorAction SilentlyContinue)
        'ps1' = @(Get-ChildItem $TargetDir -Filter *.ps1 -File -ErrorAction SilentlyContinue)
    }
    
    # Count how many different file types are present
    $presentTypes = @($fileTypes.Keys | Where-Object { $fileTypes[$_].Count -gt 0 })
    
    # Block if multiple installation-related file types present (likely an app install)
    if ($presentTypes.Count -ge 2) {
        $typeList = $presentTypes -join ', '
        Show-FriendlyError -ErrorType "ApplicationDir" -Details "$TargetDir (detected files: $typeList)"
    }
    
    # Also block if high count of any single type (original logic)
    if ($fileTypes['exe'].Count -ge 3 -or $fileTypes['dll'].Count -ge 5 -or $fileTypes['msi'].Count -ge 1) {
        $exeCount = $fileTypes['exe'].Count
        $dllCount = $fileTypes['dll'].Count
        $msiCount = $fileTypes['msi'].Count
        Show-FriendlyError -ErrorType "ApplicationDir" -Details "$TargetDir (detected $exeCount exe, $dllCount dll, $msiCount msi files)"
    }
} catch {
    # If we can't enumerate files, skip heuristic check
}

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
        Move-Item -LiteralPath $Source -Destination $Dest -Force -ErrorAction Stop
        if ($ShowVerbose) { Write-Host "Moved: $Source -> $Dest" }
        Write-Log "OK" $size $Source $Dest
        return $SourceFile
    }
    catch [System.IO.IOException] {
        # File in use or locked
        if ($_.Exception.Message -match "being used by another process") {
            if ($ShowVerbose) { 
                Write-Warning "File locked: $($SourceFile.Name) - skipping (close the file and try again)"
            }
            Write-Log "LOCKED" $size $Source $Dest
        } else {
            Write-Warning "IO Error moving $($SourceFile.Name): $($_.Exception.Message)"
            Write-Log "IO-ERROR" $size $Source $Dest
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning "Permission denied for $($SourceFile.Name) - check file permissions or run as Administrator"
        Write-Log "PERMISSION-DENIED" $size $Source $Dest
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
$catIndex = 0
$totalCategories = ($Categories | Where-Object { $_ -ne "nany" }).Count

foreach ($c in $Categories) {
    if ($c -eq "nany") { continue }
    $catIndex++
    
    $Files = $AllFiles | Where-Object { $Patterns[$c] -contains $_.Extension.ToLower() }
    $count = 0; $bytes = 0
    $fileIndex = 0
    $totalFiles = $Files.Count
    
    foreach ($f in $Files) {
        $fileIndex++
        Write-Progress -Activity "Organizing Files" -Status "Category: $c ($catIndex/$totalCategories)" `
            -CurrentOperation "Processing: $($f.Name)" `
            -PercentComplete (($catIndex-1)/$totalCategories*100 + ($fileIndex/$totalFiles)/$totalCategories*100)
        
        $MovedFile = Safe-Move -SourceFile $f -DestDir (Join-Path $TargetDir $c)
        if ($MovedFile) { $Processed += $f; $count++; $bytes += $f.Length }
    }
    $CategoryStats[$c] = @{ Count = $count; Bytes = $bytes }
    Write-Host "$c moved: $count files"
}
Write-Progress -Activity "Organizing Files" -Completed


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

            $docIndex = 0
            foreach ($f in $Docs) {
                $docIndex++
                Write-Progress -Activity "Batching Documents" -Status "Batch $batch" `
                    -CurrentOperation "Processing: $($f.Name)" `
                    -PercentComplete ($docIndex/$Docs.Count*100)
                
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
            Write-Progress -Activity "Batching Documents" -Completed
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

exit 0
