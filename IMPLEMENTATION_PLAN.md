# Safety Checks Implementation Plan

## Goal Description
Implement robust safety checks in `gnudir.ps1` to prevent accidental reorganization of sensitive system directories (Windows, Program Files) and application directories (containing executables, DLLs, etc.). This ensures the script doesn't break installed software or the OS.

## User Review Required
> [!IMPORTANT]
> This change will prevent the script from running on any directory that looks like an application installation. This might affect users trying to organize portable app folders if they contain mixed content.

## Proposed Changes

### Script Logic
#### [MODIFY] [gnudir.ps1](gnudir.ps1)
- Add a `Test-Safety` function or block at the beginning.
- **System Checks**:
    - Reject if path is root drive (e.g., `C:\`).
    - Reject if path contains `Windows`, `Program Files`, `Program Files (x86)`, `ProgramData`, `PerfLogs`.
- **Heuristic Checks**:
    - Scan for "danger" markers in the top level of the target directory: `*.exe`, `*.dll`, `*.sys`, `*.msi`.
    - If found, abort with a specific error message.
    - Allow override with a `-Force` or `-Unsafe` switch? (Maybe not for now, stick to strict safety).

### Tests
#### [NEW] [tests/test_safety.ps1](tests/test_safety.ps1)
- Create a specific test suite for safety checks.
- Test cases:
    - Mock system directories (requires careful mocking or using non-system paths that trigger the name check).
    - Create a dummy app directory with `.exe` and `.dll` files.
    - Verify script refuses to run.
    - Verify script runs on safe directories.

### CI
#### [MODIFY] [.github/workflows/ci.yml](.github/workflows/ci.yml)
- Add a step to run `tests/test_safety.ps1`.

## Verification Plan

### Automated Tests
- Run `tests/test_safety.ps1` locally.
- Run full `tests/test_suite.ps1` to ensure no regressions.
- Run `tests/test_suite.sh` on WSL/Linux to verify Linux script fixes.

### Manual Verification
- Create a folder `C:\Temp\FakeApp` with a `fake.exe`.
- Run `.\gnudir.ps1 -TargetDir C:\Temp\FakeApp -DryRun`.
- Run `./gnudir.sh --dry-run /tmp/FakeApp` (on Linux/WSL).
- Expect error in both cases.

## Linux Parity & Fixes
#### [MODIFY] [gnudir.sh](gnudir.sh)
- **Fix Corruption**: Remove the appended duplicate/legacy code at the end of the file (lines 358+).
- **Safety Checks**: Implement the same system and heuristic checks as Windows:
    - Reject root `/`.
    - Reject if path contains `bin`, `boot`, `dev`, `etc`, `lib`, `proc`, `sbin`, `sys`, `usr`, `var` (Linux system dirs).
    - Heuristic check for `*.o`, `*.so`, `*.bin` (executables/libraries) in top level.

