const { contextBridge, ipcRenderer } = require('electron');
const fs = require('fs').promises;
const path = require('path');
const os = require('os');

contextBridge.exposeInMainWorld('electronAPI', {
    // Read live.json file
    readLiveData: async () => {
        const liveJsonPath = path.join(os.tmpdir(), 'WinUpdateMonState', 'live.json');
        try {
            const data = await fs.readFile(liveJsonPath, 'utf8');
            return JSON.parse(data);
        } catch (error) {
            console.warn('Failed to read live.json:', error.message);
            return null;
        }
    },

    // Watch file changes
    watchFile: (filePath, callback) => {
        const chokidar = require('chokidar');
        const watcher = chokidar.watch(filePath, {
            persistent: true,
            awaitWriteFinish: { stabilityThreshold: 100 }
        });

        watcher.on('change', () => callback());
        watcher.on('error', (error) => console.error('Watcher error:', error));

        return () => watcher.close();
    },

    // Read historical CSV
    readHistoricalData: async (dirPath, fileName) => {
        try {
            const filePath = path.join(dirPath, fileName);
            const data = await fs.readFile(filePath, 'utf8');
            return data;
        } catch (error) {
            console.warn('Failed to read historical data:', error.message);
            return null;
        }
    },

    // Get platform information
    getPlatform: () => process.platform,

    // Get temp directory
    getTempDir: () => os.tmpdir()
});
