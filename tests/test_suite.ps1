# PowerShell Test Suite for gnudir.ps1
# Tests basic functionality including categorization and batching

param()

$ErrorActionPreference = "Stop"
$ScriptPath = Join-Path $PSScriptRoot "..\gnudir.ps1"

# Setup test directory
$TestDir = ".\test_gnudir_temp"
if (Test-Path $TestDir) { 
    Remove-Item $TestDir -Recurse -Force 
}
New-Item -ItemType Directory -Path $TestDir | Out-Null

Write-Host "=== Creating test files ===" -ForegroundColor Cyan

# Create test files
New-Item -ItemType File -Path "$TestDir\image.png" -Force | Out-Null
New-Item -ItemType File -Path "$TestDir\video.mp4" -Force | Out-Null
New-Item -ItemType File -Path "$TestDir\document.pdf" -Force | Out-Null
New-Item -ItemType File -Path "$TestDir\archive.zip" -Force | Out-Null
New-Item -ItemType File -Path "$TestDir\audio.mp3" -Force | Out-Null
New-Item -ItemType File -Path "$TestDir\app.AppImage" -Force | Out-Null
New-Item -ItemType File -Path "$TestDir\unknown.xyz" -Force | Out-Null

Write-Host "Created 7 test files" -ForegroundColor Green

# Test 1: Basic categorization
Write-Host "`n=== Test 1: Basic Categorization ===" -ForegroundColor Cyan
& $ScriptPath -TargetDir $TestDir

$passed = 0
$failed = 0

if (Test-Path "$TestDir\img\image.png") {
    Write-Host "[PASS] image.png moved to img/" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] image.png NOT in img/" -ForegroundColor Red
    $failed++
}

if (Test-Path "$TestDir\vid\video.mp4") {
    Write-Host "[PASS] video.mp4 moved to vid/" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] video.mp4 NOT in vid/" -ForegroundColor Red
    $failed++
}

if (Test-Path "$TestDir\doc\document.pdf") {
    Write-Host "[PASS] document.pdf moved to doc/" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] document.pdf NOT in doc/" -ForegroundColor Red
    $failed++
}

if (Test-Path "$TestDir\arc\archive.zip") {
    Write-Host "[PASS] archive.zip moved to arc/" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] archive.zip NOT in arc/" -ForegroundColor Red
    $failed++
}

if (Test-Path "$TestDir\audio\audio.mp3") {
    Write-Host "[PASS] audio.mp3 moved to audio/" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] audio.mp3 NOT in audio/" -ForegroundColor Red
    $failed++
}

if (Test-Path "$TestDir\apps\app.AppImage") {
    Write-Host "[PASS] app.AppImage moved to apps/" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] app.AppImage NOT in apps/" -ForegroundColor Red
    $failed++
}

if (Test-Path "$TestDir\nany\unknown.xyz") {
    Write-Host "[PASS] unknown.xyz moved to nany/" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] unknown.xyz NOT in nany/" -ForegroundColor Red
    $failed++
}

# Test 2: Document batching
Write-Host "`n=== Test 2: Document Batching ===" -ForegroundColor Cyan

# Create test documents  
1..150 | ForEach-Object {
    New-Item -ItemType File -Path "$TestDir\doc\test_$_.pdf" -Force | Out-Null
}

Write-Host "Created 150 test documents"

# Run batching with size 50
& $ScriptPath -TargetDir $TestDir -DocsBatchSize 50

# Check batches
$batch1Count = (Get-ChildItem "$TestDir\doc\1" -File -ErrorAction SilentlyContinue | Measure-Object).Count
$batch2Count = (Get-ChildItem "$TestDir\doc\2" -File -ErrorAction SilentlyContinue | Measure-Object).Count
$batch3Count = (Get-ChildItem "$TestDir\doc\3" -File -ErrorAction SilentlyContinue | Measure-Object).Count
$rootCount = (Get-ChildItem "$TestDir\doc" -File -ErrorAction SilentlyContinue | Measure-Object).Count

if ($batch1Count -eq 50 -and $batch2Count -eq 50 -and $batch3Count -eq 50 -and $rootCount -eq 0) {
    Write-Host "[PASS] Documents batched correctly (50 per folder)" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] Batching incorrect. Batch1: $batch1Count, Batch2: $batch2Count, Batch3: $batch3Count, Root: $rootCount" -ForegroundColor Red
    $failed++
}

# Test 3: Dry run
Write-Host "`n=== Test 3: Dry Run ===" -ForegroundColor Cyan
Remove-Item $TestDir -Recurse -Force
New-Item -ItemType Directory -Path $TestDir | Out-Null
New-Item -ItemType File -Path "$TestDir\test.pdf" -Force | Out-Null

& $ScriptPath -TargetDir $TestDir -DryRun

if ((Test-Path "$TestDir\test.pdf") -and -not (Test-Path "$TestDir\doc")) {
    Write-Host "[PASS] Dry run did not move files" -ForegroundColor Green
    $passed++
} else {
    Write-Host "[FAIL] Dry run moved files (unexpected)" -ForegroundColor Red
    $failed++
}

# Cleanup
Write-Host "`n=== Cleaning up ===" -ForegroundColor Cyan
Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
if ($failed -eq 0) {
    Write-Host "Failed: $failed" -ForegroundColor Green
} else {
    Write-Host "Failed: $failed" -ForegroundColor Red
}

if ($failed -eq 0) {
    Write-Host "`n[SUCCESS] All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FAILURE] Some tests failed" -ForegroundColor Red
    exit 1
}
