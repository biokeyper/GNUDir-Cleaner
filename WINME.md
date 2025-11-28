---

## 🖥️ Steps to Run `gd.ps1`

1. **Save the script**
   - Copy the full code into a file named `gnudir.ps1`.
   - Place it somewhere convenient, e.g. `C:\Scripts\gnudir.ps1`.

2. **Open PowerShell**
   - Press `Win + R`, type `powershell`, and hit Enter.
   - Or open **Windows Terminal** and select the PowerShell profile.

3. **Navigate to your script folder**
   ```powershell
   cd C:\Scripts
   ```

4. **Run the script with a target directory**
   ```powershell
   .\gnudir.ps1 -TargetDir "C:\Users\Miracle\Downloads"
   ```

   That will organize files in your `Downloads` folder.

---

## ⚙️ Common Options

- **Dry run (no actual moves, just preview):**
  ```powershell
  .\gnudir.ps1 -TargetDir "C:\Users\Miracle\Downloads" -DryRun
  ```

- **Verbose output (see every move):**
  ```powershell
  .\gnudir.ps1 -TargetDir "C:\Users\Miracle\Downloads" -Verbose
  ```

- **Recurse into subfolders:**
  ```powershell
  .\gnudir.ps1 -TargetDir "C:\Users\Miracle\Downloads" -Recurse
  ```

- **Batch documents into groups of 50:**
  ```powershell
  .\gnudir.ps1 -TargetDir "C:\Users\Miracle\Downloads" -DocsBatchSize 50
  ```

- **Log actions to a CSV file:**
  ```powershell
  .\gnudir.ps1 -TargetDir "C:\Users\Miracle\Downloads" -LogFile "C:\Scripts\gnudir-log.csv"
  ```

---

## 📝 Notes
- If you see a *“running scripts is disabled”* error, you may need to allow local scripts:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
  (Run PowerShell as Administrator for this.)

- The log file will contain per‑file entries and a final summary line:
  ```
  Timestamp,Status,Bytes,Source,Destination
  2025-11-25T04:50:00Z,OK,12345,C:\Users\Miracle\Downloads\file.pdf,C:\Users\Miracle\Downloads\doc\1\file.pdf
  SUMMARY,42,1234567,,
  ```

---

## 🧪 Testing

To run the automated test suite:

```powershell
cd tests
.\test_suite.ps1
```

The test suite verifies:
- ✅ File categorization (images, videos, documents, archives, audio, apps, misc)
- ✅ Document batching functionality (splits 150 files into batches of 50)
- ✅ Dry-run mode (preview without making changes)

All tests should pass before deployment.

---

