# PowerShell Safety Test Suite for gnudir.ps1
# Tests that critical system directories are protected

$ErrorActionPreference = "Continue" # We expect errors, so don't stop immediately

Write-Host "=== Testing Critical Safety Checks ===" -ForegroundColor Cyan

$scriptPath = Resolve-Path "..\gnudir.ps1"
$passed = 0
$failed = 0

# Helper to run test case
function Test-SafetyCheck {
    param($Path, $Description)
    
    Write-Host "Testing: $Description ($Path)..." -NoNewline
    
    # Run script against protected path
    # We expect it to fail with exit code 1 and output an error message
    
    # Handle quoting for paths with spaces or trailing backslashes
    # If path ends with backslash, we must escape it before the closing quote
    $argPath = $Path
    if ($Path.EndsWith("\")) {
        $argPath = "$Path\"
    }
    
    $argStr = "-ExecutionPolicy Bypass -File `"$scriptPath`" -TargetDir `"$argPath`""
    
    $process = Start-Process -FilePath "powershell" -ArgumentList $argStr -PassThru -NoNewWindow -Wait
    
    if ($process.ExitCode -eq 1) {
        Write-Host " [PASS] (Blocked correctly)" -ForegroundColor Green
        return $true
    } else {
        Write-Host " [FAIL] (Allowed execution!)" -ForegroundColor Red
        return $false
    }
}

# Test Cases
# Note: We use environment variables to get actual system paths
$tests = @(
    @{ Path = $env:SystemRoot; Desc = "Windows Directory" },
    @{ Path = $env:ProgramFiles; Desc = "Program Files" },
    @{ Path = [System.IO.Path]::GetPathRoot($env:SystemRoot); Desc = "System Drive Root" },
    @{ Path = "C:\Python314"; Desc = "Python Installation (Pattern Match)" },
    @{ Path = "C:\PerfLogs"; Desc = "Performance Logs (Pattern Match)" }
)

foreach ($test in $tests) {
    if (Test-SafetyCheck -Path $test.Path -Description $test.Desc) {
        $passed++
    } else {
        $failed++
    }
}

# Summary
Write-Host "`n=== Safety Test Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
if ($failed -eq 0) {
    Write-Host "Failed: $failed" -ForegroundColor Green
    Write-Host "`n[SUCCESS] All safety checks passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Failed: $failed" -ForegroundColor Red
    Write-Host "`n[FAILURE] Safety checks failed!" -ForegroundColor Red
    exit 1
}
