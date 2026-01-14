# My Setup - FIT File Sync Pipeline

## Configuration

**Installation Date:** 2026-01-14
**Location:** C:\Users\chris\fit-file-sync-pipeline

## Automation

**Scheduled Task:** FIT File Sync Pipeline
- **Frequency:** Every hour
- **Looks back:** 7 days
- **Status:** ✅ Active

## Device Configuration

**Fit-File-Faker Device:** Garmin Edge 1030
- Serial: 3982691993
- Emulates: High-end cycling computer

## Activity Summary

**Total Activities Synced:** ~103
- September 2025: 24 activities
- October 2025: 24 activities  
- November 2025: 26 activities
- December 2025: 23 activities
- January 2026: 6 activities

## Monitoring

**View logs:**
```powershell
Get-Content C:\Users\chris\fit-file-sync-pipeline\logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log -Tail 30
```

**Check Task Scheduler:**
- Open: `taskschd.msc`
- Task: FIT File Sync Pipeline
- History tab shows all runs

## Maintenance

**Update Fit-File-Faker:**
```powershell
pipx upgrade fit-file-faker
```

**Pull latest pipeline updates:**
```powershell
cd C:\Users\chris\fit-file-sync-pipeline
git pull
```

## Notes

- Pipeline runs silently in background
- Activities sync within 1 hour of appearing in intervals.icu
- Duplicates are automatically detected and skipped
- All operations logged for troubleshooting
