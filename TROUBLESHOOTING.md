# Troubleshooting Guide - FIT File Sync Pipeline

Common issues and solutions for the FIT File Sync Pipeline.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Configuration Issues](#configuration-issues)
3. [Download Issues](#download-issues)
4. [Processing Issues](#processing-issues)
5. [Upload Issues](#upload-issues)
6. [Automation Issues](#automation-issues)
7. [Getting Help](#getting-help)

---

## Installation Issues

### Fit-File-Faker Not Found

**Error:**
```
fit-file-faker : The term 'fit-file-faker' is not recognized
```

**Solutions:**

1. **Verify pipx installation:**
```powershell
   pipx list
```
   If Fit-File-Faker isn't listed, reinstall:
```powershell
   pipx install fit-file-faker
```

2. **Check PATH:**
```powershell
   $env:PATH -split ';' | Select-String 'pipx'
```
   If no pipx path found, add it:
```powershell
   python -m pipx ensurepath
```
   Then **close and reopen PowerShell**.

3. **Use full path temporarily:**
```powershell
   # Find the full path
   pipx list --verbose
   
   # Use full path
   C:\Users\YourUsername\.local\bin\fit-file-faker.exe --version
```

### PowerShell Execution Policy Error

**Error:**
```
cannot be loaded because running scripts is disabled on this system
```

**Solution:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Type `Y` when prompted.

---

## Configuration Issues

### API Key Invalid

**Error:**
```
ERROR fetching activities: The remote server returned an error: (401) Unauthorized
```

**Solutions:**

1. **Verify API key is correct:**
   - Go to https://intervals.icu/settings
   - Check your API key in "Developer Settings"
   - Copy it exactly (no extra spaces)

2. **Update config.ps1:**
```powershell
   notepad scripts\config.ps1
```
   Ensure `IntervalsApiKey` is surrounded by quotes:
```powershell
   IntervalsApiKey = "your_key_here"
```

3. **Test API key manually:**
```powershell
   $apiKey = "your_key_here"
   $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("API_KEY:$apiKey"))
   $headers = @{ Authorization = "Basic $base64Auth" }
   Invoke-RestMethod -Uri "https://intervals.icu/api/v1/athlete/0" -Headers $headers
```

### Config File Not Found

**Error:**
```
The term '.\config.ps1' is not recognized
```

**Solution:**

1. **Verify config.ps1 exists:**
```powershell
   Test-Path scripts\config.ps1
```

2. **If False, create it:**
```powershell
   Copy-Item scripts\config.template.ps1 scripts\config.ps1
   notepad scripts\config.ps1
```

---

## Download Issues

### No Activities Found

**Error:**
```
No activities found in this date range!
```

**Solutions:**

1. **Verify activities exist on intervals.icu:**
   - Go to https://intervals.icu/activities
   - Check the date range has activities

2. **Adjust date range:**
```powershell
   .\download-from-intervals.ps1 -OldestDate "2025-12-01" -NewestDate "2025-12-31"
```

3. **Check if activities have files:**
   - On intervals.icu, click an activity
   - Look for "Download original file" option
   - If not present, that activity has no original FIT file

### Activities Have No Original Files

**Error:**
```
Activities with files: 0
```

**Why This Happens:**
- Activities manually entered (no file uploaded)
- Activities from platforms that don't preserve originals
- Files were deleted

**Solutions:**

1. **Use intervals.icu generated files instead:**
   
   Edit `download-from-intervals.ps1` and change:
```powershell
   $fileUrl = "https://intervals.icu/api/v1/activity/$activityId/file"
```
   To:
```powershell
   $fileUrl = "https://intervals.icu/api/v1/activity/$activityId/fit-file"
```
   
   This downloads intervals.icu's generated FIT files.

2. **Download directly from device platform:**
   - Garmin Connect: https://connect.garmin.com
   - Coros: https://www.coros.com/app
   - Hammerhead: Export from dashboard

### Empty Files (0 Bytes)

**Error:**
```
WARNING: File is empty (0 bytes)
```

**Solutions:**

1. **Check API response:**
```powershell
   $activityId = "i12345678"  # Replace with actual ID
   $apiKey = "your_key"
   $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("API_KEY:$apiKey"))
   
   Invoke-WebRequest -Uri "https://intervals.icu/api/v1/activity/$activityId/file" `
       -Headers @{Authorization = "Basic $base64Auth"} `
       -OutFile "test.fit" -Verbose
```

2. **Check if activity has `file_type`:**
```powershell
   $activities = Invoke-RestMethod -Uri "https://intervals.icu/api/v1/athlete/0/activities?oldest=2025-12-01&newest=2025-12-31" -Headers $headers
   $activities | Where-Object { $_.id -eq "i12345678" } | Select-Object id, file_type
```

---

## Processing Issues

### Malformed FIT File

**Error:**
```
Exception: device_index encoded value -1 is not in valid range [0, 255]
```

**Why This Happens:**
- FIT file has unusual device_info records
- Common with Garmin watches vs bike computers
- File corruption or non-standard format

**Solutions:**

1. **Skip the problematic file:**
```powershell
   Move-Item data\downloaded\2025-12-26-i12345.fit data\errors\
```

2. **Report to Fit-File-Faker:**
   - Go to https://github.com/jat255/Fit-File-Faker/issues
   - Report the bug with error message
   - Attach the problematic file (if comfortable)

3. **Process manually with different settings:**
```powershell
   fit-file-faker data\errors\2025-12-26-i12345.fit --no-device-info-edit
```

### Fields Not Defined Warning

**Warning:**
```
WARNING Field id: 32 is not defined for message device_info:23
```

**Why This Happens:**
- Non-standard FIT file fields
- Usually not a problem unless followed by errors

**Solution:**
- **If processing continues:** Ignore the warning
- **If processing fails:** Move file to errors folder

### Record Size Mismatch

**Warning:**
```
WARNING Record 11049: size (31) != defined size (95)
```

**Why This Happens:**
- Incomplete or corrupted record in FIT file
- Device firmware issue

**Solutions:**

1. **Try re-downloading the file:**
```powershell
   .\download-from-intervals.ps1 -OldestDate "2025-12-26" -NewestDate "2025-12-26" -Force
```

2. **If persists, skip the file:**
```powershell
   Move-Item data\downloaded\problematic.fit data\errors\
```

---

## Upload Issues

### Garmin Connect Authentication Failed

**Error:**
```
ERROR: Authentication failed
```

**Solutions:**

1. **Re-configure Fit-File-Faker:**
```powershell
   fit-file-faker --setup
```

2. **Check Garmin credentials:**
   - Try logging into https://connect.garmin.com manually
   - Verify username/password
   - Check for 2FA requirements

3. **Update Fit-File-Faker:**
```powershell
   pipx upgrade fit-file-faker
```

### Duplicate Activity

**Error:**
```
Activity already exists
```

**Why This Happens:**
- Activity was already uploaded
- Garmin detected it as duplicate

**Solutions:**

1. **This is normal** - The file was already uploaded
2. **File will move to processed folder** automatically
3. **Check Garmin Connect** to verify

### Upload Timeout

**Error:**
```
ERROR: The operation has timed out
```

**Solutions:**

1. **Check internet connection**

2. **Retry manually:**
```powershell
   fit-file-faker data\errors\filename.fit --upload
```

3. **Add delay between uploads:**
   Edit `config.ps1`:
```powershell
   DelayBetweenFiles = 500  # Increase to 500ms
```

---

## Automation Issues

### Scheduled Task Not Running

**Check task status:**
```powershell
Get-ScheduledTask -TaskName "FIT File Sync Pipeline"
```

**Solutions:**

1. **Verify task is enabled:**
```powershell
   Enable-ScheduledTask -TaskName "FIT File Sync Pipeline"
```

2. **Check last run result:**
```powershell
   Get-ScheduledTaskInfo -TaskName "FIT File Sync Pipeline"
```

3. **Test manually:**
```powershell
   schtasks /run /tn "FIT File Sync Pipeline"
```

4. **Check Task Scheduler logs:**
   - Open Event Viewer (`eventvwr.msc`)
   - Navigate to: Applications and Services Logs > Microsoft > Windows > TaskScheduler
   - Look for errors

### Task Runs But Nothing Happens

**Solutions:**

1. **Check logs:**
```powershell
   Get-Content logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log
```

2. **Verify paths in Task Scheduler:**
   - Open Task Scheduler
   - Right-click task → Properties
   - Check "Start in" path is correct

3. **Run with logging:**
   Edit Task Scheduler action to:
```
   powershell.exe -ExecutionPolicy Bypass -File "C:\...\monitor-and-sync.ps1" -RunOnce > C:\...\logs\task-output.log 2>&1
```

### Script Runs But Files Not Processing

**Solutions:**

1. **Check if files are downloading:**
```powershell
   Get-ChildItem data\downloaded
```

2. **Verify Fit-File-Faker configuration:**
```powershell
   fit-file-faker --version
```

3. **Run process script manually:**
```powershell
   cd scripts
   .\process-and-upload.ps1
```

---

## Performance Issues

### Slow Downloads

**Solutions:**

1. **Reduce lookback period:**
   Edit `config.ps1`:
```powershell
   LookbackDays = 3  # Instead of 7
```

2. **Increase delay between files:**
```powershell
   DelayBetweenFiles = 200  # Slower but more reliable
```

### High Memory Usage

**Solutions:**

1. **Process files in batches:**
   Limit files processed per run

2. **Clear processed files periodically:**
```powershell
   # Move old processed files to archive
   $archive = "C:\Users\chris\fit-file-sync-pipeline\archive"
   New-Item -ItemType Directory -Path $archive -Force
   
   Get-ChildItem data\processed\*.fit | 
       Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} |
       Move-Item -Destination $archive
```

---

## Duplicate Activities on Connected Services

### The Issue

If you have Garmin Connect configured to automatically push activities to other services (Strava, TrainingPeaks, Ride with GPS, etc.), those services may receive duplicate activities:

1. **First upload:** Activity syncs directly from your device → intervals.icu → Connected service
2. **Second upload:** This pipeline uploads to Garmin Connect → Garmin pushes to connected services

### Which Services Handle Duplicates

**Services with duplicate detection (No action needed):**
- ✅ **Strava** - Automatically detects and rejects duplicates
- ✅ **Ride with GPS** - Automatically detects and rejects duplicates
- ✅ **intervals.icu** - Would detect duplicates if receiving from Garmin

**Services that may create duplicates:**
- ⚠️ **TrainingPeaks** - May create duplicate activities
- ⚠️ **Other services** - Behavior varies by platform

### Solutions

**Option 1: Disable Garmin Auto-Sync for Affected Services (Recommended)**

For services that create duplicates (like TrainingPeaks):

1. Go to Garmin Connect settings
2. Navigate to **"Connected Apps"** or **"Partner Apps"**
3. Find the affected service (e.g., TrainingPeaks)
4. **Disable automatic sync** or **disconnect** the service
5. Activities will still reach these services via your original device → intervals.icu → service path

**Option 2: Manually Delete Duplicates**

After pipeline uploads:
- Check the affected service
- Delete duplicate activities (usually the newer one from Garmin)
- Activities uploaded via the original device path typically have more complete data

**Option 3: Accept Duplicates**

Some users may prefer having duplicates as a backup or for different purposes.

### Identifying Duplicates

In services like TrainingPeaks, duplicate activities will have:
- Same date and time
- Same duration
- Similar data
- One will show as coming from your original device
- One will show as coming from "Garmin" (via this pipeline)

### Recommended Configuration

**Best practice for most users:**

1. **Keep connected:** Services with good duplicate detection (Strava, Ride with GPS)
2. **Disconnect or disable auto-sync:** Services that create duplicates (TrainingPeaks)
3. **Manual sync when needed:** For services where you disabled auto-sync

This ensures clean data in all platforms without duplicates.

### Testing Your Setup

After setting up the pipeline:

1. Record a test activity
2. Wait for it to sync to intervals.icu
3. Wait for pipeline to upload to Garmin (within 1 hour)
4. Check all your connected services
5. Note which ones created duplicates
6. Adjust Garmin Connect settings accordingly

---
---

## Duplicate Activities on Connected Services

### The Issue

If you have Garmin Connect configured to automatically push activities to other services (Strava, TrainingPeaks, Ride with GPS, etc.), those services may receive duplicate activities when using this pipeline:

**Normal flow (without this pipeline):**
- Activity syncs from your device (Coros, Hammerhead) → Multiple services simultaneously
- Each service receives one copy: Strava, Ride with GPS, TrainingPeaks, intervals.icu, etc.

**With this pipeline:**
1. **First upload:** Device → Service (original upload)
2. **Second upload:** Device → intervals.icu → **This pipeline** → Garmin Connect → Service (duplicate)

Because Garmin Connect pushes to connected services, those services may receive the same activity twice.

### Which Services Handle Duplicates

**Services with automatic duplicate detection:**
- ✅ **Strava** - Automatically detects and rejects duplicates (no action needed)
- ✅ **Ride with GPS** - Automatically detects and rejects duplicates (no action needed)

**Services that create duplicates:**
- ⚠️ **TrainingPeaks** - Creates duplicate activities (requires workaround)
- ⚠️ **intervals.icu** - Would create duplicates if connected to Garmin (requires workaround)
- ⚠️ **Other services** - Behavior varies by platform (test to verify)

### Current Workarounds

**For services that create duplicates (like TrainingPeaks):**

**Option 1: Disable Garmin Auto-Sync (Recommended)**

1. Go to Garmin Connect settings
2. Navigate to **"Connected Apps"** or **"Partner Apps"**
3. Find the affected service (e.g., TrainingPeaks)
4. **Disable automatic sync** or **disconnect** the service
5. Keep your device's native sync to that service active

**Result:**
- Device → Service ✅ (activities still sync normally)
- Device → intervals.icu → Pipeline → Garmin Connect ✅ (Garmin metrics available)
- No duplicates ✅

**Option 2: Manual Upload to Affected Services**

If you need data in both Garmin Connect and the affected service:
1. Disable Garmin auto-sync for that service
2. Periodically export activities from Garmin Connect
3. Manually upload to the affected service when needed
4. This is time-consuming and not ideal for daily use

**Option 3: Manually Delete Duplicates**

- Check the affected service after each pipeline sync
- Delete duplicate activities (usually the newer one from Garmin)
- Time-consuming and not sustainable long-term

### Future Improvements

We're exploring better solutions to this limitation, including:
- Selective sync options (only upload certain activity types)
- Duplicate prevention logic
- Integration with service APIs to avoid duplicates

This is a known limitation requiring workarounds. Contributions and suggestions welcome!

### Identifying Duplicates

In services like TrainingPeaks, duplicate activities will have:
- Same date and time
- Same duration  
- Similar data
- One from your original device (first)
- One from Garmin Connect via this pipeline (second)

### Why Use This Pipeline Despite This Limitation?

Even with the duplicate issue, this pipeline provides value:
- **Garmin-exclusive metrics** - Training Status, Body Battery, VO2 max calculations, Training Readiness
- **Unified training ecosystem** - All activities in Garmin Connect
- **Garmin Coach compatibility** - Use training plans requiring Garmin data
- **Worth the workaround** - For most users, disconnecting a few services from Garmin is a small trade-off

### Recommended Configuration

**For most users:**

1. **Keep enabled in Garmin:** Services with duplicate detection (Strava, Ride with GPS)
2. **Disable in Garmin:** Services that create duplicates (TrainingPeaks, intervals.icu if connected)
3. **Keep device sync active:** For ALL services

This provides clean data everywhere while maintaining access to Garmin's ecosystem.

### Testing Your Setup

After setting up the pipeline:

1. Record a test activity
2. Wait for it to sync from your device to all services (including intervals.icu)
3. Wait for pipeline to upload to Garmin Connect (within 1 hour)
4. Check all your connected services for duplicates
5. Disable Garmin auto-sync for any services that created duplicates

---
---

## Getting Help

### Check Logs First
```powershell
# View recent log entries
Get-Content logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log -Tail 50
```

### Enable Verbose Logging

Edit scripts to add `-Verbose` flag:
```powershell
Invoke-RestMethod -Uri $url -Headers $headers -Verbose
```

### Collect Diagnostic Information
```powershell
# System info
$PSVersionTable

# Fit-File-Faker info
pipx list

# Configuration (redact API key!)
Get-Content scripts\config.ps1 | Select-String -NotMatch "ApiKey"

# Recent log
Get-Content logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log -Tail 20
```

### Report an Issue

If you can't resolve the issue:

1. **Check existing issues:** https://github.com/yourusername/fit-file-sync-pipeline/issues

2. **Create new issue:**
   - Include error messages
   - Include relevant log entries (redact API keys!)
   - Describe steps to reproduce
   - System info (Windows version, PowerShell version)

3. **For Fit-File-Faker specific issues:**
   - Report at: https://github.com/jat255/Fit-File-Faker/issues

### Community Support

- **intervals.icu Forum:** https://forum.intervals.icu
- **Fit-File-Faker Discussions:** https://github.com/jat255/Fit-File-Faker/discussions

---

## Common Workflow Issues

### "I want to re-upload an activity"
```powershell
# Find the processed file
Get-ChildItem data\processed\*2025-12-26*.fit

# Move back to downloaded
Move-Item data\processed\2025-12-26-i12345.uploaded.fit data\downloaded\2025-12-26-i12345.fit

# Delete from Garmin Connect first, then reprocess
.\scripts\process-and-upload.ps1
```

### "I want to process only specific dates"
```powershell
.\scripts\download-from-intervals.ps1 -OldestDate "2025-12-25" -NewestDate "2025-12-25"
.\scripts\process-and-upload.ps1
```

### "I want to test without uploading"
```powershell
.\scripts\monitor-and-sync.ps1 -RunOnce -DryRun
```

### "Files are stuck in downloaded folder"
```powershell
# Check for errors
Get-ChildItem data\downloaded

# Try processing manually
.\scripts\process-and-upload.ps1

# Check error folder
Get-ChildItem data\errors
```

---

Still having issues? [Open an issue](https://github.com/yourusername/fit-file-sync-pipeline/issues) with details!