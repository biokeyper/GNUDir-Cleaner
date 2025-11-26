
$TargetDir = ".\test_exclude_strategy"
if (Test-Path $TargetDir) { Remove-Item $TargetDir -Recurse -Force }
New-Item -ItemType Directory -Path "$TargetDir\doc\1" -Force
New-Item -ItemType Directory -Path "$TargetDir\doc\2" -Force
New-Item -ItemType Directory -Path "$TargetDir\doc\sub" -Force
New-Item -ItemType File -Path "$TargetDir\doc\root_file.pdf" -Force
New-Item -ItemType File -Path "$TargetDir\doc\1\nested_file_1.pdf" -Force
New-Item -ItemType File -Path "$TargetDir\doc\2\nested_file_2.pdf" -Force
New-Item -ItemType File -Path "$TargetDir\doc\sub\sub_file.pdf" -Force

$docRoot = Join-Path $TargetDir "doc"

Write-Host "--- Proposed Logic Check ---"

# 1. Get files directly in doc root
$RootDocs = Get-ChildItem $docRoot -File
Write-Host "Root Docs: $($RootDocs.Name -join ', ')"

# 2. Get directories that are NOT numbered batches
$SubDirs = Get-ChildItem $docRoot -Directory | Where-Object { $_.Name -notmatch '^\d+$' }
Write-Host "Scannable Subdirs: $($SubDirs.Name -join ', ')"

# 3. Recurse into those directories
$SubDocs = $SubDirs | ForEach-Object { Get-ChildItem $_.FullName -Recurse -File }
if ($SubDocs) {
    Write-Host "Sub Docs: $($SubDocs.Name -join ', ')"
} else {
    Write-Host "Sub Docs: None"
}

# 4. Combine
$AllDocs = @($RootDocs) + @($SubDocs)
Write-Host "Total Docs to Batch: $($AllDocs.Name -join ', ')"

# Assertions
if ($AllDocs.Name -contains "root_file.pdf" -and $AllDocs.Name -contains "sub_file.pdf") {
    Write-Host "PASS: Correct files selected."
} else {
    Write-Error "FAIL: Missing expected files."
}

if ($AllDocs.Name -contains "nested_file_1.pdf" -or $AllDocs.Name -contains "nested_file_2.pdf") {
    Write-Error "FAIL: Selected files from batch folders!"
} else {
    Write-Host "PASS: Batch folders excluded."
}
