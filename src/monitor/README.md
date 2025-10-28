# PowerShell Monitor Script

Place the `Monitor.ps1` PowerShell script here.

## Overview

The Monitor.ps1 script is responsible for:
- Collecting real-time system metrics (CPU, Memory, Disk, Network)
- Detecting Windows Update processes
- Writing data to `%TEMP%\WinUpdateMonState\live.json`
- Logging historical data to CSV files

## Expected Functionality

The script should:

1. **Run continuously** with 1-second intervals
2. **Collect metrics**:
   - CPU usage percentage
   - Memory usage percentage
   - Disk queue length
   - Network total (MB/s)
3. **Detect update phases**:
   - Identify Windows Update-related processes
   - Detect download/install/configure activities
4. **Write live data**:
   - Update `live.json` every second
   - Include timestamp, metrics, and detected phase
5. **VPN detection**:
   - Check for active VPN connections
   - Flag potential metric impacts
6. **Anomaly detection**:
   - Track metric deviations
   - Generate alerts for unusual behavior

## Usage

```powershell
# Run the monitor
.\Monitor.ps1

# Run with dashboard mode (optimized output)
.\Monitor.ps1 -Dashboard

# Run with verbose logging
.\Monitor.ps1 -Verbose
```

## Output Format

The script should write to `%TEMP%\WinUpdateMonState\live.json` with this structure:

```json
{
  "timestamp": "2025-10-28T12:30:45Z",
  "cpu": 45.2,
  "mem": 62.8,
  "diskQ": 3.5,
  "netTotal": 12.4,
  "phase": "Downloading",
  "anomalies": [
    {
      "Metric": "CPU",
      "Severity": "Medium",
      "Message": "CPU usage above threshold"
    }
  ],
  "vpn": {
    "Active": true,
    "Adapters": "VPN Adapter Name",
    "Warning": "VPN detected - network metrics may be affected"
  }
}
```

## Development

If you need to create this script:

1. Use PowerShell 7+ for best compatibility
2. Use `Get-Counter` for performance metrics
3. Use `Get-Process` for process detection
4. Use `Get-NetAdapter` for network information
5. Implement JSON export with `ConvertTo-Json`

## Testing

Test the script by:

1. Running it manually
2. Checking that `live.json` is created and updated
3. Verifying metrics are accurate
4. Testing with actual Windows Updates running

## Note

The Electron dashboard depends on this script being active and writing to the expected location. Without it, the dashboard will show placeholder/zero values.
