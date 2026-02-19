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

# Test single file manually
fit-file-faker data\downloaded\2026-01-13-i123456.fit --upload

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

# Force re-download
.\scripts\download-from-intervals.ps1 -Force -OldestDate "2026-01-01" -NewestDate "2026-01-31"

# Clean up modified files
Remove-Item data\downloaded\*_modified.fit
```

---

## Key Code Patterns

### Error Detection Pattern
```powershell
$isDuplicate = $resultText -match "activity already exists|HTTP conflict"
$uploadSuccess = $resultText -match "Uploading.*using garth" -or $isDuplicate
$hasException = $resultText -match "Traceback.*Exception"

if ($hasException -and -not $uploadSuccess) {
    # Real error
}
```

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

**Upload:**
```bash
fit-file-faker path/to/file.fit --upload
```

**Config location:**
```
%LOCALAPPDATA%\FitFileFaker\config.json
```

---

## Troubleshooting Checklist

**Downloads not working:**
- [ ] Check API key in config.ps1
- [ ] Verify activities have `file_type` field
- [ ] Check date range includes activities
- [ ] Test API call manually

**Uploads failing:**
- [ ] Verify Fit-File-Faker config.json
- [ ] Check Garmin credentials
- [ ] Test manual upload with fit-file-faker
- [ ] Check for malformed FIT files

**Automation not running:**
- [ ] Check Task Scheduler is enabled
- [ ] Verify task shows "Ready" status
- [ ] Check task history for errors
- [ ] Verify PowerShell execution policy

**Duplicates being created:**
- [ ] Check if activity already in Garmin
- [ ] Verify duplicate detection logic
- [ ] Check log output for "duplicate detected"
- [ ] Review error detection pattern

---

## Common Issues and Fixes

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

### Issue: Files Marked as Errors But Upload Successfully

**Symptom:** Files in errors/ folder but appear in Garmin Connect

**Cause:** Error detection too aggressive (catching warnings)

**Fix:** Already fixed in current version (check for Traceback AND no upload success)

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
git tag -a v1.2.0 -m "Description"
git push origin v1.2.0
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
