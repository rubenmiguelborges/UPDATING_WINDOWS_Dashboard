# Windows Update Monitor - Usage Guide

## Quick Start

### 1. Prerequisites Check

Before running the application, ensure you have:

```powershell
# Check Node.js (required: 20+ LTS)
node --version

# Check npm
npm --version

# Check PowerShell version (required: 5.1+, recommended: 7+)
$PSVersionTable.PSVersion
```

### 2. Installation

```powershell
# Clone the repository
git clone https://github.com/rubenmiguelborges/UPDATING_WINDOWS_Dashboard.git
cd UPDATING_WINDOWS_Dashboard

# Install dependencies
npm install
```

### 3. Running the Application

#### Option A: Full Stack (Recommended)

**Terminal 1: Start the PowerShell Monitor**

```powershell
# Run the monitor in dashboard mode
.\src\monitor\Monitor.ps1 -Dashboard

# Or with verbose output
.\src\monitor\Monitor.ps1 -Dashboard -Verbose

# Or with custom interval (2 seconds)
.\src\monitor\Monitor.ps1 -Dashboard -Interval 2
```

**Terminal 2: Start the Electron Dashboard**

```powershell
# Development mode (with DevTools)
npm run dev

# Or production mode
npm start
```

#### Option B: Monitor Only (Testing)

```powershell
# Run monitor without dashboard mode to see console output
.\src\monitor\Monitor.ps1 -Interval 1 -Verbose
```

---

## Understanding the Monitor

### What It Does

The PowerShell monitor (`Monitor.ps1`) collects:

1. **System Metrics**
   - CPU usage (%)
   - Memory usage (%)
   - Disk queue length
   - Network throughput (MB/s)

2. **Windows Update Detection**
   - Active Windows Update processes
   - Update phase estimation
   - Process count

3. **Anomaly Detection**
   - High CPU/Memory/Disk usage
   - Unusual network activity
   - Severity levels (Low/Medium/High)

4. **VPN Awareness**
   - Detects active VPN connections
   - Warns about potential metric impacts

### Output Files

The monitor writes to two locations:

**Live Data (for Dashboard)**
```
%TEMP%\WinUpdateMonState\live.json
```
Updated every 1 second (or your specified interval)

**Historical Logs (for Analysis)**
```
C:\00_TOOLS\00_Logs\WinUpdateMonitor\metrics_YYYY-MM-DD.csv
```
Appended once per minute

---

## Using the Dashboard

### Dashboard Features

#### Real-Time Metrics
- **CPU Usage**: Current processor utilization
- **Memory Usage**: RAM usage percentage
- **Disk Queue**: I/O operations waiting
- **Network Total**: Combined upload/download in MB/s

#### Live Charts
- 60-second rolling history
- Auto-updating every 1-2 seconds
- Color-coded progress bars

#### Phase Detection
- **Idle**: No Windows Update activity
- **Downloading**: Network-heavy, low CPU
- **Installing**: High CPU and disk activity
- **Configuring**: Disk-heavy, moderate CPU
- **Processing**: CPU-heavy background work

#### Anomaly Alerts
Displays warnings when:
- CPU > 75% (Medium) or 90% (High)
- Memory > 85% (Medium) or 95% (High)
- Disk Queue > 5 (Medium) or 10 (High)
- Network > 100 MB/s (Medium)

#### VPN Warning
Shows banner when VPN is detected, indicating that network metrics may not represent actual Windows Update traffic.

### Dashboard Controls

**Development Mode** (`npm run dev`):
- DevTools available: `Ctrl+Shift+I`
- Auto-reload on code changes
- Console logging enabled

**System Tray**:
- Minimize to tray instead of closing
- Right-click tray icon for menu
- Click tray icon to toggle visibility

---

## Advanced Usage

### Custom Monitoring Intervals

```powershell
# Monitor every 2 seconds (lighter load)
.\src\monitor\Monitor.ps1 -Dashboard -Interval 2

# Monitor every 0.5 seconds (heavier load, more responsive)
.\src\monitor\Monitor.ps1 -Dashboard -Interval 0.5
```

**Recommendation**: Use 1 second for balanced performance.

### Custom Output Paths

```powershell
# Custom output directory
.\src\monitor\Monitor.ps1 -Dashboard -OutputPath "D:\MonitorData"

# Custom log directory
.\src\monitor\Monitor.ps1 -Dashboard -LogPath "D:\Logs\WinUpdate"
```

### Running as Background Task

**Option 1: PowerShell Background Job**

```powershell
# Start monitor as background job
Start-Job -ScriptBlock {
    Set-Location "C:\path\to\UPDATING_WINDOWS_Dashboard"
    .\src\monitor\Monitor.ps1 -Dashboard
}

# Check job status
Get-Job

# Stop job
Get-Job | Stop-Job
Get-Job | Remove-Job
```

**Option 2: Windows Task Scheduler**

Create a scheduled task to run the monitor at system startup:

```powershell
# Create task
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-File C:\path\to\UPDATING_WINDOWS_Dashboard\src\monitor\Monitor.ps1 -Dashboard"

$trigger = New-ScheduledTaskTrigger -AtStartup

Register-ScheduledTask -TaskName "WindowsUpdateMonitor" `
    -Action $action -Trigger $trigger -RunLevel Highest
```

---

## Monitoring Windows Updates

### Best Practices

1. **Start Monitor Before Updates**
   ```powershell
   # Start monitoring
   .\src\monitor\Monitor.ps1 -Dashboard -Verbose
   ```

2. **Trigger Windows Update**
   ```powershell
   # Check for updates
   Start-Process ms-settings:windowsupdate

   # Or use UsoClient (requires admin)
   UsoClient StartInteractiveScan
   ```

3. **Launch Dashboard**
   ```powershell
   npm run dev
   ```

4. **Watch the Phases**
   - Downloading: High network, low CPU
   - Installing: High CPU, high disk
   - Configuring: Moderate CPU, very high disk
   - Processing: High CPU, low network

### What to Look For

**Normal Update Behavior**:
- Downloading: 5-50 MB/s network, CPU < 30%
- Installing: CPU 40-80%, Disk Queue 3-10
- Configuring: CPU 30-60%, Disk Queue 5-15

**Anomalies to Investigate**:
- CPU > 90% for extended periods
- Disk Queue > 20 (potential disk issues)
- Network > 100 MB/s (possible non-update traffic)
- Phase stuck in "Downloading" with no network activity

---

## Troubleshooting

### Monitor Issues

**Problem: "Access Denied" errors**

```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → Run as Administrator
```

**Problem: Performance counters not available**

```powershell
# Rebuild performance counters
lodctr /R

# Restart Performance Logs and Alerts service
Restart-Service pla
```

**Problem: live.json not updating**

```powershell
# Check if monitor is running
Get-Process pwsh

# Verify file exists and is recent
Get-Item $env:TEMP\WinUpdateMonState\live.json |
    Select-Object FullName, LastWriteTime

# Check file contents
Get-Content $env:TEMP\WinUpdateMonState\live.json | ConvertFrom-Json
```

### Dashboard Issues

**Problem: Dashboard shows "No data" or zeros**

1. Verify monitor is running in dashboard mode
2. Check live.json exists: `$env:TEMP\WinUpdateMonState\live.json`
3. Verify JSON is valid
4. Restart dashboard

**Problem: Charts not updating**

1. Open DevTools (`Ctrl+Shift+I` in dev mode)
2. Check Console for errors
3. Verify file watcher is active
4. Check if live.json timestamp is updating

**Problem: System tray icon missing**

1. Verify icon exists: `assets\icons\icon.png`
2. Restart the dashboard
3. Check console for tray creation errors

**Problem: High CPU usage by dashboard**

1. Increase monitor interval: `-Interval 2`
2. Reduce chart history in `src/renderer/js/charts.js`:
   ```javascript
   this.maxDataPoints = 30; // Instead of 60
   ```
3. Close DevTools if open

---

## Performance Tips

### For the Monitor

- **Lower CPU Impact**: Increase interval to 2-5 seconds
- **More Responsive**: Decrease interval to 0.5 seconds (higher CPU)
- **Reduce Logging**: Comment out `Write-HistoricalLog` calls
- **Disable VPN Check**: Comment out `Test-VPNConnection`

### For the Dashboard

- **Lower Memory**: Reduce `maxDataPoints` in charts.js
- **Faster Rendering**: Disable animations (already done)
- **Lower CPU**: Increase poll interval in dataLoader.js

---

## Data Analysis

### Reading Historical Logs

```powershell
# Import today's CSV log
$log = Import-Csv "C:\00_TOOLS\00_Logs\WinUpdateMonitor\metrics_$(Get-Date -Format 'yyyy-MM-dd').csv"

# Calculate average CPU during updates
$log | Measure-Object -Property CPU -Average

# Find peak disk queue
$log | Sort-Object DiskQueue -Descending | Select-Object -First 10

# Export filtered data
$log | Where-Object { $_.Phase -ne 'Idle' } |
    Export-Csv "update_activity.csv" -NoTypeInformation
```

### Analyzing Anomalies

```powershell
# Count anomalies by hour
$log | Group-Object { ([DateTime]$_.Timestamp).Hour } |
    Select-Object Name, Count |
    Sort-Object Name

# Find high CPU periods
$log | Where-Object { [double]$_.CPU -gt 80 } |
    Select-Object Timestamp, CPU, Phase
```

---

## Building for Distribution

### Create Windows Installer

```powershell
# Build for Windows
npm run build:win

# Output will be in dist/
# - Windows installer (.exe)
# - Portable executable
# - Auto-update files
```

### Build Configuration

Edit `package.json` to customize build:

```json
{
  "build": {
    "appId": "com.yourcompany.windowsupdatemonitor",
    "productName": "Windows Update Monitor",
    "win": {
      "target": ["nsis", "portable"],
      "icon": "assets/icons/icon.png"
    }
  }
}
```

---

## Integration Ideas

### Export Data for Analysis

```powershell
# Combine multiple days
Get-ChildItem "C:\00_TOOLS\00_Logs\WinUpdateMonitor\*.csv" |
    ForEach-Object { Import-Csv $_ } |
    Export-Csv "combined_metrics.csv" -NoTypeInformation
```

### Alerting via Email

Add to Monitor.ps1:

```powershell
# After anomaly detection
if ($anomalies.Count -gt 0) {
    Send-MailMessage -To "admin@company.com" `
        -Subject "Windows Update Anomaly Detected" `
        -Body "Anomalies: $($anomalies | ConvertTo-Json)" `
        -SmtpServer "smtp.company.com"
}
```

### Integration with Monitoring Systems

The CSV logs can be imported into:
- **Splunk**: Real-time log analysis
- **Grafana**: Custom dashboards
- **Power BI**: Detailed reports
- **Excel**: Manual analysis

---

## Security Considerations

### Running as Administrator

The monitor **may require** administrator privileges for:
- Performance counter access
- Windows Update process detection
- System-wide network metrics

**Best Practice**: Run monitor as admin, dashboard as regular user.

### Network Security

- Dashboard reads only local files (no network access)
- All data stored locally on the machine
- No telemetry or external connections
- VPN detection is read-only

---

## FAQ

**Q: Can I run this on Windows Server?**
A: Yes, it works on Windows Server 2016+.

**Q: Does this affect Windows Update performance?**
A: No, it only reads metrics. Impact is minimal (<1% CPU).

**Q: Can I monitor multiple machines?**
A: Not in Phase 1. Phase 3 will add multi-machine support.

**Q: How much disk space do logs use?**
A: Approximately 1-2 MB per day of continuous monitoring.

**Q: Can I customize the dashboard UI?**
A: Yes! Edit files in `src/renderer/` - HTML, CSS, and JavaScript.

**Q: Does this work during Windows 11 updates?**
A: Yes, fully compatible with Windows 10 and 11.

---

## Getting Help

- **Issues**: https://github.com/rubenmiguelborges/UPDATING_WINDOWS_Dashboard/issues
- **Documentation**: See README.md and TEST_REPORT.md
- **Wiki**: https://github.com/rubenmiguelborges/UPDATING_WINDOWS_Dashboard/wiki

---

**Happy Monitoring!** 🚀
