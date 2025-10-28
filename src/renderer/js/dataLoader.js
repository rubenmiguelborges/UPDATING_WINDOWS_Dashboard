class DataLoader {
    constructor() {
        this.liveJsonPath = null;
        this.stopWatcher = null;
        this.callbacks = [];
        this.updateInterval = null;
    }

    async initialize() {
        // Setup path for live.json
        const tempDir = window.electronAPI.getTempDir();
        this.liveJsonPath = `${tempDir}/WinUpdateMonState/live.json`;
        console.log('Monitoring live data at:', this.liveJsonPath);
        return this;
    }

    async getLiveMetrics() {
        const data = await window.electronAPI.readLiveData();
        return data || {
            timestamp: new Date().toISOString(),
            cpu: 0,
            mem: 0,
            diskQ: 0,
            netTotal: 0,
            phase: 'Idle',
            anomalies: [],
            vpn: { Active: false }
        };
    }

    startLiveMonitoring(callback) {
        this.callbacks.push(callback);

        // Watch file for changes
        this.stopWatcher = window.electronAPI.watchFile(this.liveJsonPath, async () => {
            const data = await this.getLiveMetrics();
            this.callbacks.forEach(cb => cb(data));
        });

        // Also poll every 2 seconds as fallback
        this.updateInterval = setInterval(async () => {
            const data = await this.getLiveMetrics();
            this.callbacks.forEach(cb => cb(data));
        }, 2000);

        // Initial load
        this.getLiveMetrics().then(data => callback(data));
    }

    stopLiveMonitoring() {
        if (this.stopWatcher) {
            this.stopWatcher();
            this.stopWatcher = null;
        }
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
        }
        this.callbacks = [];
    }

    async readHistoricalCSV(dirPath, fileName) {
        const csvData = await window.electronAPI.readHistoricalData(dirPath, fileName);
        if (!csvData) return [];

        // Parse CSV
        const lines = csvData.trim().split('\n');
        if (lines.length < 2) return [];

        const headers = lines[0].split(',');
        const rows = [];

        for (let i = 1; i < lines.length; i++) {
            const values = lines[i].split(',');
            const row = {};
            headers.forEach((header, index) => {
                row[header.trim()] = values[index]?.trim() || '';
            });
            rows.push(row);
        }

        return rows;
    }
}
