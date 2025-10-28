# Windows Update Monitor Dashboard

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)
![Electron](https://img.shields.io/badge/electron-39.0.0-blue.svg)

Electron-based desktop application for monitoring Windows Update processes in real-time.

## Features

- **Real-time System Metrics**: Live monitoring of CPU, Memory, Disk Queue, and Network usage
- **Update Phase Detection**: Automatic detection of update phases (Downloading, Installing, Configuring)
- **Anomaly Detection**: Real-time alerts for unusual system behavior
- **VPN-aware Monitoring**: Detects VPN connections that may affect metrics
- **60-second Historical Charts**: Interactive Chart.js visualizations
- **System Tray Integration**: Minimize to tray for background monitoring
- **Dark Theme UI**: Modern, easy-on-the-eyes interface

## Screenshots

*Coming soon*

## Architecture

The dashboard consists of two main components:

1. **PowerShell Monitor** (`src/monitor/Monitor.ps1`): Collects system metrics every 1 second and writes to `live.json`
2. **Electron Dashboard**: Reads `live.json` and displays real-time data with charts and analytics

### Data Flow

```
PowerShell Monitor → %TEMP%\WinUpdateMonState\live.json → Electron Dashboard
```

## Installation

### Prerequisites

- **Node.js**: 20+ LTS ([Download](https://nodejs.org/))
- **Windows**: 10/11 (64-bit)
- **PowerShell**: 7+ ([Download](https://github.com/PowerShell/PowerShell))

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/rubenmiguelborges/UPDATING_WINDOWS_Dashboard.git
   cd UPDATING_WINDOWS_Dashboard
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. (Optional) Create PowerShell monitor script:
   ```bash
   # Copy Monitor.ps1 to src/monitor/ if not already present
   ```

## Usage

### Development Mode

1. Start the PowerShell monitor:
   ```powershell
   pwsh -File src/monitor/Monitor.ps1 -Dashboard
   ```

2. Launch the Electron app:
   ```bash
   npm run dev
   ```

The dashboard will automatically connect to the monitor and display real-time metrics.

### Production Build

Build the application for Windows:

```bash
npm run build:win
```

The built application will be in the `dist/` directory.

## Configuration

### Monitor Settings

Edit `src/monitor/Monitor.ps1` to adjust:
- Sampling interval (default: 1 second)
- Anomaly detection thresholds
- Output paths

### Dashboard Settings

The dashboard automatically reads from:
- **Live data**: `%TEMP%\WinUpdateMonState\live.json`
- **Historical logs**: `C:\00_TOOLS\00_Logs\WinUpdateMonitor\`

## Development

### Project Structure

```
UPDATING_WINDOWS_Dashboard/
├── electron/
│   ├── main.js              # Main process entry point
│   └── preload.js           # Secure context bridge
├── src/
│   ├── renderer/
│   │   ├── index.html       # Main UI
│   │   ├── js/
│   │   │   ├── main.js      # UI controller
│   │   │   ├── dataLoader.js   # File watcher & data parsing
│   │   │   ├── charts.js       # Chart.js wrapper
│   │   │   └── phaseDetector.js # Update phase analysis
│   │   └── styles/
│   │       └── main.css     # Dark theme styling
│   └── monitor/
│       └── Monitor.ps1      # PowerShell data collector
├── assets/
│   └── icons/
│       └── icon.png         # App icon
├── package.json
└── README.md
```

### Technologies Used

- **Electron**: Desktop application framework
- **Chart.js**: Real-time charting library
- **Chokidar**: File system watcher
- **PowerShell 7**: System metrics collection

## Roadmap

### Phase 1: MVP Core Functionality ✅
- [x] Real-time metrics display
- [x] Phase detection
- [x] Anomaly alerts
- [x] System tray integration

### Phase 2: Enhanced Analytics (Planned)
- [ ] Historical data analysis
- [ ] Export to CSV/JSON
- [ ] Custom alert rules
- [ ] Performance reports

### Phase 3: Advanced Features (Future)
- [ ] Multi-machine monitoring
- [ ] Remote dashboard access
- [ ] Machine learning phase prediction
- [ ] Integration with SCCM/Intune

## Troubleshooting

### Dashboard shows "No data"

1. Verify the PowerShell monitor is running
2. Check that `%TEMP%\WinUpdateMonState\live.json` exists
3. Ensure the JSON file is being updated (check timestamp)

### Charts not updating

1. Open DevTools (`Ctrl+Shift+I` in dev mode)
2. Check for JavaScript errors
3. Verify file watcher is active

### High CPU usage

1. Increase monitoring interval in `Monitor.ps1`
2. Reduce chart history length in `charts.js` (maxDataPoints)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Electron](https://www.electronjs.org/)
- Charts powered by [Chart.js](https://www.chartjs.org/)
- Inspired by the need for better Windows Update visibility

## Support

For issues and questions:
- Open an issue on [GitHub Issues](https://github.com/rubenmiguelborges/UPDATING_WINDOWS_Dashboard/issues)
- Check the [Wiki](https://github.com/rubenmiguelborges/UPDATING_WINDOWS_Dashboard/wiki) for detailed documentation

---

**Note**: This is Phase 1 (MVP). More features coming soon!