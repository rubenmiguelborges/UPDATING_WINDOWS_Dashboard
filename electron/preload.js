const { contextBridge, ipcRenderer } = require('electron');

// Expose safe APIs to the renderer process via IPC
contextBridge.exposeInMainWorld('electronAPI', {
    // Read live.json file
    readLiveData: async () => {
        return await ipcRenderer.invoke('read-live-data');
    },

    // Watch file changes
    watchFile: (filePath, callback) => {
        ipcRenderer.on('file-changed', () => callback());
        ipcRenderer.send('watch-file', filePath);

        return () => {
            ipcRenderer.send('unwatch-file', filePath);
        };
    },

    // Read historical CSV
    readHistoricalData: async (dirPath, fileName) => {
        return await ipcRenderer.invoke('read-historical-data', dirPath, fileName);
    },

    // Get platform information
    getPlatform: () => process.platform,

    // Get temp directory
    getTempDir: () => {
        return process.platform === 'win32' ? process.env.TEMP : '/tmp';
    },

    // Speed up Windows Updates
    speedupUpdates: async () => {
        return await ipcRenderer.invoke('speedup-updates');
    }
});
