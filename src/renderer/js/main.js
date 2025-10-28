let dataLoader;
let chartManager;
let phaseDetector;
let sessionStart;

async function initialize() {
    sessionStart = new Date();

    dataLoader = new DataLoader();
    await dataLoader.initialize();

    chartManager = new ChartManager();
    phaseDetector = new PhaseDetector();

    // Create charts
    chartManager.createChart('cpu-chart', 'CPU %', '#48bb78');
    chartManager.createChart('mem-chart', 'Memory %', '#4299e1');
    chartManager.createChart('disk-chart', 'Disk Queue', '#9f7aea');
    chartManager.createChart('net-chart', 'Network MB/s', '#ed8936');

    // Start monitoring
    dataLoader.startLiveMonitoring(handleMetricsUpdate);

    // Update clock
    setInterval(updateClock, 1000);

    // Setup speedup button
    setupSpeedupButton();

    console.log('Dashboard initialized successfully');
}

function handleMetricsUpdate(data) {
    // Update metric displays
    updateMetric('cpu', data.cpu, 100);
    updateMetric('mem', data.mem, 100);
    updateMetric('disk', data.diskQ, 10);
    updateMetric('net', data.netTotal, 100);

    // Update charts
    chartManager.updateChart('cpu-chart', data.cpu);
    chartManager.updateChart('mem-chart', data.mem);
    chartManager.updateChart('disk-chart', data.diskQ);
    chartManager.updateChart('net-chart', data.netTotal);

    // Update phase
    const phaseInfo = phaseDetector.detect(data);
    updatePhase(phaseInfo);

    // Show anomalies
    updateAnomalies(data.anomalies);

    // VPN warning
    if (data.vpn && data.vpn.Active) {
        showVPNWarning(data.vpn);
    } else {
        hideVPNWarning();
    }
}

function updateMetric(id, value, max) {
    const valueEl = document.getElementById(`${id}-value`);
    const barEl = document.getElementById(`${id}-bar`);

    if (!valueEl || !barEl) return;

    if (id === 'net') {
        valueEl.textContent = `${value.toFixed(2)} MB/s`;
    } else if (id === 'disk') {
        valueEl.textContent = value.toFixed(1);
    } else {
        valueEl.textContent = `${value.toFixed(1)}%`;
    }

    const percent = Math.min((value / max) * 100, 100);
    barEl.style.width = `${percent}%`;

    // Color coding based on value
    let color = '#48bb78'; // green
    if (percent > 80) color = '#f56565'; // red
    else if (percent > 60) color = '#ed8936'; // orange

    barEl.style.backgroundColor = color;
}

function updatePhase(phaseInfo) {
    const badge = document.getElementById('current-phase');
    if (!badge) return;

    badge.textContent = `${phaseInfo.phase} (${phaseInfo.duration}s)`;
    badge.className = `status-badge status-${phaseInfo.phase.toLowerCase()}`;

    // Update confidence if element exists
    const confidenceEl = document.getElementById('phase-confidence');
    if (confidenceEl) {
        confidenceEl.textContent = `${(phaseInfo.confidence * 100).toFixed(0)}%`;
    }
}

function updateAnomalies(anomalies) {
    const container = document.getElementById('anomalies-container');
    if (!container) return;

    // Handle null, undefined, or empty arrays
    if (!anomalies || !Array.isArray(anomalies) || anomalies.length === 0) {
        container.innerHTML = '<div class="no-anomalies">No anomalies detected</div>';
        return;
    }

    container.innerHTML = anomalies.map(a => `
        <div class="anomaly anomaly-${a.Severity.toLowerCase()}">
            <strong>${a.Metric} Anomaly (${a.Severity}):</strong> ${a.Message}
        </div>
    `).join('');
}

function showVPNWarning(vpn) {
    const warning = document.getElementById('vpn-warning');
    if (!warning) return;

    warning.style.display = 'block';

    const adaptersEl = document.getElementById('vpn-adapters');
    const messageEl = document.getElementById('vpn-message');

    if (adaptersEl) adaptersEl.textContent = vpn.Adapters || 'Unknown';
    if (messageEl) messageEl.textContent = vpn.Warning || 'VPN connection detected';
}

function hideVPNWarning() {
    const warning = document.getElementById('vpn-warning');
    if (warning) {
        warning.style.display = 'none';
    }
}

function updateClock() {
    const timeEl = document.getElementById('current-time');
    const uptimeEl = document.getElementById('session-uptime');

    if (timeEl) {
        timeEl.textContent = new Date().toLocaleTimeString();
    }

    if (uptimeEl) {
        const uptime = Math.floor((new Date() - sessionStart) / 1000);
        const hours = Math.floor(uptime / 3600);
        const minutes = Math.floor((uptime % 3600) / 60);
        const seconds = uptime % 60;

        uptimeEl.textContent =
            `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
}

function setupSpeedupButton() {
    const speedupBtn = document.getElementById('speedup-btn');
    const statusDiv = document.getElementById('speedup-status');

    if (!speedupBtn) return;

    speedupBtn.addEventListener('click', async () => {
        speedupBtn.disabled = true;
        speedupBtn.textContent = '⏳ Optimizing...';

        statusDiv.style.display = 'block';
        statusDiv.className = 'speedup-status info';
        statusDiv.textContent = 'Running Windows Update optimization commands...';

        try {
            const result = await window.electronAPI.speedupUpdates();

            if (result.success) {
                statusDiv.className = 'speedup-status success';
                statusDiv.textContent = `✓ ${result.message}`;
            } else {
                statusDiv.className = 'speedup-status error';
                statusDiv.textContent = `✗ ${result.message}`;
            }
        } catch (error) {
            statusDiv.className = 'speedup-status error';
            statusDiv.textContent = `✗ Error: ${error.message}`;
        }

        // Re-enable button after 10 seconds
        setTimeout(() => {
            speedupBtn.disabled = false;
            speedupBtn.textContent = '⚡ Speed Up Updates';
        }, 10000);

        // Hide status after 15 seconds
        setTimeout(() => {
            statusDiv.style.display = 'none';
        }, 15000);
    });
}

// Initialize on load
document.addEventListener('DOMContentLoaded', initialize);

// Cleanup on unload
window.addEventListener('beforeunload', () => {
    if (dataLoader) {
        dataLoader.stopLiveMonitoring();
    }
});
