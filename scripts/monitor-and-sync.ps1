# Main sync automation script
param(
    [switch]$RunOnce,
    [switch]$DryRun
)

# Load configuration
. "$PSScriptRoot\config.ps1"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $Config.LogFolder "sync-$(Get-Date -Format 'yyyy-MM-dd').log"
    "$timestamp [$Level] $Message" | Out-File -FilePath $logFile -Append
    Write-Host "$timestamp [$Level] $Message"
}

function Run-SyncCycle {
    Write-Log "=== Starting Sync Cycle ===" "INFO"
    
    # Step 1: Download new files
    Write-Log "Step 1: Downloading from intervals.icu"
    & "$PSScriptRoot\download-from-intervals.ps1"
    
    # Step 2: Process and upload
    Write-Log "Step 2: Processing and uploading to Garmin"
    if ($DryRun) {
        & "$PSScriptRoot\process-and-upload.ps1" -DryRun
    } else {
        & "$PSScriptRoot\process-and-upload.ps1"
    }
    
    Write-Log "=== Sync Cycle Complete ===" "SUCCESS"
}

# Main loop
Write-Log "FIT Sync Pipeline started" "SUCCESS"
Write-Log "Sync interval: $($Config.SyncIntervalMinutes) minutes"

do {
    Run-SyncCycle
    
    if (-not $RunOnce) {
        $waitSeconds = $Config.SyncIntervalMinutes * 60
        Write-Log "Waiting $($Config.SyncIntervalMinutes) minutes until next sync..."
        Start-Sleep -Seconds $waitSeconds
    }
    
} while (-not $RunOnce)

Write-Log "FIT Sync Pipeline stopped" "INFO"