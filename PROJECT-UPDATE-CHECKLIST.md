# Project Update Checklist - fit-file-sync-pipeline

## When Making ANY Code Changes

Use this checklist to ensure consistency across GitHub, local repo, Claude Project knowledge, and memory.

---

## 1. After Fixing a Bug or Adding a Feature

### Code Changes
- [ ] Edit the relevant script file(s) locally
- [ ] Test changes thoroughly (run at least one full sync cycle)
- [ ] Verify no `[ERROR]` entries in logs (expected `[WARNING]` entries are OK)

### Git & GitHub
- [ ] `git add <changed files>`
- [ ] `git commit -m "Fix/Add: <description>"` (use proper prefix: Fix, Add, Update, Refactor, Docs)
- [ ] `git push origin main`

### Documentation Updates (REQUIRED)
- [ ] Update `ROADMAP.md` with new entry under appropriate version section
- [ ] Update `API-BEHAVIOR-AND-KNOWN-ISSUES.md` if any new API quirks discovered
- [ ] Update this checklist if process changes

### Claude Project Knowledge (REQUIRED)
- [ ] Copy updated script files to Claude Project `/mnt/project/` directory
- [ ] Update memory note with new version number and key changes
- [ ] Add any new known issues to `API-BEHAVIOR-AND-KNOWN-ISSUES.md` in project knowledge

---

## 2. Before Creating a Release

### Testing Checklist
- [ ] Run full sync cycle with `.\scripts\monitor-and-sync.ps1 -RunOnce`
- [ ] Check logs for any unexpected errors: `Get-Content .\logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log`
- [ ] Verify files moved from `downloaded/` → `processed/` or `errors/` as expected
- [ ] Test with `-Force` flag if making download/processing changes: `.\scripts\download-from-intervals.ps1 -Force`

### Version & Changelog
- [ ] Determine new version number (major.minor.patch)
  - Major: Breaking changes or major features
  - Minor: New features or significant fixes
  - Patch: Bug fixes or documentation
- [ ] Verify `ROADMAP.md` has complete changelog entry for new version
- [ ] Verify version in memory note reflects new version

### Local Repository
- [ ] Ensure all changes are committed: `git status` (should show nothing)
- [ ] Create annotated tag: `git tag -a v1.X.X -m "Description of release"`
- [ ] Push tags: `git push origin v1.X.X`

### GitHub Release
- [ ] Go to https://github.com/nothingshocking/fit-file-sync-pipeline/releases/new
- [ ] Select tag from dropdown
- [ ] Fill in title: `v1.X.X - [Brief description]`
- [ ] Paste changelog excerpt from `ROADMAP.md` into description
- [ ] Include comparison link: `https://github.com/nothingshocking/fit-file-sync-pipeline/compare/vX.X.X...v1.X.X`
- [ ] Ensure "Set as latest release" is checked
- [ ] Click "Publish release"

---

## 3. When Discovering a New API Quirk or Limitation

### Document It
- [ ] Add entry to `API-BEHAVIOR-AND-KNOWN-ISSUES.md` in project knowledge
- [ ] Include: issue description, root cause (if known), impact, status, and workaround (if applicable)
- [ ] Add to version history table if it affects current or future versions
- [ ] Include forum post link or GitHub issue if relevant

### Communicate It
- [ ] Post on intervals.icu forum if it's an API issue (include specific activity IDs and dates)
- [ ] Create GitHub issue if it's a project bug
- [ ] Update Claude Project memory note if it affects future troubleshooting

### Update Memory
- [ ] Update memory note with any new known issues or limitations
- [ ] Include forum post or issue link for reference

---

## 4. When Updating Project Knowledge (Claude Project)

### Files to Keep Current
These are the CRITICAL files to update in `/mnt/project/`:
- [ ] `download-from-intervals.ps1` (latest version from GitHub)
- [ ] `process-and-upload.ps1` (latest version from GitHub)
- [ ] `ROADMAP.md` (must match GitHub version exactly)
- [ ] `API-BEHAVIOR-AND-KNOWN-ISSUES.md` (master reference for quirks and issues)

### Nice-to-Have (Update if Changed)
- [ ] `ARCHITECTURE.md` (rarely changes)
- [ ] `DEVELOPMENT-NOTES.md` (reference only)
- [ ] `PROJECT-HISTORY.md` (historical record)

### Memory Note Updates
- [ ] Current version number and release date
- [ ] Key fixes in current version (3-5 bullet points max)
- [ ] Any critical known issues affecting current version
- [ ] Link to API-BEHAVIOR-AND-KNOWN-ISSUES.md for full details

**Memory note template:**
```
fit-file-sync-pipeline is currently at v1.X.X (Month 2026). Key fixes in v1.X.X: <bullet 1>; <bullet 2>; <bullet 3>. See API-BEHAVIOR-AND-KNOWN-ISSUES.md for known issues and troubleshooting.
```

---

## 5. When Troubleshooting an Issue

### Investigation
- [ ] Check logs: `Get-Content .\logs\sync-$(Get-Date -Format 'yyyy-MM-dd').log -Tail 50`
- [ ] Search `API-BEHAVIOR-AND-KNOWN-ISSUES.md` for similar issues
- [ ] Check `ROADMAP.md` changelog to see if fixed in later version
- [ ] Verify current version: `git tag -l | Sort-Object -Version | Select-Object -Last 1`

### If Issue is New
- [ ] Document in `API-BEHAVIOR-AND-KNOWN-ISSUES.md` immediately (mark as UNRESOLVED)
- [ ] Include reproduction steps, observed behavior, and hypothesized cause
- [ ] Add to Claude Project memory note

### If Issue is Fixed
- [ ] Reference which version fixed it
- [ ] Update issue status in `API-BEHAVIOR-AND-KNOWN-ISSUES.md` to RESOLVED
- [ ] Add fix details to `ROADMAP.md` if not already there

---

## 6. Monthly/Quarterly Maintenance

### Review and Refresh
- [ ] Read through `API-BEHAVIOR-AND-KNOWN-ISSUES.md` for any stale entries
- [ ] Check GitHub issues for any unresolved bugs
- [ ] Review forum posts for API announcements
- [ ] Update "Last Updated" date at bottom of each document

### Clean Up
- [ ] Archive old log files (>30 days)
- [ ] Check for any orphaned files in `errors/` folder
- [ ] Verify no sensitive data in git history

### Future Planning
- [ ] Review `ROADMAP.md` for feasibility of planned features
- [ ] Assess if new version should be released (if significant changes made)
- [ ] Plan next release if enough changes accumulated

---

## 7. Quick Reference: What Goes Where

### GitHub Repository
- Current scripts and code
- ROADMAP.md (master changelog)
- All documentation
- Git history and tags

### Claude Project Knowledge (`/mnt/project/`)
- Latest versions of main scripts
- ROADMAP.md (must match GitHub)
- API-BEHAVIOR-AND-KNOWN-ISSUES.md (master reference)
- ARCHITECTURE.md (technical reference)
- PROJECT-HISTORY.md (background)

### Memory Note
- Current version number
- 3-5 key fixes in current version
- Reference to API-BEHAVIOR-AND-KNOWN-ISSUES.md
- Must be updated after each release

---

## 8. Checklist Checklist (Meta)

If you modify THIS checklist:
- [ ] Update BEFORE making changes (so you follow new process)
- [ ] Push to GitHub: `git add PROJECT-UPDATE-CHECKLIST.md && git commit -m "Docs: Update project checklist" && git push`
- [ ] Copy to Claude Project knowledge
- [ ] Update memory note if process changes significantly

---

## Common Mistakes to Avoid

❌ **Updating script but forgetting ROADMAP.md** → Future you won't remember what changed
❌ **Fixing issue but not documenting it in API-BEHAVIOR-AND-KNOWN-ISSUES.md** → Same issue gets debugged twice
❌ **Releasing to GitHub but forgetting to update Claude Project files** → Project knowledge becomes stale
❌ **Creating GitHub release without ROADMAP.md entry** → Release notes are incomplete or duplicated
❌ **Finding API quirk but not documenting it** → Next troubleshooting session starts from scratch
❌ **Updating memory note with old version number** → Claude thinks project is outdated

---

## How to Use This Document

1. **Before you start:** Check if there's a relevant section above
2. **While you work:** Follow the checkboxes for your task type
3. **Before you finish:** Review the "What Goes Where" section to catch anything missed
4. **If you discover something new:** Add it to this checklist so future work follows the same pattern

---

*Version: 1.0*
*Created: June 2, 2026*
*Applies to: v1.4.0 and later*
