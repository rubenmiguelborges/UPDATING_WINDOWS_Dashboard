<#
.SYNOPSIS
    Windows Update Monitor - Real-time System Metrics Collector

.DESCRIPTION
    Monitors system performance metrics and Windows Update activity in real-time.
    Writes data to live.json for consumption by the Electron dashboard.

.PARAMETER Dashboard
    Optimized mode for dashboard consumption (writes to live.json)

.PARAMETER Verbose
    Enable verbose logging output

.PARAMETER Interval
    Sampling interval in seconds (default: 1)

.EXAMPLE
    .\Monitor.ps1 -Dashboard
    Run in dashboard mode with 1-second intervals

.EXAMPLE
    .\Monitor.ps1 -Dashboard -Interval 2 -Verbose
    Run with 2-second intervals and verbose output

.NOTES
    Author: Windows Update Monitor Project
    Version: 1.0.0
    Requires: PowerShell 5.1+ (PowerShell 7+ recommended)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Dashboard,

    [Parameter()]
    [int]$Interval = 1,

    [Parameter()]
    [string]$OutputPath = "$env:TEMP\WinUpdateMonState",

    [Parameter()]
    [string]$LogPath = "C:\00_TOOLS\00_Logs\WinUpdateMonitor"
)

#Requires -Version 5.1

# Configuration
$ErrorActionPreference = 'Continue'
$VerbosePreference = if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"]) { "Continue" } else { "SilentlyContinue" }

# Global variables
$script:SessionStart = Get-Date
$script:SampleCount = 0
$script:PhaseHistory = @()
$script:BaselineMetrics = @{
    CPU = 0
    Memory = 0
    Disk = 0
    Network = 0
}

# Windows Update related processes
$script:WUProcesses = @(
    'TiWorker',          # Windows Update Worker
    'wuauclt',           # Windows Update Client
    'UsoClient',         # Update Session Orchestrator
    'TrustedInstaller',  # Windows Modules Installer
    'svchost',           # Service Host (when running wuauserv)
    'UpdateAssistant',   # Windows Update Assistant
    'MusNotification'    # Windows Update Notification
)

#region Helper Functions

function Initialize-Paths {
    <#
    .SYNOPSIS
        Create required directories for data output
    #>
    param()

    try {
        # Create output directory for live.json
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            Write-Verbose "Created output directory: $OutputPath"
        }

        # Create log directory for historical data
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
            Write-Verbose "Created log directory: $LogPath"
        }

        return $true
    }
    catch {
        Write-Error "Failed to initialize paths: $_"
        return $false
    }
}

function Get-CPUUsage {
    <#
    .SYNOPSIS
        Get current CPU usage percentage
    #>
    param()

    try {
        $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
        return [math]::Round($cpu.CounterSamples[0].CookedValue, 2)
    }
    catch {
        Write-Warning "Failed to get CPU usage: $_"
        return 0
    }
}

function Get-MemoryUsage {
    <#
    .SYNOPSIS
        Get current memory usage percentage
    #>
    param()

    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $totalMem = $os.TotalVisibleMemorySize
        $freeMem = $os.FreePhysicalMemory
        $usedMem = $totalMem - $freeMem
        $percentUsed = [math]::Round(($usedMem / $totalMem) * 100, 2)
        return $percentUsed
    }
    catch {
        Write-Warning "Failed to get memory usage: $_"
        return 0
    }
}

function Get-DiskQueueLength {
    <#
    .SYNOPSIS
        Get current disk queue length (I/O operations waiting)
    #>
    param()

    try {
        $disk = Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length' -ErrorAction Stop
        return [math]::Round($disk.CounterSamples[0].CookedValue, 2)
    }
    catch {
        Write-Warning "Failed to get disk queue: $_"
        return 0
    }
}

function Get-NetworkThroughput {
    <#
    .SYNOPSIS
        Get current network throughput in MB/s
    #>
    param()

    try {
        $net = Get-Counter '\Network Interface(*)\Bytes Total/sec' -ErrorAction Stop
        $totalBytes = ($net.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum
        $totalMB = [math]::Round($totalBytes / 1MB, 2)
        return $totalMB
    }
    catch {
        Write-Warning "Failed to get network throughput: $_"
        return 0
    }
}

function Test-VPNConnection {
    <#
    .SYNOPSIS
        Check for active VPN connections
    #>
    param()

    try {
        $vpnAdapters = Get-NetAdapter -ErrorAction Stop | Where-Object {
            # Match VPN/Virtual adapters
            $isVirtual = $_.InterfaceDescription -match 'VPN|TAP|Tunnel' -or
                         ($_.Name -match 'VPN|TAP|Tunnel')

            # Exclude WSL and Hyper-V management adapters
            $isWSL = $_.Name -match 'WSL|Hyper-V' -or
                     $_.InterfaceDescription -match 'Hyper-V|WSL'

            # Include if it's virtual but not WSL, and it's up
            $isVirtual -and -not $isWSL -and $_.Status -eq 'Up'
        }

        if ($vpnAdapters) {
            return @{
                Active = $true
                Adapters = ($vpnAdapters.Name -join ', ')
                Warning = "VPN detected - network metrics may be affected"
            }
        }
        else {
            return @{
                Active = $false
                Adapters = ''
                Warning = ''
            }
        }
    }
    catch {
        Write-Warning "Failed to check VPN: $_"
        return @{
            Active = $false
            Adapters = ''
            Warning = ''
        }
    }
}

function Get-WindowsUpdateProcesses {
    <#
    .SYNOPSIS
        Detect running Windows Update processes
    #>
    param()

    try {
        $wuProcesses = Get-Process -ErrorAction Stop | Where-Object {
            $_.ProcessName -in $script:WUProcesses
        }

        return $wuProcesses
    }
    catch {
        Write-Warning "Failed to get Windows Update processes: $_"
        return @()
    }
}

function Detect-UpdatePhase {
    <#
    .SYNOPSIS
        Detect current Windows Update phase based on metrics and processes
    #>
    param(
        [double]$CPU,
        [double]$Memory,
        [double]$DiskQ,
        [double]$NetTotal,
        [array]$Processes
    )

    $phase = "Idle"
    $confidence = 0.5

    # Check for Windows Update processes
    $hasWUProcess = $Processes.Count -gt 0

    # Rule-based phase detection
    if ($NetTotal -gt 5 -and $CPU -lt 30 -and $hasWUProcess) {
        $phase = "Downloading"
        $confidence = 0.9
    }
    elseif ($CPU -gt 40 -and $DiskQ -gt 3 -and $hasWUProcess) {
        $phase = "Installing"
        $confidence = 0.85
    }
    elseif ($DiskQ -gt 5 -and $CPU -gt 30 -and $NetTotal -lt 1 -and $hasWUProcess) {
        $phase = "Configuring"
        $confidence = 0.8
    }
    elseif ($CPU -gt 20 -and $NetTotal -lt 1 -and $hasWUProcess) {
        $phase = "Processing"
        $confidence = 0.7
    }
    elseif ($CPU -lt 10 -and $NetTotal -lt 1 -and $DiskQ -lt 2) {
        $phase = "Idle"
        $confidence = 0.95
    }

    return @{
        Phase = $phase
        Confidence = $confidence
        ProcessCount = $Processes.Count
    }
}

function Detect-Anomalies {
    <#
    .SYNOPSIS
        Detect anomalies in system metrics
    #>
    param(
        [double]$CPU,
        [double]$Memory,
        [double]$DiskQ,
        [double]$NetTotal
    )

    $anomalies = @()

    # CPU anomalies
    if ($CPU -gt 90) {
        $anomalies += @{
            Metric = "CPU"
            Severity = "High"
            Message = "CPU usage critically high: $CPU%"
        }
    }
    elseif ($CPU -gt 75) {
        $anomalies += @{
            Metric = "CPU"
            Severity = "Medium"
            Message = "CPU usage elevated: $CPU%"
        }
    }

    # Memory anomalies
    if ($Memory -gt 95) {
        $anomalies += @{
            Metric = "Memory"
            Severity = "High"
            Message = "Memory usage critically high: $Memory%"
        }
    }
    elseif ($Memory -gt 85) {
        $anomalies += @{
            Metric = "Memory"
            Severity = "Medium"
            Message = "Memory usage elevated: $Memory%"
        }
    }

    # Disk queue anomalies
    if ($DiskQ -gt 10) {
        $anomalies += @{
            Metric = "Disk"
            Severity = "High"
            Message = "Disk queue critically high: $DiskQ"
        }
    }
    elseif ($DiskQ -gt 5) {
        $anomalies += @{
            Metric = "Disk"
            Severity = "Medium"
            Message = "Disk queue elevated: $DiskQ"
        }
    }

    # Network anomalies
    if ($NetTotal -gt 100) {
        $anomalies += @{
            Metric = "Network"
            Severity = "Medium"
            Message = "Network throughput very high: $NetTotal MB/s"
        }
    }

    return $anomalies
}

function Write-LiveData {
    <#
    .SYNOPSIS
        Write current metrics to live.json for dashboard consumption
    #>
    param(
        [hashtable]$Data
    )

    try {
        $jsonPath = Join-Path $OutputPath "live.json"
        $jsonData = $Data | ConvertTo-Json -Depth 10 -Compress

        # Write atomically to prevent partial reads
        $tempPath = "$jsonPath.tmp"
        [System.IO.File]::WriteAllText($tempPath, $jsonData)
        Move-Item -Path $tempPath -Destination $jsonPath -Force

        Write-Verbose "Updated live.json"
    }
    catch {
        Write-Warning "Failed to write live.json: $_"
    }
}

function Write-HistoricalLog {
    <#
    .SYNOPSIS
        Append metrics to CSV log file
    #>
    param(
        [hashtable]$Data
    )

    try {
        $csvPath = Join-Path $LogPath "metrics_$(Get-Date -Format 'yyyy-MM-dd').csv"

        $csvData = [PSCustomObject]@{
            Timestamp = $Data.timestamp
            CPU = $Data.cpu
            Memory = $Data.mem
            DiskQueue = $Data.diskQ
            NetworkMBps = $Data.netTotal
            Phase = $Data.phase
            AnomalyCount = $Data.anomalies.Count
        }

        $csvData | Export-Csv -Path $csvPath -Append -NoTypeInformation -Force

        Write-Verbose "Appended to historical log"
    }
    catch {
        Write-Warning "Failed to write historical log: $_"
    }
}

#endregion

#region Main Monitoring Loop

function Start-Monitoring {
    <#
    .SYNOPSIS
        Main monitoring loop
    #>
    param()

    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "Windows Update Monitor - Starting..." -ForegroundColor Green
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow
    Write-Host "Log Path: $LogPath" -ForegroundColor Yellow
    Write-Host "Interval: $Interval second(s)" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Red
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""

    # Initialize paths
    if (-not (Initialize-Paths)) {
        Write-Error "Failed to initialize. Exiting."
        return
    }

    # Main loop
    while ($true) {
        try {
            $script:SampleCount++

            # Collect metrics
            $cpu = Get-CPUUsage
            $mem = Get-MemoryUsage
            $diskQ = Get-DiskQueueLength
            $netTotal = Get-NetworkThroughput

            # Check VPN
            $vpn = Test-VPNConnection

            # Get Windows Update processes
            $wuProcesses = Get-WindowsUpdateProcesses

            # Detect phase
            $phaseInfo = Detect-UpdatePhase -CPU $cpu -Memory $mem -DiskQ $diskQ -NetTotal $netTotal -Processes $wuProcesses

            # Detect anomalies
            $anomalies = Detect-Anomalies -CPU $cpu -Memory $mem -DiskQ $diskQ -NetTotal $netTotal

            # Build data object
            $data = @{
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                cpu = $cpu
                mem = $mem
                diskQ = $diskQ
                netTotal = $netTotal
                phase = $phaseInfo.Phase
                confidence = $phaseInfo.Confidence
                processCount = $phaseInfo.ProcessCount
                anomalies = $anomalies
                vpn = $vpn
                sampleCount = $script:SampleCount
                uptime = [math]::Round(((Get-Date) - $script:SessionStart).TotalSeconds, 0)
            }

            # Write to live.json
            if ($Dashboard) {
                Write-LiveData -Data $data
            }

            # Write to historical log (once per minute)
            if ($script:SampleCount % 60 -eq 0) {
                Write-HistoricalLog -Data $data
            }

            # Console output
            $timestamp = Get-Date -Format "HH:mm:ss"
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "CPU: $($cpu)% " -NoNewline -ForegroundColor $(if($cpu -gt 75){'Red'}elseif($cpu -gt 50){'Yellow'}else{'Green'})
            Write-Host "| MEM: $($mem)% " -NoNewline -ForegroundColor $(if($mem -gt 85){'Red'}elseif($mem -gt 70){'Yellow'}else{'Green'})
            Write-Host "| DISK: $diskQ " -NoNewline -ForegroundColor $(if($diskQ -gt 5){'Red'}elseif($diskQ -gt 3){'Yellow'}else{'Green'})
            Write-Host "| NET: $($netTotal) MB/s " -NoNewline -ForegroundColor $(if($netTotal -gt 50){'Yellow'}else{'Green'})
            Write-Host "| Phase: $($phaseInfo.Phase)" -ForegroundColor Cyan

            if ($anomalies.Count -gt 0) {
                Write-Host "  ⚠️  Anomalies: $($anomalies.Count)" -ForegroundColor Red
            }

            if ($vpn.Active) {
                Write-Host "  🔒 VPN Active: $($vpn.Adapters)" -ForegroundColor Yellow
            }

            # Sleep
            Start-Sleep -Seconds $Interval
        }
        catch {
            Write-Error "Error in monitoring loop: $_"
            Start-Sleep -Seconds $Interval
        }
    }
}

#endregion

# Start monitoring
try {
    Start-Monitoring
}
catch {
    Write-Error "Fatal error: $_"
}
finally {
    Write-Host "`nMonitoring stopped. Total samples: $script:SampleCount" -ForegroundColor Yellow
}
