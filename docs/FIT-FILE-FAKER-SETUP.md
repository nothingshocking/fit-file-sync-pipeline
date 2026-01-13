# Fit-File-Faker Configuration Guide

This document explains how Fit-File-Faker is configured for use with this pipeline.

## Installation Location

Fit-File-Faker is installed via pipx and stores its configuration at:
```
C:\Users\chris\AppData\Local\FitFileFaker\config.json
```

## Configuration File

Edit the configuration:
```powershell
notepad $env:LOCALAPPDATA\FitFileFaker\config.json
```

### Current Configuration
```json
{
  "garmin_username": "your_garmin_email@example.com",
  "garmin_password": "your_garmin_password",
  "fit_files_dir": "C:\\Users\\chris\\fit-file-sync-pipeline\\data\\downloaded",
  "device_info": {
    "manufacturer": "garmin",
    "product": "edge1030",
    "serial_number": "3982691993"
  }
}
```

### Configuration Details

**garmin_username** and **garmin_password**
- Your Garmin Connect login credentials
- Required for uploading activities

**fit_files_dir**
- Points to the pipeline's `data\downloaded` folder
- This is where files from intervals.icu are downloaded
- Use double backslashes (`\\`) in Windows paths

**device_info**
- **manufacturer:** Always set to `garmin`
- **product:** `edge1030` - High-end cycling computer
- **serial_number:** Unique 10-digit identifier

### Why Edge 1030?

The Edge 1030 is configured because:
- ✅ Primary activities are cycling (Coros Dura, Hammerhead Karoo 2)
- ✅ Garmin's flagship bike computer
- ✅ All cycling metrics calculate properly in Garmin Connect
- ✅ Activities appear naturally in your Garmin ecosystem

### Alternative Devices for Cycling

If you want to change the device:
- **edge1040** - Newest flagship (2024)
- **edge1030plus** - Updated version
- **edge840** - Mid-range with solar
- **edge530** - Performance-focused

## Testing Configuration

Test that Fit-File-Faker is configured correctly:
```powershell
# Verify installation
fit-file-faker --version

# Validate JSON syntax
Get-Content $env:LOCALAPPDATA\FitFileFaker\config.json | ConvertFrom-Json

# Test with a file (dry run - doesn't actually upload)
fit-file-faker path\to\test.fit --upload --dryrun
```

## Integration with Pipeline

The pipeline scripts automatically use Fit-File-Faker by calling:
```powershell
fit-file-faker <filepath> --upload
```

Fit-File-Faker reads its configuration from `config.json` automatically.

## Common JSON Syntax Errors

When editing `config.json`, watch for:
- ❌ Missing comma after each line (except the last in each section)
- ❌ Wrong setting name: use `fit_files_dir` not `fitfiles_dir`
- ❌ Single backslashes: use `C:\\Users\\` not `C:\Users\`
- ❌ Missing quotes around values
- ❌ Extra comma after last item in a section

**Correct format:**
```json
{
  "setting1": "value1",
  "setting2": "value2",
  "nested": {
    "item1": "value",
    "item2": "value"
  }
}
```

Note: No comma after `"value2"` or final `"value"` in nested section.

## Updating Configuration

If you need to change devices or credentials:
```powershell
# Edit configuration
notepad $env:LOCALAPPDATA\FitFileFaker\config.json

# Validate changes
Get-Content $env:LOCALAPPDATA\FitFileFaker\config.json | ConvertFrom-Json

# No restart needed - changes take effect immediately
```

## Troubleshooting

**JSON Syntax Errors:**
- Use a JSON validator: https://jsonlint.com
- Check for missing commas
- Verify all quotes are double quotes
- Ensure Windows paths use double backslashes

**Authentication errors:**
- Verify Garmin username/password are correct
- Try logging into connect.garmin.com manually
- Update password in both Garmin and config.json

**File not found errors:**
- Verify `fit_files_dir` path exists
- Check path uses double backslashes: `C:\\Users\\...`
- Ensure `data\downloaded` folder exists

**Device not recognized:**
- Verify `manufacturer` is `garmin`
- Check [Fit-File-Faker docs](https://github.com/jat255/Fit-File-Faker) for valid device names

## Security Notes

- ⚠️ The config.json contains your Garmin password in plain text
- Keep this file secure and private
- Never share or commit it to version control
- Consider using a strong, unique password for Garmin Connect
- After any public exposure, change your Garmin password immediately

## See Also

- [Fit-File-Faker Documentation](https://github.com/jat255/Fit-File-Faker)
- [Main Setup Guide](../SETUP.md)
- [Troubleshooting Guide](../TROUBLESHOOTING.md)
