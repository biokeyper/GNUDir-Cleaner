<#
.SYNOPSIS
    GNUDIR Cleaner - PowerShell version
.DESCRIPTION
    Organizes files in a target directory into categories:
    img, vid, doc, arc, audio, apps, nany
    Supports options: recurse, dry-run, verbose, backup-mode, exclude, keep-empty, docs-batch-size
    Logs operations to CSV if -LogFile is provided.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetDir,

    [switch]$Recurse,
    [switch]$DryRun,
    [switch]$Verbose,
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
    img   = "*.png","*.jpg","*.jpeg","*.webp","*.gif","*.bmp","*.tiff","*.tif","*.svg","*.ico","*.heic","*.heif","*.avif"
    vid   = "*.mp4","*.mkv","*.avi","*.mov","*.wmv","*.flv","*.webm","*.mpeg","*.mpg","*.3gp","*.3g2","*.m4v"
    doc   = "*.pdf","*.txt","*.doc","*.docx","*.xls","*.xlsx","*.ppt","*.pptx","*.odt","*.ods","*.odp","*.csv","*.epub","*.mobi"
    arc   = "*.zip","*.tar","*.7z","*.tar.gz","*.tar.bz2","*.tar.xz","*.xz","*.iso","*.gz","*.bz2"
    audio = "*.mp3","*.wav","*.flac","*.aac","*.ogg","*.m4a","*.wma","*.opus","*.aiff","*.aif","*.amr","*.alac","*.mka","*.au","*.spx"
    apps  = "*.AppImage","*.appimage","*.run","*.bin","*.deb","*.rpm","*.pkg","*.snap","*.img","*.ova"
}

# Logging function
function Write-Log {
    param(
        [string]$Status,
        [long]$Bytes,
        [string]$Source,
        [string]$Dest
    )
    if (-not $LogFile) { return }
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Ensure header exists
    if (-not (Test-Path $LogFile)) {
        "Timestamp,Status,Bytes,Source,Destination" | Out-File -FilePath $LogFile -Encoding UTF8
    }

    $line = "$timestamp,$Status,$Bytes,$Source,$Dest"
    Add-Content -Path $LogFile -Value $line
}

function Safe-Move {
    param(
        [string]$Source,
        [string]$DestDir
    )
    $Base = [System.IO.Path]::GetFileName($Source)
    $Dest = Join-Path $DestDir $Base

    $size = (Get-Item $Source).Length

    if ($DryRun) {
        Write-Host "DRY-RUN: $Source -> $Dest"
        Write-Log -Status "DRY-RUN" -Bytes $size -Source $Source -Dest $Dest
        return
    }

    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    }

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
            "overwrite" {
                Remove-Item $Dest -Force
            }
            "skip" {
                if ($Verbose) { Write-Host "Skipping existing: $Dest" }
                Write-Log -Status "SKIP" -Bytes $size -Source $Source -Dest $Dest
                return
            }
        }
    }

    try {
        Move-Item -LiteralPath $Source -Destination $Dest -Force
        if ($Verbose) { Write-Host "Moved: $Source -> $Dest" }
        Write-Log -Status "OK" -Bytes $size -Source $Source -Dest $Dest
    }
    catch {
        Write-Warning "Failed to move: $Source -> $Dest"
        Write-Log -Status "ERROR" -Bytes $size -Source $Source -Dest $Dest
    }
}

# Collect all files once
$AllFiles = Get-ChildItem -Path $TargetDir -Recurse:$Recurse -File |
            Where-Object { $Exclude -notcontains $_.FullName }

$Processed = @()
$totalFiles = 0
$totalBytes = 0
$startTime = Get-Date

# Run categories (except docs)
foreach ($c in $Categories) {
    if ($c -eq "doc") { continue }
    if ($Patterns.ContainsKey($c)) {
        $Files = $AllFiles | Where-Object { $Patterns[$c] | ForEach-Object { $_ } | ForEach-Object { $_ -and $_ -like $_ } }
        foreach ($f in $Files) {
            Safe-Move -Source $f.FullName -DestDir (Join-Path $TargetDir $c)
            $Processed += $f
        }
        $totalFiles += $Files.Count
        $totalBytes += ($Files | Measure-Object Length -Sum).Sum
        Write-Host "$c moved: $($Files.Count) files"
    }
}

# Docs category with batching integrated
if ($Patterns.ContainsKey("doc")) {
    $Docs = $AllFiles | Where-Object { $Patterns["doc"] | ForEach-Object { $_ } | ForEach-Object { $_ -and $_ -like $_ } }
    $i = 1; $batch = 1
    $BatchDir = Join-Path $TargetDir "doc\$batch"
    New-Item -ItemType Directory -Force -Path $BatchDir | Out-Null

    foreach ($f in $Docs) {
        if ($DocsBatchSize -gt 0 -and $i -gt $DocsBatchSize) {
            $batch++
            $i = 1
            $BatchDir = Join-Path $TargetDir "doc\$batch"
            New-Item -ItemType Directory -Force -Path $BatchDir | Out-Null
        }
        Safe-Move -Source $f.FullName -DestDir $BatchDir
        $Processed += $f
        $i++
    }
    $totalFiles += $Docs.Count
    $totalBytes += ($Docs | Measure-Object Length -Sum).Sum
    Write-Host "Documents moved: $($Docs.Count) files into $batch batches"
}

# Miscellaneous files
$MiscFiles = $AllFiles | Where-Object { $Processed -notcontains $_ }
foreach ($f in $MiscFiles) {
    Safe-Move -Source $f.FullName -DestDir (Join-Path $TargetDir "nany")
}
$totalFiles += $MiscFiles.Count
$totalBytes += ($MiscFiles | Measure-Object Length -Sum).Sum
Write-Host "Misc moved: $($MiscFiles.Count) files"

# Remove empty directories
if (-not $KeepEmpty) {
    Get-ChildItem -Path $TargetDir -Recurse -Directory |
        Where-Object { (Get-ChildItem $_.FullName -Force | Measure-Object).Count -eq 0 } |
        Remove-Item -Force
    Write-Host "Empty directories removed."
}

$runtime = (Get-Date) - $startTime
Write-Host "Organization complete in directory: $TargetDir - $totalFiles files, $totalBytes bytes in $($runtime.TotalSeconds) seconds."

# Summary log
if ($LogFile) {
    $summary = "SUMMARY,$totalFiles,$totalBytes,,"
    Add-Content -Path $LogFile -Value $summary
}


Write-Host "Organization complete in directory: $TargetDir"
