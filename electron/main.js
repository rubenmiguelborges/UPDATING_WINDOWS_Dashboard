const { app, BrowserWindow, Tray, Menu, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs').promises;
const os = require('os');
const chokidar = require('chokidar');

let mainWindow;
let tray;
let fileWatcher = null;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        minWidth: 1024,
        minHeight: 768,
        backgroundColor: '#0a0e27',
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
            nodeIntegration: false,
            contextIsolation: true
        }
    });

    mainWindow.loadFile('src/renderer/index.html');

    // Open DevTools in development
    if (process.argv.includes('--dev')) {
        mainWindow.webContents.openDevTools();
    }

    // Minimize to tray instead of closing
    mainWindow.on('close', (event) => {
        if (!app.isQuitting) {
            event.preventDefault();
            mainWindow.hide();
        }
    });
}

function createTray() {
    const iconPath = path.join(__dirname, '../assets/icons/icon.png');

    // Only create tray if icon exists
    const fs = require('fs');
    if (!fs.existsSync(iconPath)) {
        console.warn('Tray icon not found at:', iconPath);
        return;
    }

    tray = new Tray(iconPath);

    const contextMenu = Menu.buildFromTemplate([
        { label: 'Show Dashboard', click: () => mainWindow.show() },
        { type: 'separator' },
        { label: 'Quit', click: () => {
            app.isQuitting = true;
            app.quit();
        }}
    ]);

    tray.setContextMenu(contextMenu);
    tray.setToolTip('Windows Update Monitor');

    tray.on('click', () => {
        mainWindow.isVisible() ? mainWindow.hide() : mainWindow.show();
    });
}

// IPC handler for reading live data
ipcMain.handle('read-live-data', async () => {
    const liveJsonPath = path.join(os.tmpdir(), 'WinUpdateMonState', 'live.json');
    try {
        const data = await fs.readFile(liveJsonPath, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.warn('Failed to read live.json:', error.message);
        return null;
    }
});

// IPC handler for watching file
ipcMain.on('watch-file', (event, filePath) => {
    if (fileWatcher) {
        fileWatcher.close();
    }

    fileWatcher = chokidar.watch(filePath, {
        persistent: true,
        awaitWriteFinish: { stabilityThreshold: 100 }
    });

    fileWatcher.on('change', () => {
        event.sender.send('file-changed');
    });
});

// IPC handler for unwatching file
ipcMain.on('unwatch-file', () => {
    if (fileWatcher) {
        fileWatcher.close();
        fileWatcher = null;
    }
});

// IPC handler for reading historical data
ipcMain.handle('read-historical-data', async (event, dirPath, fileName) => {
    try {
        const filePath = path.join(dirPath, fileName);
        const data = await fs.readFile(filePath, 'utf8');
        return data;
    } catch (error) {
        console.warn('Failed to read historical data:', error.message);
        return null;
    }
});

// IPC handler for speedup updates
ipcMain.handle('speedup-updates', async () => {
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);

    try {
        // PowerShell commands to optimize Windows Update
        const commands = [
            'Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue',
            'Stop-Service -Name bits -Force -ErrorAction SilentlyContinue',
            'Remove-Item -Path "$env:SystemRoot\\SoftwareDistribution\\Download\\*" -Recurse -Force -ErrorAction SilentlyContinue',
            'Start-Service -Name bits',
            'Start-Service -Name wuauserv',
            'wuauclt /detectnow /updatenow'
        ].join('; ');

        const psCommand = `powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "${commands}"`;

        await execAsync(psCommand, { timeout: 30000 });

        return {
            success: true,
            message: 'Windows Update services optimized successfully! Updates will resume shortly.'
        };
    } catch (error) {
        console.error('Speedup failed:', error);
        return {
            success: false,
            message: `Optimization failed: ${error.message}. Try running as Administrator.`
        };
    }
});

app.whenReady().then(() => {
    createWindow();
    createTray();
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});
