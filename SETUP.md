# Setup Guide - FIT File Sync Pipeline

Complete installation and configuration guide for the FIT File Sync Pipeline.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Initial Testing](#initial-testing)
5. [Automation Setup](#automation-setup)
6. [Verification](#verification)

---

## Prerequisites

### Required Software

1. **Windows 11** (or Windows 10 with PowerShell 5.1+)
   - Check version: `$PSVersionTable.PSVersion`

2. **Python 3.8+**
   - Download from: https://www.python.org/downloads/
   - Verify: `python --version`

3. **pipx** (Python package installer)
```powershell
   python -m pip install --user pipx
   python -m pipx ensurepath
```
   - Close and reopen PowerShell after installation

4. **Git** (for cloning the repository)
   - Download from: https://git-scm.com/download/win
   - Verify: `git --version`

### Required Accounts

1. **intervals.icu Account**
   - Sign up: https://intervals.icu
   - Ensure your activities are syncing from your device/platform

2. **Garmin Connect Account**
   - Sign up: https://connect.garmin.com
   - Note your username/email and password

---

## Installation

### Step 1: Install Fit-File-Faker

This is the core tool that enables uploads to Garmin Connect.
```powershell
# Install Fit-File-Faker via pipx
pipx install fit-file-faker

# Verify installation
fit-file-faker --version
```

**Configure Fit-File-Faker with Garmin credentials:**
```powershell
# Run configuration wizard
fit-file-faker --setup

# Or manually edit the config file at:
# C:\Users\YourUsername\.fit_file_faker\config.ini
```

When prompted, enter:
- Your Garmin Connect email/username
- Your Garmin Connect password

**Test Fit-File-Faker works:**
```powershell
# Download a test FIT file and try uploading (dry run)
fit-file-faker path\to\test.fit --upload --dryrun
```

If this fails, see [Fit-File-Faker documentation](https://github.com/jat255/Fit-File-Faker#readme) for troubleshooting.

### Step 2: Clone This Repository
```powershell
# Navigate to where you want the project
cd C:\Users\YourUsername

# Clone the repository
git clone https://github.com/yourusername/fit-file-sync-pipeline.git

# Navigate into the project
cd fit-file-sync-pipeline
```

### Step 3: Create Folder Structure

The installation creates the basic structure, but ensure data folders exist:
```powershell
# Create data directories
New-Item -ItemType Directory -Path "data\downloaded" -Force
New-Item -ItemType Directory -Path "data\processed" -Force
New-Item -ItemType Directory -Path "data\errors" -Force
New-Item -ItemType Directory -Path "logs" -Force
```

---

## Configuration

### Step 1: Get Your intervals.icu API Key

1. Go to https://intervals.icu/settings
2. Scroll to **"Developer Settings"** (near the bottom)
3. Click **"Generate API Key"** if you don't have one
4. Copy the API key (format: `abc123xyz456...`)

### Step 2: Create Configuration File
```powershell
# Copy the template
Copy-Item scripts\config.template.ps1 scripts\config.ps1

# Edit the configuration
notepad scripts\config.ps1
```

### Step 3: Configure Settings

Edit `scripts\config.ps1` with your details:
```powershell
$Config = @{
    # YOUR intervals.icu API key (from Step 1)
    IntervalsApiKey = "paste_your_api_key_here"
    
    # Update paths if you installed elsewhere
    ProjectRoot = "C:\Users\chris\fit-file-sync-pipeline"
    DownloadFolder = "C:\Users\chris\fit-file-sync-pipeline\data\downloaded"
    ProcessedFolder = "C:\Users\chris\fit-file-sync-pipeline\data\processed"
    ErrorFolder = "C:\Users\chris\fit-file-sync-pipeline\data\errors"
    LogFolder = "C:\Users\chris\fit-file-sync-pipeline\logs"
    
    # Sync Settings - adjust as needed
    SyncIntervalMinutes = 60    # Check for new activities every hour
    LookbackDays = 7            # Check last 7 days for new activities
    
    # Processing Settings
    DryRun = $false             # Set to $true for testing
    MaxRetries = 3
    DelayBetweenFiles = 100     # Milliseconds between API calls
}
```

**Important:** Replace `C:\Users\chris` with your actual username!

**Save and close** the file.

---

## Initial Testing

### Test 1: Verify Configuration
```powershell
# Navigate to scripts folder
cd C:\Users\YourUsername\fit-file-sync-pipeline\scripts

# Test loading configuration
. .\config.ps1
$Config
```

This should display your configuration without errors.

### Test 2: Download Test Files

Download activities from a recent date range:
```powershell
# Download last week's activities
.\download-from-intervals.ps1 -OldestDate "2025-12-01" -NewestDate "2025-12-31"
```

**Expected output:**
```
=== Starting Download from intervals.icu ===
Found 23 activities
Activities with files: 23
[1/23] Downloading i12345678 - 2025-12-01
  SUCCESS: 253201 bytes
...
```

**Check the downloaded folder:**
```powershell
Get-ChildItem ..\data\downloaded
```

You should see `.fit` files.

### Test 3: Dry Run Processing

Test processing **without** actually uploading to Garmin:
```powershell
.\process-and-upload.ps1 -DryRun
```

**Expected output:**
```
=== Starting FIT File Processing ===
Found 23 files to process
[1/23] Processing: 2025-12-01-i12345678.fit
  SUCCESS: Moved to processed\
...
```

**Verify:**
- Files moved to `data\processed\` with `.uploaded.fit` extension
- Check `logs\` folder for detailed logs

### Test 4: Complete Sync Cycle (Dry Run)
```powershell
.\monitor-and-sync.ps1 -RunOnce -DryRun
```

This runs the full pipeline in test mode.

### Test 5: Real Upload (Single File)

Once dry runs succeed, test a real upload:
```powershell
# Move one file back to downloaded folder
Move-Item ..\data\processed\2025-12-26-i12345.uploaded.fit ..\data\downloaded\2025-12-26-i12345.fit

# Process without dry run
.\process-and-upload.ps1
```

**Check Garmin Connect:**
1. Go to https://connect.garmin.com/modern/activities
2. Verify the activity appears with correct date/time
3. Check that metrics are calculating

---

## Automation Setup

### Option 1: Windows Task Scheduler (Recommended)

Run the pipeline automatically on a schedule.

#### Create Scheduled Task

1. **Open Task Scheduler**
   - Press `Windows + R`
   - Type: `taskschd.msc`
   - Press Enter

2. **Create New Task**
   - Click **"Create Task"** (not "Create Basic Task")

3. **General Tab:**
   - Name: `FIT File Sync Pipeline`
   - Description: `Automated sync from intervals.icu to Garmin Connect`
   - Select: **"Run whether user is logged on or not"**
   - Check: **"Run with highest privileges"**

4. **Triggers Tab:**
   - Click **"New"**
   - Begin the task: **"On a schedule"**
   - Settings: **"Daily"**
   - Start: Choose a time (e.g., 6:00 AM)
   - Repeat task every: **1 hour**
   - For a duration of: **1 day**
   - Check: **"Enabled"**
   - Click **OK**

5. **Actions Tab:**
   - Click **"New"**
   - Action: **"Start a program"**
   - Program/script: `powershell.exe`
   - Add arguments:
```
     -ExecutionPolicy Bypass -File "C:\Users\YourUsername\fit-file-sync-pipeline\scripts\monitor-and-sync.ps1" -RunOnce
```
   - Start in: `C:\Users\YourUsername\fit-file-sync-pipeline\scripts`
   - Click **OK**

6. **Conditions Tab:**
   - Uncheck: **"Start the task only if the computer is on AC power"** (if laptop)
   - Check: **"Wake the computer to run this task"** (optional)

7. **Settings Tab:**
   - Check: **"Allow task to be run on demand"**
   - Check: **"Run task as soon as possible after a scheduled start is missed"**
   - If the task fails, restart every: **15 minutes**
   - Attempt to restart up to: **3 times**

8. **Click OK**
   - Enter your Windows password when prompted

#### Test the Scheduled Task
```powershell
# Run the task manually
schtasks /run /tn "FIT File Sync Pipeline"

# Check if it ran
Get-Content ..\logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log
```

### Option 2: Run Continuously

Run the script continuously in a PowerShell window:
```powershell
# This will run indefinitely, checking every hour
.\monitor-and-sync.ps1
```

**Not recommended** unless you have a dedicated machine that's always on.

### Option 3: Manual Execution

Run on-demand whenever you want:
```powershell
.\monitor-and-sync.ps1 -RunOnce
```

---

## Verification

### Check Logs
```powershell
# View today's log
Get-Content ..\logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log

# View in real-time (tail)
Get-Content ..\logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log -Wait
```

### Monitor Folders
```powershell
# Check for new downloads
Get-ChildItem ..\data\downloaded

# Check processed files
Get-ChildItem ..\data\processed | Sort-Object LastWriteTime -Descending | Select-Object -First 10

# Check for errors
Get-ChildItem ..\data\errors
```

### Verify on Garmin Connect

1. Go to https://connect.garmin.com/modern/activities
2. Check recent activities appear
3. Verify Training Status is updating
4. Check VO2 max and other metrics

### Check intervals.icu Integration

1. Go to https://intervals.icu/activities
2. Your activities should still show normally
3. They're now also in Garmin Connect

---

## Maintenance

### Update Fit-File-Faker
```powershell
pipx upgrade fit-file-faker
```

### Update This Pipeline
```powershell
cd C:\Users\YourUsername\fit-file-sync-pipeline
git pull
```

### Clean Up Old Logs
```powershell
# Delete logs older than 30 days
Get-ChildItem ..\logs\*.log | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item
```

### Review Error Files

Periodically check `data\errors\` for files that failed:
```powershell
Get-ChildItem ..\data\errors

# Try processing them manually
fit-file-faker ..\data\errors\problematic-file.fit --upload
```

---

## Next Steps

- ✅ Pipeline is running automatically
- ✅ Activities sync from intervals.icu to Garmin Connect
- ✅ Garmin metrics are updating

**Enjoy having all your training data in one place!**

For issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)