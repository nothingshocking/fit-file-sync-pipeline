# Project History - FIT File Sync Pipeline

## Project Origin

**Start Date:** February 19, 2026
**Developer:** Chris
**Initial Problem:** Need to sync cycling activities from non-Garmin devices (Coros Dura, Hammerhead Karoo 2) to Garmin Connect to access Garmin's training metrics and ecosystem.

### The Challenge

**Devices Used:**
- Coros Dura (cycling computer)
- Hammerhead Karoo 2 (cycling computer)

**Data Flow:**
- Device → Strava, Ride with GPS, TrainingPeaks, intervals.icu (native sync)
- Activities stored in intervals.icu with original FIT files

**Goal:**
- Get activities into Garmin Connect for Training Status, VO2 max, Body Battery, etc.
- Automate the sync process
- Maintain data integrity across all platforms

**Key Constraint:**
- Garmin Connect doesn't directly accept uploads from non-Garmin devices
- Solution: Use Fit-File-Faker to transform FIT files to appear Garmin-compatible

---

## Development Timeline

### Phase 1: Discovery and Tool Selection

**Tools Evaluated:**
- **Fit-File-Faker** - Selected for device spoofing capability
- **intervals.icu API** - Chosen for reliable FIT file storage and API access
- **PowerShell** - Selected for Windows automation and Task Scheduler integration

**Initial Setup:**
- Installed Fit-File-Faker via pipx
- Configured Garmin Edge 1030 as target device (appropriate for cycling)
- Tested manual file processing

### Phase 2: Script Development

**download-from-intervals.ps1**
- Purpose: Download original FIT files from intervals.icu API
- Key features:
  - Date range filtering
  - Only downloads activities with original files (\ile_type\ check)
  - Skip already downloaded files
  - Configurable lookback period (7 days default)

**process-and-upload.ps1**
- Purpose: Process FIT files and upload to Garmin Connect
- Key features:
  - Calls Fit-File-Faker for each file
  - Duplicate detection (Garmin returns HTTP 409 conflict)
  - Error handling with file quarantine
  - Cleanup of \_modified.fit\ files
  - Detailed logging

**monitor-and-sync.ps1**
- Purpose: Orchestrate complete sync cycle
- Key features:
  - Runs download → process → upload sequence
  - Configurable to run once or continuously
  - Integrates with Windows Task Scheduler

**config.ps1**
- Purpose: Centralized configuration
- Contains:
  - intervals.icu API key
  - File paths
  - Sync interval settings
  - Processing options

### Phase 3: Testing and Refinement

**Test Datasets:**
1. December 2025: 23 activities (initial test)
2. November 2025: 26 activities (duplicate detection test - 3 pre-uploaded)
3. September-October 2025: 48 activities (large batch test)
4. January 2026: 6 activities (live automation test)

**Total Activities Processed:** ~103 activities

**Issues Discovered:**

**Issue #1: JSON Syntax Errors in config.json**
- Problem: Missing commas, wrong field names (\itfiles_path\ vs \it_files_dir\)
- Solution: Corrected JSON syntax, documented common errors

**Issue #2: Script Error Detection Too Aggressive**
- Problem: WARNING messages treated as errors
- Solution: Refined error detection to only catch Exceptions and Traceback
- Ignored harmless device_info field warnings

**Issue #3: Modified Files Being Processed**
- Problem: \_modified.fit\ files created by Fit-File-Faker were processed
- Solution: Added filter to exclude \*_modified.fit\ files

**Issue #4: Duplicate Detection False Positives**
- Problem: Successfully uploaded files marked as errors
- Solution: Check for "Uploading.*using garth" or duplicate warning to confirm success

**Issue #5: Dry-Run Bug**
- Problem: \--dryrun\ flag with \--upload\ causes FileNotFoundError in Fit-File-Faker
- Solution: Documented as upstream bug, don't use dry-run with upload

**Issue #6: Duplicate Activities on Connected Services**
- Problem: Services connected to both device AND Garmin receive duplicates
- Impact: TrainingPeaks and intervals.icu create duplicates; Strava/RWGPS handle automatically
- Workaround: Disable Garmin auto-sync for affected services
- Future: Python version with direct service integration planned

### Phase 4: Automation

**Windows Task Scheduler Configuration:**
- Frequency: Every hour
- Runs whether user logged in or not
- Hidden execution (no PowerShell window)
- Automatic retry on failure (3 attempts, 15-minute intervals)
- 1-hour timeout per run

**Monitoring:**
- Daily log files in \logs/\ folder
- File organization: \downloaded/\, \processed/\, \errors/\
- Task Scheduler history tracking

### Phase 5: Documentation and GitHub

**Repository Structure:**
\\\
fit-file-sync-pipeline/
├── scripts/
│   ├── config.template.ps1
│   ├── config.ps1 (gitignored)
│   ├── download-from-intervals.ps1
│   ├── process-and-upload.ps1
│   └── monitor-and-sync.ps1
├── data/
│   ├── downloaded/
│   ├── processed/
│   └── errors/
├── logs/
├── docs/
│   └── FIT-FILE-FAKER-SETUP.md
├── README.md
├── SETUP.md
├── TROUBLESHOOTING.md
├── CONTRIBUTING.md
├── ROADMAP.md
├── PROJECT-HISTORY.md (this file)
├── .gitignore
└── LICENSE (MIT)
\\\

**Git Setup:**
- Initialized repository
- Created GitHub remote
- Added .gitignore (excludes config.ps1, data/, logs/)
- Released v1.0.0 (initial release)
- Released v1.1.0 (automated sync)

---

## Key Technical Decisions

### Why PowerShell?

**Pros:**
- Native to Windows (no installation required)
- Built-in Task Scheduler integration
- Easy file system operations
- Good API support (Invoke-RestMethod)

**Cons:**
- Windows-only
- Limited service API libraries
- No built-in duplicate tracking

### Why intervals.icu as Data Source?

**Pros:**
- Stores original FIT files from all devices
- Clean, well-documented API
- Free tier supports API access
- Already in user's workflow

**Cons:**
- Requires activities to flow through intervals.icu first
- Some activities may not have original files

### Why Garmin Edge 1030?

**Device Selection Criteria:**
- User's primary activities: cycling
- Devices: Coros Dura, Hammerhead Karoo 2
- Edge 1030 = flagship cycling computer (realistic match)

**Alternative devices considered:**
- Edge 1040 (newer model)
- Fenix 7 (if multisport needed)
- Forerunner 955 (if running focused)

### File Organization Strategy

**Three-folder system:**
- \downloaded/\ - Raw files from intervals.icu
- \processed/\ - Successfully uploaded files (renamed with .uploaded)
- \errors/\ - Files that failed processing

**Benefits:**
- Clear status of each file
- Easy to identify problems
- Can reprocess errors manually
- Prevents duplicate processing

---

## Configuration Specifications

### intervals.icu API

**Endpoint:** \https://intervals.icu/api/v1/athlete/0/activities\
**Authentication:** Basic Auth (API_KEY:token)
**Key Fields:**
- \id\ - Activity identifier
- \start_date_local\ - Activity timestamp
- \	ype\ - Activity type (Ride, Run, etc.)
- \ile_type\ - Presence indicates original FIT file available

**Download Endpoint:** \https://intervals.icu/api/v1/activity/{id}/file\
**Returns:** FIT file (not gzipped despite documentation)

### Fit-File-Faker Configuration

**Location:** \%LOCALAPPDATA%\\FitFileFaker\\config.json\

**Required Fields:**
\\\json
{
  "garmin_username": "email@example.com",
  "garmin_password": "password",
  "fit_files_dir": "C:\\\\path\\\\to\\\\downloaded",
  "device_info": {
    "manufacturer": "garmin",
    "product": "edge1030",
    "serial_number": "3982691993"
  }
}
\\\

**Common Errors:**
- Missing comma between fields
- Wrong field name (\itfiles_dir\ vs \it_files_dir\)
- Single backslashes in Windows paths (need double \\\\\\)
- Extra comma after last item in section

### Pipeline Configuration

**Default Settings:**
- \SyncIntervalMinutes\: 60 (check hourly)
- \LookbackDays\: 7 (scan last week for new activities)
- \DelayBetweenFiles\: 100ms (rate limiting)

**File Paths:** All under project root
- \DownloadFolder\: data/downloaded
- \ProcessedFolder\: data/processed
- \ErrorFolder\: data/errors
- \LogFolder\: logs

---

## Lessons Learned

### Technical

1. **API file metadata is critical** - Always check \ile_type\ field before attempting download
2. **Error detection requires context** - Warnings vs errors need different handling
3. **JSON syntax is fragile** - Template files prevent user errors
4. **Duplicate detection is complex** - Multiple strategies needed (HTTP 409, text matching, upload success)
5. **Cleanup is essential** - Remove temporary \_modified.fit\ files automatically

### Process

1. **Test incrementally** - Start with small datasets (1 month) before large batches
2. **Manual testing first** - Verify Fit-File-Faker works before automation
3. **Log everything** - Detailed logs saved troubleshooting time repeatedly
4. **Document known issues** - Duplicate service uploads noted for users
5. **Commit often** - Small, focused commits made debugging easier

### User Experience

1. **Clear folder structure** - Users understand status at a glance
2. **Sensible defaults** - 7-day lookback, hourly sync work for most users
3. **Graceful degradation** - Errors don't stop entire pipeline
4. **Monitoring without intervention** - Check logs occasionally, otherwise hands-off

---

## Known Limitations

### Current (v1.1.0)

1. **Windows only** - PowerShell-based, no Mac/Linux support
2. **Duplicate activities on services** - TrainingPeaks, intervals.icu if connected to Garmin
3. **Requires original FIT files** - Manually entered activities in intervals.icu won't sync
4. **No selective sync** - All activities processed (no filtering by type)
5. **Single device emulation** - All activities appear from same device (Edge 1030)
6. **No GUI** - Command line and log files only
7. **Fit-File-Faker dependency** - Relies on third-party tool with occasional bugs

### By Design

1. **7-day lookback** - Won't catch activities older than a week (prevents reprocessing old data)
2. **Hourly sync** - Not real-time (acceptable for most use cases)
3. **Garmin dependency** - Requires Garmin Connect account

---

## Success Metrics

**Development:**
- ✅ 103+ activities successfully processed
- ✅ 100% success rate on final test (48 activities)
- ✅ Zero manual intervention required after automation setup
- ✅ Duplicate detection working correctly

**User Impact:**
- ✅ Full access to Garmin training metrics unavailable elsewhere
- ✅ Activities appear in Garmin Connect within 1 hour
- ✅ Clean data in all connected services (after workaround applied)
- ✅ Complete training history unified in Garmin ecosystem

**Code Quality:**
- ✅ Comprehensive error handling
- ✅ Detailed logging
- ✅ Configuration separated from code
- ✅ Secrets gitignored
- ✅ Professional documentation

---

## Future Considerations

### Python v2.0 (Planned)

**Core Problem to Solve:** Duplicate activities on connected services

**Approach:**
1. Check if activity exists in Garmin before upload (via garth library)
2. Direct API integration with TrainingPeaks, Strava (bypass Garmin auto-sync)
3. SQLite database to track upload status per service
4. Web dashboard for monitoring and control

**Benefits:**
- Cross-platform (Windows, Mac, Linux)
- Better service integration options
- More sophisticated duplicate prevention
- Modern web UI

**Estimated Effort:** 40-80 hours development

### Short-term Improvements (v1.x)

- Email notifications on errors
- Retry logic with exponential backoff
- Activity type filtering (cycling only, etc.)
- Cloud backup of processed files
- Health check endpoint

---

## Replication Guide

For someone wanting to build something similar:

### Phase 1: Research
1. Identify data source with API (intervals.icu in this case)
2. Find device spoofing tool (Fit-File-Faker)
3. Verify API provides original files
4. Test manual upload process

### Phase 2: Core Scripts
1. Download script (API → local files)
2. Process script (transform → upload)
3. Configuration file (externalize settings)
4. Logging infrastructure

### Phase 3: Error Handling
1. File organization (downloaded/processed/errors)
2. Duplicate detection
3. Retry logic
4. Detailed error messages

### Phase 4: Automation
1. Orchestration script (run full cycle)
2. Task scheduler integration
3. Monitoring setup
4. Documentation

### Phase 5: Documentation
1. Setup guide (prerequisites → configuration → testing)
2. Troubleshooting guide (common issues)
3. Architecture documentation
4. GitHub repository

**Estimated Timeline:**
- Research: 2-4 hours
- Core development: 8-16 hours
- Testing and refinement: 4-8 hours
- Documentation: 4-8 hours
- **Total: 18-36 hours** (varies by experience)

---

## Key Files Reference

### Scripts

**download-from-intervals.ps1**
- Lines of code: ~100
- Key function: \Download-IntervalsFits\
- Critical logic: Filter activities with \ile_type\ field

**process-and-upload.ps1**
- Lines of code: ~120
- Key function: \Process-FitFiles\
- Critical logic: Error detection without false positives

**monitor-and-sync.ps1**
- Lines of code: ~50
- Key function: \Run-SyncCycle\
- Critical logic: Sequential execution with logging

### Configuration

**config.ps1**
- PowerShell hashtable
- Not committed to git
- Created from config.template.ps1

**Fit-File-Faker config.json**
- JSON format
- Located in \%LOCALAPPDATA%\\FitFileFaker\
- Contains Garmin credentials (plain text)

### Documentation

**README.md** - Project overview, features, quick start
**SETUP.md** - Step-by-step installation (comprehensive)
**TROUBLESHOOTING.md** - Common issues and solutions
**CONTRIBUTING.md** - How to contribute
**ROADMAP.md** - Future development plans
**FIT-FILE-FAKER-SETUP.md** - Tool-specific configuration

---

## Contact and Contribution

**Repository:** https://github.com/yourusername/fit-file-sync-pipeline
**License:** MIT
**Status:** Production ready, actively maintained

**Questions or contributions:**
- Open an issue on GitHub
- Submit pull request
- Start a discussion

---

## Acknowledgments

**Key Technologies:**
- [Fit-File-Faker](https://github.com/jat255/Fit-File-Faker) by @jat255 - Essential tool enabling this entire project
- [intervals.icu](https://intervals.icu) by @david - Excellent training platform with reliable API
- PowerShell - Microsoft's automation framework
- Git/GitHub - Version control and collaboration

**Development Approach:**
- Incremental development
- Test-driven refinement
- Documentation-first mindset
- User-focused design

---

*Document Version: 1.0*
*Last Updated: February 19, 2026*
*Project Status: Production (v1.1.0)*
