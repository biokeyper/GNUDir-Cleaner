# PowerShell Safety Test Suite for gnudir.ps1
# Tests safety checks and heuristic detection

param()

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Setup test directory
$TestDir = ".\test_safety_temp"
if (Test-Path $TestDir) { 
    Remove-Item $TestDir -Recurse -Force 
}
New-Item -ItemType Directory -Path $TestDir | Out-Null

Write-Host "=== Safety Check Tests ===" -ForegroundColor Cyan

$passed = 0
$failed = 0

function Run-Test {
    param($Name, $SetupBlock, $ShouldFail)
    
    Write-Host "Test: $Name" -NoNewline
    
    # Setup
    $CaseDir = Join-Path $TestDir $Name
    New-Item -ItemType Directory -Path $CaseDir -Force | Out-Null
    & $SetupBlock -Dir $CaseDir
    
    # Run
    $ScriptPath = Join-Path $PSScriptRoot "..\gnudir.ps1"
    $output = & $ScriptPath -TargetDir $CaseDir -DryRun 2>&1
    $lastExitCode = $LASTEXITCODE
    
    # Verify
    if ($ShouldFail) {
        if ($lastExitCode -ne 0 -or $output -match "Safety check failed") {
            Write-Host " [PASS] (Blocked as expected)" -ForegroundColor Green
            return $true
        } else {
            Write-Host " [FAIL] (Should have blocked)" -ForegroundColor Red
            Write-Host "Output: $output"
            return $false
        }
    } else {
        if ($lastExitCode -eq 0 -and $output -notmatch "Safety check failed") {
            Write-Host " [PASS] (Allowed as expected)" -ForegroundColor Green
            return $true
        } else {
            Write-Host " [FAIL] (Blocked unexpectedly)" -ForegroundColor Red
            Write-Host "Output: $output"
            return $false
        }
    }
}

# Test 1: Safe directory (Images only)
$res = Run-Test -Name "Safe_Images" -ShouldFail $false -SetupBlock {
    param($Dir)
    New-Item -Path "$Dir\test.jpg" -ItemType File | Out-Null
    New-Item -Path "$Dir\test.png" -ItemType File | Out-Null
}
if ($res) { $passed++ } else { $failed++ }

# Test 2: Heuristic - Multiple EXEs (Should Block)
$res = Run-Test -Name "Danger_Exes" -ShouldFail $true -SetupBlock {
    param($Dir)
    New-Item -Path "$Dir\app1.exe" -ItemType File | Out-Null
    New-Item -Path "$Dir\app2.exe" -ItemType File | Out-Null
    New-Item -Path "$Dir\app3.exe" -ItemType File | Out-Null
}
if ($res) { $passed++ } else { $failed++ }

# Test 3: Heuristic - EXE + DLL (Should Block)
$res = Run-Test -Name "Danger_Mixed" -ShouldFail $true -SetupBlock {
    param($Dir)
    New-Item -Path "$Dir\app.exe" -ItemType File | Out-Null
    New-Item -Path "$Dir\lib.dll" -ItemType File | Out-Null
}
if ($res) { $passed++ } else { $failed++ }

# Test 4: Heuristic - Single MSI (Should Block)
$res = Run-Test -Name "Danger_Msi" -ShouldFail $true -SetupBlock {
    param($Dir)
    New-Item -Path "$Dir\installer.msi" -ItemType File | Out-Null
}
if ($res) { $passed++ } else { $failed++ }

# Test 5: Safe - Single EXE (Should Allow - maybe? Script says 3+ exe or mixed)
# Script logic: if ($presentTypes.Count -ge 2) OR ($fileTypes['exe'].Count -ge 3)
# So 1 EXE should be safe if no other types.
$res = Run-Test -Name "Safe_SingleExe" -ShouldFail $false -SetupBlock {
    param($Dir)
    New-Item -Path "$Dir\tool.exe" -ItemType File | Out-Null
}
if ($res) { $passed++ } else { $failed++ }

# Cleanup
Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Summary ==="
Write-Host "Passed: $passed"
Write-Host "Failed: $failed"

if ($failed -eq 0) { exit 0 } else { exit 1 }
