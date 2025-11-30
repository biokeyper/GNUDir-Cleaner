# Safety Checks Implementation Plan - Linux (godlin)

## Goal Description
Implement robust safety checks in `gnudir.sh` (Linux version) to prevent accidental reorganization of sensitive system directories and application installations. This mirrors the safety features already implemented in the Windows version (`gnudir.ps1`).

## User Review Required
> [!IMPORTANT]
> This change will prevent the script from running on system directories and application installations. This protects against accidental damage to the OS and installed software.

## Proposed Changes

### Script Logic
#### [MODIFY] [gnudir.sh](file:///d:/dev/gd/gnudir.sh)
- Extend existing safety checks beyond just rejecting root `/`.
- **System Directory Checks**:
    - Reject critical system paths: `/bin`, `/boot`, `/dev`, `/etc`, `/lib`, `/lib64`, `/opt`, `/proc`, `/root`, `/sbin`, `/sys`, `/usr`, `/var`
    - Reject subdirectories of system paths (e.g., `/usr/bin`, `/etc/systemd`)
- **Application Directory Pattern Matching**:
    - Common app install locations: `/opt/*`, `/usr/local/*` (if containing apps)
    - Language runtimes: paths containing `python`, `node`, `ruby`, `go`
    - Databases: paths containing `mysql`, `postgres`, `mongodb`, `redis`
- **Heuristic Detection**:
    - Scan for ELF executables using `file` command or check for executable bit + binary content
    - Check for shared libraries (`.so`, `.so.*`)
    - Check for package manager files (`.deb`, `.rpm`, `.AppImage`)
    - Block if 2+ binary types detected OR 3+ executables OR 5+ libraries OR 1+ package file

### Tests
#### [NEW] [tests/test_safety.sh](file:///d:/dev/gd/tests/test_safety.sh)
- Create Bash test suite for Linux safety checks
- Test cases:
    - Safe directories (images only) - should allow
    - Multiple executables - should block
    - Mixed executables + libraries - should block
    - Package files (.deb, .AppImage) - should block
    - Single executable - should allow

### CI
#### [MODIFY] [.github/workflows/ci.yml](file:///d:/dev/gd/.github/workflows/ci.yml)
- Add step to run `tests/test_safety.sh` in the `linux-tests` job

## Verification Plan

### Automated Tests
- Run `./tests/test_safety.sh` locally on Linux
- Run full `./tests/test_suite.sh` to ensure no regressions

### Manual Verification
- Create test directory: `mkdir -p /tmp/fake_app`
- Add fake executables: `touch /tmp/fake_app/{app1,app2,app3}; chmod +x /tmp/fake_app/*`
- Run: `./gnudir.sh /tmp/fake_app --dry-run`
- Expect: Safety check failure with clear error message
