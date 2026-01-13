# Process and upload FIT files to Garmin Connect
param(
    [switch]$DryRun
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

function Process-FitFiles {
    Write-Log "=== Starting FIT File Processing ===" "INFO"
    
    # Ensure folders exist
    @($Config.ProcessedFolder, $Config.ErrorFolder) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ | Out-Null
        }
    }
    
    # Get files to process
    $fitFiles = Get-ChildItem "$($Config.DownloadFolder)\*.fit"
    
    if ($fitFiles.Count -eq 0) {
        Write-Log "No files to process" "WARNING"
        return
    }
    
    Write-Log "Found $($fitFiles.Count) files to process"
    
    $count = 0
    $success = 0
    $errors = 0
    
    foreach ($file in $fitFiles) {
        $count++
        Write-Log "[$count/$($fitFiles.Count)] Processing: $($file.Name)"
        
        try {
            # Run fit-file-faker
            if ($DryRun -or $Config.DryRun) {
                $result = fit-file-faker $file.FullName --upload --dryrun 2>&1
            } else {
                $result = fit-file-faker $file.FullName --upload 2>&1
            }
            
            # Check for errors
            $hasError = $false
            foreach ($line in $result) {
                if ($line -match "ERROR|Exception|Traceback") {
                    $hasError = $true
                    Write-Log "  Error detected in output" "ERROR"
                    break
                }
            }
            
            if ($hasError) {
                throw "Fit-File-Faker encountered an error"
            }
            
            # Success - move to processed
            $newName = "$($file.BaseName).uploaded$($file.Extension)"
            $destination = Join-Path $Config.ProcessedFolder $newName
            Move-Item $file.FullName $destination -Force
            Write-Log "  SUCCESS: Moved to processed\" "SUCCESS"
            $success++
            
        } catch {
            # Error - move to errors
            Write-Log "  ERROR: $($_.Exception.Message)" "ERROR"
            $destination = Join-Path $Config.ErrorFolder $file.Name
            Move-Item $file.FullName $destination -Force
            Write-Log "  Moved to errors\" "WARNING"
            $errors++
        }
    }
    
    Write-Log "Processing complete: $success success, $errors errors" "SUCCESS"
}

Process-FitFiles