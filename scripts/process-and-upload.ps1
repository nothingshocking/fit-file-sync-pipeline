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
    
    # Get files to process (exclude _modified.fit files)
    $fitFiles = Get-ChildItem "$($Config.DownloadFolder)\*.fit" | Where-Object { $_.Name -notmatch "_modified\.fit$" }
    
    if ($fitFiles.Count -eq 0) {
        Write-Log "No files to process" "WARNING"
        return
    }
    
    Write-Log "Found $($fitFiles.Count) files to process"
    
    $count = 0
    $success = 0
    $errors = 0
    $duplicates = 0
    
    foreach ($file in $fitFiles) {
        $count++
        Write-Log "[$count/$($fitFiles.Count)] Processing: $($file.Name)"
        
        try {
            # Run fit-file-faker
            if ($DryRun -or $Config.DryRun) {
                # Don't use --dryrun with --upload due to bug
                Write-Log "  Skipping (DryRun mode enabled)" "WARNING"
                continue
            } else {
                $result = fit-file-faker $file.FullName --upload 2>&1
            }
            
            # Convert result to string for analysis
            $resultText = $result | Out-String
            
            # Check if it's a duplicate
            $isDuplicate = $resultText -match "activity already exists|HTTP conflict"
            
            # Check for real errors (excluding duplicate warnings)
            $hasError = $false
            if ($resultText -match "Exception|Traceback" -and -not $isDuplicate) {
                $hasError = $true
                Write-Log "  Error detected in output" "ERROR"
            }
            
            if ($hasError) {
                throw "Fit-File-Faker encountered an error"
            }
            
            # Handle duplicates as success
            if ($isDuplicate) {
                Write-Log "  Already uploaded (duplicate detected)" "WARNING"
                $duplicates++
            }
            
            # Success - move to processed
            $newName = "$($file.BaseName).uploaded$($file.Extension)"
            $destination = Join-Path $Config.ProcessedFolder $newName
            Move-Item $file.FullName $destination -Force
            
            # Also move the _modified.fit file if it exists
            $modifiedFile = "$($file.DirectoryName)\$($file.BaseName)_modified$($file.Extension)"
            if (Test-Path $modifiedFile) {
                Remove-Item $modifiedFile -Force
            }
            
            if (-not $isDuplicate) {
                Write-Log "  SUCCESS: Uploaded and moved to processed\" "SUCCESS"
                $success++
            } else {
                Write-Log "  Moved to processed\ (was duplicate)" "SUCCESS"
            }
            
        } catch {
            # Error - move to errors
            Write-Log "  ERROR: $($_.Exception.Message)" "ERROR"
            $destination = Join-Path $Config.ErrorFolder $file.Name
            Move-Item $file.FullName $destination -Force
            Write-Log "  Moved to errors\" "WARNING"
            $errors++
        }
    }
    
    Write-Log "Processing complete: $success uploaded, $duplicates duplicates, $errors errors" "SUCCESS"
}

Process-FitFiles