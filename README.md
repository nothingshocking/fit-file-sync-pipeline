# FIT File Sync Pipeline

Automated pipeline that syncs workout data from intervals.icu to Garmin Connect by leveraging [Fit-File-Faker](https://github.com/jat255/Fit-File-Faker) to transform FIT files from non-Garmin devices into Garmin-compatible format.

## Why This Tool?

**The Problem:** Many athletes use non-Garmin devices (Coros, Hammerhead, Wahoo, etc.) but want to access Garmin's ecosystem:
- Training Status and Training Readiness
- Body Battery and HRV Status
- Performance metrics (VO2 max, Training Load, etc.)
- Garmin Coach training plans
- Complete activity history in one place

**The Solution:** This pipeline automatically:
1. Downloads your workout FIT files from intervals.icu
2. Processes them with Fit-File-Faker to appear as Garmin-created files
3. Uploads them to Garmin Connect
4. Runs on a schedule to keep everything in sync

## How It Works
```
intervals.icu → Download → Fit-File-Faker → Garmin Connect
                  ↓           (Transform)         ↓
              downloaded/                    All Garmin
                  ↓                          Metrics Available
              processed/ ✓
                  ↓
              errors/ ✗
```

**Key Component:** [Fit-File-Faker](https://github.com/jat255/Fit-File-Faker) does the heavy lifting by modifying FIT file device information so Garmin Connect accepts files from non-Garmin devices. This pipeline automates the entire workflow.

## Features

- 📥 **Automated Downloads** - Pulls original FIT files from intervals.icu API
- 🔧 **Device Transformation** - Uses Fit-File-Faker to make files Garmin-compatible
- 📤 **Automatic Upload** - Sends processed files to Garmin Connect
- 🔄 **Scheduled Sync** - Runs on a schedule to keep data current
- 📝 **Detailed Logging** - Tracks all operations with timestamps
- ❌ **Error Handling** - Quarantines problematic files for manual review
- 🔒 **Secure** - API keys stored locally, never committed to git

## Use Cases

**Perfect for athletes who:**
- Use Coros, Hammerhead, Wahoo, or other non-Garmin devices
- Sync activities to intervals.icu for analysis
- Want to access Garmin's training metrics and ecosystem
- Need complete activity history in Garmin Connect
- Want automated synchronization without manual uploads

**Example Workflow:**
1. Complete workout with Coros watch
2. Activity auto-syncs to intervals.icu
3. This pipeline downloads and processes it (runs every hour)
4. Activity appears in Garmin Connect with all metrics
5. Garmin's Training Status, Body Battery, etc. stay up-to-date

## Prerequisites

- **Windows 11** (or Windows 10)
- **PowerShell 5.1** or later
- **[Fit-File-Faker](https://github.com/jat255/Fit-File-Faker)** - Install via pipx: `pipx install fit-file-faker`
  - See [Fit-File-Faker Setup Guide](docs/FIT-FILE-FAKER-SETUP.md) for detailed configuration
- **intervals.icu account** with API key ([get here](https://intervals.icu/settings))
- **Garmin Connect account** configured in Fit-File-Faker

## Quick Start

See [SETUP.md](SETUP.md) for detailed installation instructions.
```powershell
# 1. Clone the repository
git clone https://github.com/yourusername/fit-file-sync-pipeline.git
cd fit-file-sync-pipeline

# 2. Create your configuration
Copy-Item scripts\config.template.ps1 scripts\config.ps1

# 3. Edit config.ps1 with your settings
notepad scripts\config.ps1

# 4. Run initial test sync
.\scripts\monitor-and-sync.ps1 -RunOnce -DryRun

# 5. Run actual sync
.\scripts\monitor-and-sync.ps1 -RunOnce
```

## Usage

### Manual Operations
```powershell
# Download files for a specific date range
.\scripts\download-from-intervals.ps1 -OldestDate "2025-11-01" -NewestDate "2025-11-30"

# Process and upload downloaded files
.\scripts\process-and-upload.ps1

# Run complete sync cycle once
.\scripts\monitor-and-sync.ps1 -RunOnce

# Test mode (downloads and processes but doesn't upload)
.\scripts\monitor-and-sync.ps1 -RunOnce -DryRun
```

### Automated Monitoring
```powershell
# Run continuous monitoring (checks every hour by default)
.\scripts\monitor-and-sync.ps1
```

**Recommended:** Set up Windows Task Scheduler to run automatically (see [SETUP.md](SETUP.md#automation)).

## Configuration

Edit `scripts\config.ps1` to customize:
```powershell
$Config = @{
    IntervalsApiKey = "your_api_key"      # From intervals.icu/settings
    SyncIntervalMinutes = 60               # How often to check for new files
    LookbackDays = 7                       # How far back to check each sync
    DryRun = $false                        # Set true for testing
}
```

## Folder Structure
```
fit-file-sync-pipeline/
├── scripts/
│   ├── download-from-intervals.ps1    # Downloads from intervals.icu
│   ├── process-and-upload.ps1         # Processes with Fit-File-Faker
│   ├── monitor-and-sync.ps1           # Main automation script
│   └── config.ps1                     # Your configuration (not in git)
├── data/
│   ├── downloaded/                    # Raw FIT files from intervals.icu
│   ├── processed/                     # Successfully uploaded files
│   └── errors/                        # Files that failed processing
├── logs/
│   └── sync-YYYY-MM-DD.log           # Daily activity logs
└── docs/
    ├── SETUP.md                       # Installation guide
    └── TROUBLESHOOTING.md            # Common issues
```

## How Fit-File-Faker Works

[Fit-File-Faker](https://github.com/jat255/Fit-File-Faker) modifies FIT files to change device identification fields, making them appear as if they came from a Garmin device. This allows:

- **Non-Garmin activities** to be uploaded to Garmin Connect
- **Full metric calculation** (VO2 max, Training Status, etc.)
- **Historical data import** from other platforms
- **Device consolidation** in one training ecosystem

**Important:** Fit-File-Faker must be configured with your Garmin Connect credentials before this pipeline will work. See their [documentation](https://github.com/jat255/Fit-File-Faker#readme) for setup.

## Supported Devices

Any device that produces FIT files and syncs to intervals.icu:
- ✅ Coros (Pace, Apex, Vertix, etc.)
- ✅ Hammerhead (Karoo)
- ✅ Wahoo (ELEMNT, RIVAL)
- ✅ Polar (Vantage, Grit, Pacer)
- ✅ Suunto
- ✅ Any other FIT-compatible device

## Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for solutions to common issues:
- Authentication errors
- Malformed FIT files
- Upload failures
- Scheduling problems

## Limitations

- **Windows only** - Currently PowerShell-based (Linux/Mac version planned)
- **intervals.icu required** - Must have activities in intervals.icu
- **Garmin Connect account** - Required for uploads
- **Original FIT files** - Only activities with original files can be processed

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Roadmap

- [ ] Linux/Mac support (bash scripts)
- [ ] Direct integration with other platforms (Strava, TrainingPeaks)
- [ ] Retry logic for failed uploads
- [ ] Web dashboard for monitoring
- [ ] Docker container option

## Related Projects

- **[Fit-File-Faker](https://github.com/jat255/Fit-File-Faker)** - The core tool that makes this possible
- **[intervals.icu](https://intervals.icu)** - Excellent training analysis platform
- **[GarminDB](https://github.com/tcgoetz/GarminDB)** - Alternative for Garmin data analysis

## License

MIT License - see [LICENSE](LICENSE)

## Acknowledgments

- **[Fit-File-Faker](https://github.com/jat255/Fit-File-Faker)** by [@jat255](https://github.com/jat255) - The essential tool that enables device-agnostic uploads to Garmin Connect
- **[intervals.icu](https://intervals.icu)** by [@david](https://intervals.icu) - Excellent API and training platform
- The endurance sports open-source community

## Disclaimer

This tool is for personal use. Ensure you comply with the terms of service for intervals.icu and Garmin Connect. This project is not affiliated with Garmin, intervals.icu, or Fit-File-Faker.

---

**Questions?** Open an [issue](https://github.com/yourusername/fit-file-sync-pipeline/issues) or check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)