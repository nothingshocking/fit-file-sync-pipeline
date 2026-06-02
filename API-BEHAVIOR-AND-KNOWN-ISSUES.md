# API Behavior and Known Issues

## intervals.icu API Quirks

### Midnight Truncation Bug (FIXED in v1.4.0)

**Issue:** The `newest` parameter in the activities list endpoint is interpreted as midnight at the START of the date, not the end. This caused same-day activities to be invisible to the API.

**Example:**
- Query: `oldest=2026-05-23&newest=2026-05-30`
- Interprets as: May 23, 00:00 to May 30, 00:00
- Result: Any activity recorded on May 30 is outside the window and not returned

**Fix:** Omit the `newest` parameter entirely from default queries. The API then defaults to "now" and returns all activities up to the current moment.

**Commit:** v1.4.0
**Status:** RESOLVED

---

### Lazy Indexing / Delayed Visibility (UNRESOLVED)

**Issue:** Activities can exist in intervals.icu with valid FIT files but not appear in API results for hours or days, then suddenly become visible.

**Observed Behavior:**
- May 29 Lunch MTB (i153484505) uploaded shortly after activity, but invisible to API for 4+ days
- May 30 Morning MTB (i153484534) uploaded May 31, but invisible for 1+ days
- Both activities became visible simultaneously after running a manual API query
- Subsequent scheduled runs immediately returned the activities

**Hypothesis:** intervals.icu may use lazy indexing or caching that gets triggered by direct queries to those specific activities. Running a query that includes the activity ID may cause the API to index it for future list endpoint queries.

**Workaround:** Increase `LookbackDays` in config.ps1 to catch late-arriving activities on subsequent cycles (though this increases API load).

**Status:** UNCONFIRMED - waiting for response from intervals.icu maintainer on forum

**Forum Post:** https://forum.intervals.icu/t/activities-not-returned-by-api-until-days-after-upload-despite-valid-file-type/130256

---

### File Type Filtering

**Issue:** Activities without a `file_type` field (or `file_type: null`) are filtered out by the pipeline, making them invisible even if they exist in intervals.icu.

**Cause:** Activities synced via some platforms don't preserve original FIT files, or files weren't retained.

**Check:** In intervals.icu, open the activity and look for "Download original file" option. If absent, the API won't return it for this pipeline.

**Status:** By design - pipeline only syncs original FIT files to maintain data integrity

---

## Known Issues

### Coros Dura Gear Assignment (v1.2.0+)

**Issue:** Coros Dura activities upload to Garmin Connect successfully and show all metrics, but Garmin doesn't recognize the device and shows no gear assignment.

**Cause:** Coros Dura FIT files contain non-standard `device_info` records that Fit-File-Faker cannot properly transform.

**Impact:** Minor - metrics are calculated correctly, gear is just missing from activity details.

**Status:** Bug reported to Fit-File-Faker maintainer. Waiting for upstream fix.

**GitHub Issue:** https://github.com/jat255/Fit-File-Faker/issues/XXX (pending)

**Workaround:** Manually assign gear in Garmin Connect activity details, or wait for Fit-File-Faker fix.

---

### UnicodeEncodeError in Fit-File-Faker (v1.3.0, FIXED in v1.4.0)

**Issue:** When Fit-File-Faker logs a duplicate detection warning (HTTP 409) containing an emoji (✅ check mark), Windows PowerShell's cp1252 encoding crashes the process with `UnicodeEncodeError`.

**Impact:** Duplicate files would not be properly logged as such, potentially causing confusion about upload status.

**Fix:** v1.3.0 added better pattern matching for duplicate detection that doesn't rely on Fit-File-Faker's log output parsing.

**Status:** RESOLVED

---

## Version History Quick Reference

| Version | Date | Key Changes | Status |
|---------|------|-------------|--------|
| v1.4.0 | June 2026 | Fixed midnight truncation; skip processed files at download stage | Current |
| v1.3.0 | May 2026 | Fixed false rate limit detection; better duplicate detection patterns | Stable |
| v1.2.0 | May 2026 | Fit-File-Faker v2.1.5 compatibility; rate limit handling | Stable |
| v1.1.1 | Feb 2026 | Minor fixes | Legacy |
| v1.1.0 | Feb 2026 | Added Task Scheduler automation | Legacy |
| v1.0.0 | Feb 2026 | Initial release | Legacy |

---

## Testing Checklist for Future Releases

Before creating a new release:

- [ ] All scripts run without `[ERROR]` entries (may have `[WARNING]` for skips)
- [ ] No activities are skipped unexpectedly (check logs for `[WARNING]` skip messages)
- [ ] At least one full cycle (download → process → upload) completes successfully
- [ ] Processed files are correctly moved to `processed/` folder
- [ ] No files remain in `downloaded/` after processing (unless rate-limited, which is expected)
- [ ] ROADMAP.md updated with changelog entry
- [ ] Git tagged with version number
- [ ] GitHub release created with description
- [ ] Project knowledge updated with any new issues discovered

---

## Debugging Tips

### When activities disappear from API results:

1. Run manual API query with explicit date range
2. Check if activities have `file_type` field
3. Verify `oldest` and `newest` parameters aren't causing midnight truncation
4. Wait 30 minutes and re-run (may be indexing delay)
5. Post on intervals.icu forum with specific activity IDs and dates

### When uploads fail silently:

1. Check if files made it to `processed/` folder
2. Look for `[WARNING] Already uploaded` entries in logs (expected behavior)
3. Verify Garmin credentials are still valid
4. Check Garmin Connect web UI for the activity (may have uploaded despite log message)
5. Review recent Fit-File-Faker output for errors

### When log messages are confusing:

- `[WARNING] Already exists` = File in `downloaded/` folder already (skip during download)
- `[WARNING] Already processed` = File in `processed/` folder already (skip during download)
- `[WARNING] Already uploaded (duplicate detected)` = Garmin returned HTTP 409 (skip during upload)
- All three are expected and normal - only `[ERROR]` messages need action

---

## For Future Developers

When adding new features or debugging:

1. **Always update this document** when discovering new API quirks or issues
2. **Add to version history table** when releasing
3. **Keep ROADMAP.md in sync** with actual current version
4. **Test date edge cases** - API behavior around midnight can be tricky
5. **Document workarounds** - this project has accumulated practical workarounds that are worth preserving

---

*Last Updated: June 2, 2026*
*Project Version: v1.4.0*
