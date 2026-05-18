# Development Notes

Quick reference for future development and troubleshooting.

## Common Tasks

### Testing Changes

```powershell
# Test download only
.\scripts\download-from-intervals.ps1 -OldestDate "2026-01-13" -NewestDate "2026-01-13"

# Test processing only
.\scripts\process-and-upload.ps1

# Test full cycle
.\scripts\monitor-and-sync.ps1 -RunOnce
```

### Debugging

```powershell
# View today's log
Get-Content logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log -Tail 50

# Test single file manually (always use full path from config)
C:\Users\chris\pipx\venvs\fit-file-faker\Scripts\fit-file-faker.exe "C:\Users\chris\fit-file-sync-pipeline\data\downloaded\filename.fit" --upload

# Capture raw output for debugging detection patterns
. "C:\Users\chris\fit-file-sync-pipeline\scripts\config.ps1"
$result = & $Config.FitFileFakerPath "C:\path\to\file.fit" --upload 2>&1
$result | Out-String

# Check what's waiting to process
Get-ChildItem data\downloaded\*.fit

# Check errors
Get-ChildItem data\errors
```

### Manual Operations

```powershell
# Reprocess error files
Move-Item data\errors\*.fit data\downloaded\
.\scripts\process-and-upload.ps1

# Move files from errors back to downloaded (excludes _modified files)
Get-ChildItem C:\Users\chris\fit-file-sync-pipeline\data\errors\*.fit |
    Where-Object { $_.Name -notmatch "_modified" } |
    ForEach-Object {
        Move-Item $_.FullName "C:\Users\chris\fit-file-sync-pipeline\data\downloaded\$($_.Name)"
    }

# Force re-download
.\scripts\download-from-intervals.ps1 -Force -OldestDate "2026-01-01" -NewestDate "2026-01-31"

# Clean up modified files
Remove-Item data\downloaded\*_modified.fit

# Disable scheduled task during troubleshooting
Disable-ScheduledTask -TaskName "FIT File Sync Pipeline"

# Re-enable scheduled task
Enable-ScheduledTask -TaskName "FIT File Sync Pipeline"

# Check if Garmin auth token exists
Test-Path "C:\Users\chris\AppData\Local\FitFileFaker\.garmin_default\garmin_tokens.json"
```

---

## Key Code Patterns

### Detection Pattern (current - v1.3.0)

The three detection patterns must be read together. The ordering matters: rate limit is
checked first, then duplicate, then exception. `GarminConnectConnectionError` is deliberately
absent from the rate limit pattern because Fit-File-Faker raises it for 409 Duplicate Activity
responses too — putting it in the rate limit pattern causes false positives.

```powershell
# Rate limit: specific patterns only - do NOT add GarminConnectConnectionError here
$isRateLimited = $resultText -match "429|rate limit|All login strategies exhausted"

# Duplicate: includes "API Error 409|Duplicate Activity" to catch the UnicodeEncodeError
# crash path (see Issue #11 in PROJECT-HISTORY.md for full explanation)
$isDuplicate = $resultText -match "activity already exists|HTTP conflict|Received HTTP conflict|API Error 409|Duplicate Activity"

# Success
$uploadSuccess = $resultText -match "Uploading.*using garth|Uploading.*to Garmin Connect|Successfully uploaded" -or $isDuplicate

# Exception: narrow patterns only - Traceback alone is not reliable because it also
# appears in the UnicodeEncodeError crash that accompanies duplicate detection
$hasException = $resultText -match "Login failed"

if ($hasException -and -not $uploadSuccess) {
    # Real error
}
```

### Why Traceback Is Not a Reliable Error Signal

When Fit-File-Faker detects a duplicate activity (HTTP 409), it attempts to log a warning
message containing a ❌ emoji. On Windows, if the console is using cp1252 encoding, this
causes a `UnicodeEncodeError` inside Rich's logging handler. The result is a `--- Logging
error ---` block with a full Python traceback printed to stderr — even though the upload
itself was handled correctly. Always check for duplicate/success indicators before treating
a traceback as an error.

### Logging Pattern

```powershell
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $Config.LogFolder "sync-$(Get-Date -Format 'yyyy-MM-dd').log"
    "$timestamp [$Level] $Message" | Out-File -FilePath $logFile -Append
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message }
    }
}
```

### File Filtering Pattern

```powershell
# Exclude modified files, only process originals
$fitFiles = Get-ChildItem "$($Config.DownloadFolder)\*.fit" | 
    Where-Object { $_.Name -notmatch "_modified\.fit$" }
```

---

## API Quick Reference

### intervals.icu

**List activities:**
```powershell
$url = "https://intervals.icu/api/v1/athlete/0/activities?oldest=2026-01-01&newest=2026-01-31"
$headers = @{ Authorization = "Basic $base64Auth" }
$activities = Invoke-RestMethod -Uri $url -Headers $headers
```

**Download file:**
```powershell
$fileUrl = "https://intervals.icu/api/v1/activity/i123456/file"
Invoke-WebRequest -Uri $fileUrl -Headers $headers -OutFile "output.fit"
```

### Fit-File-Faker

**Upload (always use full path):**
```powershell
C:\Users\chris\pipx\venvs\fit-file-faker\Scripts\fit-file-faker.exe "path\to\file.fit" --upload
```

**Config location:**
```
%LOCALAPPDATA%\FitFileFaker\config.json
```

**Auth token location:**
```
C:\Users\chris\AppData\Local\FitFileFaker\.garmin_default\garmin_tokens.json
```

---

## Troubleshooting Checklist

**Downloads not working:**
- [ ] Check API key in config.ps1
- [ ] Verify activities have `file_type` field
- [ ] Check date range includes activities
- [ ] Test API call manually

**Uploads failing:**
- [ ] Capture raw Fit-File-Faker output (see Debugging section above)
- [ ] Verify `FitFileFakerPath` in config.ps1 points to the correct executable
- [ ] Check Garmin auth token exists
- [ ] Check for malformed FIT files

**Pipeline reports rate limit but it hasn't run in days:**
- [ ] Capture raw output - the real cause is likely a duplicate 409 being misdetected
- [ ] Check detection patterns match current version in Key Code Patterns section
- [ ] Verify `GarminConnectConnectionError` is NOT in the rate limit pattern

**Automation not running:**
- [ ] Check Task Scheduler is enabled
- [ ] Verify task shows "Ready" status
- [ ] Check task history for errors
- [ ] Verify PowerShell execution policy

**Files stuck in downloaded/ after apparent rate limit:**
- [ ] Capture raw output to confirm it's a genuine rate limit vs false positive
- [ ] If false positive: fix detection patterns, reprocess
- [ ] If genuine: disable task, wait, re-enable once manual test succeeds

---

## Common Issues and Fixes

### Issue: False Rate Limit Detection on Duplicate Activities

**Symptom:** Pipeline immediately reports rate limit on every file; running the task manually works fine; it hasn't run in days so a true rate limit is unlikely

**Cause:** Fit-File-Faker raises `GarminConnectConnectionError` for both 409 Duplicate Activity responses and genuine connection errors. If `GarminConnectConnectionError` is in the rate limit detection pattern, every duplicate detection will be misread as a rate limit.

Additionally, when Fit-File-Faker logs the duplicate warning, it attempts to print a ❌ emoji. On Windows with cp1252 console encoding this causes a `UnicodeEncodeError`, producing a traceback in stderr — even though the 409 was handled correctly. The 409 detail still appears in the output and can be matched by the duplicate detection pattern.

**Fix:** Ensure `process-and-upload.ps1` uses the detection patterns in the Key Code Patterns section above. The rate limit pattern must not contain `GarminConnectConnectionError`, and the duplicate pattern must include `API Error 409|Duplicate Activity`.

### Issue: JSON Syntax Error

**Error:** `JSONDecodeError: Expecting ',' delimiter`

**Fix:**
```powershell
# Validate JSON
Get-Content $env:LOCALAPPDATA\FitFileFaker\config.json | ConvertFrom-Json

# Common mistakes:
# - Missing comma between fields
# - Extra comma after last field
# - Wrong field name (fitfiles_dir vs fit_files_dir)
# - Single backslashes (use \\)
```

### Issue: Script Can't Find config.ps1

**Error:** `Export-ModuleMember : Can only be called from inside a module`

**Fix:** Remove `Export-ModuleMember` line from config.ps1 (not needed)

### Issue: Dry-Run Fails

**Error:** `FileNotFoundError: *_modified.fit`

**Cause:** Fit-File-Faker bug with `--dryrun --upload`

**Fix:** Don't use dry-run mode, or test without upload flag

---

## Performance Optimization

**If sync is slow:**
1. Reduce `LookbackDays` (7 → 3)
2. Increase `DelayBetweenFiles` (prevent rate limiting)
3. Check network connection
4. Verify not processing duplicates repeatedly

**If logs are growing large:**
1. Implement log rotation (>30 days)
2. Reduce log verbosity (remove INFO entries)
3. Archive old logs to separate location

---

## Git Workflow

```powershell
# Make changes
git status
git add .
git commit -m "Brief description"
git push

# Create release
git tag -a v1.3.0 -m "Description"
git push origin v1.3.0
```

**Commit message prefixes:**
- `Fix:` - Bug fixes
- `Add:` - New features
- `Update:` - Modifications
- `Docs:` - Documentation only
- `Refactor:` - Code restructure

---

## Environment Variables

**PowerShell:**
- `$PSScriptRoot` - Directory containing current script
- `$env:LOCALAPPDATA` - Local AppData folder

**Paths:**
- Fit-File-Faker config: `$env:LOCALAPPDATA\FitFileFaker\config.json`
- Fit-File-Faker auth token: `C:\Users\chris\AppData\Local\FitFileFaker\.garmin_default\garmin_tokens.json`
- Project root: `C:\Users\chris\fit-file-sync-pipeline`

---

## Future Development Ideas

### Short-term
- Add email notifications
- Implement retry logic
- Activity type filtering
- Better error messages

### Long-term
- Python rewrite
- Web dashboard
- Direct service integration
- Mobile app

See ROADMAP.md for details.

---

*Quick reference only - see ARCHITECTURE.md for complete documentation*
