# Roadmap

## Current Status: v1.4.1

The PowerShell-based pipeline is **production ready** and **fully functional** for Windows users.

\---

## Changelog

### v1.4.1 (June 2026)

* Enhance: Added diagnostic logging of activity IDs returned from intervals.icu API to help troubleshoot lazy indexing issues
* Fix: Use \[string]::Join() for better PowerShell compatibility in diagnostic logging

### v1.4.0 (June 2026)

* **Fix:** Removed `newest` parameter from default API query so it defaults to "now" -- prevents midnight truncation that caused same-day activities to be missed
* **Fix:** Download script now checks the `processed/` folder before downloading -- prevents redundant re-downloads of already-uploaded activities and eliminates unnecessary Garmin duplicate calls on every hourly cycle
* **Fix:** Skip log messages changed from `\[WARNING]` to `\[INFO]` level -- keeps warnings meaningful and reduces log noise

### v1.3.0 (May 2026)

* **Fix:** Corrected false rate limit detection caused by `GarminConnectConnectionError`
appearing in duplicate activity (HTTP 409) tracebacks
* **Fix:** Added `API Error 409|Duplicate Activity` to duplicate detection pattern to catch
cases where Fit-File-Faker crashes with a `UnicodeEncodeError` while logging the duplicate
warning (emoji, cp1252 encoding incompatibility on Windows)
* **Fix:** Removed `Traceback` from exception detection -- it is not a reliable error signal
because it also appears in the harmless UnicodeEncodeError crash during duplicate logging
* **Fix:** Narrowed exception detection to `Login failed` only
* **Docs:** Updated DEVELOPMENT-NOTES.md with corrected detection patterns and explanation
* **Docs:** Added troubleshooting section for false rate limit false positives

### v1.2.0 (May 2026)

* **Fix:** Updated `process-and-upload.ps1` for Fit-File-Faker v2.1.5 output format compatibility
* **Fix:** Resolved conflicting Fit-File-Faker installations by using full executable path via `$Config.FitFileFakerPath`
* **Add:** Garmin rate limit detection -- files stay in `downloaded/` instead of moving to `errors/` when rate limited, and retry automatically on next cycle
* **Fix:** Tightened exception detection to prevent false positives from file paths containing the word "Error"
* **Fix:** Updated duplicate detection to match new Fit-File-Faker v2.1.5 output strings
* **Add:** `FitFileFakerPath` config entry for explicit executable path management
* **Docs:** Added troubleshooting sections for rate limiting, conflicting installations, Coros Dura gear issue, and false error detection
* **Known issue:** Coros Dura activities upload successfully but show no gear in Garmin Connect due to non-standard `device\_info` records -- bug reported to Fit-File-Faker maintainer

### v1.1.1 (February 2026)

* Minor fixes

### v1.1.0 (February 2026)

* Automated sync via Windows Task Scheduler
* Continuous monitoring mode
* Configurable sync interval

### v1.0.0 (February 2026)

* Initial release
* Download from intervals.icu API
* Process with Fit-File-Faker and upload to Garmin Connect
* Three-folder file organization (downloaded/processed/errors)
* Detailed logging

\---

## Future Enhancements

### Python Version (v2.0)

A Python-based rewrite to address current limitations and expand functionality:

**Key Benefits:**

* **Smart duplicate prevention** - Check if activity exists before uploading
* **Direct service integration** - Upload directly to TrainingPeaks, Strava, etc. (bypass Garmin auto-sync)
* **Activity tracking** - Database to track what's been uploaded where
* **Cross-platform** - Works on Windows, Mac, and Linux
* **Web dashboard** - Monitor sync status and control uploads via browser

**Why Python?**

* Better API libraries for service integrations
* Cross-platform compatibility
* Easier to build web interfaces
* More sophisticated duplicate detection

**Status:** Future consideration - contributions and design input welcome!

### Short-term (v1.x)

* \[ ] Email notifications on errors
* \[ ] Retry logic with exponential backoff
* \[ ] Activity type filtering (cycling only, etc.)
* \[ ] Resolve Coros Dura gear assignment once Fit-File-Faker fix is released

\---

## Contributing

Interested in helping build the Python version? See [CONTRIBUTING.md](CONTRIBUTING.md) or open an issue to discuss.

**Particularly helpful:**

* Python developers
* Experience with Strava, TrainingPeaks, or other fitness service APIs
* Web developers for dashboard UI

\---

## Questions or Suggestions?

Open an [issue](https://github.com/nothingshocking/fit-file-sync-pipeline/issues) to discuss!

