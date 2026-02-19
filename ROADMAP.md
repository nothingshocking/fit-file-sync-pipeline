# Roadmap

## Current Status: v1.1.0

The PowerShell-based pipeline is **production ready** and **fully functional** for Windows users.

---

## Future Enhancements

### Python Version (v2.0)

A Python-based rewrite to address current limitations and expand functionality:

**Key Benefits:**
- **Smart duplicate prevention** - Check if activity exists before uploading
- **Direct service integration** - Upload directly to TrainingPeaks, Strava, etc. (bypass Garmin auto-sync)
- **Activity tracking** - Database to track what's been uploaded where
- **Cross-platform** - Works on Windows, Mac, and Linux
- **Web dashboard** - Monitor sync status and control uploads via browser

**Why Python?**
- Better API libraries for service integrations
- Cross-platform compatibility
- Easier to build web interfaces
- More sophisticated duplicate detection

**Status:** Future consideration - contributions and design input welcome!

---

## Contributing

Interested in helping build the Python version? See [CONTRIBUTING.md](CONTRIBUTING.md) or open an issue to discuss.

**Particularly helpful:**
- Python developers
- Experience with Strava, TrainingPeaks, or other fitness service APIs
- Web developers for dashboard UI

---

## Questions or Suggestions?

Open an [issue](https://github.com/yourusername/fit-file-sync-pipeline/issues) to discuss!
