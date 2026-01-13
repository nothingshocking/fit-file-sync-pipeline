# Download FIT files from intervals.icu
param(
    [string]$OldestDate,
    [string]$NewestDate,
    [switch]$Force
)

# Load configuration
. "$PSScriptRoot\config.ps1"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $Config.LogFolder "sync-$(Get-Date -Format 'yyyy-MM-dd').log"
    "$timestamp [$Level] $Message" | Out-File -FilePath $logFile -Append
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message }
    }
}

function Download-IntervalsFits {
    param([string]$Start, [string]$End)
    
    Write-Log "=== Starting Download from intervals.icu ===" "INFO"
    Write-Log "Date range: $Start to $End"
    
    # Ensure folders exist
    @($Config.DownloadFolder, $Config.LogFolder) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ | Out-Null
        }
    }
    
    # Setup authentication
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("API_KEY:$($Config.IntervalsApiKey)"))
    $headers = @{ Authorization = "Basic $base64Auth" }
    
    # Fetch activities
    $url = "https://intervals.icu/api/v1/athlete/0/activities?oldest=$Start&newest=$End"
    
    try {
        $activities = Invoke-RestMethod -Uri $url -Headers $headers
        Write-Log "Found $($activities.Count) activities"
        
        $activitiesWithFiles = $activities | Where-Object { $_.file_type -ne $null -and $_.file_type -ne "" }
        Write-Log "Activities with files: $($activitiesWithFiles.Count)"
        
        if ($activitiesWithFiles.Count -eq 0) {
            Write-Log "No activities with files found" "WARNING"
            return 0
        }
        
        # Download files
        $count = 0
        $success = 0
        
        foreach ($activity in $activitiesWithFiles) {
            $count++
            $activityId = $activity.id
            $date = $activity.start_date_local.Substring(0,10)
            $outputFile = "$($Config.DownloadFolder)\$date-$activityId.fit"
            
            # Skip if already exists
            if ((Test-Path $outputFile) -and -not $Force) {
                Write-Log "[$count/$($activitiesWithFiles.Count)] Skipping $activityId (already exists)" "WARNING"
                continue
            }
            
            Write-Log "[$count/$($activitiesWithFiles.Count)] Downloading $activityId - $date"
            
            try {
                $fileUrl = "https://intervals.icu/api/v1/activity/$activityId/file"
                Invoke-WebRequest -Uri $fileUrl -Headers $headers -OutFile $outputFile
                
                $fileSize = (Get-Item $outputFile).Length
                if ($fileSize -gt 0) {
                    Write-Log "  SUCCESS: $fileSize bytes" "SUCCESS"
                    $success++
                } else {
                    Write-Log "  File is empty" "ERROR"
                    Remove-Item $outputFile
                }
            } catch {
                Write-Log "  ERROR: $($_.Exception.Message)" "ERROR"
            }
            
            Start-Sleep -Milliseconds $Config.DelayBetweenFiles
        }
        
        Write-Log "Download complete: $success/$count files" "SUCCESS"
        return $success
        
    } catch {
        Write-Log "ERROR fetching activities: $($_.Exception.Message)" "ERROR"
        return 0
    }
}

# Main execution
if (-not $OldestDate) {
    $OldestDate = (Get-Date).AddDays(-$Config.LookbackDays).ToString("yyyy-MM-dd")
}
if (-not $NewestDate) {
    $NewestDate = (Get-Date).ToString("yyyy-MM-dd")
}

Download-IntervalsFits -Start $OldestDate -End $NewestDate