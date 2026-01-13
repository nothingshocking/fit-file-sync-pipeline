# config.template.ps1 - Copy this to config.ps1 and fill in your settings

$Config = @{
    # Intervals.icu API Key (get from https://intervals.icu/settings)
    IntervalsApiKey = "YOUR_API_KEY_HERE"
    
    # Project paths (update to match your installation)
    ProjectRoot = "C:\Users\YourUsername\fit-file-sync-pipeline"
    DownloadFolder = "C:\Users\YourUsername\fit-file-sync-pipeline\data\downloaded"
    ProcessedFolder = "C:\Users\YourUsername\fit-file-sync-pipeline\data\processed"
    ErrorFolder = "C:\Users\YourUsername\fit-file-sync-pipeline\data\errors"
    LogFolder = "C:\Users\YourUsername\fit-file-sync-pipeline\logs"
    
    # Sync Settings
    SyncIntervalMinutes = 60    # How often to check for new activities
    LookbackDays = 7            # How many days back to check on each sync
    
    # Processing Settings
    DryRun = $false             # Set to $true to test without uploading
    MaxRetries = 3              # Future: retry failed uploads
    DelayBetweenFiles = 100     # Milliseconds delay between API calls
}

Export-ModuleMember -Variable Config