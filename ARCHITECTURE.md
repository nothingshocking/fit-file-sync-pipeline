# Architecture Documentation

## System Overview

The FIT File Sync Pipeline is an automated data synchronization system that bridges non-Garmin fitness devices with Garmin Connect's ecosystem.

### Data Flow

\\\
┌─────────────────┐
│  Coros Dura     │
│  Hammerhead K2  │
└────────┬────────┘
         │
         │ (native sync)
         ▼
┌─────────────────┐
│ intervals.icu   │ ◄─── Original FIT files stored here
└────────┬────────┘
         │
         │ (API download)
         ▼
┌─────────────────┐
│  This Pipeline  │
│   downloaded/   │
└────────┬────────┘
         │
         │ (Fit-File-Faker processing)
         ▼
┌─────────────────┐
│ Garmin Connect  │ ◄─── Access to Garmin metrics
└─────────────────┘
\\\

### Component Architecture

\\\
┌──────────────────────────────────────────────────┐
│            Windows Task Scheduler                │
│         (Runs every hour, hidden)                │
└───────────────────┬──────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│        monitor-and-sync.ps1                      │
│        (Orchestration script)                    │
└───────┬─────────────────────┬────────────────────┘
        │                     │
        ▼                     ▼
┌─────────────────┐   ┌─────────────────┐
│ download-from-  │   │ process-and-    │
│ intervals.ps1   │   │ upload.ps1      │
└────┬────────────┘   └────┬────────────┘
     │                     │
     ▼                     ▼
┌─────────────────┐   ┌─────────────────┐
│ intervals.icu   │   │ Fit-File-Faker  │
│      API        │   │    (pipx)       │
└─────────────────┘   └────┬────────────┘
                           │
                           ▼
                    ┌─────────────────┐
                    │ Garmin Connect  │
                    │   (via garth)   │
                    └─────────────────┘
\\\

---

## Script Architecture

### download-from-intervals.ps1

**Purpose:** Download FIT files from intervals.icu

**Inputs:**
- \-OldestDate\ (string, optional): Start of date range
- \-NewestDate\ (string, optional): End of date range
- \-Force\ (switch, optional): Re-download existing files

**Outputs:**
- FIT files in \data/downloaded/\
- Log entries in daily log file
- Return: Number of files downloaded

**Logic Flow:**
1. Load configuration (\config.ps1\)
2. Calculate date range (defaults to last 7 days)
3. Query intervals.icu API for activities
4. Filter activities with \ile_type\ field (original files available)
5. For each activity:
   - Check if already downloaded (skip unless \-Force\)
   - Download file via \/activity/{id}/file\ endpoint
   - Validate file size > 0
   - Save to \downloaded/\ folder
6. Log results

**Key Functions:**
- \Write-Log\: Structured logging (timestamp, level, message)
- \Download-IntervalsFits\: Main download logic

**Error Handling:**
- API connection failures: Log and return 0
- Empty files: Delete and log error
- Network timeouts: Logged, individual file failure doesn't stop batch

### process-and-upload.ps1

**Purpose:** Process FIT files with Fit-File-Faker and upload to Garmin

**Inputs:**
- \-DryRun\ (switch, optional): Skip processing (note: has bugs with Fit-File-Faker)

**Outputs:**
- Moved files to \processed/\ or \errors/\
- Renamed successful files with \.uploaded.fit\ extension
- Log entries

**Logic Flow:**
1. Load configuration
2. Scan \downloaded/\ for \*.fit\ files (exclude \*_modified.fit\)
3. For each file:
   - Execute \it-file-faker {file} --upload\
   - Capture stdout/stderr
   - Analyze output:
     - Check for "activity already exists" or "HTTP conflict" (duplicate)
     - Check for "Uploading.*using garth" (success indicator)
     - Check for "Traceback" or "Exception" (real error)
   - If duplicate: Log as warning, move to \processed/\ (success)
   - If success: Move to \processed/\, increment success counter
   - If error: Move to \errors/\, increment error counter
   - Cleanup: Remove \*_modified.fit\ files
4. Log summary (success, duplicates, errors)

**Key Functions:**
- \Write-Log\: Same as download script
- \Process-FitFiles\: Main processing logic

**Error Handling:**
- Fit-File-Faker crashes: File moved to \errors/\, processing continues
- Garmin authentication failures: Logged, file moved to \errors/\
- Duplicate activities: Treated as success (expected behavior)

**Critical Logic:**
\\\powershell
# Duplicate detection
\ = \ -match "activity already exists|HTTP conflict"

# Success detection
\ = \ -match "Uploading.*using garth" -or \

# Error detection (only if no success)
\ = \ -match "Traceback.*Exception"
if (\ -and -not \) {
    \ = \True
}
\\\

### monitor-and-sync.ps1

**Purpose:** Orchestrate complete sync cycle

**Inputs:**
- \-RunOnce\ (switch, optional): Run single cycle and exit
- \-DryRun\ (switch, optional): Pass to process script

**Outputs:**
- Complete sync cycle execution
- Log entries

**Logic Flow:**
1. Load configuration
2. Log sync cycle start
3. Execute \download-from-intervals.ps1\ (no parameters = last 7 days)
4. Execute \process-and-upload.ps1\ (with \-DryRun\ if specified)
5. Log sync cycle complete
6. If not \-RunOnce\: Sleep for \SyncIntervalMinutes\, repeat

**Key Functions:**
- \Write-Log\: Same logging infrastructure
- \Run-SyncCycle\: Execute download and process

**Error Handling:**
- Scripts called with \&\ operator (errors logged by child scripts)
- No retry logic (relies on hourly schedule)

### config.ps1

**Purpose:** Centralized configuration

**Structure:**
\\\powershell
\ = @{
    # API
    IntervalsApiKey = "key_here"
    
    # Paths (absolute)
    ProjectRoot = "C:\\path"
    DownloadFolder = "C:\\path\\data\\downloaded"
    ProcessedFolder = "C:\\path\\data\\processed"
    ErrorFolder = "C:\\path\\data\\errors"
    LogFolder = "C:\\path\\logs"
    
    # Sync settings
    SyncIntervalMinutes = 60
    LookbackDays = 7
    
    # Processing
    DryRun = \False
    MaxRetries = 3  # Not implemented yet
    DelayBetweenFiles = 100  # Milliseconds
}
\\\

**Usage:**
\\\powershell
. "\\\config.ps1"
\ = \.IntervalsApiKey
\\\

---

## External Dependencies

### Fit-File-Faker

**Installation:** \pipx install fit-file-faker\

**Purpose:** Transform FIT files to appear from Garmin devices

**Configuration:** \%LOCALAPPDATA%\\FitFileFaker\\config.json\

**Called via:** \it-file-faker {filepath} --upload\

**Key behaviors:**
- Reads FIT file
- Modifies device_info records
- Creates \*_modified.fit\ file
- Uploads to Garmin Connect via garth library
- Returns 0 on success, non-zero on error
- Outputs text to stdout/stderr

**Known issues:**
- \--dryrun\ with \--upload\ causes FileNotFoundError
- Some device_info fields cause warnings (harmless)
- Modified files left behind (pipeline cleans up)

### intervals.icu API

**Base URL:** \https://intervals.icu/api/v1\

**Authentication:** Basic Auth
- Header: \Authorization: Basic {base64(API_KEY:token)}\

**Key Endpoints:**

1. **List Activities**
   - \GET /athlete/0/activities?oldest={date}&newest={date}\
   - Returns: Array of activity objects
   - Key fields: \id\, \start_date_local\, \	ype\, \ile_type\

2. **Download File**
   - \GET /activity/{id}/file\
   - Returns: Binary FIT file (NOT gzipped despite docs)
   - May return 422 if no original file exists

**Rate Limiting:** Not documented, but pipeline adds 100ms delay between downloads

### Garmin Connect

**API:** Not directly used (via Fit-File-Faker/garth)

**Behavior:**
- Accepts uploads from Fit-File-Faker
- Returns HTTP 409 Conflict if duplicate activity exists
- Automatically pushes to connected services (Strava, TrainingPeaks, etc.)

---

## Data Models

### Activity (from intervals.icu API)

\\\json
{
  "id": "i123456789",
  "start_date_local": "2026-01-13T19:10:20",
  "type": "Ride",
  "file_type": "fit",
  "distance": 50000,
  "moving_time": 7200,
  // ... many other fields
}
\\\

**Critical fields for pipeline:**
- \id\: Used to download file
- \start_date_local\: Used for filename
- \ile_type\: Must be present to download

### FIT File Structure

Binary format containing:
- Device info records (manufacturer, product, serial)
- Session records (start time, duration, sport type)
- Lap records
- Record messages (GPS, heart rate, power, cadence, etc.)

**Modified by Fit-File-Faker:**
- Device info → Changed to Garmin
- Nothing else altered (preserves all training data)

### Configuration Object

\\\powershell
@{
    IntervalsApiKey = [string]
    ProjectRoot = [string]
    DownloadFolder = [string]
    ProcessedFolder = [string]
    ErrorFolder = [string]
    LogFolder = [string]
    SyncIntervalMinutes = [int]
    LookbackDays = [int]
    DryRun = [bool]
    MaxRetries = [int]
    DelayBetweenFiles = [int]
}
\\\

---

## File Naming Conventions

### Downloaded Files
Format: \YYYY-MM-DD-iACTIVITYID.fit\
Example: \2026-01-13-i117880666.fit\

### Processed Files
Format: \YYYY-MM-DD-iACTIVITYID.uploaded.fit\
Example: \2026-01-13-i117880666.uploaded.fit\

### Modified Files (temporary)
Format: \YYYY-MM-DD-iACTIVITYID_modified.fit\
Example: \2026-01-13-i117880666_modified.fit\
Note: Automatically cleaned up after processing

### Log Files
Format: \sync-YYYY-MM-DD.log\
Example: \sync-2026-02-19.log\

---

## Logging Architecture

### Log Format

\\\
YYYY-MM-DD HH:mm:ss [LEVEL] Message
\\\

Example:
\\\
2026-02-19 14:30:15 [INFO] Starting Download from intervals.icu
2026-02-19 14:30:16 [SUCCESS] Found 5 activities with files
2026-02-19 14:30:20 [ERROR] Failed to download i123456: Network timeout
\\\

### Log Levels

- **INFO**: Normal operations (downloads, processing starts)
- **SUCCESS**: Successful completions
- **WARNING**: Non-critical issues (duplicates, skipped files)
- **ERROR**: Failures requiring attention

### Log Locations

- **File**: \logs/sync-YYYY-MM-DD.log\ (one file per day)
- **Console**: Color-coded output (Red=ERROR, Yellow=WARNING, Green=SUCCESS)

### Log Retention

- Manual cleanup required
- Suggested: Keep 30 days, archive older
- Typical size: 10-50 KB per day

---

## Security Considerations

### Secrets Management

**Stored in plain text (risk areas):**
1. \scripts/config.ps1\ - intervals.icu API key
2. \%LOCALAPPDATA%\\FitFileFaker\\config.json\ - Garmin username/password

**Mitigation:**
- Files excluded from git via \.gitignore\
- Local file permissions (user-only access)
- Template files provided (users create own)

**Recommendation:**
- Use strong, unique passwords
- Rotate API keys periodically
- Don't share config files

### API Key Permissions

**intervals.icu API key:**
- Read-only access to activities
- Cannot modify or delete data
- Scoped to single athlete

### Network Security

- All API calls over HTTPS
- No data sent to third parties (except Garmin via Fit-File-Faker)
- No telemetry or analytics

---

## Performance Characteristics

### Download Speed
- ~1-2 seconds per activity
- Limited by intervals.icu API
- 100ms delay between requests (configurable)
- 26 activities: ~30-45 seconds

### Processing Speed
- ~5-10 seconds per activity
- Limited by Fit-File-Faker processing
- Garmin upload takes 2-3 seconds
- 26 activities: ~2-5 minutes

### Total Sync Cycle
- 10 activities: ~1-2 minutes
- 50 activities: ~5-8 minutes
- Includes download, process, upload, logging

### Resource Usage
- CPU: Minimal (1-2% during active sync)
- Memory: <100 MB
- Disk: FIT files typically 200-500 KB each
- Network: ~500 KB - 2 MB per activity

### Scalability
- Tested: 48 activities in single batch (successful)
- Expected limit: ~100-200 activities (API/time constraints)
- Hourly schedule prevents large backlogs

---

## Error Recovery

### Automatic Recovery

1. **Network failures**: Individual file failures don't stop batch
2. **Duplicates**: Detected and handled as success
3. **Temporary files**: Cleaned up automatically
4. **Task Scheduler**: Retries failed runs (3 attempts, 15-min intervals)

### Manual Recovery

1. **Files in errors/**: Review logs, fix underlying issue, move back to downloaded/
2. **Stuck in downloaded/**: Delete and re-download with \-Force\
3. **Authentication failures**: Update Fit-File-Faker config, reprocess
4. **Missing activities**: Manually specify date range

### Monitoring

**Check these regularly:**
- Task Scheduler: Last run time, last result
- \data/errors/\: Should be empty or minimal
- Latest log file: Look for ERROR entries
- Garmin Connect: Verify activities appearing

---

## Testing Strategy

### Manual Testing

1. **Single file**: Test with one activity first
2. **Small batch**: 5-10 activities
3. **Large batch**: 20-50 activities
4. **Duplicates**: Re-run on same dataset

### Automated Testing (Future)

Currently no automated tests. Future Python version should include:
- Unit tests for each function
- Integration tests with mock APIs
- End-to-end tests

### Test Environments

**Development:**
- Separate intervals.icu account (optional)
- Garmin test account (not recommended - duplicates)
- Use \-DryRun\ for testing (note: buggy with upload)

**Production:**
- Real accounts
- Start with small date ranges
- Monitor logs closely initially

---

## Deployment

### Prerequisites
1. Windows 10/11
2. PowerShell 5.1+
3. Python 3.8+ (for pipx)
4. Git (for repository cloning)

### Installation Steps
1. Clone repository
2. Install Fit-File-Faker
3. Configure Fit-File-Faker
4. Create \config.ps1\ from template
5. Test single sync cycle
6. Create Task Scheduler task
7. Monitor initial runs

### Rollback
- Disable Task Scheduler task
- Activities in Garmin can be manually deleted
- intervals.icu not affected (read-only)

---

## Maintenance

### Regular
- Check logs weekly for errors
- Verify Task Scheduler is running
- Monitor disk space (logs/, processed/)

### Periodic
- Update Fit-File-Faker: \pipx upgrade fit-file-faker\
- Pull pipeline updates: \git pull\
- Archive old logs (>30 days)
- Review processed files (move to archive)

### As Needed
- Regenerate intervals.icu API key (if compromised)
- Update Garmin password (in Fit-File-Faker config)
- Adjust sync frequency (edit Task Scheduler trigger)

---

*Document Version: 1.0*
*Last Updated: February 19, 2026*
